#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
	command -v sudo >/dev/null || { echo "Run as root or install sudo." >&2; exit 1; }
	SUDO=sudo
else
	SUDO=""
fi

if dpkg -s bitcalc >/dev/null 2>&1; then
	echo "==> Removing the package"
	$SUDO apt-get remove -y bitcalc
fi

removed=0
for f in /etc/apt/sources.list.d/bitcalc.sources /usr/share/keyrings/bitcalc-archive-keyring.gpg; do
	if [[ -e $f ]]; then $SUDO rm -f "$f"; removed=1; echo "==> Removed $f"; fi
done
((removed)) && $SUDO apt-get update -qq || true

echo "bitcalc has been removed from this system."
