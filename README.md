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
stow -t ~ \<package-names\>
# for keyd:
sudo stow -t / keyd
```

## Important Notes

Symlink `~/.config/background` to your wallpaper file
```bash
ln -s /path/to/wallpaper.jpg ~/.config/background
```

Symlink `~/.config/hypr/hyprland.conf` to either `hyprland_pc.conf` or `hyprland_laptop.conf`
```bash
ln -s ~/.config/hypr/hyprland_pc.conf ~/.config/hypr/hyprland.conf
```

> [!NOTE]
> Install doom emacs to use the emacs config
