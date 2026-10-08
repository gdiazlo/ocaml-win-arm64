#!/usr/bin/env bash
# Run through scripts/msys.sh, or directly in project-local CLANGARM64 Bash.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
STAGE=dist/staging/ocaml-5.5.1-windows-arm64
rm -rf -- "$STAGE"
mkdir -p "$STAGE"
git -C sources/ocaml archive HEAD | tar -x -C "$STAGE"
for f in aclocal.m4 configure.ac configure asmcomp/arm64/emit.mlp \
  runtime/arm64.S runtime/caml/fail.h runtime/win32.c otherlibs/unix/sockopt_win32.c \
  stdlib/Makefile utils/ccomp.ml tools/ocamlmklib.ml; do
  cp "sources/ocaml/$f" "$STAGE/$f"
done
git -C sources/ocaml diff --text -- aclocal.m4 configure.ac asmcomp/arm64/emit.mlp \
  runtime/arm64.S runtime/caml/fail.h runtime/win32.c otherlibs/unix/sockopt_win32.c \
  stdlib/Makefile utils/ccomp.ml tools/ocamlmklib.ml > patches/ocaml-5.5.1-windows-arm64.patch
cp patches/ocaml-5.5.1-windows-arm64.patch "$STAGE/windows-arm64.patch"
tar -czf dist/ocaml-5.5.1-windows-arm64-src.tar.gz -C dist/staging ocaml-5.5.1-windows-arm64
sha256sum dist/*.tar.gz > dist/SHA256SUMS
export ARCHIVE_SHA256=$(sha256sum dist/ocaml-5.5.1-windows-arm64-src.tar.gz | cut -d ' ' -f1)
export PROJECT_ROOT_WIN=$(cygpath -am "$ROOT")
perl -0pi -e 's{src: "[^"]*ocaml-5\.5\.1-windows-arm64-src\.tar\.gz"}{src: "$ENV{PROJECT_ROOT_WIN}/dist/ocaml-5.5.1-windows-arm64-src.tar.gz"}; s{checksum: "sha256=[^"]*"}{checksum: "sha256=$ENV{ARCHIVE_SHA256}"}' \
  repository/packages/ocaml-variants/ocaml-variants.5.5.1+windows-arm64/opam
printf 'Compiler archive and reviewable source patch generated.\n'
