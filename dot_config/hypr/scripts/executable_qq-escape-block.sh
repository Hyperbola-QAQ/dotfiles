#!/usr/bin/env bash

QQ_CLASS="QQ"
QQ_TITLE="QQ"

socat UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" STDOUT | while read -r line; do
    if [[ "$line" == activewindow* ]]; then
        active_class=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class')
        active_title=$(hyprctl activewindow -j 2>/dev/null | jq -r '.title')
        if [[ "$active_class" == "$QQ_CLASS" && "$active_title" == "$QQ_TITLE" ]]; then
            # class 和 title 都匹配 → 拦截 Escape
            hyprctl keyword bind ,Escape,exec,true 2>/dev/null
        else
            # 不匹配 → 移除拦截
            hyprctl keyword unbind ,Escape 2>/dev/null
        fi
    fi
done
