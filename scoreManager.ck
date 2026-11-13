@import {"events.ck", "logger.ck", "scoreParser.ck", "utils.ck"}
@import "smuck"

public class ScoreManager {
    -1 => int PREV_SCORE;
    1 => int NEXT_SCORE;

    Score prevScore;
    Score currScore;
    Score nextScore;

    ezScorePlayer player;

    int currScoreIdx;
    string openDirName;
    string scoreFiles[];

    FileIO fio;

    fun void openDirectory(string dirName) {
        if (!fio.open(dirName)) {
            Logger.error("Unable to open directory: " + dirName);
            return;
        }

        dirName => this.openDirName;

        this.fio.dirList() @=> scoreFiles;

        if (scoreFiles.size() < 1) {
            Logger.warn("Empty directory: " + this.openDirName);
            return;
        }

        // TODO: add validation for file, make sure its JSON
        this.currScore.parse(Utils.joinPath(this.openDirName, scoreFiles[this.currScoreIdx]));
        this.nextScore.parse(Utils.joinPath(this.openDirName, scoreFiles[(this.currScoreIdx + 1) % scoreFiles.size()]));

        // Set up ScorePlayer
        this.player.score(this.currScore.score);
        this.player.instruments(this.currScore.instruments);
    }

    fun void run() {
        while (true) {
            Events.scorePlayerEvent => now;

            if (Events.scorePlayerEvent.eventType == ScorePlayerEvent.PLAY) {
                this.play();
            } else if (Events.scorePlayerEvent.eventType == ScorePlayerEvent.PAUSE) {
                this.pause();
            } else if (Events.scorePlayerEvent.eventType == ScorePlayerEvent.NEXT) {
                this.next();
            } else if (Events.scorePlayerEvent.eventType == ScorePlayerEvent.PREV) {
                <<< "we are here, no?" >>>;
                this.prev();
            }
        }
    }

    fun void play() {
        if (!this.player.isPlaying()) {
            <<< "Play the piece?" >>>;
            this.player.play();
        }
    }

    fun void pause() {
        if (this.player.isPlaying()) {
            <<< "PAUSE PAUSE the piece?" >>>;
            this.player.pause();
        }
    }

    fun void next() {
        // if (this.player.isPlaying()) {
        //     this.player.stop();
        // }
    }

    fun void prev() {
        if (this.player.pos() > 0) {
            if (this.player.isPlaying()) {
                this.player.stop();
            }

            0 => this.player.pos;
            Events.playToggleEvent.set(1);
            Events.playToggleEvent.signal();

            this.player.play();
        } else {
            <<< "What player pos are we at?", this.player.pos() >>>;
        }
    }

    fun void updateCurrentScore(int delta) {
        delta +=> this.currScoreIdx;
        if (this.currScoreIdx < 0) {
            this.scoreFiles.size() + this.currScoreIdx => this.currScoreIdx;
        }

        this.scoreFiles.size() %=> this.currScoreIdx;
        <<< "Current score Idx:", this.currScoreIdx >>>;

        // Parse new scores
        if (delta == this.NEXT_SCORE) {

        } else if (delta == this.PREV_SCORE) {

        }
        this.currScore.parse(Utils.joinPath(this.openDirName, scoreFiles[this.currScoreIdx]));
        this.nextScore.parse(Utils.joinPath(this.openDirName, scoreFiles[(this.currScoreIdx + 1) % scoreFiles.size()]));
    }

    fun void sendScorePos() {
        while (true) {
            if (this.player.isPlaying()) {
                Events.scorePosEvent.set(this.player.pos(), this.player.endPos());
                Events.scorePosEvent.signal();
            } else {
                <<< "did we finish?", this.player.pos() >>>;
            }

            25::ms => now;
        }
    }
}
