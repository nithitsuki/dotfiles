#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

OS="$(uname -s)"
case "$OS" in
  Linux) PLATFORM="linux" ;;
  Darwin) PLATFORM="mac" ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

if ! command -v stow >/dev/null 2>&1; then
  echo "gnu-stow is not installed."
  if [[ "$PLATFORM" == "mac" ]]; then
    echo "Install with: brew install stow"
  else
    echo "Install with your package manager (examples):"
    echo "  sudo apt install stow"
    echo "  sudo pacman -S stow"
    echo "  sudo dnf install stow"
  fi
  exit 1
fi

echo "Dotfiles interactive setup ($PLATFORM)"
echo "Repository: $SCRIPT_DIR"
echo

# Collect top-level stow packages, excluding hidden entries and run.sh itself.
mapfile -t ALL_PACKAGES < <(
  find . -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf '%f\n' | sort
)

if [[ ${#ALL_PACKAGES[@]} -eq 0 ]]; then
  echo "No stow packages found."
  exit 1
fi

PACKAGES=()
for pkg in "${ALL_PACKAGES[@]}"; do
  # keyd targets /etc and is Linux-only.
  if [[ "$pkg" == "keyd" && "$PLATFORM" == "mac" ]]; then
    continue
  fi
  PACKAGES+=("$pkg")
done

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
  echo "No compatible packages found for this platform."
  exit 1
fi

echo "Available packages: ${PACKAGES[*]}"
echo

read -r -p "Use all compatible packages? [Y/n]: " use_all
use_all="${use_all:-Y}"

SELECTED=()
if [[ "$use_all" =~ ^[Yy]$ ]]; then
  SELECTED=("${PACKAGES[@]}")
else
  for pkg in "${PACKAGES[@]}"; do
    read -r -p "Include '$pkg'? [y/N]: " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      SELECTED+=("$pkg")
    fi
  done
fi

if [[ ${#SELECTED[@]} -eq 0 ]]; then
  echo "No packages selected. Exiting."
  exit 0
fi

echo
echo "Selected packages: ${SELECTED[*]}"
echo

NON_KEYD=()
DO_KEYD=false
for pkg in "${SELECTED[@]}"; do
  if [[ "$pkg" == "keyd" ]]; then
    DO_KEYD=true
  else
    NON_KEYD+=("$pkg")
  fi
done

if [[ ${#NON_KEYD[@]} -gt 0 ]]; then
  echo "Dry run (home target): stow -n ${NON_KEYD[*]}"
  stow -n "${NON_KEYD[@]}"
fi

if [[ "$DO_KEYD" == true ]]; then
  if [[ "$PLATFORM" == "linux" ]]; then
    echo
    echo "Dry run (system target): sudo stow -n -t / keyd"
    sudo stow -n -t / keyd
  else
    echo "Skipping keyd on macOS."
  fi
fi

echo
read -r -p "Apply these changes? [y/N]: " apply
if [[ ! "$apply" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

if [[ ${#NON_KEYD[@]} -gt 0 ]]; then
  echo "Applying: stow ${NON_KEYD[*]}"
  stow "${NON_KEYD[@]}"
fi

if [[ "$DO_KEYD" == true && "$PLATFORM" == "linux" ]]; then
  echo "Applying: sudo stow -t / keyd"
  sudo stow -t / keyd
fi

echo
echo "Done."
echo "Next steps:"
echo "- Ensure ~/.config/background points to your wallpaper file"
echo "- Set ~/.config/hypr/hyprland.conf to your preferred profile"
echo "- Install Doom Emacs if you use the Emacs config"
