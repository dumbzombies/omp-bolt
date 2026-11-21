# omp-bolt

Termux builds of oh-my-pi v18.12.6, compiled on GitHub Actions.

- Track A: stock Bun bionic binary + bionic `pi_natives.android-arm64.node`.
- Track B: Pi-Bolt AOT image + glibc `pi_natives.linux-arm64.node`.

Start every session by reading `.agents/state.md` then `.agents/memory.md`.

## Layout

- `patches/` — 0001 Android loader, 0002 Rust/TS Android gates, 0003 Bolt entrypoints.
- `termux/` — build scripts (`build-native-android.sh`, `build-omp-android.ts`,
  `build-bolt.ts`), launchers (`omp`, `omp-bolt`), installers, artifact verifier, README.
- `.github/workflows/build.yml` — jobs `android` (ubuntu-24.04) and `bolt`
  (ubuntu-24.04-arm); tag `v*` attaches both zips to a release.

## Commands

```bash
git clone --depth=1 -b v18.12.6 https://github.com/can1357/oh-my-pi upstream
OMP_SRC=upstream bash termux/apply-patches.sh   # idempotent
bash -n termux/*.sh && shellcheck termux/*.sh
```

`upstream/`, `out/`, `dist/` are scratch and gitignored.
