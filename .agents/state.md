# State

## Goal

Ship the Termux artifact for oh-my-pi v18.12.6: stock Bun bionic single-file
binary plus the real `pi_natives.android-arm64.node`. Built only on GitHub
Actions.

## Progress

- CI green: run 44863379314 builds, verifies, and uploads
  `omp-termux-aarch64` (`omp.bin` 216 MB, addon 98 MB, SHA256SUMS, launcher,
  installer).
- Installed on this phone at `$PREFIX/libexec/omp/` + `$PREFIX/bin/omp`,
  plus `$PREFIX/bin/omp-bolt` (symlink alias created by the installer).
- Device evidence: `omp --version` → `omp/18.12.6`, `omp-bolt --version` →
  `omp-bolt/18.12.6`, `omp-bolt -p "print ok"` → `ok`; addon
  `__piNativesBuildVersion()` → `18.12.6`; `omp -p "print ok"` → `ok`; shell
  tool writes `$TMPDIR` (`$PREFIX/tmp`); native grep hit count correct; `ps -A`
  works; `read` returns the exact requested line.
- Track B (Pi-Bolt AOT) dropped: fixed-address code image faults on Android
  (`Bus error at address 0x1600000000`), reproduced with Pi-Bolt's own binary.
- Repo: single `android` job; two patches (0001 loader, 0002 Rust/TS Android
  gates); `shellcheck`/`bash -n` clean; patch flow idempotent.

## Blockers

- None for Track A.

- Release `v18.12.6-termux.1` published with `omp-termux-aarch64.zip`,
  `omp-termux-aarch64.zip.sha256`, `install.sh`. One-shot install verified on
  device:
  `curl -fsSL https://raw.githubusercontent.com/dumbzombies/omp-bolt/master/install.sh | bash`.

## Next actions

1. None required; bump `v18.12.6-termux.N` for a new artifact.
2. Optional device probes worth reporting: clipboard via `termux-clipboard-set`,
   image attachment, browser/computer tools (no Chrome/display on Termux).
