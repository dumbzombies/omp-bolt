# omp for Termux

Termux build of [oh-my-pi](https://github.com/can1357/oh-my-pi) **v18.12.6**:
a stock Bun single-file executable for `aarch64-linux-android` (bionic) plus the
real `pi_natives.android-arm64.node` addon. Everything compiles on GitHub
Actions; the phone only unzips and installs.

## Install

One shot (Termux, aarch64) - fetches the latest release, checks its SHA-256,
and installs:

```bash
curl -fsSL https://raw.githubusercontent.com/dumbzombies/omp-bolt/master/install.sh | bash
```

Manual, from a downloaded `omp-termux-aarch64.zip`:

```bash
unzip omp-termux-aarch64.zip -d omp-termux
bash omp-termux/install.sh
```

`install.sh` verifies `SHA256SUMS` before touching `$PREFIX`:

```
$PREFIX/bin/omp                                  launcher
$PREFIX/bin/omp-bolt                             alias (symlink to omp)
$PREFIX/libexec/omp/omp.bin                      bionic binary
$PREFIX/libexec/omp/pi_natives.android-arm64.node
```

## Environment the launcher sets

- `OMP_PACKAGE_DIR` — addon directory. Required: under bionic `process.execPath`
  is `/system/bin/linker64`, so the loader cannot derive its own directory.
- `TMPDIR`/`TMP`/`TEMP` — `$PREFIX/tmp`.
- `PI_NATIVES_DIR` — `$HOME/.omp/natives`.
- `LANG`/`LC_ALL` — `C.UTF-8`; `SHELL` — `$PREFIX/bin/bash`.
- `LD_PRELOAD` is unset; `OMP_MANAGED_INSTALL=1` disables `omp update`.

`$HOME/.omp/agent/*` config is unchanged; upgrades come from release zips.

## Verify on device

```bash
omp --version                                  # omp/18.12.6
omp-bolt --version                             # omp-bolt/18.12.6 (same binary)
omp -p "print ok"                              # ok
omp -p 'run: echo $TMPDIR && touch $TMPDIR/x && ls $TMPDIR'
bun -e 'console.log(require("'"$PREFIX"'/libexec/omp/pi_natives.android-arm64.node").__piNativesBuildVersion())'
                                               # 18.12.6 — real addon
omp --resume                                   # session dir grows
```

The addon is mandatory. If it cannot load, the patched loader substitutes a stub
proxy (one warning on stderr) instead of aborting, but that is a diagnostic
mode: tool descriptions call native symbols (`editDescription`), so any real run
dies. Treat a stub warning as "rebuild the addon".

## Layout

- `patches/0001-android-loader.patch` — `android-arm64` platform tag,
  `OMP_PACKAGE_DIR` exec dir, stub fallback.
- `patches/0002-android-source.patch` — `target_os = "android"` gates in the Rust
  crates (pidfd vs `kill(pid, 0)`, process snapshot, `ps`/`kill`), the Termux
  clipboard path, and android in the bindings platform list.
- `termux/` — build scripts, launcher, installer, artifact verifier.
- `.github/workflows/build.yml` — the only place compilation runs.

## Rebuild

```bash
git clone --depth=1 -b v18.12.6 https://github.com/can1357/oh-my-pi upstream
OMP_SRC=upstream bash termux/apply-patches.sh   # idempotent
```

## Degraded mode

If `bun-linux-arm64-android` compilation ever fails on the runner, fall back to
the reference bundle mode: `OMP_ANDROID_BUNDLE=1 bun run gen:bundle` in
`packages/coding-agent`, ship that directory into `$PREFIX/libexec/omp/`, and run
`bun "$LIBEXEC/cli.js" "$@"`. That needs Termux `bun`.

## Not shipped

Pi-Bolt AOT (glibc + `BUN_AOT=1`) was built and tested, then dropped:
its code image maps at a fixed address and Android kernels fault it
(`Bus error at address 0x1600000000`, reproduced with Pi-Bolt's own release
binary). `BUN_AOT=0` runs it from bytecode, which is no better than the bionic
binary above.
