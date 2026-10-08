# Load the project's opam root and switch into the current PowerShell session.
# Usage: . .\scripts\env.ps1 [-Switch <name>]   (default: the opam root's current switch)
# Prefer scripts/shell.sh for building packages: opam builds expect MSYS2 tools.
param([string]$Switch = '')
$Root = Split-Path $PSScriptRoot -Parent
$Msys = Join-Path $Root 'tools\msys64'
if (-not $env:OCAML_DEV_HOME) { $env:OCAML_DEV_HOME = Join-Path $env:USERPROFILE '.ocaml-dev' }
$env:OPAMROOT = if ($env:OPAMROOT_DEV) { $env:OPAMROOT_DEV } else { Join-Path $env:OCAML_DEV_HOME 'opam-root' }
$env:DUNE_CACHE = 'disabled'
$env:MSYSTEM = 'CLANGARM64'
$env:COMSPEC = "$env:SystemRoot\System32\cmd.exe"
foreach ($Name in 'OCAMLLIB', 'CAMLLIB', 'CAML_LD_LIBRARY_PATH', 'OCAMLTOP_INCLUDE_PATH', 'FLEXDIR') {
    Remove-Item "Env:$Name" -ErrorAction SilentlyContinue
}
if ($Switch) { $env:OPAMSWITCH = $Switch }
$env:PATH = "$Root\local\bin;$Msys\clangarm64\bin;$Msys\usr\bin;$env:PATH"
& "$Root\local\bin\opam.exe" env --shell=pwsh | Out-String | Invoke-Expression
$Current = & "$Root\local\bin\opam.exe" switch show
Write-Output "OCaml $(ocamlc -version), switch $Current. opam root: $env:OPAMROOT"
