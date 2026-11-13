#!/bin/sh
# Alpine repository: noarch packages are listed under each architecture.
set -eu
apk add -q abuild >/dev/null
cd /site
mkdir -p /etc/apk/keys && cp /keys/stellersight.rsa.pub /etc/apk/keys/
for arch in x86_64 aarch64; do
  mkdir -p apk/$arch
  # apk fetches <name>-<version>.apk; nfpm names files <name>_<version>_all.apk.
  for f in incoming/*.apk; do
    n=$(basename "$f" .apk); n=${n%_all}
    name=${n%%_[0-9]*}; ver=${n#"$name"_}
    cp "$f" "apk/$arch/$name-$ver.apk"
  done
  (cd apk/$arch && apk index -q --rewrite-arch "$arch" -o APKINDEX.tar.gz *.apk && \
     abuild-sign -q -k /keys/stellersight.rsa -p stellersight.rsa.pub APKINDEX.tar.gz)
done
cp /keys/stellersight.rsa.pub apk/stellersight.rsa.pub
echo "apk repository built"
