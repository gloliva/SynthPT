@import {"scoreParser.ck", "scoreManager.ck"}
@import "./graphics/mainMenu.ck"


MainMenu mainMenu();
spork ~ mainMenu.updateUI();
spork ~ mainMenu.updateScorePos();
spork ~ mainMenu.run();


ScoreManager scoreManager;
spork ~ scoreManager.run();
spork ~ scoreManager.sendScorePos();
scoreManager.openDirectory("./scores");

eon => now;
