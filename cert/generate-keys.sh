#!/usr/bin/env bash

# generate-keys.sh
#
# Generate a (self-signed) CA certificate and a certificate and private key to be used by the webhook server.
# The certificate will be issued for the Common Name (CN) which is the
# cluster-internal DNS name for the service.

openssl genrsa -out ca.key 2048
openssl req -new -x509 -subj "/CN=Oauth Sidecar CA" -extensions v3_ca -days 365 -key ca.key -sha256 -out ca.crt -config san.cnf

openssl genrsa -out webhook-server-tls.key 2048
openssl req -subj "/CN=oauth-sidecar" -extensions v3_req -sha256 -new -key webhook-server-tls.key -out webhook-server-tls.csr
openssl x509 -req -extensions v3_req -days 365 -sha256 -in webhook-server-tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out webhook-server-tls.crt -extfile san.cnf

ca_pem_b64="$(openssl base64 -A <"ca.crt")"
sed -e 's@${CA_PEM_B64}@'"$ca_pem_b64"'@g' < "../deployments/kubernetes/deploy.dev.yaml.temp" | tee ../deployments/kubernetes/deploy.dev.yaml
