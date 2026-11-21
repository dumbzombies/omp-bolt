#!/usr/bin/env bash
# Apply the Android/Bolt patch set to a clean oh-my-pi checkout.
#
# OMP_SRC points at the checkout (default: upstream). The patches are rebased
# onto OMP_TAG v18.12.6, so `git apply` is the normal path; `patch -F3` absorbs
# the small context drift in 0001 (its stub block comes from a newer loader).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SRC="${OMP_SRC:-$ROOT/upstream}"

if [ ! -d "$SRC/.git" ]; then
	echo "apply-patches: $SRC is not a git checkout" >&2
	exit 1
fi

for p in "$ROOT"/patches/*.patch; do
	if git -C "$SRC" apply --check "$p" 2>/dev/null; then
		echo "apply-patches: git apply $(basename "$p")"
		git -C "$SRC" apply "$p"
	elif patch -d "$SRC" -p1 -F3 --dry-run <"$p" >/dev/null 2>&1; then
		echo "apply-patches: patch -F3 $(basename "$p")"
		patch -d "$SRC" -p1 -F3 <"$p" >/dev/null
	elif git -C "$SRC" apply --reverse --check "$p" 2>/dev/null; then
		echo "apply-patches: already applied $(basename "$p")"
	else
		echo "apply-patches: FAILED $p" >&2
		exit 1
	fi
done
