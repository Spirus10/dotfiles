{ inputs, lib, theme, ... }:

let
  inherit (lib.generators) mkLuaInline;
  toLua = lib.generators.toLua { };

  # home-manager turns each top-level `settings` attr into `hl.<name>(...)`,
  # one call per list element. `_args` makes it a multi-argument call
  # instead of a single table, and `_var` emits a Lua local.
  args = xs: { _args = xs; };

  # Dispatchers are Lua expressions, not data, so they have to be emitted
  # raw. Commands go through toLua so embedded quotes (the slurp
  # screenshot bind) get escaped instead of breaking the file.
  exec    = cmd:  mkLuaInline "hl.dsp.exec_cmd(${toLua cmd})";
  execVar = name: mkLuaInline "hl.dsp.exec_cmd(${name})";
  dsp     = expr: mkLuaInline "hl.dsp.${expr}";

  bind     = keys: dispatcher: args [ keys dispatcher ];
  bindOpts = opts: keys: dispatcher: args [ keys dispatcher opts ];

  # bindl / bindel equivalents. `locked` fires while the screen is locked,
  # `repeating` is the old binde key-repeat behaviour.
  bindLocked = bindOpts { locked = true; };
  bindMedia  = bindOpts { locked = true; repeating = true; };

  mainMod = "SUPER";

  # Matched by description, not connector name: the DP-N numbering is
  # assigned in probe order and reshuffles whenever cables get moved, which
  # twice now has landed the vertical transform on the wrong panel. The two
  # Dells are the same model, so they're told apart by serial.
  # `hyprctl monitors all` prints the description string to match against.
  monitors = {
    left   = "desc:Dell Inc. DELL P2419H 22KLR13";        # portrait
    centre = "desc:Samsung Electric Company Odyssey G50F HNAL101843";
    right  = "desc:Dell Inc. DELL P2419H 2W5LR13";
  };

  # Generate the 1..9,0 -> 1..9,10 workspace map. Matches the old
  # hyprlang config without twenty near-identical lines.
  wsKeys = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "0" ];
  wsFor  = k: if k == "0" then 10 else lib.toInt k;

  workspaceBinds =
       map (k: bind "${mainMod} + ${k}"
              (dsp "focus({ workspace = ${toString (wsFor k)} })")) wsKeys
    ++ map (k: bind "${mainMod} + SHIFT + ${k}"
              (dsp "window.move({ workspace = ${toString (wsFor k)} })")) wsKeys;

  # Quickshell (`qs`) and awww both run as their own systemd user units —
  # see quickshell.nix and wallpaper.nix. Only cliphist needs a start hook.
  startupCmds = [
    "wl-paste --type text  --watch cliphist store"
    "wl-paste --type image --watch cliphist store"
  ];
