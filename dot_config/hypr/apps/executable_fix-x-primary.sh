#!/bin/bash
#
# 【用途】把 XWayland 的 primary output 重新指回主屏 HDMI-A-1。否则 Wine/Proton
#         判定不出主屏，会把游戏绑到 1920x1080 的副屏上。
# 【调用方】~/.config/hypr/monitors.lua
#   - monitor.added / monitor.removed / monitor.layout_changed（采集盒热插拔）
#   - window.open（游戏启动兜底，走下面的快路径，正常状态无可感知开销）
# 【手动执行】bash ~/.config/hypr/apps/fix-x-primary.sh
# 【日志】~/.local/state/fix-x-primary.log（只在修复失败等异常分支写入）
#
# ---------- 根因 ----------
# 主屏 HDMI-A-1 走 A/Vaux GC553G2 采集盒的直通输出。采集盒每次重新协商 HDMI
# （切换信号源、模式变化、上电）都会让 Hyprland 收到一次热插拔；xwayland 重建输出后，
# X 服务器的 primary output 会指向已被销毁的输出 —— 此时 `xrandr` 里没有任何输出带
# primary 标记，Wine/Proton 的 get_primary_rect 报
#   "Primary is set to a disconnected XRandR output"
# 于是游戏只能退回“第一个枚举到的显示器”，可能绑到 1920x1080 的副屏上。
#
# 触发点：hypr/monitors.lua 里的 monitor.added / removed / layout_changed，以及
# window.open（游戏启动兜底）。所以本脚本必须先快、后等，不能在正常状态下有延迟。

set -u

export DISPLAY="${DISPLAY:-:0}"

# 快路径：primary 已经正确，直接走人（window.open 会频繁调用）。
xrandr --query 2>/dev/null | grep -q '^HDMI-A-1 connected primary' && exit 0

log="${XDG_STATE_HOME:-$HOME/.local/state}/fix-x-primary.log"
mkdir -p "$(dirname "$log")" 2>/dev/null

# 热插拔风暴时会连发多次，只让第一个实例干活。
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/fix-x-primary.lock" || exit 0
flock -n 9 || exit 0

# 已经在等的那次可能刚修好，再确认一遍。
xrandr --query 2>/dev/null | grep -q '^HDMI-A-1 connected primary' && exit 0

# xwayland 建输出是异步的，这里最多等 8 秒。
for _ in $(seq 1 20); do
  sleep 0.4

  xrandr --query 2>/dev/null | grep -q '^HDMI-A-1 connected' || continue

  if xrandr --output HDMI-A-1 --primary 2>>"$log"; then
    printf '%s primary 已恢复\n' "$(date '+%F %T')" >>"$log"
    exit 0
  fi
done

printf '%s 放弃：HDMI-A-1 迟迟不可用\n' "$(date '+%F %T')" >>"$log"
