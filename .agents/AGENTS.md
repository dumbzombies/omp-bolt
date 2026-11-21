# omp-bolt — project rules

Two Termux artifacts for oh-my-pi v18.12.6, built only on GitHub Actions.

Before work read `.agents/state.md`, then `.agents/memory.md`.

- `patches/` — rebased onto tag `v18.12.6`; never regenerate against a moving branch.
- `termux/` — build scripts, launchers, installers, device verification docs.
- `.github/workflows/build.yml` — both build jobs; the only place compilation runs.
- `upstream/` is a scratch clone, gitignored.

Verify a script change with `bash -n`, `shellcheck`, and a fresh-clone
`OMP_SRC=<clone> bash termux/apply-patches.sh` (run twice: second run must report
"already applied").
