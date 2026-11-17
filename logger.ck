@import "globals.ck"


public class Logger {
    fun static void error(string txt) {
        cherr <= "\033[31mERROR: " <= txt <= "\033[0m" <= IO.nl();
    }

    fun static void warn(string txt) {
        cherr <= "\033[33mWARNING: " <= txt <= "\033[0m" <= IO.nl();
    }

    fun static void debug(string txt) {
        if (Globals.VERBOSE) {
            chout <= "\033[36mDEBUG: " <= txt <= "\033[0m" <= IO.nl();
        }
    }
}
