# Run the already-built programs directly from Windows, without an MSYS shell.
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
Push-Location $Root
try {
    & .\local\bin\opam.exe --version
    if ($LASTEXITCODE -ne 0) { throw 'opam failed' }
    $Tests = @(
        'tests/compiler_smoke.exe', 'tests/compiler_smoke.bc.exe',
        'tests/socket_timeout.exe', 'tests/socket_timeout.bc.exe',
        'tests/ffi/_build/default/ffi_smoke.exe',
        'tests/ffi/_build/default/ffi_smoke.bc.exe'
    )
    foreach ($Exe in $Tests) {
        & (Join-Path $Root $Exe)
        if ($LASTEXITCODE -ne 0) { throw "Failed: $Exe" }
    }
    foreach ($Suffix in @('exe', 'bc.exe')) {
        foreach ($Name in @('sqlite', 'ssl', 'eio')) {
            $Exe = Join-Path $Root "tests/libraries/_build/default/${Name}_smoke.$Suffix"
            if ($Name -eq 'ssl') {
                & $Exe tests/libraries/fixtures/cert.pem tests/libraries/fixtures/key.pem
            } else {
                & $Exe
            }
            if ($LASTEXITCODE -ne 0) { throw "Failed: $Exe" }
        }
    }
    Write-Output 'PASS direct Windows execution (no MSYS runtime required)'
} finally {
    Pop-Location
}
