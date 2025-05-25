#!/usr/bin/env bash

# Configuration: map window classes to keyboard layouts
declare -A WINDOW_LAYOUTS=(
    ["firefox"]="fi"
    ["discord"]="fi"
)

# Default layout for everything else
DEFAULT_LAYOUT="us"

echo "Window layout switcher starting..." >&2
echo "Socket path: $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" >&2

get_active_window_class() {
    hyprctl activewindow -j | jq -r '.class // empty'
}

set_keyboard_layout() {
    local layout="$1"
    echo "Setting keyboard layout to: $layout" >&2
    
    # Get the main keyboard device
    local keyboard_device
    keyboard_device=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .name')
    
    if [[ -n "$keyboard_device" ]]; then
        echo "Using keyboard device: $keyboard_device" >&2
        # Convert layout name to number (us=0, fi=1)
        local layout_num
        case "$layout" in
            "us") layout_num="0" ;;
            "fi") layout_num="1" ;;
            *) layout_num="0" ;;
        esac
        echo "Setting layout number: $layout_num" >&2
        hyprctl switchxkblayout "$keyboard_device" "$layout_num"
    else
        echo "No main keyboard device found" >&2
    fi
}

handle_window_change() {
    local window_class
    window_class=$(get_active_window_class)
    
    echo "Active window class: '$window_class'" >&2
    
    if [[ -n "$window_class" ]]; then
        local target_layout="${WINDOW_LAYOUTS[$window_class]:-$DEFAULT_LAYOUT}"
        echo "Target layout: $target_layout" >&2
        set_keyboard_layout "$target_layout"
    else
        echo "No window class found, using default layout: $DEFAULT_LAYOUT" >&2
        set_keyboard_layout "$DEFAULT_LAYOUT"
    fi
}

# Listen to Hyprland events
echo "Starting to listen for Hyprland events..." >&2
socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    echo "Event received: $line" >&2
    case "$line" in
        activewindow*)
            echo "Active window changed, handling..." >&2
            handle_window_change
            ;;
    esac
done