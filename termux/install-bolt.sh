#!/data/data/com.termux/files/usr/bin/bash
# Install the Track B artifact from an extracted release zip.
set -euo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
HERE="$(cd "$(dirname "$0")" && pwd)"
LIBEXEC="$PREFIX/libexec/omp-bolt"

cd "$HERE"

if [ ! -f SHA256SUMS ]; then
	echo "install-bolt: SHA256SUMS missing next to this script" >&2
	exit 1
fi
sha256sum -c --strict SHA256SUMS

install -d -m 0755 "$LIBEXEC" "$PREFIX/bin"
mkdir -p "$PREFIX/tmp"

install -m 0755 omp-bolt "$LIBEXEC/omp-bolt"
install -m 0644 pi_natives.linux-arm64.node "$LIBEXEC/pi_natives.linux-arm64.node"
install -m 0755 omp-bolt-launcher "$PREFIX/bin/omp-bolt"

if command -v patchelf >/dev/null; then
	patchelf --set-interpreter "$PREFIX/glibc/lib/ld-linux-aarch64.so.1" "$LIBEXEC/omp-bolt"
	touch "$LIBEXEC/.interpreter-patched"
else
	echo "patchelf missing: install it (pkg install patchelf) or the launcher will use glibc-runner's loader" >&2
fi

echo "installed: $("$PREFIX/bin/omp-bolt" --version 2>/dev/null || echo 'omp-bolt (version check failed)')"
