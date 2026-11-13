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


public class ScoreNamesEvent extends Event {
    string curr;
    string next;

    fun void set(string curr, string next) {
        curr => this.curr;
        next => this.next;
    }
}


public class PlayToggleEvent extends Event {
    int val;

    fun void set(int val) {
        val => this.val;
    }
}


public class ScorePosEvent extends Event {
    float currPos;
    float endPos;

    fun void set(float currPos, float endPos) {
        currPos => this.currPos;
        endPos => this.endPos;
    }
}


public class Events {
    static ScorePlayerEvent scorePlayerEvent;
    static ScoreNamesEvent scoreNamesEvent;
    static PlayToggleEvent playToggleEvent;
    static ScorePosEvent scorePosEvent;
}
