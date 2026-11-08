-- ============================================
-- 社交应用：QQ & 微信 → 社交工作区（11）
-- 浮动（堆叠式）工作区：主窗口铺满屏幕叠着放，Alt+Tab 轮换；
-- 弹窗跟着鼠标冒出来，并且正常拿焦点。
--
-- 关于"铺满"的坐标：Hyprland 里窗口的 at/size 是**逻辑像素**，
-- 而 monitor.width/height 是**物理像素**，两者差一个 scale。
-- 所以凡是算显示器区域，都必须 width / scale，否则在缩放屏上会算出两倍大。
-- ============================================

-- 这个工作区用浮动（堆叠式）布局：窗口互相重叠、可自由摆放。
-- 想换成别的：SUPER+L 在该工作区循环，或改下面的 mode（floating / dwindle / scrolling）。
o.workspace_mode({ workspace = "11", mode = "floating" })

local SOCIAL_WORKSPACE = "11"

-- 窗口 class → 主窗口标题（主窗口和弹窗靠这个区分）
local MAIN_TITLES = {
    QQ = "^QQ$",
    wechat = "^微信$",
}

local PLACE_LOG = "/home/hyperbola/.local/share/agents/WorkBuddy/2026-11-07-13-00-51/.tmp/qqplace.txt"

local function log_place(tag, win, extra)
    local f = io.open(PLACE_LOG, "a")
    if not f then return end
    f:write(tag, " class=", tostring(win and win.class), " title=", tostring(win and win.title),
        extra or "", "\n")
    f:close()
end

-- ============================================
-- 显示器可用区域（逻辑像素）
-- ============================================

local function monitor_area(mon)
    if not mon then return nil end
    local ok, area = pcall(function()
        local scale = mon.scale or 1
        if scale <= 0 then scale = 1 end
        local w, h = mon.width or 0, mon.height or 0
        if (mon.transform or 0) % 2 == 1 then
            w, h = h, w
        end
        local r = mon.reserved or {}
        local l, t = r.left or 0, r.top or 0
        local rr, b = r.right or 0, r.bottom or 0
        local pos = mon.position or {}
        local lw = math.floor(w / scale - l - rr)
        local lh = math.floor(h / scale - t - b)
        if lw < 100 or lh < 100 then return nil end
        return {
            x = math.floor((pos.x or 0) + l),
            y = math.floor((pos.y or 0) + t),
            w = lw,
            h = lh,
        }
    end)
    if ok then return area end
    return nil
end

-- 窗口 → 可用区域。优先用它现在所在的显示器；副屏没了、工作区被搬走时，
-- 依次退到社交工作区的显示器、光标所在显示器，保证总能算出个能落地的区域。
local function area_for(win)
    if win then
        local ok, mon = pcall(function() return win.monitor end)
        if ok then
            local a = monitor_area(mon)
            if a then return a end
        end
    end

    local okws, ws = pcall(hl.get_workspace, tonumber(SOCIAL_WORKSPACE))
    if okws and ws then
        local okm, mon = pcall(function() return ws.monitor end)
        if okm then
            local a = monitor_area(mon)
            if a then return a end
        end
    end

    local okp, p = pcall(hl.get_cursor_pos)
    if okp and p then
        local okmon, mon = pcall(hl.get_monitor_at, p.x, p.y)
        if okmon then
            local a = monitor_area(mon)
            if a then return a end
        end
    end

    local okw, ws2 = pcall(hl.get_active_workspace)
    if okw and ws2 then
        local okm, mon = pcall(function() return ws2.monitor end)
        if okm then
            local a = monitor_area(mon)
            if a then return a end
        end
    end

    return nil
end

-- ============================================
-- 开窗规则
-- ============================================

-- 让 Omarchy 的浮动工作区开窗规则放过 QQ/微信。
--
-- default/hypr/workspace-modes.lua 会给浮动工作区的新窗口套一条 open 规则
-- （size = min(1100, .64w) x min(760, .68h)，move = 居中 + 级联偏移），
-- 并且在 window.open 里还会 arrange()/place() 再摆一次。
-- 用 o.window 声明 float 规则会把 class 记进 o.floating_apps，
-- workspace-modes 重新生成规则时会自动把它们排除掉。
for class in pairs(MAIN_TITLES) do
    o.window("^(" .. class .. ")$", { float = true, workspace = SOCIAL_WORKSPACE })
