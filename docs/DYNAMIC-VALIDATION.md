# Windows ARM64 dynamic validation

## Result

The **`windows-arm64-dynlink`** opam switch has now been built from the separate
compiler source archive and all requested libraries rebuilt in it. The original
static switch, installation, and five archives are preserved.

This remains experimental. The integration runs below passed, but the extended
upstream batch required two isolated retries; it was **not a clean batch**.

## Source package and bootstrap

Compiler package:
`repository/packages/ocaml-variants/ocaml-variants.5.5.1+windows-arm64-dynlink/opam`.
It configures `--with-flexdll=flexdll`, bootstraps the bundled wrapper with the
shipped OCaml bytecode, then builds the native wrapper/compiler. A prebuilt
FlexDLL or existing OCaml compiler is not a package dependency.

A fresh switch creation succeeded, followed by a successful source compiler
reinstallation and dependent library rebuild. The final build tree is retained
under `opam-root/windows-arm64-dynlink/.opam-switch/build/` for inspection.
Compiler configuration reports `supports_shared_libraries=true`,
`native_dynlink=true`, `architecture=arm64`, and `system=mingwarm64`.

Evidence: `logs/setup-dynamic-switch.log`,
`logs/dynamic-compiler-package-reinstall.log`,
`logs/dynamic-switch-config.log`.

The original virtual `ocaml.5.5.1` metadata now accepts either variant. This does
not change the static switch invariant or rebuild that switch. The old compiler
source/binary archives have not been regenerated.

## Fresh library and workflow tests

`scripts/test-dynamic-switch.sh` passed after the full source reinstallation:

- Compiler smoke tests in native and ordinary bytecode executables: ABI, Unix,
  GC, domains/atomics, effects, exceptions, marshal, math, and system threads.
- Winsock timeout regressions, Unicode filesystem operations through the dynamic
  toplevel, and native packed modules/libraries.
- Dune **`(modes exe byte)`**, not `byte_complete` or `-custom`, for FFI, SQLite,
  SSL, and Eio. The bytecode tests run through the switch's native ARM64 runtime
  and load actual C-stub DLLs.
- FFI integer/float arguments, callbacks with GC, callback exceptions, and
  exceptions raised from C.
- SQLite prepared statements, UTF-8, int64, blobs, and rollback.
- Verified localhost TLS 1.3, bidirectional threaded I/O, and GC during a live SSL
  connection. Certificates are regenerated for each validation run.
- Eio's upstream Windows backend: fibers/promises/timers, filesystem operations,
  domain manager, and asynchronous localhost TCP.
- Actual interactive findlib **`#require`** of SQLite, SSL, and Eio, then all three
  integration tests in the toplevel.
- ARM64 PE checks on compiler/runtime/FlexDLL, C-stub DLLs, and native applications.

These are now source-built package tests, not just the earlier manual builds.
Main logs: `logs/dynamic-switch-validation.log`,
`logs/dynamic-interactive.log`.

### Eio DLL dependency fix

The first Eio ordinary-bytecode run failed with
`cannot load shared library dlleio_unix_stubs: Cannot resolve setsockopt`.
`eio_windows` depends on `eio.unix`; the latter's stub DLL did not link Winsock.
Native linking hid this because Unix already brings Winsock into the executable.

The isolated repository override
`repository/packages/eio/eio.1.6/opam` sets
`FLEXLINKFLAGS="-lws2_32"` during Eio's build. Eio was reinstalled and the tests
passed. **No Eio, SSL, or SQLite binding source changes were made.** The override
is limited to Windows ARM64; its flag is irrelevant to the old static compiler.

## Direct Windows execution and C-library DLLs

`scripts/test-dynamic-windows.ps1` runs the already-built tests with PATH limited
to the switch's `bin` and Windows system directories. **All tests passed**,
without MSYS or compiler-toolchain directories in PATH.

This caught real deployment dependencies hidden by the build environment:

- The bytecode runtime imports **`libzstd.dll`**. The dynamic compiler package
  now installs the native DLL and its BSD license alongside its runtime.
- SQLite and OpenSSL import **`libsqlite3-0.dll`**, **`libssl-3-arm64.dll`**, and
  **`libcrypto-3-arm64.dll`**. SDK setup stages those native runtime dependencies
  in the dynamic switch's `bin`, with notices/licenses, using
  `scripts/stage-dynamic-runtime-dlls.sh`.

