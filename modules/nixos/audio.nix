{ ... }:

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

  # RT scheduling for low-latency audio (games, recording). Requires the
  # `audio` group, which the user already has.
  security.rtkit.enable = true;

  # Disable PulseAudio to avoid conflict with pipewire-pulse.
  services.pulseaudio.enable = false;
}
