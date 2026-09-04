-- ============================================
-- 远程桌面：xfreerdp rustdesk
-- ============================================

-- 远程桌面窗口类列表（方便后续添加）
local REMOTE_DESKTOP_CLASSES = {
    "xfreerdp",
    "rustdesk",
    -- 后续可以继续添加，例如：
    -- "remmina",
    -- "vncviewer",
    -- "mstsc",
}

-- 状态标志：是否处于屏蔽模式
local blocked = false

-- 定义 submap（确保非空，至少包含一个占位绑定）
hl.define_submap("remote_desktop_block", function()
    -- 允许切换工作区 (WIN + 数字键 1-9)
    for workspace = 1, 10 do
        local key = "code:" .. tostring(workspace + 9)
        hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = tostring(workspace) }))
    end
    -- 允许切换全屏
    hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen" })
)
    
    -- 可选：允许其他必要的系统快捷键
    -- hl.bind("SUPER + TAB", function() hl.dispatch(hl.dsp.application_switcher) end)
    -- hl.bind("SUPER + SPACE", function() hl.dispatch(hl.dsp.spotlight) end)
    
    -- 注意：所有未在这里定义的快捷键都会被拦截并丢弃
    -- 这意味着 SUPER+H, SUPER+M, SUPER+Q 等系统快捷键在远程桌面中不会触发
end)

-- 判断是否为远程桌面窗口
local function is_remote_desktop_window(win)
    if not win then
        return false
    end
    for _, class in ipairs(REMOTE_DESKTOP_CLASSES) do
        if win.class == class then
            return true
        end
    end
    return false
end

-- 监听窗口激活事件
local function on_active_window_changed()
    local win = hl.get_active_window()
    if is_remote_desktop_window(win) then
        if not blocked then
            hl.dispatch(hl.dsp.submap("remote_desktop_block"))
            blocked = true
        end
    else
        blocked = false
        hl.dispatch(hl.dsp.submap("reset"))
    end
end

hl.on("window.active", on_active_window_changed)
on_active_window_changed()

-- 在所有 submap 下都生效
hl.bind("CTRL + ESCAPE", function()
    local win = hl.get_active_window()
    if is_remote_desktop_window(win) then
        if blocked then
            -- 当前是屏蔽状态 → 退出
            hl.dispatch(hl.dsp.submap("reset"))
            blocked = false
        else
            -- 当前是非屏蔽状态 → 进入
            hl.dispatch(hl.dsp.submap("remote_desktop_block"))
            blocked = true
        end
    end
end, { submap_universal = true })