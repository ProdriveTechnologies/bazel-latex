#!/bin/sh
filename="$(find . -name '*.pdf')"
if type xdg-open > /dev/null 2>&1; then
    # X11-based systems (Linux, BSD).
    exec xdg-open "${filename}" &
elif type open > /dev/null 2>&1; then
    # macOS.
    exec open "${filename}"
else
    echo "Don't know how to view PDFs on this platform." >&2
    exit 1
fi
