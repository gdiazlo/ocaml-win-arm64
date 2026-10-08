# FlexDLL Windows ARM64 investigation

## Implementation update

The first import-slot/veneer implementation and separate OCaml dynamic compiler
are now working. See **[FORKS.md](FORKS.md)** for current tests, minimal fork
changes, artifacts, and remaining release work. The investigation below records
the starting state before implementation.

## Conclusion

**Extend FlexDLL, rather than replace OCaml's Windows loader.** Its existing
symbol-resolution model is the right fit for both dynamically loaded C stubs and
native OCaml plugins. Retain the tested static compiler as a bootstrap and
fallback; develop the dynamic variant separately.

This investigation did not modify FlexDLL or the working compiler. Target scope
is **native ARM64/aarch64 + Clang/MinGW-w64/UCRT**, not ARM32, ARM64EC, or an initial
MSVC port.

Baseline: FlexDLL **0.44**, commit
`ab8161fc7161a598c5aaf66f02298035639d5ef3` (2026-07-21). Its latest change already
strips stale `.llvm_addrsig` metadata from rewritten objects, which is helpful
for LLVM linking.

## How FlexDLL works

FlexDLL has two components:

1. `flexlink.exe`, an OCaml linker wrapper. It reads COFF objects/archives,
   determines which symbols are defined locally, creates symbol/import tables,
   and rewrites references to symbols provided by the host or previously loaded
   plugins. It then invokes the ordinary Windows linker.
2. `flexdll.c`, a C runtime linked into the host. It uses Windows LoadLibrary,
   resolves those deferred references against the host/plugin symbol tables,
   and applies the remaining relocations.

`flexdll_initer.c` relocates a plugin before its normal CRT entry point and static
constructors run. Windows still loads the PE image and resolves ordinary Windows
DLL imports. We need to add ARM64 support to the FlexDLL parts, not write a new
Windows PE loader.

## Experimentally verified prerequisites

Probes in `tests/flexdll-arm64-probe/` were compiled with the native CLANGARM64
compiler:

- A normal ARM64 DLL successfully loaded, exported a callable function, and
  unloaded using LoadLibrary/GetProcAddress/FreeLibrary.
- The **unmodified** FlexDLL wrapper compiled with our OCaml 5.5.1 into an ARM64
  PE executable and reported version 0.44. This proves the bootstrap is available;
  it does **not** mean the wrapper can link ARM64 targets yet.
- The existing generic COFF parser read an ARM64 object and displayed its symbols
  and relocations. The C runtime and initializer also compiled into ARM64 COFF
  objects without source changes; their loading/relocation behavior remains to
  be tested once the wrapper generates ARM64 tables.
- Clang's plain external C data access uses `.refptr.host_value`: local
  ADRP/LDR instructions address an eight-byte pointer slot, and only the slot has
  the external ADDR64 relocation. This avoids a direct instruction reference to
  distant host data.
- `__declspec(dllimport)` produces local references to `__imp_host_value` and
  `__imp_host_function`, followed by an indirect function call. FlexDLL already
  knows how to synthesize such import slots.
- Plain C external function calls still use BRANCH26. The current OCaml emitter
  uses direct ADRP/ADD references for external addresses and BRANCH26 for runtime
  calls. These require additional support or indirection.

Reproduce with:

```sh
bash scripts/msys.sh 'bash scripts/probe-flexdll-arm64.sh'
```

Evidence: `logs/flexdll-arm64-baseline.log`,
`logs/flexdll-arm64-bootstrap.log`, `logs/flexdll-arm64-coff-parser.log`,
`logs/flexdll-arm64-relocations.txt`, `logs/flexdll-arm64-disassembly.txt`, and
`logs/flexdll-arm64-runtime-compile.log`.

## Required source changes

| Component | Current restriction | ARM64 work |
|---|---|---|
| `cmdline.ml:14,23,106` | Only x86/x64 machines and existing Intel toolchains | Add an `arm64` machine and a `mingwarm64` chain using Clang |
| `coff.ml:438,446,672` | Generated absolute/relative relocations and machine headers use Intel codes | Emit machine **0xAA64**, ARM64 ADDR64 **0x000E**, and ARM64 REL32 **0x0011** where appropriate; validate object architecture |
| `reloc.ml:371–613` | Pointer-sized table generation has only x86/x64 cases | Reuse eight-byte layouts and undecorated names for ARM64 while preserving its separate machine identity |
| `reloc.ml:448` | Deferred relocation classification handles Intel types only | Add ARM64 types and corresponding runtime records; preserve locally resolvable relocations for LLD |
| `reloc.ml:869,1127–1239,1370–1567` | Image-base names, linker invocation, libraries, and support-object selection assume existing chains | Correct ARM64 names/entry point, invoke Clang/LLD, select UCRT/compiler-rt, and choose ARM64 support objects |
| `flexdll.c:30–41,265–413` | Runtime relocation kinds patch pointer/integer displacements only | Add ARM64 instruction-aware relocation where required, proper addends/range checks, and instruction-cache flushing |
| `Makefile` | Support objects and defaults target Intel GCC/MSVC chains | Build `flexdll_mingwarm64.o` and `flexdll_initer_mingwarm64.o`; package/test the new chain |
| `create_dll.ml` | Optional built-in PE linker is Intel-only | Initially reject ARM64 built-in mode explicitly and use LLD; a new internal PE linker is unnecessary |