Staging these dependencies is part of `setup-dynamic-switch.sh`; it is not an
upstream binding patch or a system-wide installation. When distributing an
application outside this SDK, supply its dependent C-library DLLs next to it or
through the application's documented DLL search path. Do not assume that
`pkg-config --static` alone forces FlexDLL to choose static archives.

Evidence: `logs/dynamic-windows-direct-tests.log`,
`logs/dynamic-runtime-dlls.log`, `logs/dynamic-library-imports.log`.
Initial failures are recorded in `logs/dynamic-windows-bytecode-diagnostics.log`
and the dependency-import logs.

## Extended unmodified upstream tests

`scripts/test-upstream-dynamic.sh` builds the upstream test driver in the separate
dynamic compiler tree, copies unchanged fixtures from the full clone (release
archives omit them), and runs `tests/upstream-dynamic-list.txt`.

Coverage includes the previous compiler/GC/effects suite plus C API, ephemeron
C API, system threads, bytecode/native Dynlink, plugin domains, initialization
order, packed/private plugins, native plugin C FFI/high arity, and regression
cases. No expected outputs or test source files were altered.

Initial complete batch: **179 considered; 166 passed, 11 skipped, 2 failed**.

- `lib-dynlink-domains/main.ml`: a Clang assembly invocation failed without an
  instruction diagnostic. The retained assembly compiled on immediate retry,
  and the entire unchanged domain/plugin test passed in isolation.
- `lib-dynlink-pr14323/test.ml`: rewriting a DLL during repeated failed loads
  encountered Windows `Permission denied`. The entire unchanged replacement
  test also passed on isolated retry. This is an intermittent file-sharing/race
  result, **not an established permanent Windows limitation**.

Thus **all 168 non-skipped tests have passed**, but only across the batch and
retries. Do not describe this as 168 passes in one clean batch or claim that
startup/file-sharing reliability has been solved. The earlier sporadic
0xC0000142 issue remains independently unconfirmed.

Skips cover unsupported Windows signal/fork cases and selected thread/socket
conditions; the skipped file list is preserved in the batch log.

Logs: `logs/upstream-dynamic-tests.log`,
`logs/upstream-dynamic-domain-retry.log`,
`logs/upstream-dynamic-assembler-retry.log`,
`logs/upstream-dynamic-replacement-retry.log`.

## Relocation, native plugins, and artifacts

A separate compiler-only binary archive is now in
`dist/ocaml-5.5.1-arm64-windows-dynlink-bin.tar.gz`. It contains the standard
libraries and DLLs, FlexDLL wrapper/support objects, native zstd DLL, and licenses.
It does **not** claim to bundle findlib or all third-party opam libraries.

Extraction under **`dist/dynamic relocation test/`** passed:
executable-relative stdlib lookup; native and ordinary-bytecode compiler smoke
tests; dynamically loaded C FFI; and a native `.cmxs` plugin with a Unicode
filename. The plugin exercises host globals, registered roots across moving GC,
C callbacks, exceptions, domains, and effects. Output/build paths contain spaces.

Evidence: `logs/dynamic-relocation-tests.log`.

`dist/windows-arm64-dynamic-repository.tar.gz` contains the updated package
metadata. The dynamic source archives remain unchanged; the compiler package's
runtime-DLL installation is a metadata change. Checksums are separate in
`dist/SHA256SUMS-dynamic`; all five original `dist/SHA256SUMS` entries still pass.

## Reproduce

From the project root:

```sh
bash scripts/msys.sh 'bash scripts/setup-dynamic-switch.sh'
bash scripts/msys.sh 'bash scripts/test-dynamic-switch.sh'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/test-dynamic-windows.ps1
bash scripts/msys.sh 'bash scripts/test-upstream-dynamic.sh'
bash scripts/msys.sh 'bash scripts/package-dynamic-binary.sh'
bash scripts/msys.sh 'bash scripts/test-dynamic-relocation.sh'
```

Compiler/library builds use two jobs; do not run the large vendored opam build
in parallel. Existing native opam 2.6.1 remains the package manager. No additional
opam source changes or user profile changes were needed.

Remaining work: repeat stress batches and diagnose intermittent process/file
failures, test Intel FlexDLL regressions on suitable machines, cover uncommon
ARM64 deferred relocation kinds, and obtain human review before publishing or
submitting upstream. The investigation and implementation are AI-assisted.
