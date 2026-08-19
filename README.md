# Dotfiles
My dotfiles, I use gnu-stow to manage them.

## Setup

### Interactive (recommended)

```bash
git clone https://github.com/nithitsuki/dotfiles.git .dotfiles
cd .dotfiles && bash ./run.sh
```
- Lets you select packages separately easily

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