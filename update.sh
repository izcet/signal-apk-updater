#!/bin/bash

source scripts/helpers.sh
export TIMESTAMP=`datetime`

URLJSON="https://updates.signal.org/android/latest.json"
URLHTML="https://signal.org/android/apk/"

DIR_APK="apks/"
DIR_CERT="certs/"
DIR_HTML="htmls/"
DIR_JSON="jsons/"
DIR_META="metadata/"

mkdir -p "${DIR_APK}" "${DIR_CERT}" "${DIR_HTML}" "${DIR_JSON}" "${DIR_META}"

OUTDIR="${DIR_CERT}" \
  ./scripts/get-certpin.sh \
  `getdomain "${URLJSON}"` \
  || exit
JSON_PIN="${DIR_CERT}`getdomain ${URLJSON}`-latest.pin"

OUTDIR="${DIR_CERT}" \
  ./scripts/get-certpin.sh \
  `getdomain "${URLHTML}"` \
  || exit
HTML_PIN="${DIR_CERT}`getdomain ${URLHTML}`-latest.pin"

OUTDIR="${DIR_JSON}" \
  ./scripts/fetch-latest-json.sh \
  "${URLJSON}" \
  "${JSON_PIN}" \
  || exit
JSON_FILE="${DIR_JSON}`slugify "${URLJSON}"`-latest.json"


OUTDIR="${DIR_HTML}" \
  DIR_META="${DIR_META}" \
  ./scripts/fetch-latest-html.sh \
  "${URLHTML}" \
  "${HTML_PIN}" \
  || exit
SIGN_KEY=`cat "${DIR_META}key_from_html"`

OUTDIR="${DIR_APK}" \
  ./scripts/fetch-latest-apk.sh \
  "${JSON_FILE}" \
  "${SIGN_KEY}" \
  || exit

echo todo adb install -r
