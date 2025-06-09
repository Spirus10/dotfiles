# Get the current window class to determine paste method
active_window=$(hyprctl activewindow -j 2>/dev/null)
window_class=$(echo "$active_window" | jq -r '.class // empty' 2>/dev/null)

# Common terminal classes - adjust based on your terminal
terminal_classes=("ghostty" "kitty" "alacritty" "foot" "wezterm" "gnome-terminal" "konsole" "xterm" "urxvt" "termite")

sleep 0.1

# Check if current window is a terminal
is_terminal=false
for term_class in "${terminal_classes[@]}"; do
    if [[ "$window_class" == *"$term_class"* ]]; then
        is_terminal=true
        break
    fi
done

# Use appropriate paste command
if [[ "$is_terminal" == true ]]; then
    wtype -M ctrl -M shift v  # Ctrl+Shift+V for terminals
else
    wtype -M ctrl v           # Ctrl+V for other applications
fi
