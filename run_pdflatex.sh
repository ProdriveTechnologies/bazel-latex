#!/bin/sh

set -eu

OUT="$(pwd)/$1"
shift
ENTRY="$1"
shift
FILES="$*"

WRKDIR="$(mktemp -d "${TMPDIR:-/tmp}/bazel.XXXXXXXX")"
trap "rm -rf \"${WRKDIR}\"" EXIT
SRCDIR="${WRKDIR}/src"
LOGFILE="${WRKDIR}/log"

mkdir "${SRCDIR}"
for file in ${FILES}
do
    case "${file}" in
    *.tar)
        tar -C "${SRCDIR}" -xf "${file}"
        ;;
    *)
        cp "${file}" "${SRCDIR}"
        ;;
    esac
done

cd "${SRCDIR}"
for i in 1 2; do
    if ! SOURCE_DATE_EPOCH=0 pdflatex -jobname=bazel_latex_output "${ENTRY}" > "${LOGFILE}" 2>&1; then
        cat "${LOGFILE}"
        exit 1
    fi
done

cp "${SRCDIR}/bazel_latex_output.pdf" "${OUT}"
