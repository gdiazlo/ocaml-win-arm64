# Create the calling Windows user's own OCaml environment from C:\ocaml-dev.
#
#   powershell -ExecutionPolicy Bypass -File C:\ocaml-dev\setup-user.ps1 [-Switch default] [-Test]
#
# Builds the ARM64 compiler (with FlexDLL), Dune, ocamlfind, SSL, SQLite3 and Eio
# into %USERPROFILE%\.ocaml-dev\opam-root and makes the switch current. Takes
# about an hour; keep the session open (closing an SSH session stops the build).
# Re-running is safe: finished steps are skipped. Nothing outside the user's
# profile is changed except the shared repository URL refresh in C:\ocaml-dev.
param([string]$Switch = 'default', [switch]$Test)
$Root = $PSScriptRoot -replace '\\', '/'
$UserHome = Join-Path $env:USERPROFILE '.ocaml-dev'
New-Item -ItemType Directory -Force $UserHome | Out-Null
$Log = (Join-Path $UserHome 'setup.log') -replace '\\', '/'
$Bash = Join-Path $PSScriptRoot 'tools\msys64\usr\bin\bash.exe'
$env:PATH = "$PSScriptRoot\tools\msys64\usr\bin;$env:PATH"
# The shared tree is owned by another user; allow git to read it in this process only.
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'safe.directory'
$env:GIT_CONFIG_VALUE_0 = '*'
$Steps = "bash scripts/setup-dynamic-switch.sh $Switch"
if ($Test) { $Steps += " && bash scripts/test-dynamic-switch.sh $Switch" }
Write-Output "Building switch '$Switch' for $env:USERNAME into $UserHome\opam-root (log: $Log)"
& $Bash "$Root/scripts/msys.sh" "set -o pipefail; { $Steps; } 2>&1 | tee '$Log'"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Setup failed (exit $LASTEXITCODE). See $Log"
    exit $LASTEXITCODE
}
Write-Output @"

Done. Open an OCaml environment with:
  cmd.exe / SSH: C:\ocaml-dev\ocaml-shell.cmd
  PowerShell:    . C:\ocaml-dev\scripts\env.ps1
"@
