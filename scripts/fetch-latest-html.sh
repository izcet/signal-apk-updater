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

OUTDIR="html"
mkdir -p "$OUTDIR"
OUT="$OUTDIR/$SLUG-$TIMESTAMP.html"

if [ -f "$CERTPIN" ] ; then
  echo "Using certificate pin at $CERTPIN"
  wget \
    --pinnedpubkey "sha256//$(cat $CERTPIN)" \
    -o "$OUTDIR/$SLUG_$TIMESTAMP.html" \
    "$FILE" 
else
  echo "No certificate pin found - trusting OS CA Certs"
  wget \
    --pinnedpubkey "sha256//$(cat $CERTPIN)" \
    -o "$OUTDIR/$SLUG_$TIMESTAMP.html" \
    "$FILE" 
fi

cp "$OUT" "$OUTDIR/$SLUG-latest.json"

