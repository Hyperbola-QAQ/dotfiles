local toggle_fps_command = "/bin/bash " .. os.getenv("HOME") .. "/.config/hypr/apps/genshin-toggle-fps.sh"

hl.window_rule({
  match = {
    class = "steam_proton",
    title = "原神",
  },
  no_dim = true,
  render_unfocused = true,
})

-- Set the render rate for hidden render_unfocused windows.
hl.config({ misc = { render_unfocused_fps = 30 } })

-- BetterGI's transparent overlay only runs for scripted sessions, but when it
-- is up it should stay out of the way instead of taking focus from the game.
hl.window_rule({
  match = {
    class = "steam_proton",
    title = "MaskWindow",
  },
  no_focus = true,
  no_follow_mouse = true,
  focus_on_activate = false,
})

-- Both input paths share one handler and registration loop.
local function toggle_fps()
  local window = hl.get_active_window()
  if window and window.class == "steam_proton" and (window.title == "原神" or window.title == "MaskWindow") then
    hl.dispatch(hl.dsp.exec_cmd(toggle_fps_command))
    return { ok = true }
  else
    return { ok = false }
  end
end

for _, keys in ipairs({ "SUPER + F9", "mouse:275" }) do
  o.bind(keys, "原神：切换 1 FPS / 正常帧率", toggle_fps, { release = true, auto_consuming = true })
end

-- HUD visibility goes through the same script: the value is written back into
-- the config and only then reloaded, so a reload cannot reset the choice.
--
-- auto_consuming: only swallow the key while a Genshin window is focused.
-- Everywhere else it must fall through to the focused client, otherwise
-- Hyprland eats SHIFT+F12 globally and games never see MangoHud's own
-- toggle hotkey (CS2 was the visible casualty).
local function toggle_hud()
  local window = hl.get_active_window()
  if window and window.class == "steam_proton" and (window.title == "原神" or window.title == "MaskWindow") then
    hl.dispatch(hl.dsp.exec_cmd(toggle_fps_command .. " hud"))
    return { ok = true }
  else
    return { ok = false }
  end
end

o.bind("SHIFT + F12", "原神：切换 MangoHud 显示", toggle_hud, { auto_consuming = true })
