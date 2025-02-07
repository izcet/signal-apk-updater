#!/bin/bash

if [ "$#" -ne "1" ] ; then
  echo "$0 \"domain name\""
  exit
fi

DOMAIN="$1"

# OUTDIR and TIMESTAMP are expected to be set by the env, if desired
CERT_RAW="${OUTDIR}${DOMAIN}/${DOMAIN}-${TIMESTAMP}.crt"
CERT_TEXT="${OUTDIR}${DOMAIN}/${DOMAIN}-${TIMESTAMP}.crt.txt"
PIN_CERT="${OUTDIR}${DOMAIN}/${DOMAIN}-${TIMESTAMP}.pin"
PIN_LAST="${OUTDIR}${DOMAIN}-latest.pin"

mkdir -p "${OUTDIR}${DOMAIN}/"

echo "Getting certificate info for '${DOMAIN}'"

# openssl is written by monkeys
# so we need to send it an empty string 
# to have it pipe the output
echo |\
  openssl s_client \
  -showcerts \
  -servername "${DOMAIN}" \
  -connect "${DOMAIN}":443 \
  2>/dev/null > "${CERT_RAW}"

cat "${CERT_RAW}" |\
  openssl x509 \
  -inform pem \
  -noout \
  -text > "${CERT_TEXT}"

# curl uses a very specific way to pin on certificates
# specific here is a synonym for bizarre
# https://blog.heckel.io/2020/12/13/calculating-public-key-hashes-for-public-key-pinning-in-curl/
cat "${CERT_RAW}" |\
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
  base64 > "${PIN_CERT}"

if [[ ! -f "${PIN_LAST}" ]] ; then
  echo "No pin exists for ${DOMAIN}"
  echo "Creating a pin on the certificate stored here:"
  echo "  ${CERT_TEXT}"
  echo "Press enter to continue or Ctrl+C to cancel."
  read -p ""
  cat "${PIN_CERT}" > "${PIN_LAST}"
elif ! diff -q "${PIN_CERT}" "${PIN_LAST}" ; then
  echo "THE CERTIFICATE HAS CHANGED!!"
  echo "The old certificate is here:"
  echo "  ${PIN_LAST}"
  echo "The new certificate is stored here:"
  echo "  ${PIN_CERT}"
  echo "Not automatically continuing."
  echo "Remove the old cert and re-try."
else
  echo "The current certificate matches the existing pin."
fi

echo "Using certificate pin at ${PIN_LAST}"

