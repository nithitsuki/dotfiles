# Dotfiles
My dotfiles, use gnu-stow to manage them.
## Setup

```bash
git clone https://github.com/nithitsuki/dotfiles.git .dotfiles
cd .dotfiles
stow  -n * # dry run to see what will be symlinked
# run the above command without -n to actually create the symlinks
```

TODO: add waybar from laptop

## Important Notes

- Symlink `~/.config/background` to your wallpaper file
- Symlink `~/.config/hypr/hyprland.conf` to either `hyprland_pc.conf` or `hyprland_laptop.conf`
- Install doom emacs to use the emacs config
