# Validation results

Validated on this Windows 11 ARM64 host with the project-local CLANGARM64 tools.
This records functional coverage, not production certification or a complete
upstream test-suite run.

## Dynamic validation update

The source-built `windows-arm64-dynlink` switch, Dune ordinary bytecode,
interactive SQLite/SSL/Eio loading, direct Windows execution, and relocated
dynamic compiler bundle now pass. The expanded upstream batch required two
isolated retries. See **[DYNAMIC-VALIDATION.md](DYNAMIC-VALIDATION.md)** for full
results and remaining reliability limits. The record below describes the
preserved original static delivery.

## Compiler and package installation

- OCaml **5.5.1** bytecode and native compilers execute locally.
- Runtime, compilers, opam, and all complete test executables were checked as
  **ARM64 PE32+**, not x86/x64 binaries under emulation.
- `ocaml-variants.5.5.1+windows-arm64` was built **from its source archive** into a
  fresh switch named `windows-arm64`. It was subsequently reinstalled with the
  packing, static-library, and socket-timeout fixes; all 39 dependent packages
  rebuilt successfully. See `logs/opam-compiler-final-reinstall.log`.
- `opam-windows-arm64.2.6.1` was built and installed from its source archive.
  `local/bin/opam.exe --version` reports **2.6.1**. Both full `make` and
  `make install` succeeded; the installer runs without unwanted UAC elevation.
  A later two-job rebuild had transient 0xC0000142 process-startup failures;
  rebuilding the final source archive with one job succeeded. The package now
  honors opam's job count, and the setup script uses one job for this build.
- The compiler binary archive was extracted under **`dist/relocation test/`**.
  Its standard library resolved to the extracted prefix. Native and custom
  bytecode smoke programs compiled and ran, including output paths containing
  spaces; the relocated Unix toplevel and socket-timeout regression passed.
  See `logs/relocation-tests.log`.

## Project regression and integration tests

`bash scripts/msys.sh 'bash scripts/test.sh'` passed after clean rebuilding the
Dune test projects. The complete output is in `logs/validation.log`.

| Area | Native | Bytecode / static toplevel | Coverage |
|---|---|---|---|
| Compiler | PASS | PASS | Windows/64-bit ABI, integer arithmetic, float C calls, exceptions, marshal, Unix, GC, domains/atomics, effects, system threads/mutexes |
| Native packing | PASS | n/a | Direct packed unit and packed unit inside another native library |
| C FFI | PASS | PASS | 10 integer arguments, 10 unboxed float arguments, callbacks with moving GC, callback exceptions, exceptions raised from C |
| Windows socket timeouts | PASS | PASS | Seconds/milliseconds roundtrip, negative/NaN/infinity rejection, actual recv expiration at approximately 0.19s for a 0.2s timeout |
| UTF-8 filenames | n/a | PASS | Create/stat/rename/list/read/remove non-ASCII Windows filenames using the supplied Unix toplevel |
| SQLite3 5.4.2 | PASS | PASS | SQLite 3.53.4, SQL, prepared statements, UTF-8, int64, blobs, transaction rollback |
| SSL 0.7.0 | PASS | PASS | OpenSSL 3.6.5, local TLS 1.3 handshake, certificate and hostname verification, bidirectional threaded I/O, GC with a live SSL object |
| Eio/Eio_windows/Eio_main 1.6 | PASS | PASS | Actual Windows backend; fibers/promises/timers, file I/O/removal, domain manager, asynchronous localhost TCP |

The SSL fixture is a generated, short-lived localhost test certificate. There is
no dependence on external network services. Native executables and Dune
`byte_complete` executables were also run directly from PowerShell using
`scripts/test-windows.ps1`, without entering MSYS2. All passed, including while
binary bundles were being assembled. See `logs/windows-direct-tests.log`.

## Selected unmodified upstream OCaml tests

`tests/upstream-list.txt` selects nine upstream directories: basic, basic-float,
basic-manyargs, callback, effects, lib-domain, lib-atomic, lib-bigarray, backtrace.

The first complete run after building the missing expect helper reported:
**119 passed, 3 skipped, 0 failed**. A later repeat after the socket fix reported
**118 passed, 3 skipped, 1 failure**: `basic/sets.ml` encountered Windows process
startup status **0xC0000142 (STATUS_DLL_INIT_FAILED)**. An immediate isolated
rerun of that unmodified test passed. Thus all 119 selected non-skipped tests
have passed, but the later batch required one retry; this host/startup flakiness
is not hidden or counted as a clean later batch.

- Batch log: `logs/upstream-tests.log` (also preserved as
  `logs/upstream-tests-dll-init-failure.log`).
- Isolated retry: `logs/upstream-sets-retry.log` (1 passed, 0 failed).
- Expected skips: native Dynlink and two signal-handler tests unsupported on
  this Windows/static-linking configuration.

An initial test attempt also lacked `testsuite/tools/expect.exe`, causing three
basic-test harness failures; building the helper resolved them. The upstream
Windows-Unicode test's toplevel action invokes plain `ocamlrun` with `unix.cma`,
which cannot access the custom toplevel's statically linked Unix primitives.
That action was excluded from the selected list; `tests/unicode_smoke.ml` instead
checks the delivered static Unix toplevel. No upstream expected results were
modified. The initial diagnostic log is `logs/upstream-tests-initial.log`.

## Reproduction and evidence

- Environment: `scripts/msys.sh`; temporary build files are also project-local.
- Source builds: `scripts/build-local.sh`, `scripts/opam-port-build.sh`.
- Switch/library installation: `scripts/setup-switch.sh`.
- Project tests: `scripts/test.sh`, `scripts/test-windows.ps1`.
- Upstream subset: `scripts/test-upstream.sh`.
- Binary relocation: `scripts/test-relocation.sh`.
- Packaging: `scripts/package-compiler.sh`, `scripts/package-compiler-binary.sh`,
  `scripts/package-opam.sh`, `scripts/package-results.sh`.
- Toolchain versions: `logs/toolchain-versions.txt`.
- Package installation/reinstallation: `logs/opam-package-install.log`,
  `logs/opam-compiler-final-reinstall.log`, `logs/library-config-reinstall.log`,
  `logs/opam-package-final-reinstall.log` (final archive, successful serial build).
- Startup diagnostics: `logs/memory-diagnostics.txt`,
  `logs/compiler-startup-repeat.log` (20 sequential compiler startups passed).
- Installed package list and switch export: `logs/installed-packages.txt`,
  `logs/windows-arm64-switch.export`.
- Archive checksums: `dist/SHA256SUMS`.

The individual fresh source-package builds have been exercised. The convenience
`build-local.sh` wrapper has not itself been run end-to-end as a single command;
it uses those build steps and is supplied for reproduction. See
`docs/PORTING.md` for static-linking limits and unvalidated areas.
