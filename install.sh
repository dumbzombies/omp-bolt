#!/data/data/com.termux/files/usr/bin/bash
# One-shot Termux installer for omp-bolt (oh-my-pi v18.12.6, Track A).
#
#   curl -fsSL https://raw.githubusercontent.com/dumbzombies/omp-bolt/master/install.sh | bash
#
# Downloads the release zip, verifies its checksum, unpacks it and runs the
# bundled installer. Installs into $PREFIX (no root, no compilation).
set -euo pipefail

REPO="dumbzombies/omp-bolt"
ZIP_NAME="omp-termux-aarch64.zip"
BASE="https://github.com/${REPO}/releases/latest/download"

die() {
	printf 'install: %s\n' "$*" >&2
	exit 1
}

# --- environment -------------------------------------------------------------
case ":$PREFIX:" in
*:/data/data/com.termux/files/usr:*) ;;
*) die "run this inside Termux (PREFIX must be /data/data/com.termux/files/usr)" ;;
esac
[ "$(uname -m)" = "aarch64" ] || die "unsupported arch: $(uname -m) (need aarch64)"

for cmd in curl unzip sha256sum; do
	command -v "$cmd" >/dev/null 2>&1 || {
		printf 'install: installing %s\n' "$cmd"
		pkg install -y "$cmd" >/dev/null 2>&1 || die "cannot install $cmd (run: pkg install $cmd)"
	}
done

# --- fetch and verify --------------------------------------------------------
WORK="$(mktemp -d "$PREFIX/tmp/omp-install.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

printf 'install: downloading %s\n' "$ZIP_NAME"
curl -fsSL --retry 3 -o "$WORK/$ZIP_NAME" "$BASE/$ZIP_NAME" ||
	die "download failed (no release yet? see https://github.com/$REPO/actions)"

curl -fsSL --retry 3 -o "$WORK/$ZIP_NAME.sha256" "$BASE/$ZIP_NAME.sha256" ||
	die "checksum download failed"
(
	cd "$WORK"
	sha256sum -c "$ZIP_NAME.sha256" >/dev/null
) || die "checksum mismatch for $ZIP_NAME"

unzip -q "$WORK/$ZIP_NAME" -d "$WORK/unpacked" || die "unzip failed"
(
	cd "$WORK/unpacked"
	bash install.sh
)