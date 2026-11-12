@import "scoreParser.ck"
@import "./graphics/mainMenu.ck"


MainMenu mainMenu();


Score score;
score.parse("./scores/song1.json");
score.printScore();


ezScorePlayer player;
player.score(score.score);
player.instruments(score.instruments);


player.play();
score.score.duration() => now;
<<< "Done playing" >>>;

5::second => now;
