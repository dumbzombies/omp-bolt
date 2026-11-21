# omp-bolt

Termux build of oh-my-pi v18.12.6, compiled on GitHub Actions. One artifact:
stock Bun bionic binary + bionic `pi_natives.android-arm64.node`.

Start every session by reading `.agents/state.md` then `.agents/memory.md`.

## Layout

- `patches/` — 0001 Android loader, 0002 Rust/TS Android gates.
- `termux/` — `build-native-android.sh`, `build-omp-android.ts`, launcher `omp`,
  `install.sh`, `verify-artifacts.sh`, README.
- `.github/workflows/build.yml` — job `android` (ubuntu-24.04); tag `v*` attaches
  the zip to a release.

## Commands

```bash
git clone --depth=1 -b v18.12.6 https://github.com/can1357/oh-my-pi upstream
OMP_SRC=upstream bash termux/apply-patches.sh   # idempotent
bash -n termux/*.sh && shellcheck termux/*.sh
```

`upstream/`, `out/`, `dist/`, `.scratch/` are scratch and gitignored.
