#!/bin/sh
# Arch Linux repository: signed packages and a signed database.
set -eu
pacman -Sy --noconfirm --needed gnupg >/dev/null 2>&1 || true
KEY="security@stellersight.com"
cd /site
mkdir -p arch/x86_64
cp incoming/*.pkg.tar.zst arch/x86_64/
cd arch/x86_64
for f in *.pkg.tar.zst; do gpg --batch --yes --local-user "$KEY" --detach-sign "$f"; done
repo-add --sign --key "$KEY" -q stellersight.db.tar.gz *.pkg.tar.zst
# Serve plain files, not symlinks: some static hosts do not follow them.
for l in stellersight.db stellersight.files stellersight.db.sig stellersight.files.sig; do
  [ -L "$l" ] && cp --remove-destination "$(readlink "$l")" "$l"
done
echo "arch repository built"
