#!/usr/bin/env bash
# Run through scripts/msys.sh. Builds both ports from the packaged sources.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
PREFIX=${1:-"$ROOT/local"}
mkdir -p "$PREFIX" sources logs
PREFIX=$(cd "$PREFIX" && pwd)
PREFIX_WIN=$(cygpath -am "$PREFIX")
export PATH="$PREFIX/bin:$PATH" DUNE_CACHE=disabled
# Avoid an inherited switch/library path selecting a different compiler.
unset OCAMLLIB CAMLLIB OCAMLTOP_INCLUDE_PATH

# These two directories are disposable extractions, not the reviewed checkouts.
rm -rf -- sources/ocaml-5.5.1-windows-arm64 sources/opam-2.6.1-windows-arm64
tar -xf dist/ocaml-5.5.1-windows-arm64-src.tar.gz -C sources
(
  cd sources/ocaml-5.5.1-windows-arm64
  ./configure --build=aarch64-w64-mingw32 --host=aarch64-w64-mingw32 \
    --prefix="$PREFIX_WIN" --disable-shared --disable-dependency-generation \
    --with-relative-libdir --with-additional-stublibsdir \
    --enable-runtime-search --enable-runtime-search-target=fallback \
    CC=clang AR=llvm-ar RANLIB=llvm-ranlib LDFLAGS=-static
  make -j2
  make install
) > logs/build-local-compiler.log 2>&1
# FlexDLL is unavailable: provide the Unix/Str primitives used by build scripts.
"$PREFIX/bin/ocamlmktop.exe" -custom -I +unix -I +str \
  -o "$PREFIX/bin/ocaml-static.exe" unix.cma str.cma
mv -f "$PREFIX/bin/ocaml-static.exe" "$PREFIX/bin/ocaml.exe"

tar -xf dist/opam-2.6.1-windows-arm64-src.tar.gz -C sources
(
  cd sources/opam-2.6.1-windows-arm64
  bash opam-port-build.sh build "$PREFIX_WIN"
  bash opam-port-build.sh install
) > logs/build-local-opam.log 2>&1
"$PREFIX/bin/ocamlc.exe" -version
"$PREFIX/bin/ocamlopt.exe" -version
"$PREFIX/bin/opam.exe" --version
file "$PREFIX/bin/"{ocamlrun,ocamlc,ocamlopt,opam,opam-installer}.exe
printf 'Installed compiler and opam into %s\n' "$PREFIX_WIN"