end

-- 主窗口规则里**不要**写 size/move：
-- 实测这条路上的 move 是"相对偏移"语义（窗口先被居中到 x=1728，再加一次 1536
-- 变成 3264，直接飞出副屏右边界），定位一律交给下面的 dispatcher。
for class, title in pairs(MAIN_TITLES) do
    hl.window_rule({
        match = { class = "^(" .. class .. ")$", title = title },
        workspace = SOCIAL_WORKSPACE,
        float = true,
        no_initial_focus = true,
        suppress_event = "activate",
    })
end

-- ============================================
-- 摆位
-- ============================================

local function target_of(win)
    return "address:" .. win.address
end

-- 按窗口尺寸/位置取当前值；取不到就给默认值，别让一次异常打断整个流程。
local function geometry_of(win)
    local okx, w = pcall(function() return win.size.x end)
    local oky, h = pcall(function() return win.size.y end)
    local okax, x = pcall(function() return win.at.x end)
    local okay, y = pcall(function() return win.at.y end)
    return (okx and w) or 0, (oky and h) or 0, (okax and x) or 0, (okay and y) or 0
end

-- 窗口比区域大时先缩，再挪。resize 会以中心为锚把窗口带走，
-- 所以顺序必须是 resize → move。
local function fit_into(addr, a, w, h, x, y)
    if not a then return end
    local nw = (w > a.w) and a.w or w
    local nh = (h > a.h) and a.h or h
    if nw ~= w or nh ~= h then
        pcall(function()
            hl.dispatch(hl.dsp.window.resize({ x = nw, y = nh, relative = false, window = addr }))
        end)
    end
    local nx = math.max(a.x, math.min(x, a.x + a.w - nw))
    local ny = math.max(a.y, math.min(y, a.y + a.h - nh))
    if nx ~= x or ny ~= y then
        pcall(function()
            hl.dispatch(hl.dsp.window.move({ x = nx, y = ny, window = addr }))
        end)
    end
end

-- 显示器布局指纹：所有显示器的名字/位置/逻辑尺寸拼成一个字符串。
-- 只要它变了（插拔屏、改分辨率、改缩放、改排列），就说明窗口该按新区域重铺。
-- 用指纹而不是"记住窗口上次多大多小"，是因为屏幕一变 Hyprland 会自己搬窗口、
-- 改尺寸，窗口自己的几何完全不可信。
local last_sig = nil

