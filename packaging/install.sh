#!/usr/bin/env bash
set -euo pipefail

BASE_URL="@BASE_URL@"
FINGERPRINT="@FINGERPRINT@"
KEYRING=/usr/share/keyrings/bitcalc-archive-keyring.gpg
LIST=/etc/apt/sources.list.d/bitcalc.sources

command -v apt-get >/dev/null || { echo "This installer needs apt (Debian, Ubuntu, Raspberry Pi OS, Kali, ...)." >&2; exit 1; }
if [[ $EUID -ne 0 ]]; then
	command -v sudo >/dev/null || { echo "Run as root or install sudo." >&2; exit 1; }
	SUDO=sudo
else
	SUDO=""
fi

echo "==> Installing prerequisites"
$SUDO apt-get update -qq
$SUDO apt-get install -y -qq ca-certificates curl gnupg

echo "==> Fetching the signing key"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
curl -fsSL "$BASE_URL/bitcalc-archive-keyring.gpg" -o "$tmp"
got=$(gpg --show-keys --with-colons "$tmp" 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')
if [[ $got != "$FINGERPRINT" ]]; then
	echo "Key fingerprint mismatch (got '$got', expected '$FINGERPRINT'). Aborting." >&2
	exit 1
fi
$SUDO install -D -m 644 "$tmp" "$KEYRING"

echo "==> Adding the repository"
$SUDO tee "$LIST" >/dev/null <<REPO
Types: deb
URIs: $BASE_URL
Suites: ./
Signed-By: $KEYRING
REPO

echo "==> Installing bitcalc"
$SUDO apt-get update -qq
$SUDO apt-get install -y bitcalc

echo
echo "Done. Try:  bitcalc 10 AND -2    (man bitcalc for everything else)"
