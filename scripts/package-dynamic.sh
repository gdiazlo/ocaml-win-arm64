#!/usr/bin/env bash
# Preserve the five original static artifacts. Export separate fork sources.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
snapshot() {
  local project=$1 stage=$2
  rm -rf -- "$stage"
  mkdir -p "$stage"
  git -C "sources/$project" archive HEAD | tar -xf - -C "$stage"
  while IFS= read -r -d '' file; do
    mkdir -p "$stage/$(dirname "$file")"
    cp "sources/$project/$file" "$stage/$file"
  done < <(git -C "sources/$project" diff --name-only -z HEAD)
}
FLEX=dist/staging/flexdll-0.44-windows-arm64
COMPILER=dist/staging/ocaml-5.5.1-windows-arm64-dynlink
snapshot flexdll "$FLEX"
cp sources/flexdll/test/arm64.c "$FLEX/test/"
{
  git -C sources/flexdll diff --text HEAD
  git -C sources/flexdll diff --no-index -- /dev/null test/arm64.c || [[ $? == 1 ]]
} > patches/flexdll-0.44-windows-arm64.patch
git -C sources/ocaml diff --text HEAD -- ':!configure' \
  > patches/ocaml-5.5.1-windows-arm64-dynlink.patch
snapshot ocaml "$COMPILER"
mkdir -p "$COMPILER/flexdll"
cp -a "$FLEX/." "$COMPILER/flexdll/"
cp patches/ocaml-5.5.1-windows-arm64-dynlink.patch "$COMPILER/windows-arm64.patch"
cp patches/flexdll-0.44-windows-arm64.patch "$COMPILER/flexdll/windows-arm64.patch"
tar -czf dist/flexdll-0.44-windows-arm64-src.tar.gz -C dist/staging "$(basename "$FLEX")"
tar -czf dist/ocaml-5.5.1-windows-arm64-dynlink-src.tar.gz -C dist/staging "$(basename "$COMPILER")"
archives=(dist/flexdll-0.44-windows-arm64-src.tar.gz dist/ocaml-5.5.1-windows-arm64-dynlink-src.tar.gz)
for archive in dist/ocaml-5.5.1-arm64-windows-dynlink-bin.tar.gz dist/windows-arm64-dynamic-repository.tar.gz; do
  [[ ! -f $archive ]] || archives+=("$archive")
done
sha256sum "${archives[@]}" > dist/SHA256SUMS-dynamic
printf 'Separate fork sources and patches generated; static archives unchanged.\n'
