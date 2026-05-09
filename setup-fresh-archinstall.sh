#!/usr/bin/env bash

set -e

# ==============================================================================
# Arch Linux Deployment Script - Stage 1
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (or inside arch-chroot)."
    exit 1
fi

echo "--> Initializing package lists and base dependencies..."
# Unconditional installation of bare minimums
pacman -Sy --needed --noconfirm git curl libnewt base-devel sudo

# ==============================================================================
# UI Helpers
# ==============================================================================
BACKTITLE="Arch Linux Automated Installer"

function msg() {
    whiptail --title "$1" --msgbox "$2" 10 60
}

# ==============================================================================
# User Configuration Phase
# ==============================================================================
TARGET_USER=""

# Ask if creating a new user or using an existing one
if whiptail --title "User Configuration" --backtitle "$BACKTITLE" \
    --yes-button "New User" --no-button "Existing User" \
    --yesno "Paru (AUR helper) cannot be built as root.\n\nDo you want to create a new user or use an existing one?" 12 70; then
    
    # Create new user
    while [ -z "$TARGET_USER" ]; do
        TARGET_USER=$(whiptail --title "New User Name" --backtitle "$BACKTITLE" \
            --inputbox "Enter the username for the new standard user:" 10 60 3>&1 1>&2 2>&3)
    done

    # We will also need a password for the new user, ensuring passwords match
    while true; do
        USER_PASS=$(whiptail --title "New User Password" --backtitle "$BACKTITLE" \
            --passwordbox "Enter password for $TARGET_USER:" 10 60 3>&1 1>&2 2>&3)
        USER_PASS_CONFIRM=$(whiptail --title "Confirm Password" --backtitle "$BACKTITLE" \
            --passwordbox "Confirm password for $TARGET_USER:" 10 60 3>&1 1>&2 2>&3)
        
        if [ "$USER_PASS" == "$USER_PASS_CONFIRM" ] && [ -n "$USER_PASS" ]; then
            break
        else
            msg "Error" "Passwords do not match or are empty. Please try again."
        fi
    done

    echo "--> Creating new user: $TARGET_USER"
    useradd -m -G wheel -s /bin/bash "$TARGET_USER" || true
    echo "$TARGET_USER:$USER_PASS" | chpasswd
else
    # Use existing user
    while [ -z "$TARGET_USER" ]; do
        TARGET_USER=$(whiptail --title "Existing User" --backtitle "$BACKTITLE" \
            --inputbox "Enter the existing username:" 10 60 3>&1 1>&2 2>&3)
        
        if ! id "$TARGET_USER" &>/dev/null; then
            msg "Error" "User '$TARGET_USER' does not exist."
            TARGET_USER=""
        fi
    done
fi

# Ensure this user is in the wheel group
usermod -aG wheel "$TARGET_USER"

# Grant passwordless sudo temporarily for the paru build process
echo "--> Setting up temporary NOPASSWD sudo for $TARGET_USER"
echo "$TARGET_USER ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/99-temp-$TARGET_USER"
chmod 440 "/etc/sudoers.d/99-temp-$TARGET_USER"

# ==============================================================================
# Paru Installation Phase
# ==============================================================================
if ! command -v paru &> /dev/null; then
    echo "--> Building and installing paru..."
    
    # Needs to be done in a place the user can write to
    su - "$TARGET_USER" -c '
        cd /tmp
        if [ ! -d "paru" ]; then
            git clone https://aur.archlinux.org/paru.git
        fi
        cd paru
        makepkg -si --noconfirm
    '
    echo "--> paru installed successfully!"
else
    echo "--> paru is already installed."
fi

# We will remove the temporary sudoers file at the very end of the main script,
# after everything else (dotfiles, full package list installs) has completed.

