#!/bin/bash

if [ "$#" -ne "4" ] ; then
  echo "$0 \"\$TIMESTAMP\" \"\$DOMAIN\" \"\$FILE\" \"\$SLUG\""
  exit
fi

TIMESTAMP="$1"
DOMAIN="$3"
FILE="$2"
SLUG="$4"

CERTPIN="certs/${DOMAIN}-latest"

OUTDIR="json"
mkdir -p "$OUTDIR"
OUT="$OUTDIR/$SLUG-$TIMESTAMP.json"

if [ -f "$CERTPIN" ] ; then
  echo "Using certificate pin at $CERTPIN"
  curl --pinnedpubkey "sha256//$(cat $CERTPIN)" "$FILE" |\
    jq > "$OUT"
else
  echo "No certificate pin found - trusting OS CA Certs"
  curl "$FILE" |\
    jq > "$OUT"
fi

cp "$OUT" "$OUTDIR/$SLUG-latest.json"

