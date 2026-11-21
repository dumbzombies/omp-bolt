# omp-bolt

Termux (aarch64) build of [oh-my-pi](https://github.com/can1357/oh-my-pi)
v18.12.6, compiled on GitHub Actions as a stock Bun bionic binary plus the real
`pi_natives.android-arm64.node` addon.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/dumbzombies/omp-bolt/master/install.sh | bash
```

Then:

```bash
omp-bolt --version   # omp-bolt/18.12.6
omp-bolt
```

The installer downloads the latest release zip, verifies its SHA-256, and
installs into `$PREFIX`. No root, no compilation on the phone. Details:
[`termux/README.md`](termux/README.md).
