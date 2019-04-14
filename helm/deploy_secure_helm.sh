#!/bin/bash
if ! [[ -x $(which openssl) ]]; then
  echo "You need openssl to run this"
  exit 1
fi

if ! [[ -x $(which helm) ]]; then
  echo "You need to install helm on your machine first"
  exit 1
fi

if [[ -d helm-chain ]]; then
  echo "Looks like there's already some stuff"
  echo "Not recreating certs"
else
  mkdir ./helm-chain; cd helm-chain

  #Create CA
  echo "Creating CA certs"
  openssl genrsa -out ./ca.key.pem 4096
  openssl req -key ca.key.pem -new -x509 -days 7300 -sha256 -out ca.cert.pem \
  -subj "/C=PL/L=Warsaw/O=tiller/CN=tiller"

  #Tiller certs
  echo "Creating Tiller certs"
  openssl genrsa -out ./tiller.key.pem 4096
  openssl req -key tiller.key.pem -new -sha256 -out tiller.csr.pem \
  -subj "/C=PL/L=Warsaw/O=tiller-server/CN=tiller-server"
  openssl x509 -req -CA ca.cert.pem -CAkey ca.key.pem -CAcreateserial \
  -in tiller.csr.pem -out tiller.cert.pem -days 365

  #Helm client certs
  echo "Creating client certs"
  openssl genrsa -out ./helm.key.pem 4096
  openssl req -key helm.key.pem -new -sha256 -out helm.csr.pem \
  -subj "/C=PL/L=Warsaw/O=helm-client/CN=helm-client"
  openssl x509 -req -CA ca.cert.pem -CAkey ca.key.pem -CAcreateserial \
  -in helm.csr.pem -out helm.cert.pem  -days 365

  echo "Certs created"
  cd ..
fi
echo "Applying tiller rbac"
kubectl apply -f tiller-rbac.yml
echo "Installer tiller"
helm init \
--upgrade \
--tiller-tls \
--tiller-tls-verify \
--tiller-tls-cert ./helm-chain/tiller.cert.pem \
--tiller-tls-key ./helm-chain/tiller.key.pem  \
--tls-ca-cert ./helm-chain/ca.cert.pem \
--tiller-image=jessestuart/tiller \
--service-account tiller \
--history-max 200

echo "Installing helm certs"
if ! [ -d $(helm home) ]; then mkdir $(helm home); fi
cp ./helm-chain/ca.cert.pem $(helm home)/ca.pem
cp ./helm-chain/helm.cert.pem $(helm home)/cert.pem
cp ./helm-chain/helm.key.pem $(helm home)/key.pem

echo "Use helm with --tls flag or add HELM_TLS_ENABLE=true to your shell env"
