@import {"defs.ck", "scoreParser.ck", "scoreManager.ck"}
@import "./lights/lightManager.ck"
@import "./graphics/mainMenu.ck"

// Command line arguments
int enableLights;
if (me.args() > 0) {
    me.arg(0) => Std.atoi => enableLights;
}

// Graphics handling
MainMenu mainMenu();
spork ~ mainMenu.updateUI();
spork ~ mainMenu.updateScoreNames();
spork ~ mainMenu.updateScorePos();
spork ~ mainMenu.updatePlayToggle();
spork ~ mainMenu.run();
me.yield();


// Playback + audio handling
ScoreManager scoreManager;
spork ~ scoreManager.run();
spork ~ scoreManager.scorePosTracker();
spork ~ scoreManager.updateScorePos();


// Lights handling
if (enableLights) {
    LightManager lightManager(Defs.LIGHTS_CONFIG_FILENAME);
    spork ~ lightManager.setFaders();
    spork ~ lightManager.setColors();
    spork ~ lightManager.sendDMX();

    // Pass noteColorMap into ScoreManager
    scoreManager.setNoteColorMap(lightManager.noteColorMap);
}

// Load files
scoreManager.openDirectory("./scores");

eon => now;
