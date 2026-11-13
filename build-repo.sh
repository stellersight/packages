#!/bin/sh
# Builds the StellerSight apt and yum repositories from the packages in
# incoming/, signed with the key in $GNUPGHOME. Run in Debian 12 with
# gnupg, apt-utils, createrepo-c and rpm installed.
set -eu
SITE=/site
KEY_UID="StellerSight Packages <security@stellersight.com>"
cd "$SITE"

# --- yum / dnf -------------------------------------------------------------
mkdir -p rpm/packages
cp incoming/*.rpm rpm/packages/
cat > "$HOME/.rpmmacros" <<MACROS
%_signature gpg
%_gpg_name $KEY_UID
%__gpg /usr/bin/gpg
MACROS
rpmsign --addsign rpm/packages/*.rpm >/dev/null
createrepo_c --update --quiet rpm
rm -f rpm/repodata/repomd.xml.asc
gpg --batch --yes --armor --detach-sign --local-user "$KEY_UID" rpm/repodata/repomd.xml
cat > rpm/stellersight.repo <<REPO
[stellersight]
name=StellerSight
baseurl=https://packages.stellersight.com/rpm
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.stellersight.com/stellersight.asc
REPO

# --- apt ---------------------------------------------------------------------
mkdir -p deb/pool/main deb/dists/stable/main/binary-amd64 deb/dists/stable/main/binary-arm64 deb/dists/stable/main/binary-all
cp incoming/*.deb deb/pool/main/
cd deb
for arch in amd64 arm64 all; do
    apt-ftparchive --arch "$arch" packages pool/main > "dists/stable/main/binary-$arch/Packages"
    gzip -9kf "dists/stable/main/binary-$arch/Packages"
done
apt-ftparchive \
    -o APT::FTPArchive::Release::Origin=StellerSight \
    -o APT::FTPArchive::Release::Label=StellerSight \
    -o APT::FTPArchive::Release::Suite=stable \
    -o APT::FTPArchive::Release::Codename=stable \
    -o APT::FTPArchive::Release::Architectures="amd64 arm64 all" \
    -o APT::FTPArchive::Release::Components=main \
    release dists/stable > dists/stable/Release
gpg --batch --yes --local-user "$KEY_UID" --clearsign -o dists/stable/InRelease dists/stable/Release
gpg --batch --yes --local-user "$KEY_UID" -abs -o dists/stable/Release.gpg dists/stable/Release
cd ..

gpg --armor --export "$KEY_UID" > stellersight.asc
gpg --export "$KEY_UID" > stellersight.gpg
gpg --fingerprint "$KEY_UID" | sed -n 2p | tr -d ' ' > FINGERPRINT
echo "repository built; key $(cat FINGERPRINT)"
