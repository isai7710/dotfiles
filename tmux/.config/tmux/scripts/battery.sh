#!/usr/bin/env bash
# Native macOS battery indicator for tmux — no plugins, just `pmset`.
# Prints a Nerd Font glyph + charge %, e.g.  " 87%".  Requires a Nerd Font.

batt="$(pmset -g batt)"
percent="$(printf '%s' "$batt" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
[ -z "$percent" ] && exit 0                 # no battery (desktop) → print nothing

if printf '%s' "$batt" | grep -q 'AC Power'; then
    icon="$(printf '\357\203\247')"         #  U+F0E7  charging / plugged in
elif [ "$percent" -ge 88 ]; then
    icon="$(printf '\357\211\200')"         #  U+F240  full
elif [ "$percent" -ge 63 ]; then
    icon="$(printf '\357\211\201')"         #  U+F241  three-quarters
elif [ "$percent" -ge 38 ]; then
    icon="$(printf '\357\211\202')"         #  U+F242  half
elif [ "$percent" -ge 13 ]; then
    icon="$(printf '\357\211\203')"         #  U+F243  quarter
else
    icon="$(printf '\357\211\204')"         #  U+F244  empty
fi

printf '%s %s%%' "$icon" "$percent"
