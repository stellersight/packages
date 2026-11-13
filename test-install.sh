#!/bin/sh
# Installs both tools from the StellerSight repository the way a user would,
# then checks that they run. Base URL is $REPO (default: the published site).
REPO=${REPO:-https://packages.stellersight.com}
set -e
if command -v apt-get >/dev/null; then
  apt-get update -qq >/dev/null; DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl ca-certificates gnupg >/dev/null 2>&1
  curl -fsSL "$REPO/stellersight.gpg" -o /usr/share/keyrings/stellersight.gpg
  echo "deb [signed-by=/usr/share/keyrings/stellersight.gpg] $REPO/deb stable main" > /etc/apt/sources.list.d/stellersight.list
  apt-get update -qq >/dev/null; DEBIAN_FRONTEND=noninteractive apt-get install -y -qq suit-linux priv-audit >/dev/null
elif command -v zypper >/dev/null; then
  rpm --import "$REPO/stellersight.asc"
  zypper -q -n addrepo --gpgcheck "$REPO/rpm" stellersight; zypper -q -n refresh >/dev/null; zypper -q -n install suit-linux priv-audit >/dev/null
elif command -v dnf >/dev/null || command -v yum >/dev/null; then
  PM=$(command -v dnf || command -v yum)
  curl -fsSL "$REPO/rpm/stellersight.repo" | sed "s#https://packages.stellersight.com#$REPO#" > /etc/yum.repos.d/stellersight.repo
  $PM install -y -q suit-linux priv-audit >/dev/null 2>&1 || { $PM install -y suit-linux priv-audit 2>&1 | tail -4; exit 1; }
elif command -v apk >/dev/null; then
  wget -qO /etc/apk/keys/stellersight.rsa.pub "$REPO/apk/stellersight.rsa.pub"
  echo "$REPO/apk" >> /etc/apk/repositories
  apk add -q suit-linux priv-audit
elif command -v pacman >/dev/null; then
  pacman-key --init >/dev/null 2>&1; curl -fsSL "$REPO/stellersight.asc" | pacman-key --add - >/dev/null 2>&1
  pacman-key --lsign-key B03D56007C15758DFB2AE4D9471660C890D39DC9 >/dev/null 2>&1
  printf '[stellersight]\nSigLevel = Required\nServer = %s/arch/$arch\n' "$REPO" >> /etc/pacman.conf
  pacman -Sy --noconfirm suit-linux priv-audit >/dev/null
fi
suit --help >/dev/null && priv-audit --version >/dev/null
[ "$(stat -c %a /var/lib/suit)" = 700 ] || { echo "FAIL: /var/lib/suit missing or not 0700"; exit 1; }
getent group suit-approvers >/dev/null || { echo "FAIL: suit-approvers group missing"; exit 1; }
[ "$(stat -c %a /etc/sudoers.d/suit)" = 440 ] || { echo "FAIL: sudoers drop-in missing"; exit 1; }
echo "INSTALL-OK $(priv-audit --version) suit $(python3 -c 'import sys; sys.path.insert(0,"/usr/lib/suit"); import suitlinux; print(suitlinux.__version__)')"
