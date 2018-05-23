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
    dir="$(dirname "${file}")"
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
for i in 1 2; do
    if ! SOURCE_DATE_EPOCH=0 pdflatex -jobname="${NAME}" "${ENTRY}" > "${LOGFILE}" 2>&1; then
        cat "${LOGFILE}"
        exit 1
    fi
done

cp "${SRCDIR}/${NAME}.pdf" "${OUT}"
