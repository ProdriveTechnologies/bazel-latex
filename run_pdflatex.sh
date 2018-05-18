#!/bin/sh

set -eu

ROOT=`pwd`

OUT="${ROOT}/$1"
shift
ENTRY="$1"
shift
FILES="$*"

TMP_DIR=${TMPDIR:-/tmp}
WRKDIR="$(mktemp -d ${TMP_DIR%%/}/bazel.XXXXXXXX)"
trap "rm -fr \"${WRKDIR}\"" EXIT

SRCDIR="${WRKDIR}/src"

LOGFILE="${WRKDIR}/log"
touch ${LOGFILE}

echo '=== copying files ===' >> "${LOGFILE}"

SCRUB_PDF="${WRKDIR}/scrub_pdf.ed"

cat > "${SCRUB_PDF}" <<EOF
H
1
/xmp:CreateDate
s/2[0-9][0-9][0-9]-[0-2][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9].[0-9][0-9]:[0-5][0-9]/1970-01-01T00:00:00+00:00/
/CreationDate
s/2[0-9][0-9][0-9][0-1][0-9][0-3][0-9][0-2][0-9][0-5][0-9][0-5][0-9].[0-9][0-9]/19700101000000+00/
/ModDate
s/2[0-9][0-9][0-9][0-2][0-9][0-3][0-9][0-2][0-9][0-5][0-9][0-5][0-9]/19700101000000/
/\/ID
s/<[^>]*>/<00000000000000000000000000000000>/g
w
q
EOF

DO_SCRUB_PDF="${WRKDIR}/scrub_pdf.sh"
cat > "${DO_SCRUB_PDF}" <<EOF
#!/bin/sh
echo Scrubbing \$1
ed \$1 < ${SCRUB_PDF}
EOF
chmod 755 "${DO_SCRUB_PDF}"

mkdir "${SRCDIR}"
for file in ${FILES}
do
    case $file in
    *.tar)
	    echo "Extract tar $file"
	    tar -C "${SRCDIR}" -xf "${file}"
	    ;;
    *)
	    echo "Copy file $file"
	    cp "${file}" "${SRCDIR}"
	    ;;
    esac
done

cd "${SRCDIR}"

echo '=== first latex run ===' >> "${LOGFILE}"

pdflatex "${ENTRY}" > $LOGFILE 2>&1 || (cat ${LOGFILE}; exit 1)

echo '=== second latex run ===' >> "${LOGFILE}"

pdflatex "${ENTRY}" > $LOGFILE 2>&1 || (cat ${LOGFILE}; exit 1)

echo '=== scrubing generated pdfs ===' >> "${LOGFILE}"

find . -name '*converted-to.pdf' -exec "${DO_SCRUB_PDF}" {} \; >> "${LOGFILE}" 2>&1

echo '=== final latex run ===' >> "${LOGFILE}"

pdflatex '\pdfinfo{/CreationDate(D:19700101000000Z)/ModDate(D:19700101000000Z)}\input{'"${ENTRY}"'}' > "${LOGFILE}" \
    || (cat ${LOGFILE}; exit 1)

OUTBASE=$(echo $(basename "${ENTRY}") | sed 's/.tex$//')
grep -av '^/ID \[\(<[0-9A-F]\{32\}>\) \1]$' "${SRCDIR}/${OUTBASE}.pdf" \
     > "${SRCDIR}/${OUTBASE}.pdf.without_pdf_id"

cp "${SRCDIR}/${OUTBASE}.pdf.without_pdf_id" "${OUT}"
