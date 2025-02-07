#!/bin/bash

function sha256 {
  local FILE="$1"
  shasum -a256 "${FILE}" | sed 's/ .*//'
}


# OUTDIR, TIMESTAMP are pulled from the env
if [ "$#" != "2" ] ; then
  echo "$0 <json metadata> <apk signing key location>"
  exit
fi

JSON_FILE="$1"
SIGN_KEY="$2"

APK_URL=`cat "${JSON_FILE}" | jq -r '.["url"]'`
APK_SHA=`cat "${JSON_FILE}" | jq -r '.["sha256sum"]'`
APK_NAME=`echo "${APK_URL}" | sed 's:.*/::'`

OUT_FILE="${OUTDIR}${TIMESTAMP}-${APK_NAME}"
LAST_FILE="${OUTDIR}latest.apk"

FETCH_LATEST=0
if [ -f "${LAST_FILE}" ] ; then
  LAST_SHA=`sha256 "${LAST_FILE}"`
  DIFF="$(diff -qi <(echo "${LAST_SHA}") <(echo "${APK_SHA}") 2>/dev/null)"
  if [ ! "$DIFF" ] ; then
    echo "The APK has not been updated since the last download."
  else
    FETCH_LATEST=1
  fi
else
  FETCH_LATEST=1
fi

if [ "${FETCH_LATEST}" -eq "1" ] ; then
  wget "${APK_URL}" -O "${OUT_FILE}"
  FILE_SHA=`sha256 "${OUT_FILE}"`
  
  DIFF="$(diff -qi <(echo "${FILE_SHA}") <(echo "${APK_SHA}") 2>/dev/null)"
  if ["$DIFF" ] ; then
    echo "THE DOWNLOADED APK DOES NOT MATCH THE CHECKSUM!!!"
    exit 1
  fi
  
  echo "todo: verify signature with apktool"
  if false ; then
    echo "todo: verify signature with apktool"
    echo "THE DOWNLOADED APK DOES NOT MATCH THE SIGNING KEY!!!"
    exit 1
  fi

  cp "${OUT_FILE}" "${LAST_FILE}"
fi

