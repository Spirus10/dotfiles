# NixOS migration — `dotfiles` → flake

## Context

The current repo is a classic imperative Arch rice: `packages.txt`/`aur-packages.txt` drive `install.sh`, `sync-configs.sh` reverse-syncs `~/.config`, and every app config is a raw dotfile patched with `sed` at install time. This works but has no reproducibility, suffers repo/system drift, and requires manual upkeep.

The user wants a full conversion to NixOS organized as a flake, modeled on `RGBCube/ncc`. Settled decisions:

- **Channel**: `nixos-unstable` (reproducibility comes from `flake.lock`, not the channel)
- **GPU**: NVIDIA only (`hardware.nvidia` with `nvidia-open`)
- **Install**: fresh, declarative partitioning via `disko`
- **Neovim**: fully declarative via `nixvim`
- **Bar**: Quickshell only — Waybar is dropped entirely
- **Shell**: `programs.zsh` with native plugins — oh-my-zsh dropped
- **Secrets**: `agenix`
- **pywal16**: dropped — static lavender palette wins

Host name: `wammu` (single host). Preserves user's hand-crafted lavender palette, monitor layout, Hyprland keybinds, Quickshell `shell.qml`, keyd/udev rules.

Work happens on existing branch `nixos-migration`.

## Target layout

```
dotfiles/
├── flake.nix                    inputs + outputs, host discovery
├── flake.lock                   committed
├── .gitignore                   + result, .direnv
├── README.md                    bootstrap instructions
├── lib/
│   └── default.nix              collectNix helper (lists .nix files in a dir)
├── hosts/
│   └── wammu/
│       ├── default.nix          mkHost entry: imports modules + HM + disko
│       ├── hardware.nix         from nixos-generate-config (blob, committed)
│       ├── disko.nix            partition layout (EFI + ext4 root proposed)
│       └── monitors.nix         DP-1/DP-2/DP-3 layout (system-level for SDDM)
├── modules/
│   ├── nixos/                   system-level (root)
│   │   ├── default.nix          aggregator
│   │   ├── boot.nix             systemd-boot, kernel, nvidia modeset
│   │   ├── nvidia.nix           hardware.nvidia.{modesetting,open=true}
│   │   ├── networking.nix       NetworkManager, tailscale, firewall
│   │   ├── audio.nix            pipewire + wireplumber, noisetorch
│   │   ├── desktop.nix          programs.hyprland, xdg-desktop-portal-hyprland, SDDM
│   │   ├── fonts.nix            nerd-fonts.* (new nixpkgs schema) + noto + liberation
│   │   ├── keyd.nix             services.keyd with capslock→meta inline
│   │   ├── udev.nix             logitech trigger + yeti rules inline
│   │   ├── services.nix         openssh, solaar, tailscaled (conditional on lsusb via systemd)
│   │   ├── virtualisation.nix   libvirt/qemu + steam + gamescope
│   │   └── packages.nix         system CLI: git, vim, curl, rsync, man-db, bind
│   └── home/                    user-level (home-manager)
│       ├── default.nix          aggregator
│       ├── theme.nix            central lavender palette (attrset consumed by others)
│       ├── hyprland.nix         wayland.windowManager.hyprland.settings (port of .conf)
│       ├── quickshell.nix       pkgs.quickshell + xdg.configFile for shell.qml
│       ├── ghostty.nix          programs.ghostty.settings with lavender theme inline
│       ├── zsh.nix              programs.zsh: syntax-highlight, autosuggest, history-substring, starship prompt
│       ├── neovim.nix           programs.nixvim: plugins, keymaps, LSP, lavender scheme
│       ├── rofi.nix             programs.rofi + themes from repo as xdg.configFile
│       ├── swappy.nix           xdg.configFile."swappy/config"
│       ├── wallpaper.nix        swww systemd user unit + bg.gif via xdg.dataFile
│       ├── xdg.nix              xdg.userDirs + default apps
│       ├── git.nix              programs.git
│       └── packages.nix         home.packages: firefox, discord, 1password, spotify, obsidian, etc.
├── users/
│   └── wammu/
│       └── default.nix          user identity (uid, groups, shell, ssh keys)
├── secrets/
│   ├── secrets.nix              agenix key→recipient map
│   └── (*.age)                  encrypted payloads, added as needed
├── pkgs/
│   └── lavender-nvim.nix        buildVimPlugin wrapper (not in nixpkgs)
├── assets/
│   └── bg.gif                   kept as-is, referenced by wallpaper.nix
└── rebuild                      tiny nu/bash helper: `nixos-rebuild switch --flake .#wammu`
```

**Deleted after migration verifies:** `install.sh`, `sync-configs.sh`, `sync-packages.sh`, `packages.txt`, `aur-packages.txt`, `.aliases`, `.zshrc`, `.config/` (the whole tree), `udev/`, `keyd/`, legacy Waybar configs, `hyprland.conf.bak`.

## Phased rollout

Each phase is a discrete commit on `nixos-migration`. Every phase after Phase 1 is verifiable by `nixos-rebuild switch --flake .#wammu` producing a bootable generation.

