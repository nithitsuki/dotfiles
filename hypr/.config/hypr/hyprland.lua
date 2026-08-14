-- Hyprland Lua config
-- https://wiki.hypr.land/Configuring/
--
-- Single config for all machines. The hardware profile (pc / laptop) is
-- chosen by an UNCOMMITTED `.env` file next to this config (gitignored):
--
--     # ~/.config/hypr/.env
--     HYPR_PROFILE=laptop
--
-- Copy `.env.example` to `.env` and set the profile for this machine.

-----------------
-- PROFILE -------
-----------------

local function readEnvFile(path)
    local env = {}
    local f   = io.open(path, "r")
    if f then
        for rawLine in f:lines() do
            -- Lua 5.5: for-loop variables are const; use a fresh local
            local line = rawLine:gsub("^%s+", ""):gsub("%s+$", "")
            if line ~= "" and not line:match("^#") then
                local key, value = line:match("^([%w_]+)%s*=%s*(.-)%s*$")
                if key then
                    env[key] = value
                end
            end
        end
        f:close()
    end
    return env
end

local home       = os.getenv("HOME") or "~"

-- XDG base dir spec: empty XDG_CONFIG_HOME behaves like unset
local xdgConfig  = os.getenv("XDG_CONFIG_HOME")
if xdgConfig == nil or xdgConfig == "" then
    xdgConfig = home .. "/.config"
end
local configDir  = xdgConfig .. "/hypr"

-- an explicit env var always wins; otherwise read the .env file
local profile    = os.getenv("HYPR_PROFILE") or readEnvFile(configDir .. "/.env").HYPR_PROFILE or "pc"

----------------
-- MONITORS ----
----------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
if profile == "laptop" then
    hl.monitor({
        output   = "eDP-1",
        mode     = "preferred",
        position = "auto",
        scale    = "2",
        bitdepth = 10,
    })
    hl.monitor({
        output   = "DP-3",
        mode     = "preferred",
        position = "auto",
        scale    = "1.6",
        bitdepth = 10,
    })
    hl.monitor({
        output   = "HDMI-A-1",
        mode     = "preferred",
        position = "auto",
        scale    = "1",
        bitdepth = 10,
    })
else -- pc (default)
    hl.monitor({
        output   = "DP-2",
        mode     = "preferred",
        position = "auto",
        scale    = "1.6",
        bitdepth = 10,
    })
end

-------------------
-- MY PROGRAMS ----
-------------------

local terminal    = "kitty"
local fileManager = "kitty --detach yazi"
local menu        = "hyprlauncher"

-----------------
-- AUTOSTART ----
-----------------

-- The old `exec-once` entries live here. They run once when the compositor
-- has fully started.
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("vesktop --wayland --start-minimized")
    hl.exec_cmd("keepassxc --minimized")
end)

-- dbus-update-activation-environment is handled automatically by Hyprland on
-- startup, so the old `exec-once` for it is no longer needed.

-----------------------------
-- ENVIRONMENT VARIABLES ----
-----------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "WhiteSur-dark")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1.6")
hl.env("GDK_SCALE", "1.6")
-- hl.env("QT_QPA_PLATFORM", "wayland")
-- hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
-- hl.env("QT_STYLE_OVERRIDE", "kvantum")
-- hl.env("QT_QPA_PLATFORMTHEME", "kde")
-- hl.env("XDG_MENU_PREFIX", "plasma-")