# ==============================================================================
# Package Selection Phase
# ==============================================================================
# Array format: "package_name" "Description" "ON/OFF"
BASE_TOOLS=(
    # --- Shell & Terminal ---
    "ly" "TUI display manager" "ON"
    "zsh" "Z shell" "ON"
    "zsh-autosuggestions" "Fish-like autosuggestions for zsh" "ON"
    "zsh-autocomplete" "Intelligent autocomplete for zsh" "ON"
    "zsh-completions" "Additional completion definitions for Zsh" "ON"
    "zsh-syntax-highlighting" "Syntax highlighting for Zsh" "ON"
    "awesome-terminal-fonts" "Icon fonts for terminals" "ON"
    "tmux" "Terminal multiplexer" "ON"
    
    # --- Text Editors ---
    "emacs-wayland" "Extensible text editor (Doom dependency)" "ON"
    "neovim" "Vim-fork focused on extensibility" "ON"
    
    # --- File Management ---
    "stow" "Symlink manager (for dots)" "ON"
    "yazi" "Blazing fast terminal file manager" "ON"
    "lsd" "Next-gen ls command" "ON"
    "zip" "Compression utility" "ON"
    "unzip" "Extraction utility" "ON"
    "7zip" "(yazi dep) File archiver" "ON"
    
    # --- System Monitoring & Info ---
    "fastfetch" "System information fetcher" "ON"
    "htop" "Interactive process viewer" "ON"
    "btop" "Resource monitor (C++)" "ON"
    "lm_sensors" "Hardware monitoring tools" "ON"
    "cava" "Terminal-based audio visualizer" "ON"
    
    # --- Networking ---
    "wget" "Network downloader" "ON"
    "net-tools" "Network utilities" "ON"
    "networkmanager" "Network connection manager (incl. nmtui)" "ON"
    "ufw" "Uncomplicated Firewall" "ON"
    
    # --- Git & Development ---
    "github-cli" "GitHub command line tool" "ON"
    "lazygit" "Simple terminal UI for git" "ON"
    "devtools" "Development tools" "ON"
    
    # --- Security & Password ---
    "keepassxc" "Password manager CLI" "ON"
    "keyd" "(AUR) Key remapping daemon" "ON"
    
    # --- Audio/Video ---
    "pipewire" "Low-latency audio/video router and server" "ON"
    "pipewire-pulse" "PulseAudio replacement for PipeWire" "ON"
    "pipewire-alsa" "ALSA configuration for PipeWire" "ON"
    "pipewire-jack" "JACK replacement for PipeWire" "ON"
    "wireplumber" "Session / policy manager for PipeWire" "ON"
    "ffmpeg" "(yazi dep) Video processing" "ON"
    
    # --- Utilities & Tools ---
    "bat" "Cat clone with syntax highlighting" "ON"
    "fzf" "(yazi dep) Fuzzy finder" "ON"
    "fd" "(yazi dep) Simple fast find" "ON"
    "ripgrep" "(yazi dep) Blazing fast grep" "ON"
    "zoxide" "(yazi dep) Smarter cd" "ON"
    "jq" "(yazi dep) JSON processor" "ON"
    "tealdeer" "Community-driven man pages (tldr)" "ON"
    
    # --- Documentation ---
    "man-db" "Standard man pages tool" "ON"
    "man-pages" "Linux man pages" "ON"
    
    # --- Image & Document Processing ---
    "imagemagick" "(yazi dep) Image viewing" "ON"
    "poppler" "(yazi dep) PDF rendering" "ON"
    "resvg" "(yazi dep - AUR) SVG rendering" "ON"
)

SELECTED_BASE=$(whiptail --title "Base Packages & Development Tools" --backtitle "$BACKTITLE" \
    --checklist "Select base tools and dependencies (Space to toggle, Enter to confirm):" 24 80 14 \
    "${BASE_TOOLS[@]}" 3>&1 1>&2 2>&3 | tr -d '"')

if [ -z "$SELECTED_BASE" ]; then
    msg "Warning" "No base packages were selected. Proceeding anyway..."
fi

GUI_TOOLS=(
    "hyprland" "Wayland compositor" "ON"
    "waybar" "Highly customizable Wayland bar" "ON"
    "hyprlauncher" "Application launcher" "ON"
    "hyprlock" "Screen locker" "ON"
    "hypridle" "Screen idle" "ON"
    "hyprpaper" "Wallpaper manager" "ON"
    "hyprpolkitagent" "Polkit agent for Hyprland" "ON"
    "hyprpicker" "Color picker" "ON"
    "kitty" "Fast, feature-rich, GPU-based terminal" "ON"
    "xdg-desktop-portal-hyprland" "xdg-desktop-portal backend for hyprland" "ON"
    "xdg-desktop-portal-termfilechooser-hunkyburrito-git" "(AUR) Terminal file chooser portal" "ON"
    "hyprmon-bin" "(AUR)  TUI monitor configuration tool for Hyprland" "ON"

    "tesseract-data-eng" "Tesseract OCR English language data" "ON"
    "firefox" "Web browser" "ON"
    "discord" "Voice and text chat" "ON"
    "vlc" "Media player" "ON"
    "pwvucontrol" "(AUR) GUI mixer for PipeWire" "ON"
    "gwenview" "Image viewer" "ON"
    "grim" "Screenshot utility" "ON"
    "zathura" "Minimal document viewer" "ON"
    "zathura-pdf-mupdf" "PDF support for zathura" "ON"
    "zaread-git" "(AUR) Read documents via terminal/zathura" "ON"

    "gnupg" "GNU Privacy Guard (for gpg-agent)" "ON"
    "pinentry" "Allows gpg-agent to prompt for passphrases" "ON"

    "vulkan-radeon" "Vulkan driver for AMD GPUs" "OFF"
    "vulkan-intel" "Vulkan driver for Intel GPUs" "OFF"
    "mesa" "Open-source OpenGL drivers" "ON"

    "wl-clipboard" "Wayland clipboard utilities" "ON"
    "cups" "Printing system" "ON"
    "poppler-data" "Additional data files for poppler (e.g. fonts)" "ON"
    "chafa" "Terminal graphics renderer (for fastfetch, yazi, etc)" "ON"

    # --- Optional Additions ---
    "libreoffice-fresh" "Office suite" "OFF"
    "krita" "Digital painting program" "OFF"
    "gimp" "GNU Image Manipulation Program" "OFF"
)

