#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
STAGE=dist/staging/opam-2.6.1-windows-arm64
rm -rf -- "$STAGE"
mkdir -p "$STAGE" sources/pristine-opam
tar -xf downloads/opam-full-2.6.1.tar.gz -C "$STAGE" --strip-components=1
tar -xf downloads/opam-full-2.6.1.tar.gz -C sources/pristine-opam --strip-components=1
for f in configure configure.ac src/core/opamStd.ml src/tools/dune \
  src/tools/windows-arm64.rc src/tools/windows-arm64.manifest; do
  cp "sources/opam-full-2.6.1/$f" "$STAGE/$f"
done
# Reviewable patch against the original full release. Generated configure omitted.
: > patches/opam-2.6.1-windows-arm64.patch
for f in configure.ac src/core/opamStd.ml src/tools/dune; do
  diff -u --label "a/$f" --label "b/$f" "sources/pristine-opam/$f" \
    "sources/opam-full-2.6.1/$f" >> patches/opam-2.6.1-windows-arm64.patch || test "$?" -eq 1
done
for f in src/tools/windows-arm64.rc src/tools/windows-arm64.manifest; do
  diff -u --label /dev/null --label "b/$f" /dev/null \
    "sources/opam-full-2.6.1/$f" >> patches/opam-2.6.1-windows-arm64.patch || test "$?" -eq 1
done
cp repository/packages/dune/dune.3.20.2/files/windows-arm64.patch "$STAGE/windows-arm64-dune.patch"
cp scripts/opam-port-build.sh "$STAGE/opam-port-build.sh"
tar -czf dist/opam-2.6.1-windows-arm64-src.tar.gz -C dist/staging opam-2.6.1-windows-arm64
bash scripts/package-opam-binary.sh
export ARCHIVE_SHA256=$(sha256sum dist/opam-2.6.1-windows-arm64-src.tar.gz | cut -d ' ' -f1)
export PROJECT_ROOT_WIN=$(cygpath -am "$ROOT")
perl -0pi -e 's{src: "[^"]*opam-2\.6\.1-windows-arm64-src\.tar\.gz"}{src: "$ENV{PROJECT_ROOT_WIN}/dist/opam-2.6.1-windows-arm64-src.tar.gz"}; s{checksum: "sha256=[^"]*"}{checksum: "sha256=$ENV{ARCHIVE_SHA256}"}' \
  repository/packages/opam-windows-arm64/opam-windows-arm64.2.6.1/opam
sha256sum dist/*.tar.gz > dist/SHA256SUMS
