#!/usr/bin/env bash
# Stage native C-library DLLs next to this switch's runtime, not in system PATH.
# These are SDK/application runtime dependencies, not the MSYS Unix runtime.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
SWITCH=${1:-windows-arm64-dynlink}
export OPAMROOT="$ROOT/opam-root"
version=$(local/bin/opam.exe var --switch="$SWITCH" ocaml-variants:version)
[[ $version == 5.5.1+windows-arm64-dynlink ]] || { echo 'Refusing to modify a non-dynamic switch' >&2; exit 1; }
PREFIX="$ROOT/opam-root/$SWITCH"
DLLDIR="$ROOT/tools/msys64/clangarm64/bin"
for dll in libzstd.dll libsqlite3-0.dll libssl-3-arm64.dll libcrypto-3-arm64.dll; do
  info=$(file "$DLLDIR/$dll")
  echo "$info"
  [[ $info == *ARM64* ]] || { echo "Not ARM64: $dll" >&2; exit 1; }
  cp "$DLLDIR/$dll" "$PREFIX/bin/$dll"
done
DOC="$PREFIX/share/doc/windows-arm64-runtime"
mkdir -p "$DOC"
cp tools/msys64/clangarm64/share/licenses/openssl/LICENSE "$DOC/openssl-LICENSE"
cp tools/msys64/clangarm64/share/licenses/zstd/LICENSE "$DOC/zstd-LICENSE"
printf '%s\n' \
  'Runtime DLLs: OpenSSL (Apache-2.0), zstd (BSD-3-Clause), SQLite (public domain).' \
  'Sources/toolchain versions are recorded in the project documentation.' \
  'SQLite dedicates its deliverable code to the public domain: https://sqlite.org/copyright.html' \
  > "$DOC/NOTICE"
sha256sum "$PREFIX/bin/"{libzstd,libsqlite3-0,libssl-3-arm64,libcrypto-3-arm64}.dll
