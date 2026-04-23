# qs-pixl

A Quickshell top bar styled after the neon-noir pixel-art mockup:
magenta-bordered segments, cyan accents, deep violet fill.

Layout (left → right):

- **Workspaces** — 5 numbered tiles, active tile filled magenta (Hyprland)
- **Media** — track label, prev / play-pause / next, tiny animated visualizer (MPRIS)
- **Volume** — speaker glyph + percent + 4-bar meter; scroll to adjust, click to mute (PipeWire)
- **Clock** — 12-hour `h:mm AM/PM` (SystemClock, minute precision)

Plus two overlays triggered by IPC (see below):

- **App launcher** — spotlight-style `.desktop` runner
- **Clipboard history** — cliphist-backed picker that decodes into `wl-copy` and runs `paste.sh`

## Run

```sh
./run.sh
```

or equivalently:

```sh
quickshell --path .
```

> All config stays inside this directory — nothing is written to `~/.config`.

## Requirements

- `quickshell` (recent build with `Quickshell.Hyprland`, `Quickshell.Services.Mpris`, `Quickshell.Services.Pipewire`)
- Running Hyprland session (workspaces segment uses `hyprctl dispatch`)
- PipeWire for the volume segment
- Any MPRIS-capable player (Spotify, mpv with mpris plugin, Firefox, etc.)

## Fonts

For the true pixel-art look, install one of:

- [Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P) — set as `Theme.pixelFont`
- [PixelOperator](https://www.dafont.com/pixel-operator.font) — used for the media label
- [VT323](https://fonts.google.com/specimen/VT323) — good alt for body text
- [Pixelify Sans](https://fonts.google.com/specimen/Pixelify+Sans)

Arch one-liner for Press Start 2P + VT323:

```sh
yay -S ttf-press-start-2p ttf-vt323
```

If none are installed, the bar still renders — it falls back to the
system default and loses the pixel aesthetic.

## Launcher

A spotlight-style launcher shares the bar's chassis. It reads installed
`.desktop` entries and supports:

- Type to search (name → generic name → comment, ranked prefix-first)
- `↑` / `↓` / `Tab` / `Shift-Tab` / `PgUp` / `PgDn` to navigate
- `Enter` to launch
- `Esc` or click outside to dismiss

### Triggering it

The launcher is controlled via Quickshell's IPC:

```sh
quickshell ipc call launcher toggle   # open if closed, close if open
quickshell ipc call launcher show
quickshell ipc call launcher hide
```

In Hyprland (`~/.config/hypr/hyprland.conf`):

```conf
bind = SUPER, SPACE, exec, quickshell -p /home/wammu/src/wammu/qs-pixl ipc call launcher toggle
```

Or any key you like — the bind just runs the IPC call.

## Clipboard history

Same chrome as the launcher, but powered by [`cliphist`](https://github.com/sentriz/cliphist).

**Requirements:**

- `cliphist` recording clipboard changes (usual setup is `wl-paste --type text --watch cliphist store`)
- `wl-clipboard` for `wl-copy`
- `~/.config/hypr/scripts/paste.sh` — invoked after `wl-copy` to paste into the focused app (this is the helper from your dotfiles)

**Control:**

```sh
quickshell -p /home/wammu/src/wammu/qs-pixl ipc call clipboard toggle
```

Hyprland bind:

```conf
bind = SUPER, V, exec, quickshell -p /home/wammu/src/wammu/qs-pixl ipc call clipboard toggle
```

Pick with Enter / click; Esc or outside-click dismisses. Entries reload from `cliphist list` every time the overlay opens.

## Tweaking

All colors, sizes, and font names live in `Theme.qml`. Change them
there and every component updates.

## Files

| File | Role |
| ---- | ---- |
| `shell.qml` | entry point (multi-monitor Variants + launcher IPC) |
| `Bar.qml` | the `PanelWindow` + 3-section layout |
| `BarChrome.qml` | blue-gradient chassis with magenta trim & cyan rim |
| `PixelFrame.qml` | reusable bordered pocket |
| `Sparkle.qml` | tiny `+` decoration between segments |
| `Workspaces.qml` | left cluster |
| `MediaPlayer.qml` | center cluster |
| `VolumeIndicator.qml` | right cluster, part 1 |
| `Clock.qml` | right cluster, part 2 |
| `Launcher.qml` | spotlight-style app launcher overlay |
| `Clipboard.qml` | cliphist-backed clipboard history overlay |
| `Theme.qml` | colors, sizes, fonts (singleton) |
| `qmldir` | module manifest |
| `run.sh` | convenience launcher script |
