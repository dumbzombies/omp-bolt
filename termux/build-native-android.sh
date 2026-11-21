#!/usr/bin/env bash
# Build the bionic (Android/Termux) pi_natives addon with the NDK.
#
# Requires: OMP_SRC (patched checkout), OUT (artifact dir),
#           ANDROID_NDK_HOME (NDK r27c), cargo with aarch64-linux-android std.
set -euo pipefail

SRC="${OMP_SRC:?OMP_SRC must point at the patched checkout}"
OUT="${OUT:?OUT must point at the artifact directory}"
NDK="${ANDROID_NDK_HOME:?ANDROID_NDK_HOME must point at the NDK}"

API=24
TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/linux-x86_64"
export PATH="$TOOLCHAIN/bin:$PATH"
export CC_aarch64_linux_android="$TOOLCHAIN/bin/aarch64-linux-android${API}-clang"
export CXX_aarch64_linux_android="$TOOLCHAIN/bin/aarch64-linux-android${API}-clang++"
export AR_aarch64_linux_android="$TOOLCHAIN/bin/llvm-ar"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$CC_aarch64_linux_android"
export CMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake"
export ANDROID_ABI=arm64-v8a
export ANDROID_PLATFORM=android-$API
export CMAKE_POLICY_VERSION_MINIMUM=3.5
export PCRE2_SYS_STATIC=1
export RUSTC_BOOTSTRAP=1
# 16 KB page alignment is required by Android 15+ devices.
export RUSTFLAGS="-C target-cpu=generic -C link-arg=-Wl,-z,max-page-size=16384"

mkdir -p "$OUT"

cd "$SRC/crates/pi-natives"
npx --yes --package @napi-rs/cli@3.7.2 napi build \
	--manifest-path Cargo.toml \
	--package-json-path ../../packages/natives/package.json \
	--target aarch64-linux-android \
	--platform --no-js --dts index.d.ts \
	-o "$OUT" --profile local

ADDON="$OUT/pi_natives.android-arm64.node"
if [ ! -f "$ADDON" ]; then
	# napi derives the filename from the target triple; the loader resolves the
	# platform tag literal, so rename whatever android .node it emitted.
	shopt -s nullglob
	candidates=("$OUT"/pi_natives.*android*.node)
	shopt -u nullglob
	if [ "${#candidates[@]}" -ne 1 ]; then
		echo "build-native-android: no android addon produced in $OUT" >&2
		ls -l "$OUT" >&2
		exit 1
	fi
	mv "${candidates[0]}" "$ADDON"
fi

llvm-strip --strip-unneeded "$ADDON"
cd "$SRC" && bun scripts/stamp-native-version.ts "$ADDON"
echo "build-native-android: $ADDON"
