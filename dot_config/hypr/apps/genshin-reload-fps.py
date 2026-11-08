#!/usr/bin/env python3
# genshin-reload-fps.py —— 给 MangoHud 发一次 F11（它的 reload 默认键）
#
# 【用途】MangoHud 只在收到 reload 键时重读配置文件。genshin-toggle-fps.sh
#         改完 fps_limit / no_display 后调用本脚本，让改动立刻生效。
#
# 【为什么注入全局按键，而不是 focuswindow 之后再送键】
#         MangoHud 自己轮询 X11 键状态，不需要游戏窗口有焦点；而 focuswindow
#         会把游戏提到最前，反而让 BetterGI 的 overlay 弹出来。
#
# 【调用方】genshin-toggle-fps.sh 最后一行：python genshin-reload-fps.py
#
# 【说明】keysym 0xffc8 = XK_F11，对应 MangoHud 的 reload_config 默认键。
#         press 后保持 1.2 秒再 release，给 MangoHud 轮询留出时间。
#

import ctypes
import time
x = ctypes.CDLL('libX11.so.6')
t = ctypes.CDLL('libXtst.so.6')
x.XOpenDisplay.argtypes = [ctypes.c_char_p]
x.XOpenDisplay.restype = ctypes.c_void_p
x.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
x.XKeysymToKeycode.restype = ctypes.c_ubyte
x.XFlush.argtypes = [ctypes.c_void_p]
x.XCloseDisplay.argtypes = [ctypes.c_void_p]
t.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
d = x.XOpenDisplay(None)
if not d:
    raise SystemExit('Cannot open X display')
keys = [x.XKeysymToKeycode(d, 0xffc8)]
try:
    for key in keys:
        t.XTestFakeKeyEvent(d, key, 1, 0)
    x.XFlush(d)
    time.sleep(1.2)
finally:
    for key in reversed(keys):
        t.XTestFakeKeyEvent(d, key, 0, 0)
    x.XFlush(d)
    x.XCloseDisplay(d)
print('Reloaded Genshin FPS config')
