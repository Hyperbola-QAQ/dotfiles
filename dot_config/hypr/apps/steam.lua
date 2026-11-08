
-- Steam 主窗口 → 副屏 2 区（全局 12，bar 上显示为 2），保持平铺不浮动
-- 防止 Steam 主窗口干扰游戏
hl.window_rule({
    match = {
        title = "^(Steam)$",
    },
    float = false,
    suppress_event = "activate",
    no_initial_focus = true,
    workspace = "12",
})

hl.window_rule({
    match = {
        title = "^(登录 Steam)$",
    },
    float = false,
    suppress_event = "activate",
    no_initial_focus = true,
    workspace = "12",
})
