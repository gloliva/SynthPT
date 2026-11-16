@import {"defs.ck", "instrument.ck", "logger.ck", "tuning.ck"}
@import {"HashMap", "smuck"}


public class Score {
    HashMap @ json;

    // score parameters
    string name;
    int numVoices;
    int bpm;

    // smuck parameters
    ezScore @ score;
    CVInstrument instruments[0];

    // error checking
    1 => int good;

    int _noteID;


    fun void parse(string file) {
        // Reset everything
        new ezScore() @=> this.score;
        this.instruments.reset();

        HashMap.fromJsonFile(file) @=> this.json;

        // Parse global score params
        this.json.getStr("name") => this.name;
        this.json.getInt("numVoices") => this.numVoices;
        this.json.getInt("bpm") => this.bpm;
        this.bpm => this.score.bpm;

        // Parse voices
        int startChan;
        ezPart parts[this.numVoices];
        for (int voice; voice < this.numVoices; voice++) {
            0 => this._noteID;

            "voice-" + voice => string partName;
            this.json.get(partName) @=> HashMap partJson;

            // Create instrument for voice
            string outputs[0];
            partJson.get("outputs") @=> HashMap outputsJson;
            for (int outputIdx; outputIdx < outputsJson.intKeys().size(); outputIdx++) {
                outputsJson.getStr(outputIdx).lower() => string output;

                if (!CVOutputType.validOutput(output)) {
                    Logger.error("[Part" + partName + "] Invalid output: " + output);
                    return;
                }

                outputs << output;
            }

            Tuning @ tuning;
            if (partJson.has("edo")) {
                new EDO(partJson.getInt("edo")) @=> tuning;
            } else {
                new EDO(12) @=> tuning;
            }

            this.instruments << new CVInstrument(voice, startChan, outputs, tuning);
            outputs.size() +=> startChan;

            // parse measures
            if (!partJson.has("measures")) {
                Logger.error("[Part" + partName + "] Does not contain any measures.");
                return;
            }

            ezMeasure namedMeasures[0];
            partJson.get("measures") @=> HashMap measuresJson;
            for (int measureIdx; measureIdx < measuresJson.intKeys().size(); measureIdx++) {
                measuresJson.get(measureIdx)$HashMap @=> HashMap measureJson;

                string id;
                1 => int repeats;

                if (measureJson.has("id")) {
                    measureJson.getStr("id") => id;
                }

                if (measureJson.has("repeats")) {
                    measureJson.getInt("repeats") => repeats;
                }

                // Check what type of measure is being parsed
                ezMeasure measure;
                if (id == "" && !measureJson.has("notes")) {
                    Logger.warn("[Part " + partName + ", Measure " + measureIdx + "] Does not contain either ID or Notes.");
                    continue;
                } else if (id != "" && !measureJson.has("notes")) {
                    if (namedMeasures.isInMap(id)) {
                        namedMeasures[id] @=> measure;
                    } else {
                        Logger.warn("[Part " + partName + ", Measure " + measureIdx + "] Measure does not have Notes, and measure name " + id + " does not already exist.");
                        continue;
                    }
                } else {
                    this._parseMeasure(measureJson) @=> measure;
                    if (id != "") {
                        measure @=> namedMeasures[id];
                    }
                }

                // measure.print();
                repeat(repeats) {
                    parts[voice].add(measure.copy());
                }
            }
            // Add a rest measure at the end
            ezMeasure restMeasure;
            restMeasure.pitches("r");
            restMeasure.rhythms("w");
            parts[voice].add(restMeasure);
        }

        // Add parts to score
        this.score.add(parts);
    }

    fun ezMeasure _parseMeasure(HashMap measureJson) {
        measureJson.get("notes") @=> HashMap notesJson;
        measureJson.get("octaves") @=> HashMap octavesJson;
        measureJson.get("volumes") @=> HashMap volumesJson;
        measureJson.get("durations") @=> HashMap durationsJson;

        // Verify same size
        if (notesJson.intKeys().size() != octavesJson.intKeys().size() ||
            notesJson.intKeys().size() != volumesJson.intKeys().size() ||
            notesJson.intKeys().size() != durationsJson.intKeys().size()
            ) {
                Logger.error("Issue parsing measure: " + measureJson.getStr("id") + ", data arrays are not all the same length.");
                return null;
            }

        ezMeasure measure;
        float onset;
        // Parse Notes
        for (int noteIdx; noteIdx < notesJson.intKeys().size(); noteIdx++) {
            float pitch;
            int isRest;

            notesJson.type(noteIdx) => int noteType;
            if (noteType == HashMap.Type_Str) {
                notesJson.getStr(noteIdx).lower() => string rest;
                if (rest != "r") {
                    Logger.error("Unknown character " + rest + " in Notes array for measure " + measureJson.getStr("id") + ", did you mean to put \"r\"?");
                } else {
                    1 => isRest;
                }
            } else if (noteType == HashMap.Type_Int) {
                notesJson.getInt(noteIdx)$float => pitch;
            } else if (noteType == HashMap.Type_Float) {
                notesJson.getFloat(noteIdx) => pitch;
            }

            octavesJson.getInt(noteIdx)$float => float octave;
            volumesJson.getFloat(noteIdx) => float volume;
            Smuckish.rhythms(durationsJson.getStr(noteIdx))[0] => float beats;

            // Create note
            ezNote note(onset, beats, pitch, volume);
            [octave, this._noteID] => note.data;
            isRest => note.isRest;

            1 +=> this._noteID;
            beats +=> onset;
            measure.add(note);
        }

        return measure;
    }

    fun void connectInstruments() {
        <<< "Connecting instruments for score:", this.name >>>;
        for (CVInstrument instrument : this.instruments) {
            instrument.connect();
        }
    }

    fun void disconnectInstruments() {
        <<< "DISconnecting instruments for score:", this.name >>>;
        for (CVInstrument instrument : this.instruments) {
            instrument.disconnect();
        }
    }

    fun float durationSecs() {
        return this.score.duration() / Defs.SRATE::samp;
    }

    fun void printScore() {
        chout <= this.name <= IO.nl();
        chout <= "\tNumber of Voices: " + this.numVoices <= IO.nl();
        chout <= "\tBPM: " + this.bpm <= IO.nl();
        chout <= "\tTime in seconds: " + this.durationSecs() <= IO.nl();
    }
}