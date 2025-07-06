#!/bin/bash
# install.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn "This script should be run on a fresh Arch Linux installation as a sudo user.\nIf you have not yet created a user, please do so now and re-run this script."
read -p "Press [Enter] to continue or Ctrl+C to abort..."

# Update system
log "Updating system..."
sudo pacman -Syu --noconfirm

# Install packages
log "Installing packages..."
while read -r package; do
    sudo pacman -S --noconfirm "$package"
done < packages.txt

# Install AUR helper if needed
if ! command -v yay &> /dev/null; then
    log "Installing yay AUR helper..."
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

# Install AUR packages

while read -r package; do
    log "Installing AUR package: $package..."
    yay -S --noconfirm "$package"
done < aur-packages.txt

# Set up zsh as default shell and install oh-my-zsh
log "Setting up zsh and oh-my-zsh..."
if [ "$SHELL" != "/bin/zsh" ]; then
    chsh -s /bin/zsh
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

log "Copying .zshrc..."
cp ./.zshrc ~/
cp ./.aliases ~/

log "Copying wallpaper..."
mkdir -p ~/images
cp ./assets/bg.gif ~/images/

log "Copying keyd config..."
sudo cp ./keyd/keyd.conf /etc/keyd/

# Copy dotfiles
log "Setting up dotfiles..."
cp -r ./.config/* ~/.config/

# Set up udev rules
log "Installing udev rules..."
sudo cp ./udev/* /etc/udev/rules.d/
sudo udevadm control --reload-rules

log "Copying Ghostty Theme..."
sudo cp -r .config/ghostty/themes/* /usr/share/ghostty/themes/

# Enable services
log "Enabling services..."
sudo systemctl enable --now noisetorch
sudo systemctl enable --now solaar

log "Setup complete! Please reboot."
