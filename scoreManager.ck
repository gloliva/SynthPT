@import {"events.ck", "instrument.ck", "logger.ck", "scoreParser.ck", "utils.ck"}
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

        this.currScoreIdx - 1 => int prevScoreIdx;
        if (prevScoreIdx < 0) {
            this.scoreFiles.size() + prevScoreIdx => prevScoreIdx;
        }
        this.prevScore.parse(Utils.joinPath(this.openDirName, scoreFiles[prevScoreIdx]));

        <<< "hhhh", this.currScore.name, this.nextScore.name >>>;
        Events.scoreNamesEvent.set(this.currScore.name, this.nextScore.name);
        Events.scoreNamesEvent.broadcast();

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
        if (this.player.isPlaying()) {
            this.player.stop();
        }

        this.updateCurrentScore(this.NEXT_SCORE);
        this.player.play();
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

        // Disconnect current instruments from DAC
        for (CVInstrument instrument : this.currScore.instruments) {
            instrument.disconnect();
        }

        // Parse new scores
        if (delta == this.NEXT_SCORE) {
            <<< "moving to next score" >>>;
            currScore @=> this.prevScore;
            nextScore @=> this.currScore;
            this.nextScore.parse(Utils.joinPath(this.openDirName, scoreFiles[(this.currScoreIdx + 1) % scoreFiles.size()]));

            this.player.score(this.currScore.score);
            this.player.instruments(this.currScore.instruments);
            0 => this.player.pos;
        } else if (delta == this.PREV_SCORE) {

        }
    }

    fun void scorePosTracker() {
        while (true) {
            if (this.player.isPlaying()) {
                Events.scorePosEvent.set(this.player.pos(), this.player.endPos());
                Events.scorePosEvent.signal();
            } else {
                if (this.player.pos() >= this.player.endPos()) {
                    <<< "Waiting......" >>>;
                    2::second => now;
                    this.next();
                }
            }

            25::ms => now;
        }
    }
}
