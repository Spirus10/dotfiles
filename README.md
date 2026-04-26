# dotfiles

NixOS flake for the `wammu` host. Everything that used to be an imperative
`install.sh` + `sync-configs.sh` + hand-edited `~/.config/*` is now declarative:
one `git pull && rebuild` brings the whole system back to the state described
in this repo.

- **Channel**: `nixpkgs` unstable, pinned by `flake.lock`
- **GPU**: NVIDIA (`hardware.nvidia` with `nvidia-open`)
- **Desktop**: Hyprland + Quickshell (bar + launcher + clipboard), SDDM login
- **Editor**: Neovim via `nixvim` — declarative plugins, LSP, keymaps
- **Shell**: `zsh` with native plugins + starship
- **Secrets**: `agenix`
- **Install**: `disko` — partitioning is part of the repo
- **Theme**: static lavender palette, threaded from `modules/home/theme.nix`

---

## Repo layout

```
flake.nix                flake inputs + outputs (host discovery)
flake.lock               pinned input revisions — commit this
lib/                     helpers (collectNix)
hosts/
  wammu/
    default.nix          entry point — imports modules + disko + HM
    hardware.nix         from nixos-generate-config (per-machine)
    disko.nix            partition layout (EFI + ext4 root)
    monitors.nix         system-level monitor layout (for SDDM)
users/
  wammu/default.nix      user account + home-manager wiring
modules/
  nixos/                 SYSTEM scope — root, boot, hardware, services
    boot.nix             systemd-boot + kernel
    nvidia.nix           driver + modeset + env vars
    desktop.nix          hyprland, portals, SDDM
    audio.nix            pipewire + wireplumber
    networking.nix       NetworkManager, tailscaled, firewall
    fonts.nix            nerd-fonts + noto + liberation
    keyd.nix             capslock → meta
    udev.nix             logitech + yeti rules
    services.nix         openssh, solaar, noisetorch
    packages.nix         system-wide CLI (git, curl, rsync, ...)
  home/                  USER scope — $HOME config, per-user packages
    default.nix          aggregator imported by users/wammu
    theme.nix            the lavender palette (single source of truth)
    hyprland.nix         wayland.windowManager.hyprland.settings
    quickshell.nix       shell.qml + systemd user unit
    ghostty.nix          terminal settings + inline theme
    zsh.nix              shell + aliases + starship
    neovim.nix           nixvim: plugins, LSP, keymaps
    wallpaper.nix        awww animated wallpaper + bg.gif
    git.nix              programs.git
    xdg.nix              default apps + user dirs
    packages.nix         user-scope apps (firefox, 1password, ...)
pkgs/
  lavender-nvim.nix      buildVimPlugin wrapper (not in nixpkgs)
secrets/
  secrets.nix            agenix recipient map (CLI-side, no NixOS import)
  *.age                  encrypted payloads (commit the ciphertext)
assets/
  bg.gif                 wallpaper (animated GIF loop)
  bg.webm                old mpvpaper conversion, currently unused
  quickshell/shell.qml   bar/launcher/clipboard UI
rebuild                  tiny wrapper around `nh os switch .`
```

