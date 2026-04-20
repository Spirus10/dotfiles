#!/bin/bash
# install.sh - Bootstrap Hyprland rice on a fresh Arch Linux installation.
# Run as a wheel user (sudo access required). Do NOT run as root.

set -e

# ── output helpers ────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()   { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── sanity checks ─────────────────────────────────────────────────────────────

[ "$EUID" -eq 0 ] && error "Do not run as root. Run as a wheel user with sudo access."
sudo -v || error "Could not obtain sudo — make sure this user is in the wheel group."

# Anchor all relative paths to the script's own directory.
cd "$(dirname "$(realpath "$0")")"

[ -f packages.txt ]     || error "packages.txt not found."
[ -f aur-packages.txt ] || error "aur-packages.txt not found."

echo -e "${CYAN}"
printf '  ┌──────────────────────────────────────────────────────┐\n'
printf '  │        Hyprland Rice Bootstrap  ·  Arch Linux        │\n'
printf '  │  user: %-44s │\n' "$(whoami)  |  home: $HOME"
printf '  └──────────────────────────────────────────────────────┘\n'
echo -e "${NC}"
warn "This will modify your system. Press Enter to continue or Ctrl+C to abort."
read -r

# ── system update ─────────────────────────────────────────────────────────────

log "Updating system..."
sudo pacman -Syu --noconfirm

# ── official packages ─────────────────────────────────────────────────────────

# Pull in curl and cliphist explicitly — they are required by this script and
# by your configs but are absent from packages.txt.
log "Installing curl and cliphist..."
sudo pacman -S --noconfirm --needed curl cliphist

log "Installing packages from packages.txt..."
mapfile -t PKGS < <(grep -Ev '^\s*(#|$)' packages.txt)
sudo pacman -S --noconfirm --needed "${PKGS[@]}"

# ── rust toolchain ────────────────────────────────────────────────────────────

# rustup is in packages.txt but ships without a default toolchain.
log "Initialising stable Rust toolchain (needed for swww build, may take a few minutes)..."
rustup default stable

# ── paru (AUR helper) ─────────────────────────────────────────────────────────

if ! command -v paru &>/dev/null; then
    log "Installing paru AUR helper..."
    BUILD=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$BUILD/paru"
    (cd "$BUILD/paru" && makepkg -si --noconfirm)
    rm -rf "$BUILD"
fi

# ── swww (built from source) ──────────────────────────────────────────────────

if ! command -v swww &>/dev/null; then
    log "Cloning and building swww from source (this will take a few minutes)..."
    BUILD=$(mktemp -d)
    git clone https://github.com/LGFae/swww.git "$BUILD/swww"
    (cd "$BUILD/swww" && cargo build --release)
    sudo install -Dm755 "$BUILD/swww/target/release/swww"        /usr/local/bin/swww
    sudo install -Dm755 "$BUILD/swww/target/release/swww-daemon" /usr/local/bin/swww-daemon
    rm -rf "$BUILD"
    log "swww installed to /usr/local/bin/"
else
    log "swww already installed, skipping build."
fi

# ── AUR packages ──────────────────────────────────────────────────────────────

log "Installing AUR packages..."
# Drop yay/yay-debug (replaced by paru) and blank/comment lines.
mapfile -t AUR_PKGS < <(grep -Ev '^\s*(#|$|yay$|yay-debug$)' aur-packages.txt)
if [ "${#AUR_PKGS[@]}" -gt 0 ]; then
    paru -S --noconfirm --needed "${AUR_PKGS[@]}"
fi

# ── zsh + oh-my-zsh ───────────────────────────────────────────────────────────

log "Setting up zsh..."
ZSH_BIN="$(which zsh)"
if [ "$SHELL" != "$ZSH_BIN" ]; then
    chsh -s "$ZSH_BIN"
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

log "Copying shell config..."
cp ./.zshrc   ~/
cp ./.aliases ~/

# ── wallpaper ─────────────────────────────────────────────────────────────────

