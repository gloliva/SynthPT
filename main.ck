@import {"scoreParser.ck", "scoreManager.ck"}
@import "./graphics/mainMenu.ck"


MainMenu mainMenu();
spork ~ mainMenu.updateUI();
spork ~ mainMenu.updateScoreNames();
spork ~ mainMenu.updateScorePos();
spork ~ mainMenu.updatePlayToggle();
spork ~ mainMenu.run();
me.yield();


ScoreManager scoreManager;
spork ~ scoreManager.run();
spork ~ scoreManager.scorePosTracker();
scoreManager.openDirectory("./scores");

eon => now;
