#!/usr/bin/env bash
# Compiler-only relocatable bundle; do not overwrite the static delivery.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT/scripts/common.sh"
cd "$ROOT"
SWITCH=${1:-default}
PREFIX="$OPAMROOT/$SWITCH"
STAGE=dist/staging/ocaml-5.5.1-arm64-windows-dynlink
rm -rf -- "$STAGE"
mkdir -p "$STAGE/bin" "$STAGE/lib" "$STAGE/licenses" "$STAGE/docs"
for exe in "$PREFIX"/bin/ocaml*.exe "$PREFIX"/bin/aarch64-w64-mingw32-ocaml*.exe; do
  case "$(basename "$exe")" in ocamlfind*|ocamlbuild*) continue ;; esac
  cp "$exe" "$STAGE/bin/"
done
cp "$PREFIX"/bin/flexlink*.exe "$PREFIX/bin/libzstd.dll" "$STAGE/bin/"
cp -a "$PREFIX/lib/ocaml" "$STAGE/lib/"
cp sources/ocaml/LICENSE "$STAGE/LICENSE"
cp sources/flexdll/LICENSE "$STAGE/licenses/flexdll-LICENSE"
cp tools/msys64/clangarm64/share/licenses/zstd/LICENSE "$STAGE/licenses/zstd-LICENSE"
cp docs/BINARY-BUNDLE.md "$STAGE/README.md"
cp docs/{FORKS,DYNAMIC-VALIDATION}.md "$STAGE/docs/"
tar -czf dist/ocaml-5.5.1-arm64-windows-dynlink-bin.tar.gz -C dist/staging "$(basename "$STAGE")"
tar -czf dist/windows-arm64-dynamic-repository.tar.gz repository
sha256sum dist/{flexdll-0.44-windows-arm64,ocaml-5.5.1-windows-arm64-dynlink}-src.tar.gz \
  dist/ocaml-5.5.1-arm64-windows-dynlink-bin.tar.gz dist/windows-arm64-dynamic-repository.tar.gz \
  > dist/SHA256SUMS-dynamic
