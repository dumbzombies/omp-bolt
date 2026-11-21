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

## 2026-11-21 — Verifier and Pi-Bolt evidence pass

- `llvm-readelf -h` prints `Machine: AArch64`, not `ARM aarch64`; the plan's
  grep was wrong. `file` prints `ARM aarch64` but does not print "for Android"
  on every release (file 5.41 here), so the Android identity test is
  `.note.android.ident` present in `llvm-readelf -n`.
- Bun's own `bun-linux-aarch64-android` template (v1.4.5) has LOAD aligns
  `0x10000` and `0x4000`, interpreter `/system/bin/linker64`, NEEDED
  `libc.so`, `libm.so`, `libdl.so` — no `liblog.so`. Therefore: alignment is a
  lower bound (`>= 0x4000`), never equality; drop the `liblog.so` requirement;
  `libc.so` + no `GLIBC_` + interpreter check are the real bionic gates.
- Verified `verify-artifacts.sh` end to end against the real Bun Android
  template (passes structurally; fails only on the injected-stamp check), and
  the positive path with a synthetic stamp plus `oh-my-pi` bytes → `OK`.
- Pi-Bolt release assets: `pi-bolt-runtime-linux-arm64.tar.gz` is the compiler
  runtime; `pi-bolt-kit-linux-arm64.tar.gz` is only a compile kit (tree +
  training profile + `kit.json`), no `bun`. `kit.json` confirms the env set and
  `--target=bun-linux-arm64 --bytecode --splitting --compile-exec-argv=--smol`.
- Locally, the downloaded runtime produced no static-heap/AOT image for a
  hello-world and printed `[static heap] 0 bytes in executable, mapped: false`
  (format confirmed, value not). Running it via `glibc-runner` fails compile
  with `BunSectionNotFound` because `/proc/self/exe` is the loader; a
  `patchelf`-ed copy compiles fine. CI's `image registered: true` +
  `mapped: true` greps stay the hard gate; never weaken them to ship a
  bytecode-only image.
- All 15 workflow `run:` blocks render to syntactically valid bash; the
  heredoc-based worker-entrypoint extraction executes and yields 5 modules;
  `patch -F3` fallback applies all three patches too.

## 2026-11-21 — First CI runs and device probe of the Android binary

- `ubuntu-24.04` job: NDK addon build succeeds; `Compile omp binary` failed with
  `Could not resolve: "@oh-my-pi/pi-agent-core/..."` for every workspace subpath.
  Cause: the compile driver ran with the repo root as cwd. Upstream's
  `scripts/build-binary.ts` runs from `packages/coding-agent`; with
  `process.chdir()` into that package the same compile succeeds locally in ~48 s
  and yields a 192 MB Android binary.
- `transformersVersion` must come from the installed
  `node_modules/@huggingface/transformers/package.json` (lock resolves 4.3.0),
  not the catalog range.
- Local artifact checks: `file` says "for Android 28"; LOAD aligns 0x4000 and
  0x10000; INTERP `/system/bin/linker64`; NEEDED `libc.so`, `libm.so`,
  `libdl.so`, `libicui18n.so.79`, `libicuuc.so.79` — the versioned ICU sonames
  resolve on this Android 13 device, so they are not a blocker.
- The binary runs on the phone: `omp/18.12.6`.
- Without the addon, stub mode aborts at startup: `editDescription is not
  available on Android` raised from `describeTool` during MCP tool refresh. The
  stub proxy is a diagnostic fallback, not a runnable configuration; the
  README now says so.

## 2026-11-21 — Pi-Bolt AOT: real trigger and Termux incompatibility

- Pi-Bolt 1.2.1 emits **no** AOT image unless a bytecode order file is supplied.
  Proof on device: identical `hello.ts` builds are 107,203,384 B without an order
  file and 108,710,712 B with one (`v2` header plus at least one `F <hash>`
  line), and only the latter prints `[aot] image of … bytes mapped`.
  Bun.build's top-level `bytecodeOrder` is ignored; `compile.bytecodeOrder`
  works. `patch 0003` now exposes `bytecodeOrder` and `build-bolt.ts` reads
  `OMP_BYTECODE_ORDER`.
- Order files are written at run time with `BUN_BYTECODE_ORDER_OUT`; CI does a
  bytecode seed build, runs `seed --version` to record the order, then rebuilds
  with AOT. On device this produced `[aot] image of 85458944 bytes mapped,
  70123520 of them code` and `[static heap] 262537256 bytes … mapped: true`.
- The agent bundle contains a 325,513-byte top-level module, above the default
  `maximumAOTCandidateBytecodeSize` (262144); with
  `omitBytecodeFromStaticHeap=1` the build stops. `BUN_JSC_maximumAOTCandidateBytecodeSize=500000`
  builds it.
- Track B does not run on Android: launch panics `Bus error at address
  0x1600000000` (the fixed AOT code-image address). Pi-Bolt's own released `pi`
  crashes identically here, so it is an engine/Android-kernel limitation.
  `BUN_AOT=0` runs the same binary from bytecode. Consequence: Track B stays an
  experimental CI artifact, no release asset, README documents the failure.
- The AOT verify greps now match what pi-bolt 1.2.1 prints
  (`mapped: true`, `[aot] image of …`); the older "image registered" line is
  absent.
