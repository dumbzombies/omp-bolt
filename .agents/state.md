# State

## Goal

Repo producing two Termux artifacts for oh-my-pi v18.12.6 via GitHub Actions:
Track A (`omp`, bionic, stock Bun) and Track B (`omp-bolt`, Pi-Bolt AOT, glibc).

## Progress

- Committed `54ed177` (initial tree) and `734c2ec` (guarded installer version probe,
  verification notes). Working tree clean; `upstream/` is an ignored scratch clone.
- `patches/0001..0003` apply to a clean `v18.12.6` checkout via `git apply`; a
  second run reports "already applied". Exactly 14 files change: 0002's 12 plus
  `loader-state.js` and `compile-binary.ts`.
- Loader under Bun: `OMP_PACKAGE_DIR=/tmp/fake` produces the candidate
  `/tmp/fake/pi_natives.android-arm64.node`; `getAddonFilenames({tag:"android-arm64"})`
  returns `pi_natives.android-arm64.node`.
- Installer simulations against a fake `PREFIX` with a fake glibc loader:
  `sha256sum -c --strict` gates both installs, `libexec/{omp,omp-bolt}` layout is
  correct, Track A launcher exports `TMPDIR`, `OMP_PACKAGE_DIR`, `PI_NATIVES_DIR`,
  `LANG`, `SHELL`, `OMP_MANAGED_INSTALL=1` and unsets `LD_PRELOAD`; Track B launcher
  runs both branches (patched interpreter, loader fallback); `install-bolt.sh`
  installs `omp-bolt-launcher` as `$PREFIX/bin/omp-bolt`.
- Worker extraction over the patched tree yields 5 module paths
  (`eval/js/worker-entry.ts`, `terminal-output-worker.ts`,
  `parent-watchdog-worker.ts`, `tab-worker-entry.ts`, `computer/worker-entry.ts`).
- `shellcheck -S warning` and `bash -n` clean on `termux/*.sh`; both TS drivers
  pass `bun build`; workflow YAML parses with jobs `android` and `bolt`;
  `verify-artifacts.sh` fails cleanly when artifacts are missing.

## Blockers

- No CI run yet (needs the repo pushed; `bolt` needs a public repo for the free
  arm64 runner, otherwise the plan's QEMU fallback needs approval).
- Device verification not run; needs release artifacts.

## Next actions

1. Push, run `workflow_dispatch`, confirm `verify-artifacts.sh` passes and Track B
   logs `mapped: true` and `image registered: true`.
2. Tag `v18.12.6-termux.1` to attach both zips to a release.
3. Device: install both zips, run the README verification commands.
