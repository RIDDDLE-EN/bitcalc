#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=${1:?usage: build-deb.sh <version>  (e.g. 1.2.3)}
VERSION=${VERSION#v}
[[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+([.+~-][0-9A-Za-z.]+)?$ ]] || { echo "bad version '$VERSION'" >&2; exit 1; }

EPOCH=${SOURCE_DATE_EPOCH:-$(git log -1 --format=%ct 2>/dev/null || date +%s)}
export SOURCE_DATE_EPOCH=$EPOCH
DATE=$(date -u -d "@$EPOCH" '+%B %Y')

ROOT=build/pkg
rm -rf build dist
mkdir -p "$ROOT"/{DEBIAN,usr/bin,usr/share/man/man1,usr/share/doc/bitcalc,usr/share/bash-completion/completions} dist

# program: stamp version, use the Debian-policy interpreter path
sed -e "s/@VERSION@/$VERSION/g" -e '1s|.*|#!/bin/bash|' src/bitcalc >"$ROOT/usr/bin/bitcalc"
chmod 755 "$ROOT/usr/bin/bitcalc"
bash -n "$ROOT/usr/bin/bitcalc"

# man page
sed -e "s/@VERSION@/$VERSION/g" -e "s/@DATE@/$DATE/g" man/bitcalc.1 | gzip -9n >"$ROOT/usr/share/man/man1/bitcalc.1.gz"

# completion, docs
install -m 644 completions/bitcalc.bash "$ROOT/usr/share/bash-completion/completions/bitcalc"
install -m 644 LICENSE "$ROOT/usr/share/doc/bitcalc/copyright"
install -m 644 README.md "$ROOT/usr/share/doc/bitcalc/README.md"
gzip -9n "$ROOT/usr/share/doc/bitcalc/README.md"

# control file
SIZE=$(du -sk --exclude=DEBIAN "$ROOT" | cut -f1)
sed -e "s/@VERSION@/$VERSION/" -e "s/@SIZE@/$SIZE/" packaging/control.in >"$ROOT/DEBIAN/control"

# normalise timestamps for reproducible output
find "$ROOT" -exec touch -h -d "@$EPOCH" {} +

OUT=dist/bitcalc_${VERSION}_all.deb
dpkg-deb --root-owner-group -Zxz --build "$ROOT" "$OUT"
dpkg-deb --info "$OUT" | sed -n '1,12p'
echo "built $OUT"
