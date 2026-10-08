#!/usr/bin/env bash
# Isolated source build of the dynamic variant. Does not touch local/ or the opam root.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT/scripts/common.sh"
cd "$ROOT"
export PATH="$ROOT/local-dynamic/flexdll:$OPAMROOT_UNIX/windows-arm64/bin:$PATH"
unset OCAMLLIB CAMLLIB CAML_LD_LIBRARY_PATH OCAMLTOP_INCLUDE_PATH FLEXDIR
make -C sources/flexdll -j1 all CHAINS=mingwarm64 MSVC_DETECT=0 RC=windres
mkdir -p local-dynamic/flexdll
cp sources/flexdll/{flexlink.exe,flexdll.h,flexdll_mingwarm64.o,flexdll_initer_mingwarm64.o} local-dynamic/flexdll/
(cd sources/ocaml && autoconf)
BUILD=sources/ocaml-windows-arm64-dynamic
if [[ ${1:-} != --resume ]]; then
  rm -rf -- "$BUILD"
  mkdir -p "$BUILD"
  git -C sources/ocaml archive HEAD | tar -xf - -C "$BUILD"
  # Snapshot tracked edits directly: Git's Windows EOL attributes can make
  # archive output differ from the patch context. Generated configure is binary.
  while IFS= read -r -d '' file; do
    mkdir -p "$BUILD/$(dirname "$file")"
    cp "sources/ocaml/$file" "$BUILD/$file"
  done < <(git -C sources/ocaml diff --name-only -z HEAD)
  (
    cd "$BUILD"
    ./configure --build=aarch64-w64-mingw32 --host=aarch64-w64-mingw32 \
      --prefix="$(cygpath -am "$ROOT/local-dynamic")" --enable-shared \
      --disable-dependency-generation --with-relative-libdir \
      --with-additional-stublibsdir --enable-runtime-search \
      --enable-runtime-search-target=fallback \
      CC=clang AR=llvm-ar RANLIB=llvm-ranlib
  ) > logs/ocaml-dynamic-configure.log 2>&1
fi
make -C "$BUILD" -j2 > logs/ocaml-dynamic-build.log 2>&1
make -C "$BUILD" install > logs/ocaml-dynamic-install.log 2>&1
local-dynamic/bin/ocamlopt.exe -config
file local-dynamic/bin/{ocamlrun,ocamlc,ocamlopt}.exe
