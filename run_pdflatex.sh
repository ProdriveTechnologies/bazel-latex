#!/bin/sh

set -eu

NAME="$1"
shift
OUT="$(pwd)/$1"
shift
FILES="$*"

WRKDIR="$(mktemp -d "${TMPDIR:-/tmp}/bazel.XXXXXXXX")"
trap "rm -rf \"${WRKDIR}\"" EXIT
SRCDIR="${WRKDIR}/src"
LOGFILE="${WRKDIR}/log"

# Copy all files that we're permitted to use into a temporary directory.
mkdir "${SRCDIR}"
for file in ${FILES}
do
    dir="$(dirname "${file}" | sed 's|^bazel-out/[^/]*/genfiles/||')"
    mkdir -p "${SRCDIR}/${dir}"
    cp "${file}" "${SRCDIR}/${dir}"
done

# Make all sources in external repositories directly includable.
cd "${SRCDIR}"
export TEXINPUTS=
for external in external/*; do
  TEXINPUTS="${TEXINPUTS}${external}:"
done

# Generate PDF.
ENTRY="$(grep -rl '^\\documentclass\>' .)"
PDFLATEX_OUT="${SRCDIR}/${NAME}.pdf"
for i in 1 2 3 4 5 6 7 8 9 10; do
    if ! SOURCE_DATE_EPOCH=0 pdflatex -file-line-error -jobname="${NAME}" "${ENTRY}" > "${LOGFILE}" 2>&1; then
        cat "${LOGFILE}"
        exit 1
    fi

    # Only terminate successfully if we have two pdflatex runs that yield the same document.
    if test -f "${PDFLATEX_OUT}.previous" && cmp -s "${PDFLATEX_OUT}" "${PDFLATEX_OUT}.previous"; then
        cp "${PDFLATEX_OUT}" "${OUT}"
        exit 0
    fi
    cp "${PDFLATEX_OUT}" "${PDFLATEX_OUT}.previous"
done

echo "Number of pdflatex runs insufficient to obtain definitive output"
exit 1
