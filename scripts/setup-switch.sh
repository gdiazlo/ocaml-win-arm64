#!/usr/bin/env bash
# Run through scripts/msys.sh after scripts/build-local.sh (or use existing local/).
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
export PATH="$ROOT/local/bin:$PATH" OPAMROOT="$ROOT/opam-root" DUNE_CACHE=disabled
OPAM="$ROOT/local/bin/opam.exe"
SWITCH=${1:-windows-arm64}
if [[ ! -d sources/opam-repository/.git ]]; then
  git clone https://github.com/ocaml/opam-repository.git sources/opam-repository
fi
# Refresh local archive URLs/checksums without rebuilding the archives.
ROOT_WIN=$(cygpath -am "$ROOT")
export PROJECT_ROOT_WIN="$ROOT_WIN"
for pkg in ocaml-variants/ocaml-variants.5.5.1+windows-arm64 \
           opam-windows-arm64/opam-windows-arm64.2.6.1; do
  perl -0pi -e 's{src: "[^"]*/dist/}{src: "$ENV{PROJECT_ROOT_WIN}/dist/}' \
    "repository/packages/$pkg/opam"
done
if [[ ! -f "$OPAMROOT/config" ]]; then
  "$OPAM" init --bare -y --no-setup --disable-sandboxing \
    --no-cygwin-setup default "$ROOT_WIN/sources/opam-repository"
fi
if ! "$OPAM" repository list --all --short | grep -qx windows-arm64; then
  "$OPAM" repository add --all windows-arm64 "$ROOT_WIN/repository"
fi
"$OPAM" update windows-arm64
if ! "$OPAM" switch list --short | grep -qx "$SWITCH"; then
  "$OPAM" switch create "$SWITCH" ocaml-variants.5.5.1+windows-arm64 \
    --repos=windows-arm64,default -y --jobs=2 --no-depexts
fi
# A separate action ensures the static pkg-config environment is available
# before any library discovery rules run.
"$OPAM" install --switch="$SWITCH" -y --jobs=2 --no-depexts conf-pkg-config
"$OPAM" install --switch="$SWITCH" -y --jobs=2 --no-depexts \
  dune.3.20.2 ocamlfind.1.9.9~preview ssl.0.7.0 sqlite3.5.4.2 \
  eio.1.6 eio_windows.1.6 eio_main.1.6
# Serialize opam's large vendored build to avoid transient Windows startup errors.
"$OPAM" install --switch="$SWITCH" -y --jobs=1 --no-depexts opam-windows-arm64.2.6.1
"$OPAM" list --switch="$SWITCH" --installed
