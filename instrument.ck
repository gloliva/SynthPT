@import {"events.ck", "tuning.ck"}
@import "smuck"


public class CVOutputType {
    "pitch" => static string PITCH;
    "gate" => static string GATE;
    "trigger" => static string TRIGGER;

    fun static int validOutput(string out) {
        if (
            out == CVOutputType.PITCH ||
            out == CVOutputType.GATE ||
            out == CVOutputType.TRIGGER
        ) return 1;

        return 0;
    }
}


public class CVInstrument extends ezInstrument {
    int id;
    int startChan;
    string outputs[];

    // Outputs
    Step pitch(0.);
    Step gate(0.);
    Step trigger(0.);

    // Note params
    int currNote;

    // Tuning
    Tuning @ tuning;

    // Lights
    int noteColorMap[];

    fun @construct(int id, int startChan, string outputs[], Tuning tuning) {
        id => this.id;
        startChan => this.startChan;
        outputs @=> this.outputs;
        tuning @=> this.tuning;
        this.numVoices(1);
    }

    fun void noteOn(ezNote note, int voice) {
        note.data()[0]$int => int octave;
        note.data()[1]$int => int noteID;

        // Set outputs
        this.tuning.cv(note.pitch()$int, octave) => this.pitch.next;
        note.velocity() => this.gate.next;
        spork ~ this.sendTrigger();

        // Send pitch event for Light handling
        if (this.noteColorMap != null) {
            note.pitch()$int => this.noteColorMap[this.id];
        }

        noteID => this.currNote;
        // <<< "Pitch:", note.pitch(), "Volume:", note.velocity(), "Octave:", octave, "ID", noteID >>>;
    }

    fun void noteOff(ezNote note, int voice) {
        // Check if score is being paused and an empty Off note is sent
        if (note.data().size() < 2) {
            0. => this.gate.next;
            return;
        }

        note.data()[1]$int => int noteID;

        if (noteID == this.currNote) {
            // <<< "\tDone for pitch:", note.pitch() >>>;
            0. => this.gate.next;
        }
    }

    fun void sendTrigger() {
        0.7 => this.trigger.next;
        10::ms => now;
        0. => this.trigger.next;
    }

    fun void connect() {
        for (int outIdx; outIdx < this.outputs.size(); outIdx++) {
            this.outputs[outIdx] => string output;

            if (output == CVOutputType.PITCH) {
                this.pitch => dac.chan(startChan + outIdx);
            } else if (output == CVOutputType.GATE) {
                this.gate => dac.chan(startChan + outIdx);
            } else if (output == CVOutputType.TRIGGER) {
                this.trigger => dac.chan(startChan + outIdx);
            }
        }
    }

    fun void setNoteColorMap(int noteColorMap[]) {
        noteColorMap @=> this.noteColorMap;
    }

    fun void disconnect() {
        for (int outIdx; outIdx < this.outputs.size(); outIdx++) {
            this.outputs[outIdx] => string output;
            this.startChan + outIdx => int chanIdx;

            if (output == CVOutputType.PITCH) {
                this.pitch =< dac.chan(chanIdx);
            } else if (output == CVOutputType.GATE) {
                this.gate =< dac.chan(chanIdx);
            } else if (output == CVOutputType.TRIGGER) {
                this.trigger =< dac.chan(chanIdx);
            }
        }
    }
}