in
{
  xdg.dataFile."icons/Future-Cyan".source =
    "${inputs.future-cyan-hyprcursor}/Future-Cyan-Hyprcursor_Theme";

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;

    # hyprlang is deprecated as of Hyprland 0.55; the config is now Lua
    # ($XDG_CONFIG_HOME/hypr/hyprland.lua). Upstream home-manager only
    # defaults this to "lua" at stateVersion >= 26.05, so set it
    # explicitly rather than waiting on a stateVersion bump.
    configType = "lua";

    settings = {
      # Lua locals, referenced bare inside the exec dispatchers below.
      terminal    = { _var = "ghostty"; };
      fileManager = { _var = "dolphin"; };
      browser     = { _var = "firefox"; };
      passManager = { _var = "1password"; };

      monitor = [
        { output = monitors.centre; mode = "preferred"; position = "0x0";     scale = "auto"; }
        { output = monitors.right;  mode = "preferred"; position = "2560x0";  scale = "auto"; }
        # transform 1 (90°) rather than 3 (270°): the panel is physically
        # rotated the other way so its bezel doesn't crowd the Samsung.
        { output = monitors.left;   mode = "preferred"; position = "-1080x0"; scale = "auto"; transform = 1; }
      ];

      workspace_rule = [
        { workspace = "1"; monitor = monitors.left; }
        { workspace = "2"; monitor = monitors.centre; }
        { workspace = "3"; monitor = monitors.right; }
      ];

      env = [
        # No GTK_THEME here on purpose — it's a GTK3-only debug override
        # that bypasses settings.ini and is invisible to the appearance
        # portal, so it never reached Firefox. Dark mode is configured
        # properly in gtk.nix instead.
        (args [ "QT_QPA_PLATFORMTHEME" "qt6ct" ])
        (args [ "XCURSOR_THEME"        "Future-Cyan" ])
        (args [ "XCURSOR_SIZE"         "24" ])
        (args [ "HYPRCURSOR_THEME"     "Future-Cyan" ])
        (args [ "HYPRCURSOR_SIZE"      "24" ])
      ];

      on = args [
        "hyprland.start"
        (mkLuaInline (
          "function()\n"
          + lib.concatMapStrings (c: "  hl.exec_cmd(${toLua c})\n") startupCmds
          + "end"
        ))
      ];

      config = {
        general = {
          gaps_in     = 5;
          gaps_out    = 20;
          border_size = 2;
          col = {
            active_border = {
              colors = [ (theme.purple.rgba "ee") (theme.purpleLite.rgba "ee") ];
              angle  = 45;
            };
            inactive_border = "rgba(595959aa)";
          };
          resize_on_border = false;
          allow_tearing    = false;
          layout           = "dwindle";
        };

        cursor = {
          enable_hyprcursor = true;
          inactive_timeout  = 0;
        };

        decoration = {
          rounding         = 10;
          rounding_power   = 2;
          active_opacity   = 1.0;
          inactive_opacity = 1.0;
          shadow = {
            enabled      = true;
            range        = 4;
            render_power = 3;
            color        = "rgba(1a1a1aee)";
          };
          blur = {
            enabled  = true;
            size     = 3;
            passes   = 1;
            vibrancy = 0.1696;
          };
        };

        # Curves and per-leaf animations are their own calls now — see
        # `curve` / `animation` below.
        animations.enabled = true;

        dwindle.preserve_split = true;

        master.new_status = "master";

        misc = {
          force_default_wallpaper = -1;
          disable_hyprland_logo   = false;
        };

        input = {
          kb_layout    = "us";
          follow_mouse = 1;
          sensitivity  = 0;
          touchpad.natural_scroll = false;
        };
      };

      # `curve` is in home-manager's importantPrefixes, so these render
      # above the animations that reference them by name.
      curve = [
        (args [ "easeOutQuint"   { type = "bezier"; points = [ [ 0.23 1.0 ]  [ 0.32 1.0 ] ]; } ])
        (args [ "easeInOutCubic" { type = "bezier"; points = [ [ 0.65 0.05 ] [ 0.36 1.0 ] ]; } ])
        (args [ "linear"         { type = "bezier"; points = [ [ 0.0 0.0 ]   [ 1.0 1.0 ] ]; } ])
        (args [ "almostLinear"   { type = "bezier"; points = [ [ 0.5 0.5 ]   [ 0.75 1.0 ] ]; } ])
        (args [ "quick"          { type = "bezier"; points = [ [ 0.15 0.0 ]  [ 0.1 1.0 ] ]; } ])
      ];

      animation = [
        { leaf = "global";        enabled = true; speed = 10;   bezier = "default"; }
        { leaf = "border";        enabled = true; speed = 5.39; bezier = "easeOutQuint"; }
        { leaf = "windows";       enabled = true; speed = 4.79; bezier = "easeOutQuint"; }
        { leaf = "windowsIn";     enabled = true; speed = 4.1;  bezier = "easeOutQuint";  style = "popin 87%"; }
        { leaf = "windowsOut";    enabled = true; speed = 1.49; bezier = "linear";        style = "popin 87%"; }
        { leaf = "fadeIn";        enabled = true; speed = 1.73; bezier = "almostLinear"; }
        { leaf = "fadeOut";       enabled = true; speed = 1.46; bezier = "almostLinear"; }
        { leaf = "fade";          enabled = true; speed = 3.03; bezier = "quick"; }
        { leaf = "layers";        enabled = true; speed = 3.81; bezier = "easeOutQuint"; }
        { leaf = "layersIn";      enabled = true; speed = 4;    bezier = "easeOutQuint";  style = "fade"; }
        { leaf = "layersOut";     enabled = true; speed = 1.5;  bezier = "linear";        style = "fade"; }
        { leaf = "fadeLayersIn";  enabled = true; speed = 1.79; bezier = "almostLinear"; }
        { leaf = "fadeLayersOut"; enabled = true; speed = 1.39; bezier = "almostLinear"; }
        { leaf = "workspaces";    enabled = true; speed = 1.94; bezier = "almostLinear";  style = "fade"; }
        { leaf = "workspacesIn";  enabled = true; speed = 1.21; bezier = "almostLinear";  style = "fade"; }
        { leaf = "workspacesOut"; enabled = true; speed = 1.94; bezier = "almostLinear";  style = "fade"; }
      ];

      window_rule = [
        {
          name  = "theme-border-and-suppress";
          match.class = ".*";
          border_color = {
            colors = [ (theme.purple.rgba "ff") (theme.bgAlt.rgba "ff") ];
          };
          suppress_event = "maximize";
        }
        # Fix drag issues with empty-title xwayland floaters.
        {
          name = "xwayland-empty-floater-nofocus";
          match = {
            class      = "^$";
            title      = "^$";
            xwayland   = true;
            float      = true;
            fullscreen = false;
            pin        = false;
          };
          no_focus = true;
        }
      ];

      bind = [
        # Apps
        (bind "${mainMod} + T" (execVar "terminal"))
        (bind "${mainMod} + B" (execVar "browser"))
        (bind "${mainMod} + D" (exec "discord"))
        (bind "${mainMod} + E" (execVar "fileManager"))
        (bind "${mainMod} + R" (exec "qs ipc call launcher toggle"))
        (bind "${mainMod} + P" (execVar "passManager"))

        # Window mgmt
        (bind "${mainMod} + Q" (dsp "window.close()"))
        (bind "${mainMod} + M" (dsp "exit()"))
        (bind "${mainMod} + F" (dsp "window.fullscreen()"))
        (bind "${mainMod} + J" (dsp "layout(\"togglesplit\")"))

        # Quickshell IPC — launcher, media, clipboard all handled by
        # the `qs` daemon (modules/home/quickshell.nix). Mapped IPC
        # handlers live in assets/quickshell/shell.qml.
        (bind "${mainMod} + SPACE" (exec "qs ipc call launcher toggle"))
        (bind "${mainMod} + N"     (exec "qs ipc call media toggle"))
        (bind "${mainMod} + V"     (exec "qs ipc call clipboard toggle"))

        # Focus
        (bind "${mainMod} + left"  (dsp ''focus({ direction = "left" })''))
        (bind "${mainMod} + right" (dsp ''focus({ direction = "right" })''))
        (bind "${mainMod} + up"    (dsp ''focus({ direction = "up" })''))
        (bind "${mainMod} + down"  (dsp ''focus({ direction = "down" })''))

        # Scroll through workspaces
        (bind "${mainMod} + mouse_down" (dsp ''focus({ workspace = "e+1" })''))
        (bind "${mainMod} + mouse_up"   (dsp ''focus({ workspace = "e-1" })''))

        # Screenshots
        (bind "Print" (exec "grim - | wl-copy"))
        (bind "${mainMod} + SHIFT + S"
          (exec ''grim -g "$(slurp -w 0)" - | swappy -f -''))

        # Move/resize with the mouse. `mouse:` in the key string is what
        # marks these as mouse binds — hl.bind takes no opts for them
        # (mouse binds reject locked/release/repeating).
        (bind "${mainMod} + mouse:272" (dsp "window.drag()"))
        (bind "${mainMod} + mouse:273" (dsp "window.resize()"))

        # Media keys — fire while the screen is locked.
        (bindMedia "XF86AudioRaiseVolume" (exec "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
        (bindMedia "XF86AudioLowerVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
        (bindMedia "XF86AudioMute"        (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
        (bindMedia "XF86AudioMicMute"     (exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
        (bindMedia "XF86MonBrightnessUp"   (exec "brightnessctl s 10%+"))
        (bindMedia "XF86MonBrightnessDown" (exec "brightnessctl s 10%-"))

        (bindLocked "XF86AudioNext"  (exec "playerctl next"))
        (bindLocked "XF86AudioPause" (exec "playerctl play-pause"))
        (bindLocked "XF86AudioPlay"  (exec "playerctl play-pause"))
        (bindLocked "XF86AudioPrev"  (exec "playerctl previous"))
      ] ++ workspaceBinds;
    };
  };
}
