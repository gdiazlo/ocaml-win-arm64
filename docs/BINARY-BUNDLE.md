# Windows ARM64 binary bundles

These are experimental native Windows ARM64 ports, not official OCaml/opam
releases. See the project `README.md`, `docs/PORTING.md`, and `docs/VALIDATION.md`.

## Separate dynamic compiler bundle

`ocaml-5.5.1-arm64-windows-dynlink-bin.tar.gz` contains the dynamic compiler,
standard-library DLLs, ARM64 FlexDLL, and native zstd runtime DLL/license. It
passed relocation to a path with spaces, ordinary-bytecode C-stub loading, and a
native plugin with a Unicode filename. Third-party findlib/Eio/SSL/SQLite
packages are installed separately through `setup-dynamic-switch.sh`, which also
stages their native C-library runtime DLLs. See `docs/DYNAMIC-VALIDATION.md`.

## Original static OCaml 5.5.1

Extract `ocaml-5.5.1-arm64-windows-bin.tar.gz` and add its `bin` directory to PATH.
Keep `bin` and `lib/ocaml` together. The standard library uses executable-relative
paths; the bundle was tested after relocation, including to a path with spaces.
The bytecode toplevel includes Unix and Str statically.

Running the compiler/runtime requires Windows ARM64. Compiling and linking native
programs or bytecode programs with C stubs additionally requires MSYS2 CLANGARM64's
Clang/LLVM toolchain on PATH. Use the project `scripts/msys.sh` launcher for a
configured environment. It must be the ARM64 toolchain, not CLANG64/MINGW64.

**This original bundle is static linking only:** native `.cmxs` plugins and
dynamically loaded C-stub DLLs are unavailable in it. Use the separate dynamic
bundle for those workflows. With Dune, use `exe`
or `byte_complete`; with ocamlc and C stubs, use `-custom`. The compiler supports
native `-pack` using LLVM archives.

## opam 2.6.1

Extract `opam-2.6.1-arm64-windows-bin.tar.gz` and copy its executables to a directory
on PATH. They are ARM64 PE files with only Windows system DLL dependencies.
`opam-installer.exe` embeds an `asInvoker` manifest so installation into a
user-owned prefix does not spuriously require elevation.

Use `opam exec` or evaluate `opam env` in your shell. Direct modification of a
parent shell's environment through remote code injection is disabled in this
ARM64 port. Avoid running the copy inside a switch when reinstalling that same
package: Windows locks a running executable. The project keeps its main copy in
`local/bin/opam.exe` for this reason.

The compiler package in the accompanying repository is
`ocaml-variants.5.5.1+windows-arm64`; the optional opam package is
`opam-windows-arm64.2.6.1`. Both build from the accompanying source archives.

These bundles do not include MSYS2, Clang, or the complete opam repository.
SHA-256 checksums are in `dist/SHA256SUMS`. Upstream license files are included;
review all dependency licenses before external redistribution.
