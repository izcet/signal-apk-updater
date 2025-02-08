#!/bin/bash

function extractsignerinfo {
  # signal.org conveniently put their signer info in the html
  # in a more easily globbable part of the text
  local FILE="$1"
  grep -i '^[A-F0-9:]*$' "${FILE}" |\
    tr -d '\n' |\
    tr -d ':'
}

# OUTDIR, TIMESTAMP, and DIR_META are pulled from the env
if [ "$#" != "1" ] && [ "$#" != "2" ] ; then
  echo "$0 url [certificate pin location]"
  exit
fi

URL="$1"
DOMAIN="$(getdomain "${URL}")"
SLUG="$(slugify "${URL}")"

CERTPIN="$2"

HTML_OUT="${OUTDIR}${DOMAIN}/${SLUG}-${TIMESTAMP}.html"
HTML_LAST="${OUTDIR}${SLUG}-latest.html"
mkdir -p "${OUTDIR}${DOMAIN}"

META_OUT="${DIR_META}key_from_html"

if [ -f "${CERTPIN}" ] ; then
  echo "Using certificate pin at ${CERTPIN}"
  wget \
    --pinnedpubkey "sha256//$(cat "${CERTPIN}")" \
    -O "${HTML_OUT}" \
    "${URL}" 
else
  echo "No certificate pin found - trusting OS CA Certs"
  wget \
    --pinnedpubkey "sha256//$(cat "${CERTPIN}")" \
    -O "${HTML_OUT}" \
    "${URL}" 
fi

SIGN_OUT="$(extractsignerinfo "${HTML_OUT}")"
SIGN_LAST="$(extractsignerinfo "${HTML_LAST}")"
DIFF="$(diff -qi <(echo "${SIGN_OUT}") <(echo "${SIGN_LAST}") 2>/dev/null)"

if [ ! -f "${HTML_LAST}" ] ; then
  echo "This is the first time downlodading the page"
  echo "Trusting the signer key:"
  echo "  ${SIGN_OUT}"
elif [ "$DIFF" ] ; then
  echo "THE APP SIGNING KEY INFO HAS CHANGED!!!"
  echo "Old key:"
  echo "  ${SIGN_LAST}"
  echo "New key:"
  echo "  ${SIGN_OUT}"
  echo ""
  echo "Press Ctrl-C to cancel or Enter to trust the new key:"
  read -pr ""
fi

cp "${HTML_OUT}" "${HTML_LAST}"
echo "${SIGN_OUT}" > "${META_OUT}" 

