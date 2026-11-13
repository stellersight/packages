# StellerSight Packages

Signed apt, dnf/yum, zypper, apk and pacman repositories for
[SUIT for Linux](https://github.com/stellersight/suit-linux) and
[Priv-Audit](https://github.com/stellersight/priv-audit), published at
<https://packages.stellersight.com/>. Install instructions are on that page.

Signing key: `StellerSight Packages <security@stellersight.com>`,
RSA 4096, fingerprint `B03D 5600 7C15 758D FB2A E4D9 4716 60C8 90D3 9DC9`.
Alpine packages are signed with `apk/stellersight.rsa.pub`.

## Maintainers

`release.sh` builds every package format from the two projects' committed
HEADs with [nfpm](https://nfpm.goreleaser.com) and rebuilds and signs all
repositories. `test-install.sh` installs both tools from a repository URL on
any supported distribution. The private keys are not in this repository.

Copyright StellerSight Private Limited. Packages are Apache-2.0.
