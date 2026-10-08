#!/usr/bin/env bash
# Interactive CLANGARM64 Bash with your own opam root and switch, starting in
# the directory you called it from.
# Usage: bash scripts/shell.sh [switch]   (default: your opam root's current switch)
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export OCAML_PROJECT_SWITCH=${1:-}
export OCAML_SHELL_CWD=$(cygpath -am "$PWD")
exec bash "$ROOT/scripts/msys.sh" 'exec bash --rcfile scripts/shellrc.sh -i'
