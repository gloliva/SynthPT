public class ScorePlayerEvent extends Event {
    1 => static int PLAY;
    2 => static int PAUSE;
    3 => static int STOP;
    4 => static int NEXT;
    5 => static int PREV;

    int eventType;

    fun void set(int eventType) {
        eventType => this.eventType;
    }
}


public class ScoreInfoEvent extends Event {
    string name;
    float seconds;

    fun void set(string name, float seconds) {
        name => this.name;
        seconds => this.seconds;
    }
}


public class PlayToggleEvent extends Event {
    int val;

    fun void set(int val) {
        val => this.val;
    }
}


public class ScorePosEvent extends Event {
    // Score position coming from ScorePlayer
    float currPos;
    float endPos;

    fun void set(float currPos, float endPos) {
        currPos => this.currPos;
        endPos => this.endPos;
    }
}


public class SeekerChangeEvent extends Event {
    // Score position coming from clicking on seeker
    float pos;

    fun void set(float pos) {
        pos => this.pos;
    }
}


public class Events {
    static ScorePlayerEvent scorePlayerEvent;
    static ScoreInfoEvent scoreInfoEvent;
    static PlayToggleEvent playToggleEvent;
    static ScorePosEvent scorePosEvent;
    static SeekerChangeEvent seekerChangeEvent;
}
