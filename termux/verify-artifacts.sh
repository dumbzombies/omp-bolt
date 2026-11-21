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

# `.note.android.ident` is stamped by the NDK linker; `file` only prints
# "for Android" on some releases, so test the note itself.
load_align() {
	llvm-readelf -l "$1" | awk '/LOAD/ {print $NF}' | sort -u
}

for f in "$BIN" "$ADDON"; do
	llvm-readelf -n "$f" | grep -q '\.note\.android\.ident' ||
		fail "$(basename "$f") has no .note.android.ident (not an NDK/bionic link)"
	aligns="$(load_align "$f")"
	[ -n "$aligns" ] || fail "$(basename "$f") has no LOAD segments"
	for a in $aligns; do
		# Android 15+ requires >= 16 KB; Bun's own Android template uses both
		# 0x4000 and 0x10000, so this is a lower bound, not equality.
		[ $((a)) -ge 16384 ] || fail "$(basename "$f") LOAD align $a, want >= 0x4000"
	done
done

llvm-readelf -h "$ADDON" | grep -q 'AArch64' || fail "addon is not arm64"

if llvm-readelf -d "$ADDON" | grep NEEDED | grep -q 'GLIBC_'; then
	llvm-readelf -d "$ADDON" | grep NEEDED >&2
	fail "addon links against glibc; expected bionic"
fi
llvm-readelf -d "$ADDON" | grep NEEDED | grep -q 'libc.so' || fail "addon does not link bionic libc.so"
llvm-readelf -d "$BIN" | grep NEEDED | grep -q 'libc.so' || fail "omp.bin does not link bionic libc.so"
llvm-readelf -d "$BIN" | grep NEEDED | grep -q 'GLIBC_' && fail "omp.bin links against glibc"
# bionic binaries run through /system/bin/linker64; a glibc interpreter means the
# compile silently targeted the host toolchain.
llvm-readelf -l "$BIN" | grep -q 'system/bin/linker64' ||
	fail "omp.bin interpreter is not bionic linker64"

strings -a "$ADDON" | grep -q 'PI_NATIVES_VERSION_STAMP:' || fail "addon carries no version stamp"

NATIVES_VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' \
	"$SRC/packages/natives/package.json")"
strings -a "$ADDON" | grep -q "PI_NATIVES_VERSION_STAMP:${NATIVES_VERSION}" ||
	fail "addon stamp is not ${NATIVES_VERSION}"

strings -a "$BIN" | grep -q 'oh-my-pi' || fail "omp.bin does not look like an oh-my-pi bundle"

echo "verify-artifacts: OK (addon $NATIVES_VERSION)"
