#!/bin/bash

function datetime { 
  # return time formatted "2024-02-31_19-56-56"
  date +%F_%H-%M-%S
}

function slugify {
  # sanitize links to "https___updates.signal.org_android_latest.json"
  echo "$0" | sed 's-[:/?()]-_-g'
}

function getdomain {
  # sanitize links to "updates.signal.org"
  echo "$0" | sed 's?https://??' | sed 's:/.*::'
}

TIMESTAMP=`datetime`
URLJSON="https://updates.signal.org/android/latest.json"
URLHTML="https://signal.org/android/apk/"

./scripts/get-certpin.sh "$TIMESTAMP" `getdomain "$URLJSON"` || exit
./scripts/get-certpin.sh "$TIMESTAMP" `getdomain "$URLHTML"` || exit

./scripts/fetch-latest-json.sh \
  "$TIMESTAMP" \
  `getdomain "$URLJSON"` \
  "$URLJSON" \
  `slugify "$URLJSON"` || exit

./scripts/fetch-latest-html.sh \
  "$TIMESTAMP" \
  `getdomain "$URLHTML"` \
  "$URLHTML" \
  `slugify "$URLHTML"` || exit

