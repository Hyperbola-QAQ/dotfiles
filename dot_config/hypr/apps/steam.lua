
-- 防止 Steam 主窗口干扰游戏
hl.window_rule({
    match = {
        title = "^(Steam)$",
    },
    float = false,
    suppress_event = "activate",
    no_initial_focus = true,
    workspace = "11",
})

hl.window_rule({
    match = {
        title = "^(登录 Steam)$",
    },
    float = false,
    suppress_event = "activate",
    no_initial_focus = true,
    workspace = "11",
})