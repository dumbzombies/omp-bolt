# State

## Goal

Repo producing two Termux artifacts for oh-my-pi v18.12.6 via GitHub Actions:
Track A (`omp`, bionic, stock Bun) and Track B (`omp-bolt`, Pi-Bolt AOT, glibc).

## Progress

- Head `36d8b41`; tree clean; `upstream/` is an ignored scratch clone at the
  patched state.
- `patches/0001..0003` apply to a clean `v18.12.6` checkout via `git apply` and
  via the `patch -F3` fallback; a second run reports "already applied". 14 files
  change: 0002's 12 plus `loader-state.js` and `compile-binary.ts`.
- Loader under Bun: `OMP_PACKAGE_DIR` puts the addon in the candidate list;
  `getAddonFilenames({tag:"android-arm64"})` returns the literal filename.
- `termux/verify-artifacts.sh` now checks what the real tooling proves:
  `.note.android.ident` present on both artifacts, LOAD align `>= 0x4000`
  (Bun's template uses `0x4000` and `0x10000`), NEEDED `libc.so`, no `GLIBC_`,
  interpreter `/system/bin/linker64`, stamp equal to the natives version, and
  `oh-my-pi` in the bundle. Proven against the real Bun 1.4.5
  `bun-linux-aarch64-android` template: structural checks pass, stamp check
  fails on the unmodified template, and a stamped copy yields `OK`.
- Installers simulated against a fake `PREFIX` and fake glibc loader: SHA256SUMS
  gate, `libexec` layout, Track A env contract, Track B both launcher branches,
  `omp-bolt-launcher` rename on install.
- All 15 workflow `run:` blocks render to valid bash; the heredoc worker
  extraction executes and yields 5 module paths; YAML parses with jobs
  `android` and `bolt`; `shellcheck -S warning` and `bash -n` clean; both TS
  drivers pass `bun build`.

## Blockers

- No CI run yet (repo must be pushed; `bolt` needs a public repo for the free
  arm64 runner, otherwise the plan's QEMU fallback needs approval).
- Device verification not run; needs release artifacts.
- Track B risk: the downloaded Pi-Bolt runtime produced no AOT image in a local
  hello-world test. CI's `image registered: true` / `mapped: true` gates fail the
  job rather than ship a bytecode-only binary; investigate there if it trips.

## Next actions

1. Push, run `workflow_dispatch`, confirm `verify-artifacts.sh` passes and Track B
   logs `mapped: true` and `image registered: true`.
2. Tag `v18.12.6-termux.1` to attach both zips to a release.
3. Device: install both zips, run the README verification commands.
