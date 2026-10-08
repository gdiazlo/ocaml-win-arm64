# Maintained fork policy and dynamic-linking status

## Latest validation

The separate **`windows-arm64-dynlink`** opam compiler package and fresh library
switch are now validated from source. Dune ordinary bytecode, interactive
`#require`, direct Windows execution without MSYS/toolchain PATH, and the
relocated binary bundle pass. All 168 non-skipped selected upstream tests have
passed across one batch and two isolated retries; that batch was not clean.
See **[DYNAMIC-VALIDATION.md](DYNAMIC-VALIDATION.md)** for precise results,
runtime-DLL dependencies, artifacts, and reproduction.

## Branches and baselines

Keep additive, platform-specific changes on `windows-arm64` branches. Do not
rewrite upstream history, mix unrelated cleanup into port patches, or change
upstream test expectations to hide failures. No remotes have been created or
pushed and no upstream contribution has been submitted.

| Project | Local source | Upstream baseline |
|---|---|---|
| OCaml | `sources/ocaml`, branch `windows-arm64` | 5.5.1, `46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91` |
| FlexDLL | `sources/flexdll`, branch `windows-arm64` | 0.44, `ab8161fc7161a598c5aaf66f02298035639d5ef3` |
| opam | `sources/opam-full-2.6.1` | pristine release in `sources/pristine-opam` |

The source changes remain uncommitted for review. opam is currently an extracted
release rather than a Git checkout; import the release baseline before arranging
its existing patch into fork commits. Remote repository names/owners remain a
maintainer decision.

Human review and the upstream AI-disclosure policies apply before contribution.
Do not infer that upstream has accepted or supports these changes.

## Patch boundaries

- **FlexDLL:** new `arm64` machine / `mingwarm64` Clang chain; ARM64 COFF IDs;
  eight-byte import/export tables; local x16 call veneers backed by existing
  absolute runtime relocations; native support objects; ARM64 cache flushing;
  machine validation; LLVM export inspection; ARM64 test fixture.
- **OCaml:** existing static port plus FlexDLL chain selection and bootstrap
  wiring, local address slots for dynamic ARM64 code, and the existing Windows
  `$` symbol separator in compiler/runtime assembly. No replacement loader,
  duplicate GC runtime, or plugin-registration mechanism.
- **opam:** no additional dynamic-linking changes were necessary in this phase.
- **Eio/SSL/SQLite:** no binding source changes.

The FlexDLL implementation has approximately 120 added lines in six existing
source/build files, plus its new regression fixture and short README additions. The OCaml dynamic additions are small
and isolated on top of the existing port. Generated `configure` is packaged but
excluded from the reviewable patch; regenerate it using `autoconf`.

### LLD compatibility finding

LLVM 22.1.8's COFF writer selects the first relocation page **before** sorting
relocation entries. Descending input relocations can therefore produce invalid
PE base-relocation blocks. This manifested as error 193 / invalid Win32 image in
native programs linking Unix, not the earlier intermittent 0xC0000142 startup
failure. Sorting ARM64 COFF relocations in FlexDLL before writing objects fixes
it without changing LLVM or post-processing executable images.

Diagnostics: `logs/ocaml-dynamic-reloc-diagnostics.log`,
`logs/ocaml-dynamic-reloc-fix.log`; reference source in
`downloads/lld-COFF-{Writer,Chunks}.cpp`. An upstream LLVM report/fix is a future
human-reviewed contribution, not something already submitted.

## Preserved static delivery

`local/`, `opam-root/windows-arm64`, their packages, and the five original
archives are unchanged. `sha256sum -c dist/SHA256SUMS` still passes.

The initial separate installation is **`local-dynamic/`**. Build output is
isolated in `sources/ocaml-windows-arm64-dynamic/`, with standalone FlexDLL in
`local-dynamic/flexdll/`. The source-built opam switch is
**`opam-root/windows-arm64-dynlink/`**; its compiler package bootstraps FlexDLL
from the bundled sources.

**Rebuild native libraries for the new compiler.** The initial static compiler
used dot-separated native symbols; the corrected Windows convention uses `$`.
Do not mix its old `.cmx`/`.cmxa`/object files with the new compiler's native
output. This experimental ABI change is another reason to preserve separate
installations/switches.