Two scopes, always: **system** things (drivers, services, kernel, anything
needing root) go under `modules/nixos/`; **user** things (your editor config,
shell, fonts' XDG setup, GUI apps) go under `modules/home/`.

---

## Fresh install (from the NixOS ISO)

1. Boot the NixOS minimal ISO.
2. Get network. Wi-Fi: `sudo systemctl start wpa_supplicant`, then
   `wpa_cli` — or just plug in Ethernet.
3. Partition and install in one shot using disko. This wipes the disk in
   `hosts/wammu/disko.nix` — confirm the device path before running:

   ```
   sudo nix --experimental-features 'nix-command flakes' run \
     github:nix-community/disko -- \
     --mode disko --flake github:spirus10/dotfiles#wammu
   sudo nixos-install --flake github:spirus10/dotfiles#wammu
   ```

4. Set the user password when prompted, reboot, pull the disk.
5. Clone the repo on the fresh system so future rebuilds happen from a
   local checkout:

   ```
   git clone https://github.com/spirus10/dotfiles ~/src/wammu/dotfiles
   ```

6. Populate the agenix recipient map (see **Secrets** below). You don't
   need to do this until you actually encrypt a secret — rebuilds work
   fine with an empty `secrets/secrets.nix`.

---

## The mental model (if you're new to Nix)

A few ideas up front — skipping these is the usual reason Nix feels weird.

**You do not install packages imperatively.** There is no `apt install`,
no `pip install` into the system, no `npm install -g`. Every package on
this machine is listed somewhere in this repo. If it's not in the repo,
it's not installed. If you run `nix-env -i foo`, you're creating exactly
the kind of drift this repo exists to eliminate — don't.

**Two scopes, two files.**
- System-wide CLI → `modules/nixos/packages.nix`. Applies to every user,
  requires a `nixos-rebuild`.
- Your user's GUI apps / personal tools → `modules/home/packages.nix`.
  Managed by home-manager.

**Rebuild = activate a new generation.** `nixos-rebuild switch` builds a
whole new system closure, flips a symlink, and activates it. The old
generation is still bootable from the bootloader menu. Nothing is ever
mutated in place — that's why rollback is one `systemctl reboot` away.

**`flake.lock` is the source of truth for versions.** `nixpkgs-unstable`
is the channel, but you're not on a moving target — you're on whatever
revision `flake.lock` pins. `nix flake update` rolls that forward.

**Config files under `~/.config` are not yours.** Home-manager writes
them as symlinks into the Nix store. Don't edit `~/.config/ghostty/config`
directly — it'll either be overwritten or (worse) ignored on the next
rebuild. Edit `modules/home/ghostty.nix` and rebuild.

---

## Daily use

### Rebuilding

```
./rebuild              # wrapper: nh os switch .
```

or raw:

```
sudo nixos-rebuild switch --flake .#wammu
```

`switch` = build + activate + boot-into-this-next-time. Other verbs:

- `boot` — stage for next boot, don't activate now (kernel upgrades)
- `test` — activate now, don't add to bootloader (reverts on reboot)
- `build` — build only, no activation (useful for catching errors)

To build the VM variant from this same root flake:

```
sudo nixos-rebuild switch --flake .#wammu-vm
```

### Adding a package

**System CLI** (e.g. `htop`) — needed globally, at login shells, in
system services:

```nix
# modules/nixos/packages.nix
environment.systemPackages = with pkgs; [
  # ...
  htop
];
```

**Your GUI apps / personal tools** (e.g. `signal-desktop`) — only you
use it:

```nix
# modules/home/packages.nix
home.packages = with pkgs; [
  # ...
  signal-desktop
];
```

Then `./rebuild`. If you're not sure which attribute name a package has,
`nix search nixpkgs <term>`.

### Trying a package *without* installing it

```
nix shell nixpkgs#hello
```

Drops you into a subshell with `hello` on `$PATH`. Exit the shell, it's
gone. This is the right answer for one-off tools — don't add things to
`packages.nix` just to try them.

### Updating inputs

```
nix flake update                     # bump everything
nix flake update nixpkgs             # bump one input
./rebuild                            # activate the new versions
```

Commit `flake.lock` afterward.

### GitHub auth (PAT) for flakes

If you hit unauthenticated GitHub rate limits while fetching flake
inputs, add a token to Nix's config on the machine doing the build:

```
# user-level (non-NixOS)
mkdir -p ~/.config/nix
printf 'access-tokens = github.com=YOUR_TOKEN\n' >> ~/.config/nix/nix.conf

# or system-wide on NixOS
sudo sh -c "printf 'access-tokens = github.com=YOUR_TOKEN\n' >> /etc/nix/nix.conf"
```

Then restart the daemon (`sudo systemctl restart nix-daemon`) or open a
new shell before retrying.

### Rolling back

```
sudo nixos-rebuild switch --rollback
```

or pick an older generation from the bootloader at boot. To list what's
around: `sudo nix-env --list-generations --profile /nix/var/nix/profiles/system`.

### Garbage collection

Generations accumulate. When `/nix/store` gets large:

```
sudo nix-collect-garbage --delete-older-than 14d    # keep last 2 weeks
sudo nixos-rebuild switch --flake .#wammu           # regenerate boot entries
```

Never delete the current generation.

### Adding a whole new module

Say you want a new service — `foobar`. Two steps:

1. Create `modules/nixos/foobar.nix` (or `modules/home/foobar.nix` if it's
   user-scope). Write a normal module:

   ```nix
   { pkgs, ... }:
   {
     services.foobar.enable = true;
   }
   ```

2. That's it. The `collectNix` helper in `lib/default.nix` auto-imports
   every `.nix` file under `modules/nixos/` and `modules/home/`. No
   `imports = [ ./foobar.nix ];` boilerplate required.

### Editing a config file from upstream

If a module's NixOS options don't cover something you need, use
`environment.etc."foo/bar.conf".text = ''...''` (system) or
`xdg.configFile."foo/bar.conf".text = ''...''` (home). But: if a
`programs.<thing>` or `services.<thing>` exists, prefer it — options are
typed, validated, and survive upstream schema changes better than raw
strings.

### The theme

`modules/home/theme.nix` is the single source of truth for colors. It's
threaded into every home-manager module via `_module.args.theme`, so any
module can do:

```nix
{ theme, ... }:
{
  programs.something.settings.color = theme.purple.hex;
}
```

Change a color once, rebuild, everything follows.

---

## Secrets (agenix)

Agenix encrypts files against SSH public keys. At boot, a systemd
activation decrypts them under `/run/agenix/<name>` using the host's
`/etc/ssh/ssh_host_ed25519_key`. The ciphertext is safe to commit.

**First-time setup** (after `wammu` is up):

```
ssh wammu 'cat /etc/ssh/ssh_host_ed25519_key.pub'
```

Paste the host pubkey into `wammu-host` inside `secrets/secrets.nix`.
Paste your local pubkey (`cat ~/.ssh/id_ed25519.pub`) into `wammu-user`.

**Add a secret**:

```
cd secrets
agenix -e wifi-home.age          # editor opens; paste plaintext; save
```

Then in whichever module needs it:

```nix
age.secrets.wifi-home.file = ../../secrets/wifi-home.age;

# at runtime, refer to: config.age.secrets.wifi-home.path
# which resolves to /run/agenix/wifi-home
```

**Rekey** (after adding or removing a recipient):

```
cd secrets && agenix -r
```

Never commit the plaintext. Never commit `~/.ssh/id_ed25519`. `.gitignore`
already excludes `.agenix/`.

---

## Dev shells

Project-specific toolchains belong in per-project `flake.nix` files, not
in this repo. The pattern is:

```nix
# some-project/flake.nix
{
  outputs = { nixpkgs, ... }: {
    devShells.x86_64-linux.default =
      let pkgs = nixpkgs.legacyPackages.x86_64-linux; in
      pkgs.mkShell { buildInputs = [ pkgs.rustc pkgs.cargo ]; };
  };
}
```

`nix develop` or (with `direnv`) a one-line `.envrc` containing `use flake`
auto-loads it when you `cd` in.

This keeps the system config lean: `rustc` isn't installed globally, it's
only present inside projects that ask for it.

---

## Conventions

- **One file per concern.** Module files are small and focused; no
  `misc.nix` dumping ground.
- **System vs home is load-bearing.** Don't put user GUI apps in
  `modules/nixos/packages.nix`. Don't put kernel modules in home.
- **Commit `flake.lock`.** It's not a build artifact, it's the version pin.
- **No `nix-env -i`, no `nix profile install`.** Edit a module, rebuild.
  If it's not in the repo, it's not installed.
- **No `~/.config/*` hand-edits.** Home-manager owns those paths. Edit
  the corresponding `.nix` file.
- **No speculative secrets.** Wire `agenix` only when a real secret
  needs to exist.
