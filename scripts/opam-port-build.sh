#!/usr/bin/env bash
# Included at the root of the patched opam source archive.
set -euo pipefail
case "${1:-}" in
  build)
    prefix=$(cygpath -am "$2")
    jobs=${3:-1}
    export DUNE_CACHE=disabled
    ./configure --with-vendored-deps --without-dune --prefix="$prefix" CC=clang CXX=clang++
    patch -d src_ext/dune-local -p1 < windows-arm64-dune.patch
    # src_ext/Makefile otherwise bootstraps with all available processors.
    (cd src_ext/dune-local && ocaml boot/bootstrap.ml -j "$jobs")
    make -j"$jobs" DUNE_ARGS="-j$jobs"
    ;;
  install)
    make install
    ;;
  *) echo 'usage: opam-port-build.sh build PREFIX [JOBS] | install' >&2; exit 2 ;;
esac
