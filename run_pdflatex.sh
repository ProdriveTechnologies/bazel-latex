#!/bin/sh

set -eu

NAME="$1"
shift
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
    if ! SOURCE_DATE_EPOCH=0 pdflatex -jobname="${NAME}" "${ENTRY}" > "${LOGFILE}" 2>&1; then
        cat "${LOGFILE}"
        exit 1
    fi
done

cp "${SRCDIR}/${NAME}.pdf" "${OUT}"
