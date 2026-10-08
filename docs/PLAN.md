# Windows ARM64 port plan

Project root: `C:/ocaml-dev` (originally `C:/Users/gdiaz/ocaml`). All downloaded tools, sources, build
products, opam state, patches and tests remain below this directory.

## Dynamic validation status

A separate dynamic compiler was installed from source into
`windows-arm64-dynlink`. Dune native/ordinary-bytecode and interactive
SQLite/SSL/Eio tests, direct Windows tests, and compiler relocation pass. All 168
non-skipped selected upstream tests have passed across a batch and two retries;
the batch was not clean. See `docs/DYNAMIC-VALIDATION.md` for evidence and
remaining reliability work. The original static delivery remains preserved.

## Upstream baselines

- OCaml 5.5.1, commit `46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`.
- opam 2.6.1 (latest stable release verified via GitHub on 2026-10-07).
- MSYS2 CLANGARM64: native AArch64 Windows GNU ABI with UCRT.
- Host: Windows 11 ARM64. The harness/Git Bash can be x64-emulated; the
  compiler runtime and generated native programs must be ARM64 PE binaries.

## Milestones

1. Install a project-local C/assembly toolchain and Unix build tools.
2. Bootstrap OCaml bytecode, then the existing ARM64 native backend with
   Windows/COFF-specific adaptations. Preserve other platforms unchanged.
3. Install locally; test bytecode, native code, domains, effects, threads,
   exceptions, GC and C FFI. Check executable machine types.
4. Produce a local opam repository and compiler package. Validate installation
   into a fresh project-local switch (not just `ocaml-system`).
5. Build native ARM64 opam 2.6.1, using the official x64 executable only to
   bootstrap if needed.
6. Build/test SSL and SQLite bindings against ARM64 OpenSSL/SQLite.
7. Build/test Eio; distinguish the portable core from an actual Windows I/O
   backend, and document any unsupported features explicitly.

## Minimal-change strategy

First obtain a static-linking compiler without attempting to invent a new
FlexDLL backend (upstream FlexDLL has no ARM64 support). The delivered port
therefore keeps C-stub loading and native dynlink disabled. Native object packing
is implemented with flattened LLVM archives and has passed direct/library tests.
Eio, SSL, and SQLite use upstream sources without library code patches.

## Layout

- `sources/`: upstream source trees, modified working copies.
- `tools/`: isolated MSYS2 and bootstrap executables.
- `downloads/`: original release archives and release metadata.
- `patches/`: reviewable upstream-relative patches.
- `scripts/`: repeatable setup, build, packaging and test entry points.
- `repository/`: local opam repository.
- `dist/`: distributable sources/packages.
- `tests/`: standalone functional/FFI/integration tests.
- `logs/`: commands, compiler configuration and test results.
- `docs/`: decisions, scope and installation instructions.

AI assistance: this effort is performed using the pi coding agent with an
OpenAI model. Any upstream submission must disclose AI assistance and be
reviewed in full, following OCaml's `AI.md`; no upstream submission is made
by this project automatically.

## Outcome

The compiler and native opam work locally, source-build opam packages have been
installed, and the requested libraries pass native and bytecode integration
tests. The 119 selected non-skipped upstream tests have passed (a later batch
needed one retry after a Windows process-startup failure); 3 tests are expected
skips. See `README.md`, `docs/PORTING.md`, and `docs/VALIDATION.md` for usage,
measured evidence, and the remaining experimental/static-linking limitations.
