-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "ghostty -e ssh server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

o.bind("SUPER + R", "Launch apps", "omarchy-menu toggle apps")

o.bind("SUPER + SHIFT + R", "SSH", "ghostty -e ssh server")

hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "Music", "open-orpheus")

o.bind("SUPER + E", "File manager", { omarchy = "nautilus" })



-- 音乐控制快捷键
-- 下一首：CTRL + ALT + 右箭头
o.bind("CTRL + ALT + RIGHT", "Music next", "playerctl next")
o.bind("CTRL + ALT + LEFT", "Music previous", "playerctl previous")
o.bind("CTRL + ALT + SPACE", "Music play/pause", "playerctl play-pause")
o.bind("CTRL + ALT + P", "Music play/pause", "playerctl play-pause")
o.bind("CTRL + ALT + UP", "Volume up", "playerctl volume .1+")
o.bind("CTRL + ALT + DOWN", "Volume down", "playerctl volume .1-")
-- 快进/快退 (例如，每次跳转 10 秒)
o.bind("CTRL + ALT + SHIFT + RIGHT", "Seek forward", "playerctl position 10+")
o.bind("CTRL + ALT + SHIFT + LEFT", "Seek backward", "playerctl position 5-")
-- 以 0.1 为步长调整速度
o.bind("CTRL + ALT + SHIFT + UP", "Speed up", "playerctl rate 0.1+")
o.bind("CTRL + ALT + SHIFT + DOWN", "Slow down", "playerctl rate 0.1-")