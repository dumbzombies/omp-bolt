# State

## Goal

Build the Termux artifact for oh-my-pi v18.12.6 on GitHub Actions: stock Bun
bionic single-file binary plus the real `pi_natives.android-arm64.node` addon.
Nothing compiles on the phone.

## Progress

- Track B (Pi-Bolt AOT) removed at the user's decision: its image faults on
  Android kernels (`Bus error at address 0x1600000000`), reproduced with
  Pi-Bolt's own release binary. Patch 0003, `build-bolt.ts`, `omp-bolt`,
  `install-bolt.sh` and the `bolt` job are gone; README records why.
- Single job `android` (ubuntu-24.04): NDK addon build, Android compile,
  verifier, zip, artifact, tag release.
- Local proof: `bun termux/build-omp-android.ts` produced a 192 MB
  `bun-linux-arm64-android` binary; it runs on this phone (`omp/18.12.6`);
  `file` reports "for Android 28"; LOAD aligns `0x4000`/`0x10000`; INTERP
  `/system/bin/linker64`; NEEDED `libc.so libm.so libdl.so
  libicui18n.so.79 libicuuc.so.79`.
- Addon is mandatory: stub mode dies at startup on `editDescription`.
- Patches apply to a clean `v18.12.6` clone via `git apply` and via the
  `patch -F3` fallback; a second run reports "already applied".
- `shellcheck -S warning` and `bash -n` clean; workflow YAML parses with the
  single `android` job.

## Blockers

- Waiting on the Track A CI run to produce the first installable zip (addon
  build + compile + verify).

## Next actions

1. Confirm run https://github.com/dumbzombies/omp-bolt/actions/runs/ is green
   and download `omp-termux-aarch64`.
2. Install on device, run the README verification commands, report broken
   features with their exact errors.
3. Tag `v18.12.6-termux.1` once device checks pass.
