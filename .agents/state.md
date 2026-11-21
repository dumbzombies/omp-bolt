# State

## Goal

Repo producing two Termux artifacts for oh-my-pi v18.12.6 via GitHub Actions:
Track A (`omp`, bionic, stock Bun) and Track B (`omp-bolt`, Pi-Bolt AOT, glibc).

## Progress

- Repo scaffold complete and committed (`54ed177`): `.gitignore`, `patches/0001..0003`,
  `termux/*`, `.github/workflows/build.yml`, `termux/README.md`, memory bank.
- Patches verified on a clean `v18.12.6` clone: all three apply via `git apply`;
  second run reports "already applied" (idempotent). Patched files: 14, exactly
  0002's 12 plus loader and `compile-binary.ts`.
- Loader override tested under Bun: `OMP_PACKAGE_DIR=/tmp/fake` puts
  `/tmp/fake/pi_natives.android-arm64.node` in the candidate list;
  `getAddonFilenames({tag:"android-arm64"})` returns the literal addon name.
- Installers simulated against a fake `PREFIX` with a fake glibc loader:
  Track A `install.sh` verifies SHA256SUMS, installs into `libexec/omp`, and the
  launcher exports the full env contract (`TMPDIR`, `OMP_PACKAGE_DIR`,
  `PI_NATIVES_DIR`, `LANG`, `SHELL`, `OMP_MANAGED_INSTALL=1`, no `LD_PRELOAD`).
  Track B `install-bolt.sh` installs `omp-bolt-launcher` as `$PREFIX/bin/omp-bolt`;
  both launcher branches (patched interpreter, loader fallback) execute.
- `bash -n` and `shellcheck -S warning` clean on all `termux/*.sh`; workflow
  YAML parses with jobs `android`, `bolt`; `verify-artifacts.sh` fails cleanly on
  missing artifacts.

## Blockers

- No CI run yet (needs the repo pushed; `bolt` requires a public repo for the
  free arm64 runner, otherwise the plan's QEMU fallback needs approval).
- Device verification (both tracks) not run; needs release artifacts.

## Next actions

1. Push repo, run `workflow_dispatch`, confirm `verify-artifacts.sh` and the
   Track B AOT log (`mapped: true`, `image registered: true`).
2. Tag `v18.12.6-termux.1` to attach both zips to a release.
3. Device: install both zips, run the README verification commands.