## Reproduce current results

```sh
bash scripts/msys.sh 'bash scripts/test-flexdll-arm64.sh'
bash scripts/msys.sh 'bash scripts/build-dynamic.sh'
bash scripts/msys.sh 'bash scripts/test-dynamic.sh'
bash scripts/msys.sh 'bash scripts/package-dynamic.sh'
```

`build-dynamic.sh` uses the validated static compiler to build the FlexDLL
wrapper, snapshots tracked OCaml edits, and performs a fresh compiler build and
installation. `--resume` is available only for the existing build tree; it does
not automatically copy subsequent source edits into that tree. The wrapper's
C support objects are built with native Clang. Compiler builds use two jobs;
FlexDLL builds use one.

The `local-dynamic/bin` and `local-dynamic/flexdll` directories must both be in
PATH when invoking the new compiler. Do not inherit `OCAMLLIB` or
`CAML_LD_LIBRARY_PATH` from the old switch.

## Passed validation

- FlexDLL upstream demo and new host/plugin tests: host data, direct and imported
  calls, function/data pointers, constructors before use, plugin dependencies,
  50 reloads, missing-symbol rejection. Verified DLL/host separation around
  **31 GB**, well beyond branch/ADRP range.
- New compiler built and installed; `supports_shared_libraries=true` and
  `native_dynlink=true`. Compiler/runtime and tested native/plugin binaries are
  ARM64 PE images.
- Ordinary bytecode (**without `-custom`**) and native compiler smoke tests:
  Unix, threads, GC, domains, atomics, exceptions, C math, and effects.
- Native and bytecode timeout regressions; Unicode toplevel filesystem test.
- Dynamically loaded C FFI DLL: integer/float calls, callbacks with GC, callback
  exceptions, and exceptions raised from C.
- Native `.cmxs` plugin: host globals, registered plugin roots across moving GC,
  callbacks across host/plugin/C boundaries, exceptions, domains, and effects.
- Ordinary bytecode SQLite and SSL integration tests using **DLL C stubs**:
  prepared statements/UTF-8/int64/blobs/rollback and verified localhost TLS 1.3.

Those initial milestone tests used manual isolated binding builds. The later
fresh-switch validation rebuilt SSL, SQLite, Eio, and all dependencies from
source, exercised Dune ordinary bytecode and interactive loading, and added a
package-local Winsock link flag for Eio's Unix stub DLL. Binding sources remain
unchanged. See `docs/DYNAMIC-VALIDATION.md` for the final package evidence.

Main evidence: `logs/flexdll-arm64-tests.log`, `logs/dynamic-validation.log`,
`logs/ocaml-dynamic-{configure,build,install}.log`, and
`logs/ocaml-dynamic-dynlink.log`.

## Separate source artifacts

- `patches/flexdll-0.44-windows-arm64.patch`
- `patches/ocaml-5.5.1-windows-arm64-dynlink.patch`
- `dist/flexdll-0.44-windows-arm64-src.tar.gz`
- `dist/ocaml-5.5.1-windows-arm64-dynlink-src.tar.gz` (includes FlexDLL sources)
- `dist/SHA256SUMS-dynamic`

These snapshots are separate from the original static packages. The compiler
source archive has now been installed and reinstalled through opam as
`ocaml-variants.5.5.1+windows-arm64-dynlink`. Separate dynamic compiler-binary and
repository archives are also available; the original five archives are unchanged.

## Remaining work before a maintained dynamic release

1. Repeat stress batches and diagnose intermittent compiler startup and DLL
   file-sharing failures; retries are recorded, not treated as a root-cause fix.
2. Broaden platform/runtime validation beyond the 179 selected upstream tests.
3. Add targeted deferred-relocation tests for uncommon ARM64 assembly: current
   support is import-slot/veneer-first. Unsupported external instruction kinds
   are rejected; the optional built-in PE linker and Intel CRT default manifests
   are deliberately not advertised for ARM64. MSVC/ARM64EC/ARM32 are out of scope.
4. Test Intel FlexDLL regressions on suitable machines; review, organize commits,
   and then publish forks.

This is a working experimental dynamic-linking milestone, not production
certification or a claim of complete support for arbitrary ARM64 object files.
