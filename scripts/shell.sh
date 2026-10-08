#!/usr/bin/env bash
# Interactive CLANGARM64 Bash with the project's opam root and switch.
# Usage: bash scripts/shell.sh [switch]   (default: the opam root's current switch)
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT/scripts/common.sh"
export OCAML_PROJECT_SWITCH=${1:-}
exec bash "$ROOT/scripts/msys.sh" 'exec bash --rcfile scripts/shellrc.sh -i'
