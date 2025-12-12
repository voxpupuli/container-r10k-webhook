#!/bin/bash

set -e

#
# @summary If you somehow need own certificates inside the container.
#
# @example
# you want to run the webhook on a target with an internal ca certificate.
# export the CERT_JSON on container run and it should be imported with this script.
# it is expected that the certificate is a json hash of PEM certificates.
#
# {"certificates":{"root_ca":"-----BEGIN CERTIFICATE-----\n...","signing_ca":"-----BEGIN CERTIFICATE-----\n..."}}
#
if [ -n "${CERT_JSON}" ]; then
  for key in $(echo "${CERT_JSON}" | jq -r '.certificates | keys[]'); do
    cert=$(echo "${CERT_JSON}" | jq -r ".certificates[\"$key\"]")
    printf "%s" "${cert}" > /usr/local/share/ca-certificates/${HOSTNAME}-${key}.pem
    echo "INFO: imported ${key}"
  done

  update-ca-certificates
fi
