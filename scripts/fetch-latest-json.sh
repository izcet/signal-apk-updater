#!/bin/bash

if [ "$#" != "1" ] && [ "$#" != "2" ] ; then
  echo "$0 url [certificate pin location]"
  exit
fi

URL="$1"
DOMAIN="$(getdomain "${URL}")"
SLUG="$(slugify "${URL}")"
CERTPIN="$2"

mkdir -p "${OUTDIR}${DOMAIN}"
JSON_OUT="${OUTDIR}${DOMAIN}/${SLUG}-${TIMESTAMP}.json"
JSON_LAST="${OUTDIR}${SLUG}-latest.json"

if [ -f "${CERTPIN}" ] ; then
  echo "Using certificate pin at ${CERTPIN}"
  curl --pinnedpubkey "sha256//$(cat "${CERTPIN}")" "${URL}" |\
    jq > "${JSON_OUT}"
else
  echo "No certificate pin found - trusting OS CA Certs"
  curl "${URL}" |\
    jq > "${JSON_OUT}"
fi

cp "${JSON_OUT}" "${JSON_LAST}"

