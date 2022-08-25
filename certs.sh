#!/bin/bash -xe

#https://faun.pub/manage-redhat-microshift-cluster-through-shipa-f635af288ec6
cat <<EOF> api.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
EOF

ADDITIONAL_NAMES="microshift.danclark.io"

i=1
for dns in $(sudo openssl x509 -in /var/lib/microshift/certs/kube-apiserver/secrets/service-network-serving-certkey/tls.crt -text | grep "X509v3 Subject Alternative Name:" -A1 | tail -1 | tr -d ' ' | tr ',' '\n' | grep 'DNS:')
do
  echo "DNS.${i} = ${dns}" >> api.conf
  let i=i+1
done

for name in ${ADDITIONAL_NAMES}
do
  echo "DNS.${i} = ${name}" >> api.conf
  let i=i+1
done

i=1
for ip in $(sudo openssl x509 -in /var/lib/microshift/certs/kube-apiserver/secrets/service-network-serving-certkey/tls.crt -text | grep "X509v3 Subject Alternative Name:" -A1 | tail -1 | tr -d ' ' | tr ',' '\n' | grep 'IP Address:')
do
  echo "IP.${i} = ${ip}" >> api.conf
  let i=i+1
done

ADDITIONAL_IPS="192.168.1.176 70.109.62.51"
for ip in ${ADDITIONAL_IPS}
do
  echo "IP.${i} = ${ip}" >> api.conf
  let i=i+1
done

# Create the new cert and key

openssl genrsa -out tls.key 2048
openssl req -new -key tls.key -subj "/CN=kube-apiserver" -out tls.csr -config api.conf
sudo openssl x509 -req -in tls.csr -CA /var/lib/microshift/certs/ca-bundle/ca-bundle.crt -CAkey /var/lib/microshift/certs/ca-bundle/ca-bundle.key -CAcreateserial -out tls.crt -extensions v3_req -extfile api.conf -days 1000
rm -f tls.csr
openssl x509 -in tls.crt -text # Check that the new IP address is added

# Shutdown microshift
sudo systemctl stop microshift

# Backup existing certs
sudo cp /var/lib/microshift/certs/kube-apiserver/secrets/service-network-serving-certkey/tls.crt ./tls.crt.orig
sudo cp /var/lib/microshift/certs/kube-apiserver/secrets/service-network-serving-certkey/tls.key ./tls.key.orig

# Remove existing certs
sudo rm -f /var/lib/microshift/certs/kube-apiserver/secrets/service-network-serving-certkey/tls.crt
sudo rm -f /var/lib/microshift/certs/kube-apiserver/secrets/service-network-serving-certkey/tls.key

# Drop new certs in place
sudo cp ./tls.crt /var/lib/microshift/certs/kube-apiserver/secrets/service-network-serving-certkey/tls.crt
sudo cp ./tls.key /var/lib/microshift/certs/kube-apiserver/secrets/service-network-serving-certkey/tls.key

sudo chown root.root /var/lib/microshift/certs/kube-apiserver/secrets/service-network-serving-certkey/tls.crt
sudo chown root.root /var/lib/microshift/certs/kube-apiserver/secrets/service-network-serving-certkey/tls.key

sudo chmod 0644 /var/lib/microshift/certs/kube-apiserver/secrets/service-network-serving-certkey/tls.crt
sudo chmod 0644 /var/lib/microshift/certs/kube-apiserver/secrets/service-network-serving-certkey/tls.key

sudo restorecon -v /var/lib/microshift/certs/kube-apiserver/secrets/service-network-serving-certkey/tls.crt
sudo restorecon -v /var/lib/microshift/certs/kube-apiserver/secrets/service-network-serving-certkey/tls.key

# Restart microshift
sudo systemctl start microshift

exit 0
