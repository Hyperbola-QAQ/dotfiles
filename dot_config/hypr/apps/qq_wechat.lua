-- ============================================
-- 社交应用：QQ & 微信 → workspace 10
-- ============================================

-- 1. 统一分配到 workspace 10
local app_classes = { "QQ", "wechat" }
for _, class in ipairs(app_classes) do
    hl.window_rule({
        match = { class = "^(" .. class .. ")$" },
        no_initial_focus = true,
        suppress_event = "activate",
        workspace = "10",
        group = "set",  -- 自动成组
    })
end



-- QQ: Escape 键拦截
local function on_active_window_changed()
    local win = hl.get_active_window()
    if win and win.class == "QQ" and win.title == "QQ" then
        hl.bind("Escape", hl.dsp.no_op(), { replace = true })
    else
        hl.unbind("Escape")
    end
end
hl.on("window.active", on_active_window_changed)
on_active_window_changed()


hl.window_rule({
    match = { class = "^wechat$", title = "微信" },
    float = false,
})

-- 3. 微信: 非主窗口去装饰
local wechat_exclude = "朋友圈|设置|聊天文件|预览|图片和视频"
hl.window_rule({
    match = {
        class = "^(wechat)$",
        title = "negative:^(" .. wechat_exclude .. ")\\W*",
    },
    no_blur = true,
    border_size = 0,
    no_shadow = true,
})

hl.window_rule({
    match = { class = "^wechat$", title = "^微信发送给$" },
    no_blur = true,
    border_size = 0,
    no_shadow = true,
})