LLVM library discovery cannot blindly reuse the GCC defaults: this toolchain's
`-print-libgcc-file-name` returns **libclang_rt.builtins-aarch64.a**, not libgcc.
Its library search paths are semicolon-separated and its CRT objects are already
available. Direct-DLL export extraction also needs LLVM-compatible output parsing
if that feature is enabled; the existing parser expects GNU objdump output.
Do not reuse `default_amd64.manifest`, which declares an AMD64 VC90 CRT dependency.
Use an ARM64-appropriate/UCRT-compatible manifest policy.

## ARM64 relocation and distance issues

Observed relocation types in the C, assembly, and OCaml probes:

| COFF relocation | Code | Purpose |
|---|---|---|
| ADDR64 | 0x000E | Full-width addresses and pointer slots |
| BRANCH26 | 0x0003 | Direct B/BL instructions |
| PAGEBASE_REL21 | 0x0004 | ADRP page-address calculation |
| PAGEOFFSET_12A | 0x0006 | ADD immediate low page offset |
| PAGEOFFSET_12L | 0x0007 | Scaled load/store low page offset |
| ADDR32NB | 0x0002 | Image-relative addresses, including unwind metadata |
| REL32 | 0x0011 | Signed relative data references |

Additional section/debug/TLS relocation kinds have different ARM64 numbers and
must not accidentally use Intel classifications. Unsupported deferred kinds
must produce explicit errors rather than silently corrupting code.

A direct ARM64 B/BL has approximately **±128 MiB** reach. ADRP has approximately
**±4 GiB** page reach. DLL/EXE addresses under ASLR are not guaranteed to satisfy
these ranges. Therefore merely implementing the arithmetic and hoping DLLs load
near the executable is not robust.

Recommended strategy:

- Use full-width pointer slots for imported addresses (`__imp_` / `.refptr`).
- For ordinary direct imported calls, generate a **local veneer** that loads a
  full-width target pointer and tail-branches to it. Leave the B/BL-to-veneer
  relocation to LLD. Use x16/x17, already reserved for veneers by OCaml's ARM64
  register allocator; do not modify x18 or disturb arguments, LR, or the stack.
- Change OCaml's ARM64 Windows dynamic-code emission to load external addresses
  through local COFF pointer slots instead of the current forced direct ADRP/ADD
  sequence. Keep static emission unchanged.
- For direct instruction relocations that remain, decode/re-encode instruction
  fields and their addends correctly, preserving opcode/register fields and
  enforcing alignment and range constraints. Full support for arbitrary ARM64
  objects is a broader task than an import-slot-first OCaml milestone.

`VirtualProtect` alone is insufficient after changing executable instructions.
The existing runtime does not call **FlushInstructionCache**; ARM64 requires
correct instruction-cache synchronization before executing patched/generated
code. Preserve/restore page permissions and test error paths as well.

## DLL initialization, unwind metadata, and OCaml integration

Keep relocation before CRT/static constructors, as the current FlexDLL
initializer does. Validate its entry-point naming and the host callback pointer
handoff on ARM64. Preserve `.pdata`/`.xdata` and associative COMDAT relationships
when rewriting objects. Let Clang and LLD handle normal Windows unwind metadata;
any non-leaf generated thunk needs correct unwind treatment.

OCaml already routes its Windows loader through FlexDLL in
`runtime/win32.c:220–255`. Its `CAMLextern` macro already selects dllimport on
64-bit MinGW when dynamic support is enabled (`runtime/caml/misc.h:135–147`).
This is a major reason to extend FlexDLL rather than introduce a second loader
and runtime-export mechanism.

Remaining OCaml work:

- Add the new FlexDLL chain to `configure.ac` and bootstrap wiring in `Makefile`.
- Switch ARM64 executable/DLL linking to the tested wrapper for the dynamic
  variant and enable the shared-library feature checks only after they pass.
- Update ARM64 Windows dynamic symbol-address emission in `asmcomp/arm64/emit.mlp`.
- Restore normal shared C-stub output and validate native Dynlink registration of
  plugin code, frames, roots, and module initialization with the existing runtime.
- Do not link a second independent OCaml GC/runtime into each plugin.

The existing 0xC0000142 process-startup flakiness occurred with the static build,
without FlexDLL. It remains a separate reliability investigation, not evidence
of a FlexDLL relocation problem.

## Proposed milestones and acceptance tests

1. **Architecture/absolute-import milestone:** new chain, ARM64 descriptor tables,
   support objects, and host exports. Load C plugins using dllimport/pointer slots;
   test host function/data imports and dependency on a previously loaded plugin.
2. **General call milestone:** safe veneers for direct imports; verify missing
   symbols, repeated loads, constructors, and targets beyond branch range.
3. **OCaml C stubs:** ordinary bytecode DLL loading, toplevel `#require` for SQLite
   and SSL, and Dune default bytecode workflows. Test callbacks, moving GC,
   exceptions, UTF-8 paths, and threads/domains.
4. **Native plugins:** simple then multi-module `.cmxs`, imported OCaml globals,
   plugin dependencies, GC/root/frame registration, effects, and backtraces.
5. **Packaging/regressions:** separate dynamic compiler/opam packages and expanded
   tests. Preserve the functioning static switch and test Intel FlexDLL chains
   where suitable tooling is available before proposing upstream changes.

## References

- `sources/flexdll/README.md` (architecture, runtime tables, dllimport, initialization).
- Microsoft PE/COFF format, ARM64 relocation table:
  https://learn.microsoft.com/en-us/windows/win32/debug/pe-format#arm64-processors
  (downloaded reference: `downloads/pe-format.md`).
- Windows FlushInstructionCache:
  https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-flushinstructioncache
- Windows ARM64 exception handling:
  https://learn.microsoft.com/en-us/cpp/build/arm64-exception-handling

AI-assisted investigation. No upstream contribution or claim of completed
ARM64 FlexDLL support is made by these probes.
