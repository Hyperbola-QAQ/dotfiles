#!/bin/bash
#
# 【用途】
# 改写 ~/.config/MangoHud/wine-YuanShen.conf 里的 fps_limit（或 no_display），
# 然后让 MangoHud 重读配置。用来把原神压到 1 FPS 挂机，或恢复满帧。
#
# 【用法】
#   （无参数）  在「不限帧 fps_limit=0」和「限帧 fps_limit=1」之间来回切换
#   normal      fps_limit=0，不限帧
#   low         fps_limit=1，限帧
#   hud         翻转 no_display（MangoHud 显隐），结果写回配置再重载
#
# 【调用方】~/.config/hypr/apps/genshin_impact.lua
#   SUPER + F9 / 鼠标侧键(mouse:275)  -> 无参数，切换限帧
#   SHIFT + F12                       -> hud，切换 MangoHud 显隐
#   两个绑定都只在原神窗口聚焦时生效（auto_consuming），其他地方按键会穿透
#
# 【前提】游戏必须在跑：用 hyprctl 找 class=steam_proton 且标题为「原神」的窗口，
#         找不到就直接退出，避免误触改掉配置。
#
# 【依赖】jq、ripgrep(rg)、python（末尾调用 genshin-reload-fps.py）
#

# Serialize switching: a second press must not race the first config reload.
exec 9>"$XDG_RUNTIME_DIR/genshin-toggle-fps.lock"
if ! flock -n 9; then
  exit 0
fi

# Do nothing when the game is not running.
window=$(hyprctl clients -j | jq -r '.[] | select(.class == "steam_proton" and .title == "原神") | .address' | head -n 1)
if [[ -z $window ]]; then
  exit 0
fi

config="$HOME/.config/MangoHud/wine-YuanShen.conf"
current_fps=$(rg '^fps_limit=' "$config" | cut -d= -f2)

case ${1:-toggle} in
  normal)
    fps=0
    ;;
  low)
    fps=1
    ;;
  hud)
    # Flip HUD visibility and write it back, so later reloads keep the choice.
    fps=$current_fps
    if rg -q '^no_display=1$' "$config"; then
      sed -i 's/^no_display=.*/no_display=0/' "$config"
    else
      sed -i 's/^no_display=.*/no_display=1/' "$config"
    fi
    ;;
  *)
    if [[ $current_fps == "1" ]]; then
      fps=0
    else
      fps=1
    fi
    ;;
esac

sed -i "s/^fps_limit=.*/fps_limit=$fps/" "$config"

# The reload key is injected into the global X11 key state; MangoHud polls the
# keymap itself and does not need the game focused. Focusing the game here
# would also raise it, which is what makes BetterGI show its overlay.
python "$HOME/.config/hypr/apps/genshin-reload-fps.py"
