{ lib, theme, ... }:

let
  # Generate "SUPER, <n>, workspace, <n>" (and the SHIFT variant) for
  # the 1..9,0 -> 1..9,10 workspace map. Matches the Arch conf without
  # ten near-identical lines.
  wsKeys = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "0" ];
  wsFor  = k: if k == "0" then "10" else k;

  workspaceBinds =
       map (k: "$mainMod, ${k}, workspace, ${wsFor k}") wsKeys
    ++ map (k: "$mainMod SHIFT, ${k}, movetoworkspace, ${wsFor k}") wsKeys;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    settings = {
      "$mainMod"     = "SUPER";
      "$terminal"    = "ghostty";
      "$fileManager" = "dolphin";
      "$browser"     = "firefox";
      "$passManager" = "1password";

      monitor = [
        "DP-1,2560x1440_135.00,0x0,auto"
        "DP-2,preferred,2560x0,auto"
        "DP-3,preferred,-1080x0,auto,transform,3"
      ];

      workspace = [
        "1,monitor:DP-2"
        "2,monitor:DP-3"
        "3,monitor:DP-1"
      ];

      env = [
        "GTK_THEME,Adwaita:dark"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
      ];

      # Quickshell (`qs`) and swww are added in Phase 4 via their own
      # home modules. Keep this minimal for now — just clipboard.
      exec-once = [
        "wl-paste --type text  --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];

      general = {
        gaps_in     = 5;
        gaps_out    = 20;
        border_size = 2;
        "col.active_border"   = "${theme.purple.rgba "ee"} ${theme.purpleLite.rgba "ee"} 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        resize_on_border      = false;
        allow_tearing         = false;
        layout                = "dwindle";
      };

      cursor.inactive_timeout = 0;

      decoration = {
        rounding        = 10;
        rounding_power  = 2;
        active_opacity  = 1.0;
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

      animations = {
        enabled = true;
        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];
        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 1, 1.94, almostLinear, fade"
          "workspacesIn, 1, 1.21, almostLinear, fade"
          "workspacesOut, 1, 1.94, almostLinear, fade"
        ];
      };

      dwindle = {
        pseudotile      = true;
        preserve_split  = true;
      };

      master.new_status = "master";

      misc = {
        force_default_wallpaper = -1;
        disable_hyprland_logo   = false;
      };

      input = {
        kb_layout     = "us";
        follow_mouse  = 1;
        sensitivity   = 0;
        touchpad.natural_scroll = false;
      };

      windowrule = [
        {
          name = "theme-border-and-suppress";
          border_color   = "${theme.purple.rgba "ff"} ${theme.bgAlt.rgba "ff"}";
          suppress_event = "maximize";
          "match:class"  = ".*";
        }
        # Fix drag issues with empty-title xwayland floaters.
        {
          name = "xwayland-empty-floater-nofocus";
          no_focus            = "on";
          "match:class"       = "^$";
          "match:title"       = "^$";
          "match:xwayland"    = 1;
          "match:float"       = 1;
          "match:fullscreen"  = 0;
          "match:pin"         = 0;
        }
      ];

      bind = [
        # Apps
        "$mainMod, T, exec, $terminal"
        "$mainMod, B, exec, $browser"
        "$mainMod, D, exec, discord"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, R, exec, qs ipc call launcher toggle"
        "$mainMod, P, exec, $passManager"

        # Window mgmt
        "$mainMod, Q, killactive"
        "$mainMod, M, exit"
        "$mainMod, F, fullscreen"
        "$mainMod, J, togglesplit"

        # Quickshell IPC — launcher, media, clipboard all handled by
        # the `qs` daemon (modules/home/quickshell.nix). Mapped IPC
        # handlers live in assets/quickshell/shell.qml.
        "$mainMod, SPACE, exec, qs ipc call launcher toggle"
        "$mainMod, N, exec, qs ipc call media toggle"
        "$mainMod, V, exec, qs ipc call clipboard toggle"

        # Focus
        "$mainMod, left,  movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up,    movefocus, u"
        "$mainMod, down,  movefocus, d"

        # Scroll through workspaces
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up,   workspace, e-1"

        # Screenshots
        "            , Print, exec, grim - | wl-copy"
        "$mainMod SHIFT, S,   exec, grim -g \"$(slurp -w 0)\" - | swappy -f -"
      ] ++ workspaceBinds;

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      # Locked binds (fire while screen locked) for media keys.
      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume        @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute,        exec, wpctl set-mute          @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute,     exec, wpctl set-mute          @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86MonBrightnessUp,   exec, brightnessctl s 10%+"
        ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"
      ];
      bindl = [
        ", XF86AudioNext,  exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay,  exec, playerctl play-pause"
        ", XF86AudioPrev,  exec, playerctl previous"
      ];
    };
  };
}