### Phase 0 — Scaffolding
- `flake.nix` with inputs: `nixpkgs` (unstable), `home-manager`, `nixvim`, `disko`, `agenix`, `nixos-hardware`, `themes` (RGBCube/ThemeNix)
- `lib/default.nix` with `collectNix` (walks a directory, filters `*.nix`, returns list of paths for `imports = ...`)
- `.gitignore`: add `result`, `result-*`, `.direnv/`
- Placeholder `hosts/wammu/default.nix` returning a minimal empty config so `nix flake check` passes
- Commit message: `flake: scaffold inputs and host discovery`

### Phase 1 — Boot + disko (installable)
- `hosts/wammu/disko.nix`: GPT + 512 MB EFI FAT32 + ext4 root. Ask for disk device name during install.
- `hosts/wammu/hardware.nix`: placeholder until `nixos-generate-config` runs on target hardware
- `modules/nixos/boot.nix`: `boot.loader.systemd-boot.enable`, kernel
- `modules/nixos/nvidia.nix`: `hardware.nvidia = { open = true; modesetting.enable = true; nvidiaSettings = true; }`, `services.xserver.videoDrivers = [ "nvidia" ]`, `NVD_BACKEND=direct`, `GBM_BACKEND=nvidia-drm` env
- `modules/nixos/networking.nix`: NetworkManager, tailscaled, firewall with Tailscale trust
- `users/wammu/default.nix`: user `wammu`, groups `[wheel networkmanager audio video input]`, zsh shell, placeholder hashed password
- **Verification**: boot from NixOS ISO, `disko-install --flake github:spirus10/dotfiles/nixos-migration#wammu`, reboot into terminal login. No desktop yet.

### Phase 2 — Desktop base (graphical login)
- `modules/nixos/desktop.nix`: `programs.hyprland.enable`, `xdg.portal`, SDDM wayland
- `modules/nixos/audio.nix`: pipewire + wireplumber + pipewire-pulse + alsa
- `modules/nixos/fonts.nix`: `pkgs.nerd-fonts.*` (new attr scheme), `noto`, `liberation`, `font-awesome`
- `modules/nixos/keyd.nix`: `services.keyd.keyboards.default.settings.main.capslock = "leftmeta"`
- `modules/nixos/udev.nix`: `services.udev.extraRules` inline from current files
- `modules/nixos/services.nix`: openssh, solaar, noisetorch (package + enable pattern)
- **Verification**: `nixos-rebuild switch`, reboot, log into blank Hyprland (empty bar, no keybinds).

### Phase 3 — Hyprland + theme + terminal (usable desktop)
- `modules/home/theme.nix`: the lavender palette as an attrset (16 named colors with `hex`, `rgb`, `rgba` helpers)
- `modules/home/hyprland.nix`: port `hyprland.conf` to `wayland.windowManager.hyprland.settings` — monitors, keybinds, animations, window rules
- `modules/home/ghostty.nix`: port `ghostty/config` with lavender theme inlined from `theme.nix`
- `modules/home/zsh.nix`: `enableSyntaxHighlighting`, `autosuggestion.enable`, `historySubstringSearch.enable`, port LS_COLORS/ZSH_HIGHLIGHT_STYLES referencing `theme.nix`, keep your reboot-to-windows/uefi functions, `programs.starship` with lavender-themed prompt replacing robbyrussell
- `modules/home/xdg.nix`, `git.nix`, `packages.nix` (firefox, discord, 1password, spotify, etc.)
- `users/wammu/default.nix`: wire in `home-manager.users.wammu` importing all `modules/home`
- **Verification**: log into Hyprland, open Ghostty, zsh starts with colors matching lavender.

### Phase 4 — Bar + launcher + wallpaper (visual parity)
- `modules/home/quickshell.nix`: `home.packages = [ pkgs.quickshell ]`, `xdg.configFile."quickshell/shell.qml".source = ../../assets/quickshell/shell.qml` (move `shell.qml` into repo-assets first), systemd user unit for `qs`
- `modules/home/rofi.nix`: `programs.rofi.enable`, `theme = ./themes/lavender.rasi` (reusing existing rasi files moved to repo)
- `modules/home/wallpaper.nix`: `home.packages = [ pkgs.swww ]`, `assets/bg.gif` installed to `~/.local/share/wallpapers/bg.gif`, systemd user unit `swww-daemon.service` + `swww-restore.service`
- **Verification**: bar renders, launcher opens on SUPER+R, wallpaper animates.

