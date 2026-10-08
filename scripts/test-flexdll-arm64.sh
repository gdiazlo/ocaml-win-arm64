#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT/scripts/common.sh"
cd "$ROOT"
export PATH="$OPAMROOT_UNIX/windows-arm64/bin:$PATH"
make -C sources/flexdll -j1 all CHAINS=mingwarm64 MSVC_DETECT=0 RC=windres
BUILD="$ROOT/tests/flexdll-arm64"
mkdir -p "$BUILD"
cd "$BUILD"
SRC="$ROOT/sources/flexdll/test/arm64.c"
FLEX="$ROOT/sources/flexdll/flexlink.exe"
clang -O2 -DTEST_HOST -I"$ROOT/sources/flexdll" -c "$SRC" -o host.o
"$FLEX" -chain mingwarm64 -exe -o host.exe host.o
clang -O2 -c "$SRC" -o missing.o
"$FLEX" -chain mingwarm64 -o arm64-missing.dll missing.o
for imports in direct dllimport; do
  flags=()
  if [[ $imports == dllimport ]]; then flags=(-DTEST_DLLIMPORT); fi
  clang -O2 -DTEST_PLUGIN1 "${flags[@]}" -c "$SRC" -o one.o
  clang -O2 -DTEST_PLUGIN2 "${flags[@]}" -c "$SRC" -o two.o
  "$FLEX" -chain mingwarm64 -o arm64-one.dll one.o
  "$FLEX" -chain mingwarm64 -o arm64-two.dll two.o
  echo "Testing $imports imports"
  ./host.exe
  file host.exe arm64-{one,two,missing}.dll
  llvm-objdump -d arm64-one.dll > "$ROOT/logs/flexdll-arm64-$imports-linked.txt"
done
