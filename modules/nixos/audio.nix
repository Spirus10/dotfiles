{ pkgs, ... }:

let
  # Software capture gain for the FIFINE, as a linear multiplier.
  #
  # The mic's physical gain dial is set for Windows and deliberately left
  # alone. With it that low the USB feature-unit gain is already pinned at
  # its ceiling (the capture route reports route.hw-volume = true with
  # channelVolumes at 1.0), so every remaining dB has to come from
  # software — which is per-OS and never touches the dial.
  #
  # Sized from measurement, not guesswork: speech peaked at -30.7 dBFS,
  # so +18.1 dB (8x) puts peaks at about -12.6 dBFS. That leaves ~12 dB
  # of headroom for louder moments rather than pushing toward clipping.
  #
  # Note this cannot improve SNR — it lifts the voice and the noise floor
  # (measured -65 dBFS) equally. That is what the RNNoise stage is for.
  #
  # This is applied as a stage inside the filter graph below rather than
  # as a volume on the mic's device node. Setting it on the device node
  # works, but the filter-chain resets that node's volume back to 1.0
  # whenever it attaches — reproduced deliberately, twice. Gain inside
  # the graph is immune to that, needs no helper service or wireplumber
  # state, and feeds RNNoise a healthy level, which its VAD wants.
  micGain = 8.0;
in
{
  # Pipewire replaces PulseAudio entirely. wireplumber is the default
  # session manager; pipewire-pulse/jack/alsa provide compat layers so
  # legacy clients keep working without changes.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # The FIFINE mic exposes a playback device too — the headphone-monitor
  # jack on the mic body. Nothing is plugged into it, but it scored the
  # same priority.session (1109) as the G733 headset, so with no saved
  # default wireplumber broke the tie by discovery order and made the mic
  # the default sink. Apps that follow the system default (Firefox) went
  # silent; apps that pick a device in-app (Discord) were unaffected.
  #
  # Zeroing its priority keeps the node around — you can still select it
  # explicitly — but makes it the last candidate for default sink, so it
  # can't grab the default again when the wireless headset is off at boot.
  services.pipewire.wireplumber.extraConfig."51-fifine-no-default-sink" = {
    "monitor.alsa.rules" = [
      {
        # `~` marks a regex (a bare string here would be an exact match,
        # not a glob). Wildcarded past the serial so a firmware or device
        # swap doesn't silently stop matching. alsa_output only — the
        # capture side is the actual mic and must keep its priority.
        matches = [ { "node.name" = "~alsa_output\\.usb-MV-SILICON_fifine_Microphone_.*"; } ];
        actions.update-props = {
          "priority.session" = 0;
          "priority.driver"  = 0;
        };
      }
    ];
  };

  # RNNoise noise suppression, run natively by PipeWire as a filter-chain.
  #
  # This replaces noisetorch, which was wired up but could never have
  # worked: its udev trigger used ENV{SYSTEMD_WANTS}, which activates
  # *system* units while noisetorch-start.service existed only as a user
  # unit; the package was installed via environment.systemPackages so it
  # never got the cap_sys_resource wrapper that programs.noisetorch.enable
  # provides; and `noisetorch -i` with no -s targets the default source,
  # which here is the Elgato capture card rather than the mic.
  #
  # A filter-chain sidesteps all three — no privileged binary, no udev, no
  # user service, and the input is pinned to the FIFINE by name below.
  # Same underlying RNNoise engine noisetorch wrapped.
  #
  # Exposes a new source, "FIFINE (Noise Suppressed)". Select it in Discord;
  # the raw mic stays available if you ever want it unprocessed.
  services.pipewire.extraConfig.pipewire."99-fifine-rnnoise" = {
    "context.modules" = [
      {
        name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "FIFINE (Noise Suppressed)";
          "media.name"       = "FIFINE (Noise Suppressed)";

          "filter.graph" = {
            nodes = [
              # Gain first, then denoise: RNNoise's VAD is trained on
              # speech at sane levels, so boosting ahead of it works
              # better than cleaning up a very quiet signal and lifting
              # the result. `linear` is a PipeWire builtin (ports In/Out,
              # controls Mult/Add).
              {
                type    = "builtin";
                name    = "gain";
                label   = "linear";
                control = { "Mult" = micGain; "Add" = 0.0; };
              }
              {
                type   = "ladspa";
                name   = "rnnoise";
                plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                # Mono variant: the FIFINE capture node is 1-channel.
                # Label and control names come from the plugin's own
                # descriptor (analyseplugin), not from guesswork — a
                # mismatch here makes the chain fail to load silently.
                label  = "noise_suppressor_mono";
                control = {
                  # Plugin defaults are 49.5 / 500 / 100. Grace is shortened
                  # so the gate closes sooner after speech; threshold left
                  # near default because this mic's SNR is only ~16 dB and
                  # a higher gate would start clipping quiet syllables.
                  "VAD Threshold (%)"          = 50.0;
                  "VAD Grace Period (ms)"      = 200;
                  "Retroactive VAD Grace (ms)" = 100;
                };
              }
            ];
            # Only the gain->rnnoise hop is explicit; the graph's own
            # input and output are inferred from the remaining unconnected
            # ports (gain:In and rnnoise:Output).
            links = [
              { output = "gain:Out"; input = "rnnoise:Input"; }
            ];
          };

          # Pinned to the mic by node name so this can't latch onto the
          # default source the way `noisetorch -i` did. Note the name
          # carries the device serial — if the mic is ever replaced, this
          # needs updating, and the chain would fall back to the default
          # input rather than failing loudly.
          "capture.props" = {
            "node.name"      = "fifine_denoised.capture";
            "node.passive"   = true;
            "target.object"  = "alsa_input.usb-MV-SILICON_fifine_Microphone_20190808-00.mono-fallback";
            "audio.position" = [ "MONO" ];
          };

          "playback.props" = {
            "node.name"      = "fifine_denoised";
            "media.class"    = "Audio/Source";
            "audio.position" = [ "MONO" ];
          };
        };
      }
    ];
  };

  # RT scheduling for low-latency audio (games, recording). Requires the
  # `audio` group, which the user already has.
  security.rtkit.enable = true;

  # Disable PulseAudio to avoid conflict with pipewire-pulse.
  services.pulseaudio.enable = false;
}
