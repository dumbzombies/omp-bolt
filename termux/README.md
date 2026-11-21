# omp for Termux

Two Termux artifacts for [oh-my-pi](https://github.com/can1357/oh-my-pi)
**v18.12.6**, built on GitHub Actions. Nothing compiles on the phone.

| Track | Artifact | Runtime | Addon | Installer |
|---|---|---|---|---|
| A | `omp-termux-aarch64.zip` | stock Bun single-file binary, bionic | `pi_natives.android-arm64.node` | `install.sh` |
| B | `omp-bolt-termux-aarch64.zip` (experimental) | Pi-Bolt AOT image (`bolt-v1.2.1`), glibc | `pi_natives.linux-arm64.node` | `install-bolt.sh` |

Track B does not run on Android kernels: the AOT image maps at a fixed address
and the launch dies with `Bus error at address 0x1600000000` (the same failure
hits Pi-Bolt's own release binary). `BUN_AOT=0 omp-bolt …` runs it from bytecode,
which makes it equivalent to Track A plus a glibc loader. CI still builds it for
reference; it is not attached to releases.

Both share `$HOME/.omp/agent/*`. Both set `OMP_MANAGED_INSTALL=1`, so `omp update`
is disabled; upgrades come from these release zips.

## Install

```bash
# Track A
unzip omp-termux-aarch64.zip -d omp-termux && bash omp-termux/install.sh

# Track B
pkg install patchelf glibc-runner
unzip omp-bolt-termux-aarch64.zip -d omp-bolt-termux && bash omp-bolt-termux/install-bolt.sh
```

Installers verify `SHA256SUMS` before touching `$PREFIX`.

## Layout

```
$PREFIX/bin/omp                     launcher (Track A)
$PREFIX/bin/omp-bolt                launcher (Track B)
$PREFIX/libexec/omp/omp.bin         bionic binary
$PREFIX/libexec/omp/pi_natives.android-arm64.node
$PREFIX/libexec/omp-bolt/omp-bolt   AOT image
$PREFIX/libexec/omp-bolt/pi_natives.linux-arm64.node
```

## Environment the launchers set

- `OMP_PACKAGE_DIR` — addon directory. Required: under bionic `process.execPath` is
  `/system/bin/linker64`, so the loader cannot derive its own directory.
- `TMPDIR`/`TMP`/`TEMP` — `$PREFIX/tmp`.
- `PI_NATIVES_DIR` — `$HOME/.omp/natives`.
- `LANG`/`LC_ALL` — `C.UTF-8`; `SHELL` — `$PREFIX/bin/bash`.
- `LD_PRELOAD` is unset; `OMP_MANAGED_INSTALL=1`.

Track B additionally patches the ELF interpreter to
`$PREFIX/glibc/lib/ld-linux-aarch64.so.1` when `patchelf` exists, because omp
respawns `process.execPath` for some subprocesses. Without `patchelf` the
launcher runs the image through that loader explicitly.

## Verify on device

```bash
omp --version                                  # omp/18.12.6
omp -p "print ok"                              # ok
omp -p 'run: echo $TMPDIR && touch $TMPDIR/x && ls $TMPDIR'
bun -e 'console.log(require("'"$PREFIX"'/libexec/omp/pi_natives.android-arm64.node").__piNativesBuildVersion())'
                                               # 18.12.6 — real addon, not stubs
omp --resume                                   # session dir grows
```

```bash
BUN_STATIC_HEAP_VERBOSE=1 omp-bolt --version   # omp/18.12.6, no "running from bytecode"
omp-bolt -p "read package.json and summarize it"
```

If the addon cannot load, Track A still starts: the patched loader substitutes a
stub proxy (one warning on stderr) instead of aborting. That is a diagnostic
mode, not a usable CLI — the agent's tool descriptions call native symbols
(`editDescription` and friends), so any real run needs the addon. Treat a stub
warning as "install/rebuild the addon", not as a supported configuration.

## Rebuild

```bash
git clone --depth=1 -b v18.12.6 https://github.com/can1357/oh-my-pi upstream
OMP_SRC=upstream bash termux/apply-patches.sh
```

Patches: `0001` Android loader (platform tag, `OMP_PACKAGE_DIR`, stub fallback),
`0002` Android cfg gates in the Rust crates and clipboard, `0003` extra
entrypoints in `compile-binary.ts` (Track B AOT).

## Degraded mode

If `bun-linux-arm64-android` compilation ever fails on the runner, Track A falls
back to the reference bundle mode: `OMP_ANDROID_BUNDLE=1 bun run gen:bundle` in
`packages/coding-agent`, ship that directory into `$PREFIX/libexec/omp/`, and run
`bun "$LIBEXEC/cli.js" "$@"`. That needs Termux `bun`.
