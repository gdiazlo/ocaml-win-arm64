# Run the fresh switch's programs with no MSYS/toolchain directories in PATH.
param([string]$Switch = 'default')
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$OpamRoot = if ($env:OPAMROOT_DEV) { $env:OPAMROOT_DEV } else { Join-Path $env:USERPROFILE '.ocaml-dev\opam-root' }
$Prefix = Join-Path $OpamRoot $Switch
$SavedPath = $env:PATH
$SavedStubs = $env:CAML_LD_LIBRARY_PATH
$SavedLib = $env:OCAMLLIB
Push-Location $Root
try {
    $env:PATH = "$Prefix\bin;$env:SystemRoot\System32;$env:SystemRoot"
    $env:OCAMLLIB = "$Prefix\lib\ocaml"
    $env:CAML_LD_LIBRARY_PATH = "$Root\tests\dynamic-switch\_build\default\ffi;$Prefix\lib\stublibs"
    & "$Root\local\bin\opam.exe" --version
    if ($LASTEXITCODE -ne 0) { throw 'native opam failed' }
    foreach ($Exe in @('compiler/compiler.exe', 'compiler/compiler.byte.exe',
                       'compiler/timeout-ocamlc.exe', 'compiler/timeout-ocamlopt.exe',
                       'pack/pack.exe', 'pack/pack-library.exe', '_build/default/ffi/ffi_smoke.exe')) {
        & (Join-Path $Root "tests/dynamic-switch/$Exe")
        if ($LASTEXITCODE -ne 0) { throw "Failed: $Exe" }
    }
    & "$Prefix\bin\ocamlrun.exe" tests/dynamic-switch/_build/default/ffi/ffi_smoke.bc
    if ($LASTEXITCODE -ne 0) { throw 'bytecode FFI failed' }
    foreach ($Name in @('sqlite', 'ssl', 'eio')) {
        $Args = @()
        if ($Name -eq 'ssl') {
            $Args = @('tests/libraries/fixtures/cert.pem', 'tests/libraries/fixtures/key.pem')
        }
        $Base = "tests/dynamic-switch/_build/default/libraries/${Name}_smoke"
        & "$Root/$Base.exe" @Args
        if ($LASTEXITCODE -ne 0) { throw "native $Name failed" }
        & "$Prefix\bin\ocamlrun.exe" "$Base.bc" @Args
        if ($LASTEXITCODE -ne 0) { throw "ordinary bytecode $Name failed" }
    }
    Write-Output 'PASS dynamic switch direct Windows execution: no MSYS/toolchain PATH'
} finally {
    $env:PATH = $SavedPath
    $env:CAML_LD_LIBRARY_PATH = $SavedStubs
    $env:OCAMLLIB = $SavedLib
    Pop-Location
}
