#!/bin/bash

HISTORY_FILE="$HOME/.cache/cliphist"
MAX_HISTORY=100

# Check if current window is a terminal
active_window=$(hyprctl activewindow -j)
window_class=$(echo "$active_window" | jq -r '.class')

# Common terminal window classes
terminal_classes=("kitty" "alacritty" "wezterm" "foot" "gnome-terminal" "konsole" "xterm" "urxvt" "st" "ghostty")

is_terminal=false
for term in "${terminal_classes[@]}"; do
    if [[ "$window_class" == *"$term"* ]]; then
        is_terminal=true
        break
    fi
done

# Perform copy based on window type
if [[ "$is_terminal" == true ]]; then
    # Terminal window - use Ctrl+Shift+C
    # wtype -M ctrl -M shift -k c
    wltype -P ctrl -P shift -k c -m ctrl -m shift
else
    # Non-terminal window - use Ctrl+C
    wtype -M ctrl -k c >/dev/null 2>&1
fi

# Small delay to allow copy to complete
sleep 0.1

selection=$(wl-paste --primary 2>/dev/null)

if [[ -z "$selection" ]]; then
    # if no selection, try to get from clipboard
    selection=$(wl-paste 2>/dev/null)
fi

if [[ -n "$selection" ]]; then

    echo -n "$selection" | wl-copy

    mkdir -p "$(dirname "$HISTORY_FILE")"

    temp_file=$(mktemp)

    {
        echo "$selection"
        if [[ -f "$HISTORY_FILE" ]]; then
            grep -Fxv "$selection" "$HISTORY_FILE" 2>/dev/null || true
        fi
    } | head -n "$MAX_HISTORY" > "$temp_file"

    mv "$temp_file" "$HISTORY_FILE"

fi
