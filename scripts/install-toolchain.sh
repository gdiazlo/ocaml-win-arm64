#!/usr/bin/env bash
# Run inside the project-local MSYS2 CLANGARM64 environment.
set -euo pipefail
[[ ${MSYSTEM:-} == CLANGARM64 ]] || { echo 'Use scripts/msys.sh' >&2; exit 2; }
# A core MSYS update may terminate this shell; rerun this script in that case.
pacman -Syu --noconfirm
pacman -S --noconfirm --needed make autoconf automake patch diffutils tar git perl \
  mingw-w64-clang-aarch64-clang mingw-w64-clang-aarch64-lld \
  mingw-w64-clang-aarch64-llvm mingw-w64-clang-aarch64-pkgconf \
  mingw-w64-clang-aarch64-zstd mingw-w64-clang-aarch64-openssl \
  mingw-w64-clang-aarch64-sqlite3
clang -dumpmachine
