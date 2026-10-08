# Port design and scope

The original static port is described below. The separate dynamic compiler and
minimal FlexDLL fork changes are documented in **[FORKS.md](FORKS.md)**; current
source-package/library validation is in
**[DYNAMIC-VALIDATION.md](DYNAMIC-VALIDATION.md)**.

## Baselines and toolchain

- OCaml **5.5.1**, commit `46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`.
- opam **2.6.1**, latest stable release checked on 2026-10-07.
- opam-repository snapshot: `8be50539770551c7731762640e5c7c39ae1666c1`.
- Project-local MSYS2 CLANGARM64; Clang/LLVM **22.1.8**, target
  `aarch64-w64-windows-gnu`, MinGW-w64/UCRT.
- ARM64 OpenSSL **3.6.5**, SQLite **3.53.4**, zstd **1.5.7**.

Exact installed toolchain versions are recorded in `logs/toolchain-versions.txt`.
The original Git/MSYS shell and MSYS2's Unix tools are x64-emulated. This does not
make the compiler a cross-architecture x64 build: compiler/runtime/opam and all
validated complete executables have the ARM64 PE machine type.

## OCaml changes

The reviewable patch is `patches/ocaml-5.5.1-windows-arm64.patch`. It excludes the
large regenerated `configure`, which is included in the source archive.

1. **Configuration:** accept `aarch64-w64-mingw32`, permit Clang for MinGW,
   choose the existing ARM64 backend with `Config.system = "mingwarm64"`, and
   allow shared-library/FlexDLL support to be disabled for this target. Use the
   Unicode entry point and a 32 MiB Windows stack reservation.
2. **Assembly:** use COFF `.rdata` for float literals and direct ARM64 page/low-12
   relocations instead of ELF GOT relocations. Apply the same distinction in the
   existing ARM64 runtime assembly. No new architecture backend was written.
3. **Runtime:** add ARM64 Windows exception-context handling for stack overflow
   and use the platform setjmp/longjmp implementation rather than the x64 GCC
   builtin workaround. Domain, effect, callback, and thread machinery otherwise
   remains upstream code.
4. **Bytecode launchers:** compile the small freestanding Windows header with
   `-ffreestanding`, preventing LLVM from introducing unavailable CRT calls.
5. **Linking:** normalize response-file path separators for LLVM's GNU-style
   parser. Implement native `-pack` with `llvm-lib` archives because COFF does not
   support an ELF-style partial relocatable link; `llvm-ar qcL` flattens them when
   creating another OCaml archive. Both direct packed linking and packed-library
   linking are tested.
6. **Static libraries:** do not record unavailable C-stub DLLs when ocamlmklib
   builds ARM64 static libraries. The compiler package installs a custom Unix/Str
   toplevel so upstream build scripts can use these primitives without FlexDLL.
7. **Windows socket timeouts:** Winsock requires a DWORD in milliseconds, not a
   POSIX timeval. Correct the existing Windows Unix helper, validate the range,
   and round positive fractional milliseconds up. This general Windows bug was
   found when a nominal 10-second TLS test timeout expired after 10 milliseconds.
   A regression test checks roundtrips, invalid values, and actual recv timing.

## opam changes

`patches/opam-2.6.1-windows-arm64.patch` contains the opam changes:

- Select ARM64 Clang rather than an i686/x86_64 companion compiler.
- Link vendored C++ solver dependencies with static libc++, libc++abi,
  libunwind, winpthreads, and the necessary Windows system import libraries.
- Disable unvalidated parent-shell remote code injection from the ARM64 build.
  Ordinary `opam env` and `opam exec` remain available.
- Embed an `asInvoker` manifest in opam-installer. Without FlexDLL's usual default
  manifest, Windows' installer-name heuristic otherwise requests elevation even
  for a user-owned prefix.

The vendored Dune bootstrap has a separate two-line patch recognizing
`mingwarm64` when selecting Windows flags. The same patch is supplied for Dune
3.20.2 in the repository. The original dose3 Git-info script and original opam
putenv build script are retained; the static Unix toplevel lets them run normally.
Full `make`, `make install`, and the source-build opam package have been exercised.

## Libraries and repository metadata

**No Eio, SSL, or SQLite binding source code is modified.**

- `conf-pkg-config`, `conf-libssl`, and `conf-sqlite3` overrides select the supplied
  ARM64 CLANGARM64 libraries instead of upstream x86-only Windows depext packages.
- Static pkg-config discovery includes private Windows dependencies such as
  `crypt32`. SSL's metadata explicitly sets `PKG_CONFIG_ARGN=--static` during its
  build. Merely adding `-lssl -lcrypto` is insufficient for static OpenSSL 3.6.
- Findlib 1.9.9~preview's generated configuration uses Windows `;` search-path
  separators and explicit `.exe` compiler names. Its small installation helper
  is distributed as an opam extra-file with a checksum.
- Eio_main selects the actual upstream **eio_windows** backend. Tests use Windows
  asynchronous networking and filesystem operations, not a mock backend.

The local repository is an ARM64 overlay on the default opam repository. Its
compiler and opam packages build source archives with checksums, rather than
pretending the existing local compiler is `ocaml-system`.

## Limits and unvalidated areas

- **No ARM64 FlexDLL, dynamic C-stub loading, or native `.cmxs` plugins.**
  Dune native `exe` and `byte_complete`, and ocamlc `-custom`, are supported.
  Arbitrary `#require` of C-backed libraries in the toplevel is not supported;
  only the bundled Unix/Str primitives are prelinked there.
- Only **Clang/MinGW-w64/UCRT** on Windows ARM64 was tested. This is not an MSVC
  port, and unrelated Windows x86/x64 configurations were not regression-tested.
- OCaml backtraces are tested, but Windows debugger/SEH unwind integration and
  pathological C-stack-overflow/OOM recovery have not been comprehensively tested.
- The complete upstream compiler, opam, and library test suites were not run.
  Selected upstream compiler tests and project integration tests are documented
  in `docs/VALIDATION.md`.
- The Eio test is local Windows I/O coverage, not a claim of Linux io_uring or
  universal POSIX feature equivalence. TLS tests use a local test CA/certificate,
  not external services or the Windows system trust store.
- Keep build concurrency low: two compiler/library jobs and one for opam's large
  vendored build. The host reports 8 GB physical RAM, with about 4 GB available
  when measured. Windows process startup occasionally failed with 0xC0000142,
  including a later two-job opam rebuild. Serial opam rebuilding succeeded.
  The cause is unconfirmed; low concurrency is a mitigation, not a proven fix.

This is an experimental downstream port. Human review and the upstream AI-policy
requirements apply before any contribution or production deployment.
