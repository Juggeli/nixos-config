#!/usr/bin/python

# This script requires i3ipc-python package (install it from a system package manager
# or pip).
# It makes inactive windows transparent. Use `transparency_val` variable to control
# transparency strength in range of 0…1 or use the command line argument -o.

import argparse
import i3ipc
import signal
import sys
from functools import partial

focused = "1.00"
unfocused = "0.80"

def get_active_kb():
    active_kb = "English (US)"
    for input in ipc.get_inputs():
        if input.type == "keyboard":
            active_kb = input.xkb_active_layout_name
    return active_kb


def on_window_focus(ipc, event):
    print("On window focus")
    global prev_focused
    global prev_workspace

    focused_workspace = ipc.get_tree().find_focused()

    if focused_workspace == None:
        return

    focused = event.container
    workspace = focused_workspace.workspace().num

    if focused.id != prev_focused.id:  # https://github.com/swaywm/sway/issues/2859
        focused.command("opacity 1")
        if workspace == prev_workspace:
            prev_focused.command("opacity " + unfocused)
        prev_focused = focused
        prev_workspace = workspace

    print(get_active_kb())
    if "WebCord" in focused.name:
        print("Got webcord")
        if get_active_kb() == "English (US)":
            ipc.command("input '1:1:AT_Translated_Set_2_keyboard' xkb_switch_layout next")
    else:
        if get_active_kb() == "Finnish":
            ipc.command("input '1:1:AT_Translated_Set_2_keyboard' xkb_switch_layout next")


def remove_opacity(ipc):
    for workspace in ipc.get_tree().workspaces():
        for w in workspace:
            w.command("opacity " + focused)
    ipc.main_quit()
    sys.exit(0)

if __name__ == "__main__":
    global ipc

    ipc = i3ipc.Connection()
    prev_focused = None
    prev_workspace = ipc.get_tree().find_focused().workspace().num

    for window in ipc.get_tree():
        if window.focused:
            prev_focused = window
        else:
            window.command("opacity " + unfocused)
    for sig in [signal.SIGINT, signal.SIGTERM]:
        signal.signal(sig, lambda signal, frame: remove_opacity(ipc))
    ipc.on("window::focus", partial(on_window_focus))
    ipc.main()

