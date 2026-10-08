#!/usr/bin/env bash
# Refresh source artifacts before running this if upstream patches changed.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
tar -czf dist/windows-arm64-repository.tar.gz repository
sha256sum dist/*.tar.gz > dist/SHA256SUMS
sha256sum -c dist/SHA256SUMS
printf '\nDistributable archives:\n'
ls -lh dist/*.tar.gz
