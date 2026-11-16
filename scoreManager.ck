@import {"events.ck", "logger.ck", "scoreParser.ck", "utils.ck"}
@import "smuck"

public class ScoreManager {
    -1 => int PREV_SCORE;
    1 => int NEXT_SCORE;

    Score currScore;
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
        Events.scoreNamesEvent.set(this.currScore.name, "TODO");
        Events.scoreNamesEvent.broadcast();

        // Set up ScorePlayer
        this.currScore.connectInstruments();
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
        if (this.player.isPlaying()) {
            this.player.stop();
        }

        this.updateCurrentScore(this.NEXT_SCORE);
        this.player.play();
    }

    fun void prev() {
        if (this.player.pos() > 1.) {
            if (this.player.isPlaying()) {
                this.player.stop();
                0 => this.player.pos;

                Events.playToggleEvent.set(1);
                Events.playToggleEvent.signal();
                this.player.play();
            } else {
                0 => this.player.pos;
                Events.playToggleEvent.set(0);
                Events.playToggleEvent.signal();

                Events.scorePosEvent.set(0., this.player.endPos());
                Events.scorePosEvent.signal();
            }
        } else {
            <<< "What player pos are we at?", this.player.pos() >>>;
            this.updateCurrentScore(this.PREV_SCORE);
            Events.playToggleEvent.set(1);
            Events.playToggleEvent.signal();
            this.player.play();
        }
    }

    fun void updateCurrentScore(int delta) {
        delta +=> this.currScoreIdx;
        if (this.currScoreIdx < 0) {
            this.scoreFiles.size() + this.currScoreIdx => this.currScoreIdx;
        }

        this.scoreFiles.size() %=> this.currScoreIdx;
        <<< "Current score Idx:", this.currScoreIdx >>>;

        // Disconnect current instruments from DAC
        this.currScore.disconnectInstruments();

        // Parse new scores
        this.currScore.parse(Utils.joinPath(this.openDirName, scoreFiles[this.currScoreIdx]));
        this.currScore.connectInstruments();
        this.player.score(this.currScore.score);
        this.player.instruments(this.currScore.instruments);
        0 => this.player.pos;
    }

    fun void scorePosTracker() {
        while (true) {
            if (this.player.isPlaying()) {
                Events.scorePosEvent.set(this.player.pos(), this.player.endPos());
                Events.scorePosEvent.signal();
            } else {
                if (this.player.pos() >= this.player.endPos()) {
                    this.next();
                }
            }

            25::ms => now;
        }
    }
}
