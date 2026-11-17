@import {"defs.ck", "globals.ck", "scoreParser.ck", "scoreManager.ck"}
@import "./lights/lightManager.ck"
@import "./graphics/mainMenu.ck"

// Command line arguments
int enableLights;
if (me.args() > 0) {
    me.arg(0) => Std.atoi => enableLights;
}

if (me.args() > 1) {
    me.arg(1) => Std.atoi => Globals.VERBOSE;
}


// Graphics handling
MainMenu mainMenu();
me.yield();


// Playback + audio handling
ScoreManager scoreManager();


// Lights handling
LightManager @ lightManager;
if (enableLights) {
    new LightManager(Defs.LIGHTS_CONFIG_FILENAME) @=> lightManager;

    // Pass noteColorMap into ScoreManager
    scoreManager.setNoteColorMap(lightManager.noteColorMap);
}

// Load files
scoreManager.openDirectory("./scores");


// Wait for close events + cleanup on exit
1 => int running;


fun void handleWindowClose() {
    GWindow.closeEvent() => now;
    0 => running;
} spork ~ handleWindowClose();


while (running) {
    if (GWindow.keyDown(GWindow.KEY_ESCAPE)) {
        0 => running;
    }

    GG.nextFrame() => now;
}


// Cleanup and exit
if (enableLights) {
    scoreManager.close();
    lightManager.close();
}