log "Copying wallpaper..."
mkdir -p ~/images
[ -f ./assets/bg.gif ] && cp ./assets/bg.gif ~/images/ || warn "assets/bg.gif not found — skipping wallpaper copy."

# ── keyd ──────────────────────────────────────────────────────────────────────

log "Installing keyd config..."
sudo mkdir -p /etc/keyd
sudo cp ./keyd/keyd.conf /etc/keyd/
sudo systemctl enable --now keyd

# ── dotfiles ──────────────────────────────────────────────────────────────────

log "Copying dotfiles to ~/.config/..."
mkdir -p ~/.config
cp -r ./.config/* ~/.config/

# ── patch hardcoded username ──────────────────────────────────────────────────

# hyprland.conf embeds /home/wammu/ in the wallpaper exec-once and keybind paths.
log "Patching hardcoded /home/wammu/ paths to $HOME/..."
find ~/.config -type f \( -name "*.conf" -o -name "*.json" -o -name "*.jsonc" -o -name "config" \) \
    -exec grep -lF '/home/wammu/' {} \; \
    | while read -r f; do
        sed -i "s|/home/wammu/|${HOME}/|g" "$f"
        log "  patched: $f"
    done

# ── ghostty themes ────────────────────────────────────────────────────────────

log "Installing Ghostty themes..."
sudo mkdir -p /usr/share/ghostty/themes
sudo cp -r .config/ghostty/themes/* /usr/share/ghostty/themes/

# ── udev rules ────────────────────────────────────────────────────────────────

log "Installing udev rules..."
sudo cp ./udev/* /etc/udev/rules.d/
sudo udevadm control --reload-rules

# ── services ──────────────────────────────────────────────────────────────────

log "Enabling core services..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now tailscaled
sudo systemctl enable sddm          # don't --now; that would kill this terminal session

# noisetorch: enabled but NOT started — requires the user to open the GUI after
# first boot and select their microphone source before activating the filter.
log "Enabling noisetorch service..."
sudo systemctl enable noisetorch
warn "noisetorch is enabled but NOT started. After reboot, open noisetorch, select your mic, and click 'Load noisetorch'."

# solaar: only relevant if a Logitech USB device is present.
if lsusb 2>/dev/null | grep -qi "logitech"; then
    log "Logitech device detected — enabling solaar..."
    sudo systemctl enable --now solaar
else
    warn "No Logitech USB device detected — skipping solaar. Enable it later with: sudo systemctl enable --now solaar"
fi

# ── missing helper script warnings ───────────────────────────────────────────

MISSING_COUNT=0
MISSING_SCRIPTS=(
    "$HOME/.config/hypr/scripts/copy-with-history.sh"
    "$HOME/.config/hypr/scripts/paste.sh"
    "$HOME/.config/hypr/scripts/clipboard-history.sh"
    "$HOME/.config/waybar/scripts/swwwallpaper.sh"
    "$HOME/.config/waybar/scripts/cliphist.sh"
    "$HOME/.config/waybar/scripts/swwwallselect.sh"
)

for script in "${MISSING_SCRIPTS[@]}"; do
    if [ ! -f "$script" ]; then
        warn "Missing helper script: $script"
        (( MISSING_COUNT++ )) || true
    fi
done

if [ "$MISSING_COUNT" -gt 0 ]; then
    warn "$MISSING_COUNT helper script(s) missing. Hyprland keybinds and waybar modules that call them will silently fail until they exist."
fi

# ── done ──────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}┌─────────────────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│                    Setup complete!                      │${NC}"
echo -e "${GREEN}│                                                         │${NC}"
echo -e "${GREEN}│  Next steps:                                            │${NC}"
echo -e "${GREEN}│    1. Reboot                                            │${NC}"
echo -e "${GREEN}│    2. Open noisetorch → select mic → click Load         │${NC}"
echo -e "${GREEN}│    3. Verify monitor layout in hyprland.conf            │${NC}"
echo -e "${GREEN}│    4. Add any missing helper scripts flagged above      │${NC}"
echo -e "${GREEN}└─────────────────────────────────────────────────────────┘${NC}"
