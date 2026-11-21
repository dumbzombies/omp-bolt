#!/data/data/com.termux/files/usr/bin/bash
# Install the Track A artifact from an extracted release zip.
set -euo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
HERE="$(cd "$(dirname "$0")" && pwd)"
LIBEXEC="$PREFIX/libexec/omp"

cd "$HERE"

if [ ! -f SHA256SUMS ]; then
	echo "install: SHA256SUMS missing next to this script" >&2
	exit 1
fi
sha256sum -c --strict SHA256SUMS

install -d -m 0755 "$LIBEXEC" "$PREFIX/bin"
mkdir -p "$PREFIX/tmp"

install -m 0755 omp.bin "$LIBEXEC/omp.bin"
install -m 0644 pi_natives.android-arm64.node "$LIBEXEC/pi_natives.android-arm64.node"
install -m 0755 omp "$PREFIX/bin/omp"
# Alias: this build answers to both names.
ln -sf omp "$PREFIX/bin/omp-bolt"

echo "installed: $("$PREFIX/bin/omp" --version 2>/dev/null || echo 'omp (version check failed)')"
