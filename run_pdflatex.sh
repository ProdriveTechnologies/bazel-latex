#!/bin/sh

set -eu

OUT="$(pwd)/$1"
shift
ENTRY="$1"
shift
FILES="$*"

WRKDIR="$(mktemp -d ${TMPDIR:-/tmp}/bazel.XXXXXXXX)"
trap "rm -rf \"${WRKDIR}\"" EXIT
SRCDIR="${WRKDIR}/src"
LOGFILE="${WRKDIR}/log"

mkdir "${SRCDIR}"
for file in ${FILES}
do
    case $file in
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
    if ! pdflatex '\pdfinfoomitdate=1\pdftrailerid{}\pdfsuppressptexinfo=-1\input{'"${ENTRY}"'}' > "${LOGFILE}" 2>&1; then
        cat "${LOGFILE}"
        exit 1
    fi
done

cp "${SRCDIR}/$(basename "${ENTRY}" .tex).pdf" "${OUT}"
