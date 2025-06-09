#!/bin/bash

HISTORY_FILE="$HOME/.cache/cliphist"

touch "$HISTORY_FILE"

if [[ ! -s "$HISTORY_FILE" ]]; then
    echo "No clipboard history found"
    exit 1
fi

selected=$(cat "$HISTORY_FILE" | wofi --dmenu --conf ~/.config/wofi/clipboard-config)

if [[ -n "$selected" ]]; then
    echo -n "$selected" | wl-copy

    window_info=$(hyprctl activewindow 2>/dev/null)
    window_class=$(echo "$window_info" | grep "class:" | cut -d' ' -f2-)

    sleep 0.1

    if echo "$window_class" | grep -qi -E "(ghostty|kitty|alacritty|foot|wezterm|gnome-terminal|konsole|xterm|urxvt|termite|terminal)"; then
        wtype -M ctrl -M shift v
    else
        wtype -M ctrl v
    fi
fi
