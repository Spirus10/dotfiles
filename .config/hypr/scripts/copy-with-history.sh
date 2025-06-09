#!/bin/bash

HISTORY_FILE="$HOME/.cache/cliphist"
MAX_HISTORY=100

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