-------------------
-- LOOK AND FEEL --
-------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 12,

        border_size = 1,

        col = {
            -- https://wiki.hypr.land/Configuring/Basics/Variables/#variable-types for color formats
            active_border   = { colors = { "0xaf99202c", "0x88ff99ee" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "scrolling",
    },

    decoration = {
        rounding = 10,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 0.9,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        -- https://wiki.hypr.land/Configuring/Basics/Variables/#blur
        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.3,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name         = "no-gaps-wtv1",
--     match        = { float = false, workspace = "w[tv1]" },
--     border_size  = 0,
--     rounding     = 0,
-- })
-- hl.window_rule({
--     name         = "no-gaps-f1",
--     match        = { float = false, workspace = "f[1]" },
--     border_size  = 0,
--     rounding     = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Variables/#misc
hl.config({
    misc = {
        force_default_wallpaper = 0, -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
        background_color        = "0x00131313",
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,
    },
})

-------------
-- INPUT ----
-------------

-- https://wiki.hypr.land/Configuring/Variables/#input
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "ctrl:nocaps",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0.65, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- https://wiki.hypr.land/Configuring/Variables/#gestures
-- hl.gesture({
--     fingers    = 3,
--     direction  = "horizontal",
--     action     = "workspace",
-- })

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

-----------------
-- KEYBINDINGS --
-----------------

-- See https://wiki.hypr.land/Configuring/Basics/Binds/
local mainMod = "ALT" -- See "Windows" key as main modifier

-- NOTE: the old `WINDOWS` modifier alias is gone in the Lua API, use SUPER/WIN/META.
local winMod = "SUPER"

-- Lock
hl.bind(winMod .. " + Q", hl.dsp.exec_cmd("hyprlock"))
-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + CTRL + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + CTRL + I", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(winMod .. " + CTRL + M", hl.dsp.exit())
hl.bind(winMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + CTRL + E", hl.dsp.exec_cmd("emacsclient -nc"))
hl.bind(mainMod .. " + CTRL + V", hl.dsp.window.float())
hl.bind(mainMod .. " + CTRL + f", hl.dsp.window.fullscreen()) -- took me long enough, for DDLC btw
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))

-- Scrolling layout
hl.bind(mainMod .. " + CTRL + period", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + CTRL + comma", hl.dsp.layout("swapcol l"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + CTRL + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + CTRL + TAB", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mainMod .. " + CTRL + D", hl.dsp.focus({ workspace = "name:D" }))
hl.bind(mainMod .. " + CTRL + SHIFT + D", hl.dsp.window.move({ workspace = "name:D" }))

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + CTRL + W", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + W", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Hide waybar
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("killall waybar || waybar"))

-- Trying to fix the crash: toggle displays off/on.
-- (Was `hyprctl keyword monitor "hyprctl dispatch dpms off" && ...` before.)
hl.bind(mainMod .. " + R", function()
    hl.dispatch(hl.dsp.dpms({ action = "off" }))
    hl.dispatch(hl.dsp.dpms({ action = "on" }))
end)

-- Copy screenshot to clipboard
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only --freeze"))

-- Color picker
hl.bind(winMod .. " + P", hl.dsp.exec_cmd("hyprpicker | wl-copy"))

-- Laptop multimedia keys for volume and LCD brightness
-- (bindel == locked + repeating in the old syntax)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

-- Requires playerctl (bindl == locked in the old syntax)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Laptop lid stuff
-- trigger when the switch is turning on (lid closed)
hl.bind("switch:on:Lid Switch", hl.dsp.dpms({ action = "off" }), { locked = true })
-- trigger when the switch is turning off (lid opened)
hl.bind("switch:off:Lid Switch", function()
    hl.dispatch(hl.dsp.dpms({ action = "on" }))
    hl.exec_cmd("hyprlock")
end, { locked = true })

----------------------------
-- WINDOWS AND WORKSPACES --
----------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more
-- See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/ for workspace rules

-- Assign applications to specific workspaces
hl.window_rule({
    name      = "assign-firefox",
    workspace = "1",
    match     = { class = "^(firefox)$" },
})
hl.window_rule({
    name      = "assign-code-emacs",
    workspace = "2",
    match     = { class = "^(code|Emacs)$" },
})
hl.window_rule({
    name      = "assign-vesktop",
    workspace = "name:D",
    match     = { class = "^(vesktop)$" },
})

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({
    name           = "ignore-maximize",
    suppress_event = "maximize",
    match          = { class = ".*" },
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name     = "xwayland-fix",
    no_focus = true,
    match    = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = true,
        pin        = false,
    },
})

-- Banish Discord to workspace 9 silently so it never steals focus.
-- NOTE: vesktop itself stays on workspace `name:D` (see assign-vesktop above) --
-- window rules apply in registration order and the last match wins, so the
-- old rule matching `^(vesktop|discord)$` was stealing vesktop to 9.
hl.window_rule({
    name      = "banish-vesktop",
    workspace = "9 silent",
    match     = { class = "^(discord)$" },
})

--------------------------
-- LAYERS AND XWAYLAND ---
--------------------------

-- Add blur to waybar and hyprlauncher
hl.layer_rule({
    name  = "waybar-blur",
    blur  = true,
    match = { namespace = "waybar" },
})
hl.layer_rule({
    name  = "hyprlauncher-blur",
    blur  = true,
    match = { namespace = "hyprlauncher" },
})

-- Unscale XWayland
hl.config({
    xwayland = {
        force_zero_scaling = false,
    },
})

-- hyprmon: managed monitor profile include
require("hyprmon")
