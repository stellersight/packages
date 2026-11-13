#!/bin/bash
# Builds every package format for SUIT for Linux and Priv-Audit from their
# committed HEADs, then rebuilds and signs the apt, yum/zypper, apk and pacman
# repositories in this directory. Signing keys stay in ../packages-signing.
set -euo pipefail
HERE=D:/StellerSight-Docs/tools
SUIT_VERSION=${SUIT_VERSION:-0.2.0}; SUIT_PRE=${SUIT_PRE:-beta1}
PA_VERSION=${PA_VERSION:-0.1.0}
W=/d/StellerSight-Docs/tools/pkgbuild
rm -rf $W && mkdir -p $W/suit $W/pa $W/dist
(cd /d/StellerSight-Docs/tools/suit-linux && git archive HEAD | tar -x -C $W/suit)
(cd /d/StellerSight-Docs/stellersight-priv-audit && git archive HEAD | tar -x -C $W/pa)
nfpm() {
  MSYS_NO_PATHCONV=1 docker run --rm -v "$HERE/pkgbuild:/w" -v "$HERE/packages-signing:/keys:ro" \
    -e APK_KEY_FILE=/keys/stellersight.rsa "$@"
}
for p in deb rpm apk archlinux; do
  nfpm -w /w/suit -e VERSION=$SUIT_VERSION -e PRERELEASE=$SUIT_PRE goreleaser/nfpm:v2.41.1 package -f packaging/nfpm-suit.yaml -p $p -t /w/dist/
  nfpm -w /w/pa -e VERSION=$PA_VERSION goreleaser/nfpm:v2.41.1 package -f packaging/nfpm.yaml -p $p -t /w/dist/
done
rm -rf incoming deb rpm apk arch && mkdir incoming && cp $W/dist/* incoming/
MSYS_NO_PATHCONV=1 docker run --rm -e GNUPGHOME=/keys/gnupg -v "$HERE/packages-signing:/keys" -v "$HERE/packages-site:/site" stellersight-repo-tools sh /site/build-repo.sh
MSYS_NO_PATHCONV=1 docker run --rm -v "$HERE/packages-signing:/keys:ro" -v "$HERE/packages-site:/site" alpine:3.20 sh /site/build-apk.sh
MSYS_NO_PATHCONV=1 docker run --rm -e GNUPGHOME=/keys/gnupg -v "$HERE/packages-signing:/keys" -v "$HERE/packages-site:/site" archlinux:base sh /site/build-arch.sh
rm -rf incoming
echo "release complete"
