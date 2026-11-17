@import {"config.ck", "types.ck"}
@import {"../base.ck", "../utils.ck"}


public class LightManager extends Base {
    DMX dmx;
    LightConfig @ config;
    ParLight lights[0];
    int noteColorMap[0];

   [
        @(255, 0, 0),
        @(255, 128, 0),
        @(255, 255, 0),
        @(170, 255, 0),
        @(0, 255, 0),
        @(0, 255, 128),
        @(0, 255, 255),
        @(0, 128, 255),
        @(0, 0, 255),
        @(127, 0, 255),
        @(255, 0, 255),
        @(255, 0, 127),
    ] @=> vec3 colors[];

    fun @construct(string configFilename) {
        // Parse DMX config
        Utils.joinPath(me.dir(), configFilename) => string lightsConfigFilepath;
        new LightConfig(lightsConfigFilepath) @=> this.config;

        // Handle DMX parameters
        dmx.protocol(this.config.getProtocol());
        dmx.port(this.config.getPort());
        dmx.rts(this.config.getRTS());

        // Set up lights
        for (int i; i < config.numLights(); i++) {
            this.config.lightsConfig.get(i) @=> HashMap lightConfig;

            ParLight light(
                this.dmx,
                lightConfig.getInt("dmxChannel"),
                lightConfig.getInt("numChannels"),
                lightConfig.getInt("masterChannel"),
                lightConfig.getInt("redChannel")
            );

            this.lights << light;
            this.noteColorMap << 0;
            light.print();
        }

        // Input handling for light master faders
        for (int i; i < adc.channels(); i++) {
            adc.chan(i) => blackhole;
        }

        // Shred management
        spork ~ this.setFaders() @=> Shred setFadersShred;
        spork ~ this.setColors() @=> Shred setColorsShred;
        spork ~ this.sendDMX() @=> Shred sendDMXShred;
        this.addShreds([setFadersShred, setColorsShred, sendDMXShred]);
    }

    fun void setColors() {
        while (true) {
            for (int i; i < this.lights.size(); i++) {
                this.noteColorMap[i] % this.colors.size() => int colorIdx;
                this.lights[i].setColor(this.colors[colorIdx]);
            }

            10::ms => now;
        }
    }

    fun void setFaders() {
        while (true) {
            for (int i; i < this.lights.size(); i++) {
                adc.chan(i).last() => float envVal;
                Std.scalef(envVal, 0., 1., 0, 100)$int => int faderVal;
                this.lights[i].setMaster(faderVal);
            }

            10::ms => now;
        }
    }

    fun void sendDMX() {
        // Send DMX information on a schedule
        while (true) {
            this.dmx.send();
            30::ms => now;
        }
    }

}
