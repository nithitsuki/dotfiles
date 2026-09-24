# Dotfiles
My dotfiles, I use gnu-stow to manage them.

## Setup

### Interactive (recommended)

```bash
git clone https://github.com/nithitsuki/dotfiles.git .dotfiles
cd .dotfiles && bash ./run.sh
```
- Lets you select packages separately easily

### Windows (PowerShell)

```powershell
git clone https://github.com/nithitsuki/dotfiles.git "$HOME\.dotfiles"
cd "$HOME\.dotfiles"
powershell -ExecutionPolicy Bypass -File .\run.ps1
```

Windows counterpart to `run.sh`. It:
- Installs GNU Stow (for Git Bash) and verifies real symlink support,
  offering to enable Windows Developer Mode if needed.
- Stows the packages you pick (default: `emacs` → `~/.config/doom`).
- Sets `HOME` and `PATH` so Emacs and Git Bash agree on what `~` means.
- Optionally installs the latest GNU Emacs (via winget, or Chocolatey) and sets
  up Doom Emacs in `~/.emacs.d` — without overwriting the stowed config.
- Installs the JetBrainsMono Nerd Font (the config's icon font; Nerd Fonts v3
  abbreviates family names, so Windows only exposes `JetBrainsMono NFM`).
- Registers the Emacs daemon to start at login, and creates `emacsclient`
  shortcuts in the Start Menu, on the desktop, and on the taskbar.

Options: `-Yes` (non-interactive), `-Packages emacs,zsh`, `-NoEmacs`,
`-NoDaemon`, `-NoShortcuts`, `-NoFont`, `-DryRun`, `-Force`.

Only `emacs`, `kitty`, `zsh` and `dot-pi` make sense on Windows; `hypr`,
`waybar`, `keyd` and the xdg-desktop-portal packages are Linux-only.

### Manual (stow)

```bash
git clone https://github.com/nithitsuki/dotfiles.git .dotfiles
cd .dotfiles
stow -t ~ --dotfiles <package-names>
# for keyd:
sudo stow -t / keyd
```

## Important Notes

Symlink `~/.config/background` to your wallpaper file
```bash
ln -s /path/to/wallpaper.jpg ~/.config/background
```

Pick the hardware profile by editing the (gitignored) `~/.config/hypr/.env` file:
```bash
# ~/.config/hypr/.env  (uncommitted, per-machine)
HYPR_PROFILE=pc      # or: laptop
```
See `hypr/.config/hypr/.env.example` in the repo for a template.

> [!NOTE]
> Install doom emacs to use the emacs config

## hypr-lens (fork)

Screen capture, OCR, search, and recording overlay. Installed from my fork of
[thesleepingsage/hypr-lens](https://github.com/thesleepingsage/hypr-lens); installer fixes are in
[PR #9](https://github.com/thesleepingsage/hypr-lens/pull/9).

```bash
# Install (Arch only)
git clone https://github.com/nithitsuki/hypr-lens.git ~/Projects/hypr-lens
cd ~/Projects/hypr-lens
./hypr-lens-install.sh     # say yes to the OpenCV venv (content detection)

# Start it (also in the hyprland.lua autostart block)
hypr-lens                  # or: hl
```

Keybinds live in `hypr/.config/hypr/hyprland.lua`: `Print` (region screenshot), `Shift+Print`
(OCR), `Ctrl+Print` (image search), `Alt+Print` (record), `Ctrl+Shift+Print` (record + sound).
The installed reference list is `~/.config/hypr-lens/keybinds.example.conf`.

> [!NOTE]
> - Keep the fork fast-forwarded to upstream: `gh repo sync nithitsuki/hypr-lens`
> - Optional packages the installer offers: `satty` (annotate on right-click) and `wf-recorder` (recording)

## Coding Agents

The `dot-pi` package stows pi's config to `~/.pi/agent/settings.json`, the global rules in `~/.pi/agent/APPEND_SYSTEM.md`, and the `ship-quality` workflow skill (requires `--dotfiles`). opencode's config lives in `~/.config/opencode/` and is **not** stowed (it holds secrets — see below). See [coding-agent-setup.md](coding-agent-setup.md) for details, pinned packages, the project-skills loading rule, and what's deliberately not stowed.

## Setup a fresh Arch based distro
> [!CAUTION]
> ONLY USE THIS ON A FRESH INSTALLATION, IT WILL CAUSE IRREPARABLE DAMAGE TO YOUR SYSTEM IF USED ON AN EXISTING ONE

```bash
[root@host]# bash <(curl -sL https://raw.githubusercontent.com/nithitsuki/dotfiles/refs/heads/main/setup-fresh-archinstall.sh)
```

> [!CAUTION]
> READ THE WARNING ABOVE, THIS WILL CAUSE IRREPARABLE DAMAGE TO YOUR SYSTEM IF USED ON AN EXISTING ONE, YOU HAVE BEEN WARNED