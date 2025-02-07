#!/bin/bash

if [ "$#" -ne "1" ] ; then
  echo "$0 \"\$TIMESTAMP\" \"\$DOMAIN\""
  exit
fi

TIMESTAMP="$1"
DOMAIN="$2"
OUTDIR="certs"
mkdir -p "$OUTDIR"
RAWCERT="$OUTDIR/$DOMAIN-$TIMESTAMP.crt"
TEXTCERT="$OUTDIR/$DOMAIN-$TIMESTAMP.crt.txt"
CERTPIN="$OUTDIR/$DOMAIN-$TIMESTAMP.pin"

# openssl is written by monkeys
# so we need to send it an empty string 
# to have it pipe the output
echo |\
  openssl s_client \
    -showcerts \
    -servername "$DOMAIN" \
    -connect "$DOMAIN":443 \
    2>/dev/null > "$RAWCERT"

cat "$RAWCERT" |\
  openssl x509 \
    -inform pem \
    -noout \
    -text > "$TEXTCERT"

# curl uses a very specific way to pin on certificates
# specific here is a synonym for bizarre
# https://blog.heckel.io/2020/12/13/calculating-public-key-hashes-for-public-key-pinning-in-curl/
cat "$RAWCERT" |\
  openssl x509 \
    -pubkey \
    -noout |\
  openssl asn1parse \
    -inform PEM \
    -in - \
    -noout \
    -out - |\
  shasum -a256 |\
  cut -f1 -d' ' |\
  xxd -r -ps |\
  base64 > "$CERTPIN"

LATEST="$OUTDIR/${DOMAIN}-latest"
if [ ! -f "$LATEST" ] ; then
  echo "No pin exists for $DOMAIN"
  echo "Creating a pin on the certificate stored here:"
  echo "  $TEXTCERT"
  echo "Press enter to continue or Ctrl+C to cancel."
  read -p ""
  cat "$CERTPIN" > "$LATEST"
else if [ ! diff -q "$CERTPIN" "$LATEST" ] ; then
  echo "THE CERTIFICATE HAS CHANGED!!"
  echo "The old certificate is here:"
  echo "  $LATEST"
  echo "The new certificate is stored here:"
  echo "  $CERTPIN"
  echo "Not automatically continuing."
  echo "Remove the old cert and re-try."
else
  echo "The current certificate matches the existing pin."
fi

