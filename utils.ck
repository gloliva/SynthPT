public class Utils {
    fun static string joinPath(string prefix, string filename) {
        if (prefix.charAt2(prefix.length() - 1) != "/") {
            return prefix + "/" + filename;
        }

        return prefix + filename;
    }
}
