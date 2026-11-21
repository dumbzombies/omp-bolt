# omp-bolt — memory

## 2026-11-21 — Project purpose

Produces two installable Termux artifacts without compiling on the phone:

- Track A `omp-termux-aarch64.zip`: stock Bun single-file bionic binary
  (`bun-linux-arm64-android`) + `pi_natives.android-arm64.node`.
- Track B `omp-bolt-termux-aarch64.zip`: Pi-Bolt AOT image (`BUN_AOT=1`,
  `BUN_STATIC_HEAP=1`) + glibc `pi_natives.linux-arm64.node`, run under Termux
  glibc (patched ELF interpreter or `ld-linux-aarch64.so.1`).

Upstream pinned to `v18.12.6`; reference Android port is
`KILP49/oh-my-pi@android-18.12.6`.

## 2026-11-21 — Patch set decisions

- `0001-android-loader.patch` derives from the reference branch's one-line
  `SUPPORTED_PLATFORMS` addition, plus two local edits: `OMP_PACKAGE_DIR`
  override for `execDir` (bionic `process.execPath` is `/system/bin/linker64`)
  and the reference stub-proxy block **moved before** the
  `!SUPPORTED_PLATFORMS.includes()` throw. In the reference it lives inside
  that `if`, which is dead once android is a supported platform; out here a
  missing addon degrades to stubs with one warning instead of aborting.
- `0002-android-source.patch` is generated with
  `git diff HEAD FETCH_HEAD -- <12 paths>` (diff must go **from** v18.12.6
  **to** the KILP branch; the reverse direction produces a patch that will not
  apply). Excluded on purpose: README/CHANGELOGs, the reference's own
  workflows and `scripts/termux/*`, and its bundle-mode scripts — this repo
  replaces those with CI binaries and its own launchers.
- `0003-bolt-entrypoints.patch` adds `entrypoints?: readonly string[]` to
  `CodingAgentCompileOptions` so Track B can put worker modules into the AOT
  image.

## 2026-11-21 — Gotchas

- `bun-android-arm64` is rejected by Bun; the target string is
  `bun-linux-arm64-android`. TS types lack it, hence the deliberate cast.
- `verify-artifacts.sh` requires 16 KB LOAD alignment (`0x4000`) on both
  artifacts — Android 15+ requirement, set via
  `RUSTFLAGS=-C link-arg=-Wl,-z,max-page-size=16384`.
- The bionic addon must not have `GLIBC_` NEEDED entries; a bionic addon also
  cannot load in a glibc process, so Track B builds its own host addon.
- A bionic binary has no `libdl`-style dynamic loader path; `napi` may emit
  `pi_natives.<triple>.node`, so both build scripts rename to the platform-tag
  filename the loader resolves.
- Track B runs only on `ubuntu-24.04-arm`: a `linux-arm64` runtime on an x64
  host would emit AOT code for the wrong architecture.
- The reference worker-entrypoint grep (`rg -l 'new Worker\('`) finds worker
  *creators*, not modules; the workflow instead extracts
  `new URL("./…worker….ts", import.meta.url)` literals.
- File-flow collision: Track B's launcher and binary cannot both live in a
  zip produced with `zip -j`; the launcher ships as `omp-bolt-launcher` and
  `install-bolt.sh` installs it as `$PREFIX/bin/omp-bolt`.

## 2026-11-21 — Launcher/installer verification notes

- Installers run `sha256sum -c --strict` before touching `$PREFIX`; both print
  the version through the installed launcher, guarded so a failed probe cannot
  fail the install.
- `LD_PRELOAD` must be unset *before* the launcher's bash starts; the script's
  own `unset LD_PRELOAD` only protects children. A preload pointing at a missing
  library kills bash itself.
- Track B: `omp-bolt` (launcher) and `omp-bolt` (image) collide under `zip -j`,
  so the zip ships `omp-bolt-launcher` and the installer renames on install.
- `workerHostEntry()` returns the compiled host entry; extra AOT entrypoints are
  only for `new URL("./…worker….ts", import.meta.url)` modules.

## 2026-11-21 — Final session facts

- Upstream has no `postinstall` on any workspace; `bun install` never builds a
  native addon, so cross-compilation is unaffected by dependency install. Root
  `prepare` runs `gen:tool-views`, duplicating our explicit step harmlessly.
- `compile-binary.ts` pulls `buildDocsIndexPayload()` from `docs/**/*.md`, and the
  coding-agent build expects `gen:stats` output; keep both generation steps before
  any compile in CI.
- Worker-entrypoint extraction must scan for
  `new URL("./…worker….ts", import.meta.url)` literals; on v18.12.6 this yields 5
  modules. `workerHostEntry()` (compiled path) dispatches them from the binary.
- Committed tree: `54ed177` (initial) and `734c2ec` (guarded version probes).
  `upstream/`, `out/`, `.scratch/` stay gitignored.
