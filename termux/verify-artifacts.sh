#!/usr/bin/env bash
# Verify Track A artifact properties on the build runner. Fails the job on any
# mismatch: wrong arch, <16 KB page alignment, glibc linkage leaking into a
# bionic binary, missing release stamp, missing bundle identity.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SRC="${OMP_SRC:-$ROOT/upstream}"
OUT="${OUT:-$ROOT/out}"
ADDON="$OUT/pi_natives.android-arm64.node"
BIN="$OUT/omp.bin"

if ! command -v llvm-readelf >/dev/null; then
	if [ -n "${ANDROID_NDK_HOME:-}" ]; then
		export PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
	fi
fi
command -v llvm-readelf >/dev/null || {
	echo "verify-artifacts: llvm-readelf missing" >&2
	exit 1
}

for f in "$BIN" "$ADDON"; do
	[ -f "$f" ] || {
		echo "verify-artifacts: missing $f" >&2
		exit 1
	}
done

fail() {
	echo "verify-artifacts: FAIL $*" >&2
	exit 1
}

file "$BIN" | grep -q 'ARM aarch64' || fail "omp.bin is not arm64"
file "$BIN" | grep -q 'for Android' || fail "omp.bin is not an Android executable"

load_align() {
	llvm-readelf -l "$1" | awk '/LOAD/ {print $NF}' | sort -u
}

for f in "$BIN" "$ADDON"; do
	aligns="$(load_align "$f")"
	for a in $aligns; do
		[ "$a" = "0x4000" ] || fail "$(basename "$f") LOAD align $a, want 0x4000"
	done
	[ -n "$aligns" ] || fail "$(basename "$f") has no LOAD segments"
done

llvm-readelf -h "$ADDON" | grep -q 'ARM aarch64' || fail "addon is not arm64"

if llvm-readelf -d "$ADDON" | grep NEEDED | grep -q 'GLIBC_'; then
	llvm-readelf -d "$ADDON" | grep NEEDED >&2
	fail "addon links against glibc; expected bionic"
fi
llvm-readelf -d "$ADDON" | grep NEEDED | grep -q 'liblog.so' || fail "addon has no liblog.so NEEDED entry"
llvm-readelf -d "$BIN" | grep NEEDED | grep -q 'GLIBC_' && fail "omp.bin links against glibc"

strings -a "$ADDON" | grep -q 'PI_NATIVES_VERSION_STAMP:' || fail "addon carries no version stamp"

NATIVES_VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' \
	"$SRC/packages/natives/package.json")"
strings -a "$ADDON" | grep -q "PI_NATIVES_VERSION_STAMP:${NATIVES_VERSION}" ||
	fail "addon stamp is not ${NATIVES_VERSION}"

strings -a "$BIN" | grep -q 'oh-my-pi' || fail "omp.bin does not look like an oh-my-pi bundle"

echo "verify-artifacts: OK (addon $NATIVES_VERSION)"
