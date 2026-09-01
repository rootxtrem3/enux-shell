#!/bin/bash

# Toggle a scratchpad terminal: open if not running, else hide/restore it
if hyprctl clients -j | jq -e 'any(.[]; .workspace.name == "special:scratchpad")' > /dev/null; then
    hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")'
else
    setsid kitty --class scratchpad >/dev/null 2>&1 &
fi
