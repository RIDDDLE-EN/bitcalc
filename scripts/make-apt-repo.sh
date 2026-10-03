#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

POOL=${1:?pool dir}; OUT=${2:?output dir}; BASE_URL=${3:?base url}
BASE_URL=${BASE_URL%/}
command -v apt-ftparchive >/dev/null || { echo "apt-utils is required (apt-ftparchive)" >&2; exit 1; }
ls "$POOL"/*.deb >/dev/null 2>&1 || { echo "no .deb files in $POOL" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT/pool"
cp "$POOL"/*.deb "$OUT/pool/"
cp keys/bitcalc-archive-keyring.gpg keys/bitcalc-archive-keyring.asc "$OUT/"
FPR=$(<keys/FINGERPRINT)

(
	cd "$OUT"
	apt-ftparchive packages pool >Packages
	gzip -9nk Packages
	xz -9k Packages
	apt-ftparchive \
		-o APT::FTPArchive::Release::Origin=bitcalc \
		-o APT::FTPArchive::Release::Label=bitcalc \
		-o APT::FTPArchive::Release::Suite=stable \
		-o APT::FTPArchive::Release::Architectures=all \
		-o APT::FTPArchive::Release::Description="bitcalc APT repository" \
		release . >Release.tmp
	mv Release.tmp Release

	GPG=(gpg --batch --yes --pinentry-mode loopback)
	[[ -n ${SIGN_KEY_ID:-} ]] && GPG+=(--local-user "$SIGN_KEY_ID")
	[[ -n ${GPG_PASSPHRASE:-} ]] && GPG+=(--passphrase-fd 3)
	sign() { if [[ -n ${GPG_PASSPHRASE:-} ]]; then "${GPG[@]}" "$@" 3< <(printf '%s' "$GPG_PASSPHRASE"); else "${GPG[@]}" "$@"; fi; }
	sign --clearsign -o InRelease.tmp Release || { echo "signing InRelease failed" >&2; exit 1; }
	mv InRelease.tmp InRelease
	sign --armor --detach-sign -o Release.gpg Release || { echo "signing Release.gpg failed" >&2; exit 1; }
)

# landing page + installers with the URL and key fingerprint baked in
for f in install.sh uninstall.sh; do
	sed -e "s|@BASE_URL@|$BASE_URL|g" -e "s|@FINGERPRINT@|$FPR|g" "packaging/$f" >"$OUT/$f"
	chmod 755 "$OUT/$f"
done
sed -e "s|@BASE_URL@|$BASE_URL|g" -e "s|@FINGERPRINT@|$FPR|g" packaging/index.html >"$OUT/index.html"
touch "$OUT/.nojekyll"

# verify what we just produced
gpg --batch --verify "$OUT/Release.gpg" "$OUT/Release" 2>&1 | sed 's/^/  /'
gpg --batch --verify "$OUT/InRelease" >/dev/null 2>&1 || { echo "InRelease does not verify" >&2; exit 1; }
echo "repository ready in $OUT"
