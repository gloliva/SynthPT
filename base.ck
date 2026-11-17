public class Base {
    Shred activeShreds[0];

    fun void addShreds(Shred shreds[]) {
        for (Shred shred : shreds) {
            this.activeShreds << shred;
        }
    }

    fun void close() {
        for (Shred shred : this.activeShreds) {
            shred.exit();
        }
    }
}
