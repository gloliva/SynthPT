@import {"../base.ck", "../events.ck"}
@import "ChuGUI"


public class MainMenu extends Base {
    // Buttons
    0 => int prevPlayToggle;
    0 => int playToggle;
    0 => int playIconIdx;

    ["play.png", "pause.png"] @=> string playIcons[];
    "next.png" => string nextIcon;
    "prev.png" => string prevIcon;

    // Song names
    string currSongName;
    string nextSongName;

    // Song durations
    "00:00" => string timeElapsed;
    "00:00" => string songLengthTimestamp;
    float songLengthSeconds;

    // Seeker
    float seekerPos;

    fun @construct() {
        // ChuGL setup
        GWindow.title("SynthPT");
        false => GWindow.closeable;
        8. => GG.scene().camera().posZ;
        GG.scene().camera().orthographic();
        Color.BLACK => GG.scene().backgroundColor;

        // Shred management
        spork ~ this.updateUI() @=> Shred updateUIShred;
        spork ~ this.updateScoreInfo() @=> Shred updateScoreInfoShred;
        spork ~ this.updateScorePos() @=> Shred updateScorePosShred;
        spork ~ this.updatePlayToggle() @=> Shred updatePlayToggleShred;
        spork ~ this.run() @=> Shred runShred;
        this.addShreds([updateUIShred, updateScoreInfoShred, updateScorePosShred, updatePlayToggleShred, runShred]);
    }

    fun string _secToTimestamp(float timeInSec) {
        Math.floor(timeInSec / 60.)$int => int minutes;
        (timeInSec % 60)$int => int seconds;

        string timestamp;
        if (minutes < 10) {
            "0" + minutes + ":" => timestamp;
        } else {
            minutes + ":" => timestamp;
        }

        if (seconds < 10) {
            timestamp + "0" + seconds => timestamp;
        } else {
            timestamp + seconds => timestamp;
        }

        return timestamp;
    }

