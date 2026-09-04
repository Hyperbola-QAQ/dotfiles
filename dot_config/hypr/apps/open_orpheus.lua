hl.window_rule({
    match = {
        class = "open-orpheus",
        title = "Open Orpheus Menu",
    },
    float = true,
    no_blur = true,
    border_size = 0,
    no_shadow = true,
    -- 移动到鼠标位置，偏移量 (10, 10) 让窗口出现在鼠标右下角
    move = "cursor 10 10",
})