#!/usr/bin/env bash
set -euo pipefail

CERT_DIR="./certificates"

mkdir -p "${CERT_DIR}"

#######################################
# Generate CA key (once)
#######################################
if [ ! -f "${CERT_DIR}/ca.key" ]; then
  echo "Generating CA private key..."
  openssl genrsa -out "${CERT_DIR}/ca.key" 2048
else
  echo "CA key already exists at ${CERT_DIR}/ca.key, skipping."
fi

#######################################
# Generate CA certificate (once)
#######################################
if [ ! -f "${CERT_DIR}/ca.crt" ]; then
  echo "Generating CA certificate..."
  openssl req -x509 -new -nodes \
    -key "${CERT_DIR}/ca.key" \
    -sha256 -days 1000 \
    -out "${CERT_DIR}/ca.crt" \
    -subj "/C=US/ST=Atropia/L=Krasnovia/O=Self/OU=Self/CN=Local Generated CA"
else
  echo "CA certificate already exists at ${CERT_DIR}/ca.crt, skipping."
fi

#######################################
# Function to generate cert for one hostname
#######################################
generate_cert_for_host() {
  local host="$1"

  local key_path="${CERT_DIR}/${host}.key"
  local csr_conf_path="${CERT_DIR}/${host}.csr.conf"
  local csr_path="${CERT_DIR}/${host}.csr"
  local crt_conf_path="${CERT_DIR}/${host}.crt.conf"
  local crt_path="${CERT_DIR}/${host}.crt"

  echo
  echo "==== Processing host: ${host} ===="

  #############################
  # Generate private key (EC secp384r1)
  #############################
  if [ ! -f "${key_path}" ]; then
    echo "Generating EC key for ${host}..."
    openssl ecparam -name secp384r1 -genkey -noout -out "${key_path}"
  else
    echo "Key for ${host} already exists at ${key_path}, skipping."
  fi

  #############################
  # Generate CSR config (inline)
  #############################
  echo "Creating CSR config for ${host}..."
  cat > "${csr_conf_path}" <<EOF
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[ dn ]
C  = US
ST = Atropia
L  = Krasnovia
O  = Self
OU = Self
CN = ${host}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${host}
EOF

  #############################
  # Generate CSR
  #############################
  echo "Generating CSR for ${host}..."
  openssl req -new \
    -key "${key_path}" \
    -out "${csr_path}" \
    -config "${csr_conf_path}"

  #############################
  # Generate cert extensions config (inline)
  #############################
  echo "Creating cert extensions config for ${host}..."
  cat > "${crt_conf_path}" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${host}
EOF

  #############################
  # Sign CSR to produce certificate
  #############################
  echo "Signing certificate for ${host}..."
  openssl x509 -req \
    -in "${csr_path}" \
    -CA "${CERT_DIR}/ca.crt" \
    -CAkey "${CERT_DIR}/ca.key" \
    -CAcreateserial \
    -out "${crt_path}" \
    -days 1000 \
    -sha256 \
    -extfile "${crt_conf_path}"

  echo "Finished ${host}:"
  echo "  Key : ${key_path}"
  echo "  CSR : ${csr_path}"
  echo "  Cert: ${crt_path}"
}

#######################################
# Interactive loop: type hostnames manually
#######################################
while true; do
  echo
  read -rp "Enter hostname (FQDN) for new cert (or press Enter to quit): " HOST
  if [ -z "${HOST}" ]; then
    echo "No hostname entered, exiting."
    break
  fi

  generate_cert_for_host "${HOST}"
done

echo
echo "All done."