    fun void updateUI() {

        ChuGUI gui --> GG.scene();
        gui.sizeUnits(ChuGUI.WORLD);

        while (true) {
            GG.nextFrame() => now; // must be called before rendering any components

            // Labels
            gui.pushID("Current Song Name");
            UIStyle.pushColor(UIStyle.COL_LABEL, Color.WHITE);
            UIStyle.pushVar(UIStyle.VAR_LABEL_SIZE, 0.25);
            UIStyle.pushVar(UIStyle.VAR_LABEL_CONTROL_POINTS, @(0.5, 0.5));
            gui.label(this.currSongName, @(0.0, 0.2));
            UIStyle.popVar(2);
            UIStyle.popColor(1);
            gui.popID();

            // Time handling labels
            UIStyle.pushColor(UIStyle.COL_LABEL, Color.WHITE);
            UIStyle.pushVar(UIStyle.VAR_LABEL_SIZE, 0.15);
            UIStyle.pushVar(UIStyle.VAR_LABEL_CONTROL_POINTS, @(0.5, 0.5));
            gui.pushID("Time Elapsed");
            gui.label(this.timeElapsed, @(-0.45, 0.));
            gui.popID();

            gui.pushID("Song Length");
            gui.label(this.songLengthTimestamp, @(0.45, 0.));
            gui.popID();
            UIStyle.popVar(2);
            UIStyle.popColor(1);

            // Play/Pause Button
            me.dir() + "../assets/" + this.playIcons[this.playIconIdx] => string playIconFile;

            gui.pushID("playButton");
            UIStyle.pushColor(UIStyle.COL_BUTTON, Color.WHITE);
            UIStyle.pushColor(UIStyle.COL_BUTTON_PRESSED, Color.GREEN);
            UIStyle.pushVar(UIStyle.VAR_BUTTON_CONTROL_POINTS, @(0.5, 0.5));
            UIStyle.pushVar(UIStyle.VAR_BUTTON_BORDER_RADIUS, 1.0);
            UIStyle.pushVar(UIStyle.VAR_BUTTON_SIZE, ChuGUI.NDCToWorldSize(@(0.2, 0.12)));
            UIStyle.pushVar(UIStyle.VAR_BUTTON_ICON_SIZE, 0.4);
            gui.toggleButton("", playIconFile, @(0., -0.2), this.playToggle) => this.playToggle;
            UIStyle.popVar(4);
            UIStyle.popColor(2);
            gui.popID();

            if (this.playToggle != this.prevPlayToggle) {
                if (this.playToggle == 1) {
                    1 => this.playIconIdx;
                    Events.scorePlayerEvent.set(Events.scorePlayerEvent.PLAY);
                } else {
                    0 => this.playIconIdx;
                    Events.scorePlayerEvent.set(Events.scorePlayerEvent.PAUSE);
                }
                Events.scorePlayerEvent.signal();

                this.playToggle => this.prevPlayToggle;
            }

            // Next button
            UIStyle.pushColor(UIStyle.COL_BUTTON, Color.WHITE);
            UIStyle.pushColor(UIStyle.COL_BUTTON_PRESSED, Color.DARKGRAY);
            UIStyle.pushVar(UIStyle.VAR_BUTTON_BORDER_RADIUS, 1.0);
            UIStyle.pushVar(UIStyle.VAR_BUTTON_SIZE, ChuGUI.NDCToWorldSize(@(0.12, 0.12)));
            UIStyle.pushVar(UIStyle.VAR_BUTTON_ICON_SIZE, 0.3);
            gui.button("", me.dir() + "../assets/" + this.nextIcon, @(0.2, -0.2)) => int nextClicked;
            UIStyle.popVar(3);
            UIStyle.popColor(2);

            if (nextClicked) {
                Events.scorePlayerEvent.set(Events.scorePlayerEvent.NEXT);
                Events.scorePlayerEvent.signal();
            }

            // Prev button
            UIStyle.pushColor(UIStyle.COL_BUTTON, Color.WHITE);
            UIStyle.pushColor(UIStyle.COL_BUTTON_PRESSED, Color.DARKGRAY);
            UIStyle.pushVar(UIStyle.VAR_BUTTON_BORDER_RADIUS, 1.0);
            UIStyle.pushVar(UIStyle.VAR_BUTTON_SIZE, ChuGUI.NDCToWorldSize(@(0.12, 0.12)));
            UIStyle.pushVar(UIStyle.VAR_BUTTON_ICON_SIZE, 0.3);
            gui.button("", me.dir() + "../assets/" + this.prevIcon, @(-0.2, -0.2)) => int prevClicked;
            UIStyle.popVar(3);
            UIStyle.popColor(2);

            if (prevClicked) {
                Events.scorePlayerEvent.set(Events.scorePlayerEvent.PREV);
                Events.scorePlayerEvent.signal();
            }

            // Seek bar slider
            UIStyle.pushColor(UIStyle.COL_SLIDER_TRACK, Color.GREEN);
            UIStyle.pushColor(UIStyle.COL_SLIDER_HANDLE, Color.WHITE);
            UIStyle.pushVar(UIStyle.VAR_SLIDER_TRACK_BORDER_RADIUS, 0.4);
            UIStyle.pushVar(UIStyle.VAR_SLIDER_HANDLE_BORDER_RADIUS, 0.4);
            UIStyle.pushVar(UIStyle.VAR_SLIDER_TRACK_BORDER_WIDTH, 0.2);
            UIStyle.pushVar(UIStyle.VAR_SLIDER_HANDLE_SIZE, @(0.1, 0.3));
            gui.slider("seeker", @(0, 0.0), 0, 1, this.seekerPos) => float seekerVal;
            UIStyle.popVar(4);
            UIStyle.popColor(2);

            // Clicked on the seeker this frame
            if (GWindow.mouseLeftDown() && seekerVal != this.seekerPos) {
                Events.seekerChangeEvent.set(seekerVal);
                Events.seekerChangeEvent.broadcast();
            }

            seekerVal => this.seekerPos;
        }
    }

    fun void updateScoreInfo() {
        while (true) {
            Events.scoreInfoEvent => now;
            Events.scoreInfoEvent.name => this.currSongName;
            Events.scoreInfoEvent.seconds => this.songLengthSeconds;
            this._secToTimestamp(Events.scoreInfoEvent.seconds) => this.songLengthTimestamp;
        }
    }

    fun void updatePlayToggle() {
        while (true) {
            Events.playToggleEvent => now;
            Events.playToggleEvent.val => this.playToggle;
            Events.playToggleEvent.val => this.prevPlayToggle;
            Events.playToggleEvent.val => this.playIconIdx;

        }
    }

    fun void updateScorePos() {
        while (true) {
            Events.scorePosEvent => now;
            Std.scalef(Events.scorePosEvent.currPos, 0., Events.scorePosEvent.endPos, 0., 1.) => this.seekerPos;
            Std.scalef(Events.scorePosEvent.currPos, 0., Events.scorePosEvent.endPos, 0., this.songLengthSeconds) => float seconds;
            this._secToTimestamp(seconds) => this.timeElapsed;
        }
    }

    fun void run() {
        while (true) {
            GG.nextFrame() => now;

            // UI
            if (UI.begin("Debugger")) {
                // show a UI display of the current scenegraph
                UI.scenegraph(GG.scene());
            }
            UI.end();
        }
    }
}
