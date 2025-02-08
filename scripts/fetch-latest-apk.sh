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

APK_URL="$(jq -r '.["url"]' "${JSON_FILE}")"
APK_SHA="$(jq -r '.["sha256sum"]' "${JSON_FILE}")"

# shellcheck disable=SC2001
APK_NAME="$(echo "${APK_URL}" | sed 's:.*/::')"

OUT_FILE="${OUTDIR}${TIMESTAMP}-${APK_NAME}"
LAST_FILE="${OUTDIR}latest.apk"

FETCH_LATEST=0
if [ -f "${LAST_FILE}" ] ; then
  LAST_SHA="$(sha256 "${LAST_FILE}")"
  DIFF="$(diff -qi <(echo "${LAST_SHA}") <(echo "${APK_SHA}") 2>/dev/null)"
  if [ ! "$DIFF" ] ; then
    echo "A newer APK has not been released since the last one downloaded."
  else
    FETCH_LATEST=1
  fi
else
  FETCH_LATEST=1
fi

if [ "${FETCH_LATEST}" -eq "1" ] ; then
  wget "${APK_URL}" -O "${OUT_FILE}"
  FILE_SHA="$(sha256 "${OUT_FILE}")"
  
  DIFF="$(diff -qi <(echo "${FILE_SHA}") <(echo "${APK_SHA}") 2>/dev/null)"
  if [ "$DIFF" ] ; then
    echo "THE DOWNLOADED APK DOES NOT MATCH THE CHECKSUM!!!"
    exit 1
  fi
 
  if [ ! "$(which apksigner)" ] ; then
    echo "UNABLE TO VERIFY THE SIGNING KEY!!!"
    echo "To fix this issue, make sure apksigner is on your \$PATH."
    echo "To continue anyway, press Enter, or Ctrl+C to cancel."
    read -pr ""
    echo "VERIFICATION SKIPPED!!!"
  else
    apksigner verify \
      -v \
      --print-certs \
      --min-sdk-version 24 \
      "${OUT_FILE}" \
      > "${OUT_FILE}.crt" \
      2>&1 
    
    VERIFIES="$?"
    if [ ! "$VERIFIES" ] ; then
      echo "APKSIGNER VERIFICATION FAILED!!!"
      echo "Check the output logged in:"
      echo "  ${OUT_FILE}.crt"
      exit 1
    fi

    REGEX="^Signer \(minSdkVersion=[0-9]+, maxSdkVersion=[0-9]+\) certificate SHA-256 digest: [0-9a-f]+$"
    MATCH="$(grep -E "${REGEX}" "${OUT_FILE}.crt" |\
      grep -i "${SIGN_KEY}")"

    if [ ! "${MATCH}" ] ; then
      echo "APK SIGNATURE MISSING!!!"
      echo -e "Expected signer:\n  ${SIGN_KEY}"
      echo "Actual signers:"
      grep -E "${REGEX}" "${OUT_FILE}.crt"
      exit 1
    else
      echo "Signature verified!"
      echo -e "Using signing key:\n  ${SIGN_KEY}"
    fi
  fi

  cp "${OUT_FILE}" "${LAST_FILE}"
fi

