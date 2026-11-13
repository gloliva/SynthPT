@import "../events.ck"
@import "ChuGUI"


public class MainMenu {
    // Buttons
    0 => int prevPlayToggle;
    0 => int playToggle;
    0 => int playIconIdx;

    ["play.png", "pause.png"] @=> string playIcons[];
    "next.png" => string nextIcon;
    "prev.png" => string prevIcon;

    // Seeker
    float seekerPos;

    fun @construct() {
        GWindow.title("SynthPT");
        8. => GG.scene().camera().posZ;
        GG.scene().camera().orthographic();
        Color.BLACK => GG.scene().backgroundColor;
    }

    fun void updateUI() {

        ChuGUI gui --> GG.scene();
        gui.sizeUnits(ChuGUI.WORLD);

        while (true) {
            GG.nextFrame() => now; // must be called before rendering any components

            // Play/Pause Button
            me.dir() + "../assets/" + this.playIcons[this.playIconIdx] => string playIconFile;

            UIStyle.pushColor(UIStyle.COL_BUTTON, Color.WHITE);
            UIStyle.pushColor(UIStyle.COL_BUTTON_PRESSED, Color.GREEN);
            UIStyle.pushVar(UIStyle.VAR_BUTTON_CONTROL_POINTS, @(0.5, 0.5));
            UIStyle.pushVar(UIStyle.VAR_BUTTON_BORDER_RADIUS, 1.0);
            UIStyle.pushVar(UIStyle.VAR_BUTTON_SIZE, ChuGUI.NDCToWorldSize(@(0.2, 0.12)));
            UIStyle.pushVar(UIStyle.VAR_BUTTON_ICON_SIZE, 0.4);
            gui.toggleButton("", playIconFile, @(0., 0.), this.playToggle) => this.playToggle;
            UIStyle.popVar(4);
            UIStyle.popColor(2);

            if (this.playToggle != this.prevPlayToggle) {
                <<< "playToggle", this.playToggle, "PrevToggle", this.prevPlayToggle >>>;
                if (this.playToggle == 1) {
                    1 => this.playIconIdx;
                    Events.scorePlayerEvent.set(Events.scorePlayerEvent.PLAY);
                } else {
                    0 => this.playIconIdx;
                    Events.scorePlayerEvent.set(Events.scorePlayerEvent.PAUSE);
                }
                Events.scorePlayerEvent.broadcast();

                this.playToggle => this.prevPlayToggle;
            }

            // Next button
            UIStyle.pushColor(UIStyle.COL_BUTTON, Color.WHITE);
            UIStyle.pushColor(UIStyle.COL_BUTTON_PRESSED, Color.DARKGRAY);
            UIStyle.pushVar(UIStyle.VAR_BUTTON_BORDER_RADIUS, 1.0);
            UIStyle.pushVar(UIStyle.VAR_BUTTON_SIZE, ChuGUI.NDCToWorldSize(@(0.12, 0.12)));
            UIStyle.pushVar(UIStyle.VAR_BUTTON_ICON_SIZE, 0.3);
            gui.button("", me.dir() + "../assets/" + this.nextIcon, @(0.2, 0.)) => int nextClicked;
            UIStyle.popVar(3);
            UIStyle.popColor(2);

            if (nextClicked) {
                <<< "did we click next?" >>>;
                Events.scorePlayerEvent.set(Events.scorePlayerEvent.NEXT);
                Events.scorePlayerEvent.broadcast();
            }

            // Prev button
            UIStyle.pushColor(UIStyle.COL_BUTTON, Color.WHITE);
            UIStyle.pushColor(UIStyle.COL_BUTTON_PRESSED, Color.DARKGRAY);
            UIStyle.pushVar(UIStyle.VAR_BUTTON_BORDER_RADIUS, 1.0);
            UIStyle.pushVar(UIStyle.VAR_BUTTON_SIZE, ChuGUI.NDCToWorldSize(@(0.12, 0.12)));
            UIStyle.pushVar(UIStyle.VAR_BUTTON_ICON_SIZE, 0.3);
            gui.button("", me.dir() + "../assets/" + this.prevIcon, @(-0.2, 0.)) => int prevClicked;
            UIStyle.popVar(3);
            UIStyle.popColor(2);

            if (prevClicked) {
                <<< "did we click prev?" >>>;
                Events.scorePlayerEvent.set(Events.scorePlayerEvent.PREV);
                Events.scorePlayerEvent.broadcast();
            }

            // Seek bar slider
            UIStyle.pushColor(UIStyle.COL_SLIDER_TRACK, Color.GREEN);
            UIStyle.pushColor(UIStyle.COL_SLIDER_HANDLE, Color.WHITE);
            UIStyle.pushVar(UIStyle.VAR_SLIDER_TRACK_BORDER_RADIUS, 0.4);
            UIStyle.pushVar(UIStyle.VAR_SLIDER_HANDLE_BORDER_RADIUS, 0.4);
            UIStyle.pushVar(UIStyle.VAR_SLIDER_TRACK_BORDER_WIDTH, 0.2);
            UIStyle.pushVar(UIStyle.VAR_SLIDER_HANDLE_SIZE, @(0.1, 0.3));
            gui.slider("seeker", @(0, 0.2), 0, 1, seekerPos) => seekerPos;
            UIStyle.popVar(4);
            UIStyle.popColor(2);
        }
    }

    fun void updateScorePos() {
        while (true) {
            Events.scorePosEvent => now;
            Std.scalef(Events.scorePosEvent.currPos, 0., Events.scorePosEvent.endPos, 0., 1.) => this.seekerPos;
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
