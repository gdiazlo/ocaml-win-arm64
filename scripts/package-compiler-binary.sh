#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
SWITCH=${1:-windows-arm64}
PREFIX="opam-root/$SWITCH"
STAGE=dist/staging/ocaml-5.5.1-arm64-windows
rm -rf -- "$STAGE"
mkdir -p "$STAGE/bin" "$STAGE/lib"
for exe in "$PREFIX"/bin/ocaml*.exe "$PREFIX"/bin/aarch64-w64-mingw32-ocaml*.exe; do
  case "$(basename "$exe")" in ocamlfind*|ocamlbuild*) continue ;; esac
  cp "$exe" "$STAGE/bin/"
done
cp -a "$PREFIX/lib/ocaml" "$STAGE/lib/"
cp sources/ocaml/LICENSE "$STAGE/LICENSE"
cp docs/BINARY-BUNDLE.md "$STAGE/README.md"
tar -czf dist/ocaml-5.5.1-arm64-windows-bin.tar.gz -C dist/staging ocaml-5.5.1-arm64-windows
sha256sum dist/*.tar.gz > dist/SHA256SUMS
