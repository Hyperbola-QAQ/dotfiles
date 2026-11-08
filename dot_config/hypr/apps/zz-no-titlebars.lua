-- 彻底关闭 hyprbars 标题栏。
--
-- 【功能】
-- 把 hyprbars 插件的 enabled 固定为 false，桌面模式（浮动工作区）下窗口不再有标题栏。
--
-- 【为什么文件名要带 zz- 前缀】
-- omarchy 用 require_all.files() 加载 apps/ 目录，实现是
--   find <dir> -maxdepth 1 -type f -name '*.lua' -printf '%f\n' | sort
-- 即按文件名字典序加载。实际顺序：
--   genshin_impact -> open_orpheus -> qq_wechat -> remote_desktop
--   -> steam -> wemeet -> zz-no-titlebars   <- 本文件最后执行
-- 而 omarchy 的 workspace-modes.lua 会在切到浮动工作区时 lazy-load hyprbars
-- 并把 enabled 打开。要压住它，必须有一个在所有其他 app 文件之后执行的文件
-- 再覆盖一次 —— zz- 就是用来垫底的，换名字就会失效。
--
-- 【为什么放在 apps/ 而不是 looknfeel.lua】
-- 插件是运行时 lazy-load 的，加载发生在切浮动工作区那一刻；在它被启用之前
-- 写配置没有意义，必须等它加载后在本目录末尾再压一次。
--
-- 【插件加载后会触发一次配置重载】本文件会跟着再跑一遍，
-- 所以运行时反复切换浮动工作区，标题栏也不会回来。

if hl.plugin.hyprbars then
  hl.config({
    plugin = {
      hyprbars = {
        enabled = false,
      },
    },
  })
end
