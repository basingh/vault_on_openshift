#!/bin/bash

# SERVICE is the name of the Vault service in Kubernetes.
# It does not have to match the actual running service, though it may help for consistency.
echo "########################## setting service param ##########################"

SERVICE=vault-server-tls

echo $SERVICE


# NAMESPACE where the Vault service is running.
echo "########################## setting namespace param ##########################"

NAMESPACE=vault

echo $NAMESPACE
# SECRET_NAME to create in the Kubernetes secrets store.
echo "########################## setting secret name ##########################"

SECRET_NAME=vault-server-tls

echo $SECRET_NAME
# TMPDIR is a temporary working directory.
echo "########################## setting temp directory param ##########################"

TMPDIR=/tmp

echo $TMPDIR
#Create a key for Kubernetes to sign.

echo "########################## creating a vault key in temp dire ##########################"

openssl genrsa -out ${TMPDIR}/vault.key 2048

#Create a Certificate Signing Request (CSR).
#Create a file ${TMPDIR}/csr.conf with the following contents:
sleep 15


echo "########################## creating csr.conf ##########################"


cat <<EOF >${TMPDIR}/csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${SERVICE}
DNS.2 = ${SERVICE}.${NAMESPACE}
DNS.3 = ${SERVICE}.${NAMESPACE}.svc
DNS.4 = ${SERVICE}.${NAMESPACE}.svc.cluster.local
IP.1 = 127.0.0.1
EOF

# create CSR
echo "########################## creating CSR ##########################"

openssl req -new -key ${TMPDIR}/vault.key -subj "/CN=${SERVICE}.${NAMESPACE}.svc" -out ${TMPDIR}/server.csr -config ${TMPDIR}/csr.conf

sleep 15

# Create the certificate
# Create a file ${TMPDIR}/csr.yaml with the following contents:

export CSR_NAME=vault-csr

echo "########################## creating csr yaml to be fed to Openshift ##########################"

cat <<EOF >${TMPDIR}/csr.yaml
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  groups:
  - system:authenticated
  request: $(cat ${TMPDIR}/server.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

# send the CSR to openshift
echo "########################## send CSR to OS ##########################"


oc create -f ${TMPDIR}/csr.yaml

# approve CSR in openshift
sleep 15

echo "########################## approve CSR ##########################"


oc adm certificate approve ${CSR_NAME}
 
# Store key, cert, and Kubernetes CA into Kubernetes secrets store
# Retrieve the certificate.

echo $(oc get csr)

sleep 15

echo "########################## get server cert ##########################"


serverCert=$(oc get csr vault-csr -o jsonpath='{.status.certificate}')

echo $serverCert

echo "########################## write certificate out to file ##########################"


echo "${serverCert}" | openssl base64 -d -A -out ${TMPDIR}/vault.crt

sleep 5


echo "########################## Retrieve kubernetes CA ##########################"

kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > ${TMPDIR}/vault.ca

sleep 5

echo "########################## store key, cert and CA in kubernetes secret ##########################"

kubectl create secret generic ${SECRET_NAME} \
        --namespace ${NAMESPACE} \
        --from-file=vault.key=${TMPDIR}/vault.key \
        --from-file=vault.crt=${TMPDIR}/vault.crt \
        --from-file=vault.ca=${TMPDIR}/vault.ca