local function layout_sig()
    local ok, mons = pcall(hl.get_monitors)
    if not ok or type(mons) ~= "table" then return nil end
    local parts = {}
    for _, m in ipairs(mons) do
        local a = monitor_area(m)
        if a then
            parts[#parts + 1] = tostring(m.name) .. "@" .. a.x .. "," .. a.y
                .. ":" .. a.w .. "x" .. a.h
        else
            parts[#parts + 1] = tostring(m.name) .. "@off"
        end
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

-- 按地址找回窗口对象（定时器里用，避免拿旧对象）
local function find_window(addr)
    local ok, wins = pcall(hl.get_windows)
    if not ok or type(wins) ~= "table" then return nil end
    for _, w in ipairs(wins) do
        if w.address == addr then return w end
    end
    return nil
end

-- 铺完隔一小会儿回读真实几何：
--   · 没铺满 → 可能是应用临时上报了最大尺寸（微信刚映射到新屏时就会这样，
--     手动拖一下或过一会儿就好了），所以重试几次，别一次失败就认输；
--   · 重试完还是铺不满 → 居中放着，别歪在左上角。
-- 注意：这里的 addr 必须是裸地址（0x...），带 "address:" 前缀的只能给 dispatch 用。
local attempts = {}
local MAX_RETRY = 3

-- 前向声明：verify_fill 里要回调 fill_main
local fill_main

local function verify_fill(addr, a, tag)
    local tgt = "address:" .. addr
    hl.timer(function()
        local ok, err = pcall(function()
            local w = find_window(addr)
            if not w then return end
            local cw, ch, cx, cy = geometry_of(w)
            if cw <= 0 or ch <= 0 then return end
            if cw >= a.w - 2 and ch >= a.h - 2 then
                attempts[addr] = 0
                return
            end

            local n = attempts[addr] or 0
            if n < MAX_RETRY then
                attempts[addr] = n + 1
                log_place(tag .. "+short" .. n, w, " " .. tostring(cw) .. "x" .. tostring(ch)
                    .. " 未达 " .. tostring(a.w) .. "x" .. tostring(a.h) .. "，稍后重试")
                hl.timer(function()
                    local w2 = find_window(addr)
                    if w2 then
                        fill_main(w2, tag .. "+retry" .. (n + 1), a)
                    end
                end, { timeout = 900, type = "oneshot" })
                return
            end

            attempts[addr] = 0
            local nx = a.x + math.floor((a.w - cw) / 2)
            local ny = a.y + math.floor((a.h - ch) / 2)
            if cx ~= nx or cy ~= ny then
                pcall(function()
                    hl.dispatch(hl.dsp.window.move({ x = nx, y = ny, window = tgt }))
                end)
            end
            log_place(tag .. "+clamped", w, " 只有 " .. tostring(cw) .. "x" .. tostring(ch)
                .. "（目标 " .. tostring(a.w) .. "x" .. tostring(a.h) .. "）-> 居中 "
                .. tostring(nx) .. "," .. tostring(ny))
        end)
        if not ok then
            log_place(tag .. "+verify-err", nil, " " .. tostring(err))
        end
    end, { timeout = 450, type = "oneshot" })
end

-- 主窗口铺满它所在显示器的可用区域。
function fill_main(win, tag, area_override)
    if not win or not win.address then return end
    local a = area_override or area_for(win)
    if not a then
        log_place(tag, win, " [no area]")
        return
    end
    local addr = target_of(win)
    -- 已经正好铺在那儿了就别再 dispatch 一次，免得白闪一下。
    local cw, ch, cx, cy = geometry_of(win)
    if cw == a.w and ch == a.h and cx == a.x and cy == a.y then
        return
    end
    pcall(function()
        hl.dispatch(hl.dsp.window.float({ action = "on", window = addr }))
    end)
    pcall(function()
        hl.dispatch(hl.dsp.window.resize({ x = a.w, y = a.h, relative = false, window = addr }))
    end)
    pcall(function()
        hl.dispatch(hl.dsp.window.move({ x = a.x, y = a.y, window = addr }))
    end)
    verify_fill(win.address, a, tag)
    log_place(tag, win, string.format(" area=%d,%d %dx%d", a.x, a.y, a.w, a.h))
end

-- 安全网：只处理"跑出屏幕"的窗口——比屏幕大就缩到屏幕大小，越界就拽回范围内。
-- 完全在范围内的小窗口一律不动，免得跟用户自己调整的窗口打架。
--
-- 另外要连续两次看到**同一个**越界坐标才动手：Hyprland 的移动/缩放有动画，
-- 动画中间帧的坐标也在界外，逐帧纠正会和动画互相拉扯，窗口会抖。
local drift = {}

local function ensure_inside(win, tag, force)
    if not win or not win.address then return false end
    -- 全屏/最大化全屏的窗口尺寸由 Hyprland 自己管，别去拽它，否则会和全屏状态互拉。
    local okfs, fs = pcall(function() return win.fullscreen end)
    if okfs and fs and fs ~= 0 then return false end
    local a = area_for(win)
    if not a then return false end
    local w, h, x, y = geometry_of(win)
    if w <= 0 or h <= 0 then return false end
    local out = (x < a.x) or (y < a.y)
        or (x + w > a.x + a.w) or (y + h > a.y + a.h)
        or (w > a.w) or (h > a.h)
    if not out then
        drift[win.address] = nil
        return false
    end

    local key = string.format("%d,%d,%d,%d", x, y, w, h)
    local rec = drift[win.address]
    if rec and rec.key == key then
        rec.hits = rec.hits + 1
    else
        rec = { key = key, hits = 1 }
        drift[win.address] = rec
    end
    if not force and rec.hits < 2 then
        return false
    end
    drift[win.address] = nil

    fit_into(target_of(win), a, w, h, x, y)
    log_place(tag, win, string.format(" %dx%d @%d,%d -> %dx%d @%d,%d",
        w, h, x, y, math.min(w, a.w), math.min(h, a.h),
        math.max(a.x, math.min(x, a.x + a.w - math.min(w, a.w))),
        math.max(a.y, math.min(y, a.y + a.h - math.min(h, a.h)))))
    return true
end

-- 社交主窗口必须待在社交工作区。副屏掉线时 Hyprland 会把 11 号工作区的窗口
-- 搬到别的号上，这里把它们拉回来；如果窗口正显示在眼前，就让视图跟着走，
-- 否则（在别的工作区上）静默搬，不打断当前操作。
local function on_social_workspace(win)
    local ws = win and win.workspace
    if not ws then return false end
    local target = tonumber(SOCIAL_WORKSPACE)
    if ws.name and tonumber(tostring(ws.name)) == target then return true end
    if ws.id and tonumber(ws.id) == target then return true end
    return false
end

local function ensure_on_social(win, tag)
    if not win or not win.address or on_social_workspace(win) then return end
    local wsid = win.workspace and win.workspace.id
    local ok, cur = pcall(hl.get_active_workspace)
    local follow = (ok and cur and wsid ~= nil and cur.id == wsid) or false
    pcall(function()
        hl.dispatch(hl.dsp.window.move({
            workspace = SOCIAL_WORKSPACE,
            follow = follow,
            window = target_of(win),
        }))
    end)
    log_place(tag, win, string.format(" ws %s -> %s follow=%s",
        tostring(win.workspace and win.workspace.name), SOCIAL_WORKSPACE, tostring(follow)))
end

local function is_main_window(win)
    return win and win.class and win.title
        and MAIN_TITLES[win.class] ~= nil
        and win.title:match(MAIN_TITLES[win.class]) ~= nil
end

-- 主窗口刚铺好可能又被 workspace-modes 的 place() 或应用自己改一次，
-- 所以隔一段补两刀（timeout 单位是毫秒）。
local function fill_main_later(win, tag)
    if not win or not win.address then return end
    local addr = win.address
    for _, delay in ipairs({ 250, 1200 }) do
        hl.timer(function()
            local w = find_window(addr)
            if w then
                ensure_inside(w, tag .. "+" .. delay .. "ms", true)
                if is_main_window(w) then fill_main(w, tag .. "+" .. delay .. "ms") end
            end
        end, { timeout = delay, type = "oneshot" })
    end
end

-- ============================================
-- 弹窗：跟随光标
-- ============================================

local opened_social = {}
local social_seen = {}

local function is_social_popup(win)
    if not win or not win.class or not MAIN_TITLES[win.class] then
        return false
    end
    local t = win.title or ""
    return t:match(MAIN_TITLES[win.class]) == nil
end

local function place_popup(win, tag)
    local okp, p = pcall(hl.get_cursor_pos)
    if not okp or not p then
        return
    end
    -- 先确保是浮动窗口：平铺窗口 move 是空操作。
    hl.dispatch(hl.dsp.window.float({ action = "on", window = target_of(win) }))
    local w, h = geometry_of(win)
    local x = math.floor(p.x) - 30
    local y = math.floor(p.y) - 30
    local a = area_for(win)
    fit_into(target_of(win), a, w, h, x, y)
    log_place(tag, win, string.format(" size=%dx%d cursor=%d,%d", w, h,
        math.floor(p.x), math.floor(p.y)))
end

hl.on("window.open", function(win)
    if not win or not win.class or not MAIN_TITLES[win.class] or not win.address then
        return
    end
    social_seen[win.address] = true
    local t = win.title or ""
    local main_at_open = t:match(MAIN_TITLES[win.class]) ~= nil
    opened_social[win.address] = { at = os.time(), main = main_at_open }
    if main_at_open then
        fill_main(win, "open")
        fill_main_later(win, "open")
        return
    end
    place_popup(win, "open")
end)

-- 微信的登录窗口和主窗口是同一个 class，标题也可能一直是「微信」；
-- 登录完成后窗口会重新 map 一次，这时标题/尺寸才变。补一次，保证铺满。
hl.on("window.title", function(win)
    if not win or not win.address or not win.class or not MAIN_TITLES[win.class] then
        return
    end
    local rec = opened_social[win.address]
    local is_main = not is_social_popup(win)

    if is_main then
        if rec and rec.main then
            return
        end
        if rec then rec.main = true end
        fill_main(win, "title-main")
        fill_main_later(win, "title-main")
        return
    end

    if not rec then
        return
    end
    if os.time() - rec.at > 5 then
        opened_social[win.address] = nil
        return
    end
    if rec.main then
        return
    end
    place_popup(win, "title")
end)

-- 社交工作区现在落在哪块屏上。窗口刚被搬回 11 号时，win.monitor 还是旧值，
-- 所以"重铺"要用工作区的显示器算区域，不能信窗口自己的。
local function social_area()
    local ok, ws = pcall(hl.get_workspace, tonumber(SOCIAL_WORKSPACE))
    if not ok or not ws then return nil end
    local okm, mon = pcall(function() return ws.monitor end)
    if not okm then return nil end
    return monitor_area(mon)
end

-- 显示器增删 / 布局变化（比如副屏掉了）：窗口会被 Hyprland 搬到别的工作区，
-- 还会被缩成奇怪的尺寸。等它搬完，先把窗口收回 11 号工作区，再统一按新区域铺满。
local function rescue_all(tag)
    local ok, wins = pcall(hl.get_windows)
    if not ok or type(wins) ~= "table" then return end
    for _, w in ipairs(wins) do
        if is_main_window(w) then
            ensure_on_social(w, tag)
            local a = social_area() or area_for(w)
            if a then
                fill_main(w, tag, a)
            else
                ensure_inside(w, tag, true)
            end
        end
    end
end

local function rescue_later(tag)
    for _, delay in ipairs({ 400, 1500 }) do
        hl.timer(function()
            rescue_all(tag .. "+" .. delay .. "ms")
        end, { timeout = delay, type = "oneshot" })
    end
end

for _, ev in ipairs({ "monitor.added", "monitor.removed", "monitor.layout_changed" }) do
    local ok = pcall(function()
        hl.on(ev, function()
            last_sig = layout_sig()
            rescue_later(ev)
        end)
    end)
    if not ok then
        log_place(ev, nil, " [hook failed]")
    end
end

-- 加载/重载配置时铺满一次：这个文件的意义就是"社交主窗口始终铺满"。
last_sig = layout_sig()
rescue_later("load")

-- 常驻看门狗（每秒一次）：
--   ① 显示器布局指纹变了（插拔屏 / 改分辨率 / 改缩放 / 改排列）→ 全部按新区域重铺。
--      指纹是兜底：万一 monitor.* 事件没送到，这里也会在 1 秒内纠正。
--   ② 窗口越界 / 比屏幕还大 → 拽回可视区（连续两次同一坐标才动，避开动画中间帧）。
--   正常大小、位置也对的小窗口不会被碰，所以不会跟用户手动调整打架。
hl.timer(function()
    local sig = layout_sig()
    if sig and sig ~= last_sig then
        last_sig = sig
        log_place("layout-changed", nil, " " .. sig)
        rescue_all("layout")
    end

    local ok, wins = pcall(hl.get_windows)
    if not ok or type(wins) ~= "table" then return end
    for _, w in ipairs(wins) do
        if is_main_window(w) then
            ensure_inside(w, "guard")
        end
    end
end, { timeout = 1000, type = "repeat" })

-- ============================================
-- 主窗口 Escape 键拦截（键 = class，值 = 主窗口标题；子窗口不拦）
-- ============================================
local escape_blocked = {
    QQ = "QQ",
    wechat = "微信",
}

local esc_blocked = false

local function on_active_window_changed()
    local win = hl.get_active_window()
    local block = win ~= nil and escape_blocked[win.class] == win.title
    -- 只在状态翻转时才动绑定。Hyprland 不会去重，切来切去会堆出几十条同样的绑定。
    if block == esc_blocked then
        return
    end
    esc_blocked = block
    if block then
        hl.bind("Escape", hl.dsp.no_op(), { replace = true })
    else
        hl.unbind("Escape")
    end
end
hl.on("window.active", on_active_window_changed)
on_active_window_changed()

-- ============================================
-- 微信：非主窗口去装饰（朋友圈、设置、聊天文件、预览、图片和视频）
-- ============================================
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
