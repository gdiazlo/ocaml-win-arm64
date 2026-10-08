#!/usr/bin/env bash
# Fresh source-archive compiler build, preserving the static switch/install.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
export OPAMROOT="$ROOT/opam-root" DUNE_CACHE=disabled OPAMKEEPLOGS=true
unset OCAMLLIB CAMLLIB CAML_LD_LIBRARY_PATH OCAMLTOP_INCLUDE_PATH FLEXDIR
OPAM="$ROOT/local/bin/opam.exe"
SWITCH=${1:-windows-arm64-dynlink}
export PROJECT_ROOT_WIN=$(cygpath -am "$ROOT")
perl -0pi -e 's{src: "[^"]*/dist/}{src: "$ENV{PROJECT_ROOT_WIN}/dist/}' \
  repository/packages/ocaml-variants/ocaml-variants.5.5.1+windows-arm64-dynlink/opam
"$OPAM" update windows-arm64
if ! "$OPAM" switch list --short | grep -qx "$SWITCH"; then
  "$OPAM" switch create "$SWITCH" ocaml-variants.5.5.1+windows-arm64-dynlink \
    --repos=windows-arm64,default -y --jobs=2 --no-depexts
fi
"$OPAM" exec --switch="$SWITCH" -- ocamlopt.exe -config
"$OPAM" install --switch="$SWITCH" -y --jobs=2 --no-depexts conf-pkg-config
"$OPAM" install --switch="$SWITCH" -y --jobs=2 --no-depexts \
  dune.3.20.2 ocamlfind.1.9.9~preview ssl.0.7.0 sqlite3.5.4.2 \
  eio.1.6 eio_windows.1.6 eio_main.1.6
bash scripts/stage-dynamic-runtime-dlls.sh "$SWITCH"
"$OPAM" list --switch="$SWITCH" --installed
