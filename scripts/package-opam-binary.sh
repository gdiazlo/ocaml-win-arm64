#!/usr/bin/env bash
# Can refresh binaries without changing the validated source archive/checksum.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
STAGE=dist/staging/opam-2.6.1-arm64-windows
rm -rf -- "$STAGE"
mkdir -p "$STAGE/licenses"
cp local/bin/opam{,-installer,-putenv}.exe "$STAGE/"
cp sources/opam-full-2.6.1/LICENSE "$STAGE/LICENSE"
cp docs/BINARY-BUNDLE.md "$STAGE/README.md"
(
  cd sources/opam-full-2.6.1
  find src_ext -type f \( -iname 'license*' -o -iname 'copying*' \) -exec \
    cp --parents '{}' "$ROOT/$STAGE/licenses/" \;
)
tar -czf dist/opam-2.6.1-arm64-windows-bin.tar.gz -C dist/staging opam-2.6.1-arm64-windows
sha256sum dist/*.tar.gz > dist/SHA256SUMS