GUI_MODE=$(whiptail --title "Graphical Environment" --backtitle "$BACKTITLE" \
    --menu "How do you want to proceed with Graphical/GUI packages?" 14 60 3 \
    "ALL" "Install all GUI packages in the list" \
    "CUSTOM" "Review and select individually" \
    "NONE" "Skip GUI installation entirely" 3>&1 1>&2 2>&3)

if [ "$GUI_MODE" = "ALL" ]; then
    # Extract only the package names from the array (every 3rd element starting at 0)
    SELECTED_GUI=""
    for (( i=0; i<${#GUI_TOOLS[@]}; i+=3 )); do
        SELECTED_GUI="$SELECTED_GUI ${GUI_TOOLS[i]}"
    done
elif [ "$GUI_MODE" = "CUSTOM" ]; then
    SELECTED_GUI=$(whiptail --title "Graphical Packages & Applications" --backtitle "$BACKTITLE" \
        --checklist "Select graphical tools and Wayland setup (Space to toggle, Enter to confirm):" 24 80 14 \
        "${GUI_TOOLS[@]}" 3>&1 1>&2 2>&3 | tr -d '"')
else
    SELECTED_GUI=""
fi

# ==============================================================================
# Installation Phase
# ==============================================================================
echo "--> Installing selected packages..."
ALL_PKGS="$SELECTED_BASE $SELECTED_GUI"
if [ -n "$ALL_PKGS" ]; then
    # We execute paru as the target user to safely install both official and AUR packages
    su - "$TARGET_USER" -c "paru -S --needed --noconfirm $ALL_PKGS"
fi

# ==============================================================================
# Shell Configuration
# ==============================================================================
echo "--> Changing default shell to ZSH for $TARGET_USER..."
chsh -s "$(which zsh)" "$TARGET_USER"

# ==============================================================================
# Dotfiles Deployment
# ==============================================================================
echo "--> Cloning and deploying dotfiles..."
su - "$TARGET_USER" -c '
    if [ ! -d "$HOME/.dotfiles" ]; then
        echo "Cloning dotfiles repository..."
        git clone https://github.com/nithitsuki/dotfiles.git "$HOME/.dotfiles"
    fi
    # Execute the interactive run script if present
    if [ -f "$HOME/.dotfiles/run.sh" ]; then
        cd "$HOME/.dotfiles" && bash ./run.sh
    fi
'

# Note: Additional manual symlinking for background and hyprland configs
# should be evaluated based on the user environment (pc vs laptop)
# e.g., ln -s ~/.config/hypr/hyprland_pc.conf ~/.config/hypr/hyprland.conf

# ==============================================================================
# Services & GPG Agent Setup
# ==============================================================================
echo "--> Enabling system services and setting up GPG Agent..."

if [[ $SELECTED_BASE == *"ly"* ]]; then
    systemctl enable ly@tty3.service
    systemctl disable getty@tty3.service
fi

if [[ $SELECTED_BASE == *"networkmanager"* ]]; then
    systemctl enable NetworkManager.service
fi

if [[ $SELECTED_BASE == *"ufw"* ]]; then
    systemctl enable ufw.service
fi

if [[ $SELECTED_BASE == *"keyd"* ]]; then
    systemctl enable keyd.service
fi

# GPG-Agent setup for the standard user
su - "$TARGET_USER" -c '
    mkdir -p ~/.gnupg
    chmod 700 ~/.gnupg
    
    # Initialize basic gpg-agent config explicitly for SSH/GPG handling
    cat <<EOF > ~/.gnupg/gpg-agent.conf
enable-ssh-support
default-cache-ttl 60
max-cache-ttl 120
pinentry-program /usr/bin/pinentry
EOF
    
    # Ensure proper permissions
    chmod 600 ~/.gnupg/gpg-agent.conf
    
    # Reload agent seamlessly
    gpg-connect-agent reloadagent /bye > /dev/null 2>&1 || true
'

# ==============================================================================
# Doom Emacs Installation
# ==============================================================================
if [[ $SELECTED_BASE == *"emacs"* ]]; then
    echo "--> Installing Doom Emacs..."
    su - "$TARGET_USER" -c '
        if [ ! -d "$HOME/.config/emacs" ]; then
            git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
            # Unattended installation of Doom
            ~/.config/emacs/bin/doom install --force
        else
            echo "Doom Emacs configuration already exists."
        fi
    '
fi

echo "--> Finalizing setup and cleaning up..."
rm -f "/etc/sudoers.d/99-temp-$TARGET_USER"

echo "--> Prep phase complete."
msg "Success" "Base dependencies and paru installed successfully for user: $TARGET_USER"
