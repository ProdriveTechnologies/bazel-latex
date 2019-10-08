#!/bin/sh
filename="$(find . -name '*.pdf')"


if type xdg-open > /dev/null 2>&1; then
    # X11-based systems (Linux, BSD).
    if [ $1 == "None" ]; then   
        exec xdg-open "${filename}" 2>/dev/null &
    else
        exec xdg-open "${filename}" &
    fi

elif type open > /dev/null 2>&1; then
    # macOS.
    exec open "${filename}"
else
    echo "Don't know how to view PDFs on this platform." >&2
    exit 1
fi
