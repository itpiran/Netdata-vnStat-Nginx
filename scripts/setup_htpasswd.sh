#!/usr/bin/env bash
# Create an htpasswd file for basic auth and update nginx site template to use it.
set -euo pipefail
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <domain> <user> <pass>"
  exit 1
fi
DOMAIN="$1"
USER="$2"
PASS="$3"

HTPASSWD_DIR="/etc/nginx/htpasswd"
mkdir -p "${HTPASSWD_DIR}"
HTPASSWD_FILE="${HTPASSWD_DIR}/${DOMAIN}.htpasswd"

# Create htpasswd (openssl-based)
# Use Apache's htpasswd if available, otherwise use openssl to generate bcrypt via python fallback.
if command -v htpasswd >/dev/null 2>&1; then
  printf "%s\n" "${PASS}" | htpasswd -i -B -c "${HTPASSWD_FILE}" "${USER}"
else
  # fallback: use python to create bcrypt hash (requires python3-bcrypt)
  if ! python3 -c "import bcrypt" >/dev/null 2>&1; then
    apt update
    apt install -y python3-bcrypt
  fi
  python3 - <<PY
import bcrypt, sys
user = sys.argv[1]
pwd = sys.argv[2].encode('utf-8')
h = bcrypt.hashpw(pwd, bcrypt.gensalt())
print(f"{user}:" + h.decode('utf-8'))
PY "${USER}" "${PASS}" > "${HTPASSWD_FILE}"
fi

echo "Created htpasswd at ${HTPASSWD_FILE}"