### Phase 5 — Nixvim port
- `modules/home/neovim.nix`: `programs.nixvim` with plugins: `telescope`, `harpoon2`, `treesitter` (all grammars), `fugitive`, `undotree`, `zen-mode`, `trouble`, `cloak`, `copilot-lua` + `copilotchat`
- **No Mason.** Instead: `programs.nixvim.lsp.servers = { rust_analyzer, ts_ls, nixd, lua_ls, pyright, ... }` — language servers come from nixpkgs, declaratively
- `pkgs/lavender-nvim.nix`: `buildVimPlugin` wrapping the github source (not in nixpkgs). Referenced via `programs.nixvim.extraPlugins`.
- Port remaps (`remap.lua`) and options (`set.lua`) into `keymaps` and `opts` attrs
- **Verification**: `nvim` opens with lavender theme, telescope works, LSP attaches to a nix file.

### Phase 6 — Secrets (agenix)
- Generate age key from host SSH key
- `secrets/secrets.nix`: recipient mapping
- Wire `age.secrets.<name>.file = ./secrets/<name>.age` only if/when a secret is actually needed (wireguard keys, tailscale auth key, API tokens). No speculative secrets.
- **Verification**: `nixos-rebuild` succeeds with empty secrets set; add one real secret end-to-end as smoke test.

### Phase 7 — Cleanup + docs
- Delete all imperative-era files (listed above under "Deleted after migration verifies")
- Replace `README.md` with bootstrap doc: how to install from ISO using disko, how to rebuild, how to add a secret
- Add `rebuild` helper: `#!/usr/bin/env bash\nnh os switch .` (using `nh` — a nicer `nixos-rebuild` wrapper)
- Commit message: `chore: remove imperative-era dotfiles`

## Files to reference and port verbatim

| Source | Target | Method |
|---|---|---|
| `.config/hypr/hyprland.conf` | `modules/home/hyprland.nix` | manual port to `settings` attrset |
| `.config/quickshell/shell.qml` | `assets/quickshell/shell.qml` | move verbatim, point xdg.configFile at it |
| `.config/ghostty/config` | `modules/home/ghostty.nix` | manual port, drop `theme=lavender` in favor of inline `theme` attr |
| `.config/ghostty/themes/lavender` | `theme.nix` (palette source) + referenced by ghostty module | extract palette as Nix attrset |
| `.config/rofi/**` | `modules/home/rofi.nix` + `assets/rofi/` | mostly move-as-file; `programs.rofi` generates `config.rasi` |
| `.config/nvim/lua/wammu/**` | `modules/home/neovim.nix` (full nixvim port) | rewrite |
| `keyd/default.conf` | `modules/nixos/keyd.nix` | inline as `services.keyd.keyboards.default.settings` |
| `udev/rules.d/*.rules` | `modules/nixos/udev.nix` | inline as `services.udev.extraRules` |
| `assets/bg.gif` | `assets/bg.gif` | keep |
| `.zshrc` (palette/LS_COLORS) | `modules/home/zsh.nix` + `theme.nix` | rewrite |

## Nix patterns being used

- **Flake with host discovery**: `readDir ./hosts |> mapAttrs (name: _: import ./hosts/${name} { inherit inputs lib; })` — matches RGBCube
- **`collectNix` helper in `lib/`**: a function that returns every `.nix` under a path so `modules/nixos/default.nix` can auto-import all siblings
- **`specialArgs = { inherit inputs; }`**: so any module can reference `inputs.themes`, `inputs.nixvim`, etc. without threading manually
- **Home-manager as NixOS module**: `home-manager.nixosModules.home-manager` imported into the system, user config colocated
- **ThemeNix**: `inputs.themes.themes.custom { name = "lavender"; colors = { base00 = "..."; ... }; }` → gives us `with0x`/`withHashtag` for free and lets us swap schemes later

## Verification end-to-end

After Phase 7 the full test is:
1. Boot NixOS minimal ISO on the `wammu` hardware
2. `nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko --flake github:spirus10/dotfiles#wammu`
3. `nixos-install --flake github:spirus10/dotfiles#wammu`
4. Reboot → SDDM → login → Hyprland with Quickshell bar, animated wallpaper, lavender Ghostty, working nvim with LSP
5. `sudo nixos-rebuild switch --flake .#wammu` in the cloned repo produces no changes (idempotent)
6. `nh os switch .` works as the daily rebuild command

## Things intentionally *not* doing

- No `nh` / `nix-darwin` / multi-host abstraction until there's a second host
- No Hercules CI
- No `nixos-mailserver`, no `fenix` (use `rustup` via devshell or `rust-bin` overlay per-project, not system)
- No secrets added speculatively — agenix is wired up but `secrets/` is empty until a real secret appears
- No `disko-install` automation beyond writing the disko module — user runs it manually once
- No conversion of Arch's `grub` dual-boot with Windows unless user explicitly wants it (would need `boot.loader.grub` instead of systemd-boot; easy to add later)
