-- ~/.config/hypryou/hyprland.lua
--
-- Personal overrides for HyprYou.
--
-- This file is loaded LAST (see /usr/share/hypryou/hyprland/main.lua), so the
-- unbind/bind calls here win over HyprYou's settings file.

--------------------
-- SCALING --------
--------------------

-- HyprYou's main.lua pins every output to scale 1. The laptop panel is
-- eDP-1 (2880x1800), which needs scale 2.
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "auto",
    scale    = 2,
    bitdepth = 10,
})

--------------------
-- OLED CARE -----
--------------------

-- Dim unfocused windows so bright, static content is muted.
hl.config({
    decoration = {
        dim_inactive = true,
        dim_strength = 0.2,
    },
})

--------------------
-- INPUT ----------
--------------------

-- Caps Lock acts as Ctrl, as in the usual setup.
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "ctrl:nocaps",
        sensitivity = 0.65,
        follow_mouse = 1,
        touchpad = {
            natural_scroll = false,
        },
    },
})

--------------------
-- PROGRAMS -------
--------------------

local terminal    = "kitty"
local fileManager = "kitty --detach yazi"

--------------------
-- AUTOSTART ------
--------------------

-- Start hypr-lens once the compositor is up. The Print-family keybinds below
-- dispatch to the global shortcuts that this daemon registers.
-- HyprYou's own main.lua already registers an hl.on("hyprland.start") handler,
-- so this is a second one; both run.
local home = os.getenv("HOME")

hl.on("hyprland.start", function()
    hl.exec_cmd(home .. "/.local/bin/hypr-lens")
end)

--------------------------
-- SCREENSHOT OVERLAY ---
--------------------------

-- HyprYou animates layer surfaces (animation.lua: layersIn/layersOut, style
-- "slide"). That makes the hypr-lens selector, which is a layer surface in the
-- overlay layer, slide in and feel laggy. Show and hide it with no animation.
hl.layer_rule({
    match = { namespace = ".*regionSelector.*" },
    no_anim = true,
})

--------------------
-- KEYBINDS -------
--------------------
-- mainMod is ALT, winMod is SUPER, as in the usual setup.

local mainMod = "ALT"
local winMod  = "SUPER"

-- HyprYou already owns these keys. Remove its binds first so only ours fire
-- (Hyprland runs every bind that matches a key).
hl.unbind(winMod .. " + Q")
hl.unbind(winMod .. " + E")
hl.unbind("XF86AudioRaiseVolume")
hl.unbind("XF86AudioLowerVolume")
hl.unbind("XF86AudioMute")
hl.unbind("XF86AudioMicMute")
hl.unbind("XF86MonBrightnessUp")
hl.unbind("XF86MonBrightnessDown")
hl.unbind("XF86AudioPlay")
hl.unbind("XF86AudioPause")
hl.unbind("XF86AudioNext")
hl.unbind("XF86AudioPrev")

-- HyprYou's screenshot keys (hyprland_generated.lua). They run
-- `hypryouctl screenshot`, which shells out to hyprshot and opens HyprYou's
-- preview window. Screenshots go through hypr-lens only (the Print family
-- below), so remove all six.
hl.unbind("SUPER + SHIFT + S")
hl.unbind("SUPER + SHIFT + F")
hl.unbind("SUPER + CTRL + S")
hl.unbind("SUPER + CTRL + F")
hl.unbind("SUPER + ALT + S")
hl.unbind("SUPER + ALT + F")

-- HyprYou's app launcher, on the usual key.
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("hypryouctl toggle_window apps_menu"))

-- Lock (HyprYou's native GTK4 session lock)
hl.bind(winMod .. " + Q", hl.dsp.exec_cmd("hypryouctl lock"))

hl.bind(mainMod .. " + CTRL + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + CTRL + I", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(winMod .. " + CTRL + M", hl.dsp.exit())
hl.bind(winMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + CTRL + E", hl.dsp.exec_cmd("emacsclient -nc"))
hl.bind(mainMod .. " + CTRL + V", hl.dsp.window.float())
hl.bind(mainMod .. " + CTRL + f", hl.dsp.window.fullscreen())

-- Scrolling-layout binds. These only work while the layout is "scrolling".
hl.bind(mainMod .. " + CTRL + period", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + CTRL + comma", hl.dsp.layout("swapcol l"))

-- Move focus with mainMod + CTRL + HJKL
hl.bind(mainMod .. " + CTRL + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.focus({ direction = "down" }))

-- Workspaces: mainMod + CTRL + [0-9]; move window: add SHIFT
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + CTRL + TAB", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mainMod .. " + CTRL + D", hl.dsp.focus({ workspace = "name:D" }))
hl.bind(mainMod .. " + CTRL + SHIFT + D", hl.dsp.window.move({ workspace = "name:D" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + CTRL + W", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + W", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Hide waybar
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("killall waybar || waybar"))

-- Toggle displays off/on
hl.bind(mainMod .. " + R", function()
    hl.dispatch(hl.dsp.dpms({ action = "off" }))
    hl.dispatch(hl.dsp.dpms({ action = "on" }))
end)

-- Screenshots, OCR, image search, and recording, all through hypr-lens (started
-- in the AUTOSTART block above). Modifiers pick the action, as in the usual
-- setup: Print (region screenshot), Shift+Print (OCR), Ctrl+Print (image
-- search), Alt+Print (record), Ctrl+Shift+Print (record with sound).
-- The quickshell:region* global shortcuts only exist while the daemon runs.
hl.bind("Print", hl.dsp.global("quickshell:regionScreenshot"))  -- region screenshot -> clipboard
hl.bind("SHIFT + Print", hl.dsp.global("quickshell:regionOcr"))  -- OCR -> clipboard
hl.bind("CTRL + Print", hl.dsp.global("quickshell:regionSearch"))  -- image search (Google Lens)
hl.bind("ALT + Print", hl.dsp.global("quickshell:regionRecord"))  -- record region (toggle)
hl.bind("CTRL + SHIFT + Print", hl.dsp.global("quickshell:regionRecordWithSound"))  -- record with sound

-- Color picker
hl.bind(winMod .. " + P", hl.dsp.exec_cmd("hyprpicker | wl-copy"))

-- Multimedia keys
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Laptop lid: closing locks the session and turns the screen off.
hl.bind("switch:on:Lid Switch", function()
    hl.exec_cmd("hypryouctl lock")
    hl.dispatch(hl.dsp.dpms({ action = "off" }))
end, { locked = true })

hl.bind("switch:off:Lid Switch", hl.dsp.dpms({ action = "on" }), { locked = true })
