#!/usr/bin/env bash
# Run commands in the project's isolated MSYS2 CLANGARM64 environment.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
export MSYSTEM=CLANGARM64 MSYS2_PATH_TYPE=inherit CHERE_INVOKING=1
ROOT_WIN=$(cygpath -am "$ROOT")
mkdir -p "$ROOT/tmp"
export TMPDIR="$ROOT/tmp" TMP="$ROOT_WIN/tmp" TEMP="$ROOT_WIN/tmp"
exec "$ROOT/tools/msys64/usr/bin/bash.exe" -lc "cd '$ROOT_WIN' && export COMSPEC='C:\\Windows\\System32\\cmd.exe' DUNE_CACHE=disabled && $*"
