#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v gpg >/dev/null || { echo "gpg is required" >&2; exit 1; }

NAME=${KEY_NAME:-"bitcalc APT signing key"}
EMAIL=${KEY_EMAIL:-"ridddle5050@gmail.com"}
GNUPGHOME=$(mktemp -d)
export GNUPGHOME
trap 'rm -rf "$GNUPGHOME"' EXIT
chmod 700 "$GNUPGHOME"

echo "You will be asked for a passphrase (recommended). Store it in the secret APT_GPG_PASSPHRASE."
gpg --quick-generate-key "$NAME <$EMAIL>" rsa4096 sign 2y

FPR=$(gpg --list-keys --with-colons | awk -F: '/^fpr:/ {print $10; exit}')
mkdir -p keys
gpg --export "$FPR" >keys/bitcalc-archive-keyring.gpg          # binary: what apt's Signed-By wants
gpg --armor --export "$FPR" >keys/bitcalc-archive-keyring.asc  # armored copy for humans
echo "$FPR" >keys/FINGERPRINT

echo
echo "Public key written to keys/ (commit these files). Fingerprint: $FPR"
echo
echo "=== PRIVATE KEY: add as GitHub secret APT_GPG_PRIVATE_KEY, then delete this terminal output ==="
gpg --armor --export-secret-keys "$FPR"
echo "=== END ==="
echo "Keep an offline backup of the private key somewhere safe."
