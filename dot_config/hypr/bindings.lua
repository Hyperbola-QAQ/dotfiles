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
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

o.bind("SUPER + R", "Launch apps", "omarchy-menu toggle apps")

o.bind("SUPER + SHIFT + R", "SSH", "ghostty -e ssh server")

hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "Music", "open-orpheus")

-- 4.5.0 给 SUPER + Q 新加了关窗，与 SUPER + W 重复，取消掉 Q 这条
hl.unbind("SUPER + Q")

-- Alt+Tab：Windows 风格的窗口循环。
-- 只 cycle_next 的话焦点会换到下一层窗口上，但它没被提到最前，
-- 鼠标一动 follow_mouse 立刻把焦点还回去。所以跟一个 bring_to_top。
hl.unbind("ALT + TAB")
hl.unbind("ALT + SHIFT + TAB")
o.bind("ALT + TAB", "Next window", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)
o.bind("ALT + SHIFT + TAB", "Previous window", function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- 切显示器：SUPER + ALT + TAB / +SHIFT
-- 原来这组是 CTRL + ALT + TAB；两条对调，和「组内切换」互换位置。
hl.unbind("SUPER + ALT + TAB")
hl.unbind("SUPER + ALT + SHIFT + TAB")
o.bind("SUPER + ALT + TAB", "Focus on next monitor", hl.dsp.focus({ monitor = "+1" }))
o.bind("SUPER + ALT + SHIFT + TAB", "Focus on previous monitor", hl.dsp.focus({ monitor = "-1" }))

-- 组内窗口切换：CTRL + ALT + TAB / +SHIFT（接替原来的 SUPER + ALT）
hl.unbind("CTRL + ALT + TAB")
hl.unbind("CTRL + ALT + SHIFT + TAB")
o.bind("CTRL + ALT + TAB", "Next window in group", hl.dsp.group.next())
o.bind("CTRL + ALT + SHIFT + TAB", "Previous window in group", hl.dsp.group.prev())

-- 静默截图：截完直接进剪贴板，不弹预览、不进编辑器
o.bind("CTRL + PRINT", "Silent screenshot (copy)", "omarchy-capture-screenshot copy")

o.bind("SUPER + E", "File manager", { omarchy = "nautilus" })

-- SUPER + grave 已交给 4.5.0 默认的 Quake 控制台（下拉式终端）；
-- 切到上一次的工作区改用默认的 SUPER + CTRL + TAB（按显示器记录）。


-- 音乐控制快捷键
-- 下一首：CTRL + ALT + 右箭头
o.bind("CTRL + ALT + RIGHT", "Music next", "playerctl next")
o.bind("CTRL + ALT + LEFT", "Music previous", "playerctl previous")
o.bind("CTRL + ALT + SPACE", "Music play/pause", "playerctl play-pause")
-- 鼠标组合键：侧键(BTN_EXTRA/276) 由 keyd 在 evdev 层当作“层激活键”，
-- 按住侧键时左/中/右键会变成 F13/F14/F15（见 /etc/keyd/default.conf）。
-- 两个坑，别踩：
--   1) Hyprland 0.57 拒绝任何“非修饰键 + 鼠标事件”的组合，所以只能绑单键，
--      不能写 "F13 + mouse:272"（External events cannot be combined with other keys）。
--   2) 必须用 code:191/192/193（evdev 键码 +8），不能用 "F13" 这类名字绑定：
--      同一颗键上既挂名字绑定又挂键码绑定，两者会互相顶掉，最后一个都不触发。
o.bind("code:191", "Mouse side + left: seek back 10s", "playerctl position 10-")   -- 侧键+左键 = 快退 10 秒
o.bind("code:192", "Mouse side + middle: play/pause", "playerctl play-pause")      -- 侧键+中键 = 播放/暂停
o.bind("code:193", "Mouse side + right: seek fwd 10s", "playerctl position 10+")   -- 侧键+右键 = 快进 10 秒

o.bind("CTRL + ALT + P", "Music play/pause", "playerctl play-pause")
o.bind("CTRL + ALT + UP", "Volume up", "playerctl volume .1+")
o.bind("CTRL + ALT + DOWN", "Volume down", "playerctl volume .1-")
-- 快进/快退 (例如，每次跳转 10 秒)
o.bind("CTRL + ALT + SHIFT + RIGHT", "Seek forward", "playerctl position 10+")
o.bind("CTRL + ALT + SHIFT + LEFT", "Seek backward", "playerctl position 5-")