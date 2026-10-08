# Make your OCaml environment available in every new session (including SSH)
# by storing it in your user environment (HKCU\Environment). Affects only the
# Windows account that runs it.
#
#   powershell -ExecutionPolicy Bypass -File C:\ocaml-dev\persist-env.ps1           # apply
#   powershell -ExecutionPolicy Bypass -File C:\ocaml-dev\persist-env.ps1 -Preview  # show only
#   powershell -ExecutionPolicy Bypass -File C:\ocaml-dev\persist-env.ps1 -Remove   # undo
#
# Persists OPAMROOT, the switch variables from `opam env`, and PATH entries for
# the switch, opam, and the Clang toolchain (appended, so it shadows nothing).
# MSYS2's Unix tools are not added: use ocaml-shell.cmd to build opam packages
# with C code. Re-run after `opam switch set` to follow another switch.
# Open a new session afterwards; running sessions keep their old environment.
param([string]$Switch = '', [switch]$Remove, [switch]$Preview)
$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Opam = Join-Path $Root 'local\bin\opam.exe'
$Clang = Join-Path $Root 'tools\msys64\clangarm64\bin'
$Managed = 'OPAMROOT', 'OPAM_SWITCH_PREFIX', 'OCAMLTOP_INCLUDE_PATH',
           'OCAML_TOPLEVEL_PATH', 'CAML_LD_LIBRARY_PATH', 'PKG_CONFIG_ARGN',
           'DUNE_CACHE', 'FLEXLINKFLAGS', 'OCAML_DEV_PERSISTED'
$Key = 'HKCU:\Environment'

# Entries this script owns: anything under C:\ocaml-dev or a .ocaml-dev opam root.
function Test-Ours([string]$Entry) {
    $E = $Entry.TrimEnd('\')
    $E -like "$Root*" -or $E -like '*\.ocaml-dev\opam-root\*'
}

$RawPath = (Get-Item $Key).GetValue('Path', '', 'DoNotExpandEnvironmentNames')
$Kept = @($RawPath -split ';' | Where-Object { $_ -and -not (Test-Ours $_) })

$Vars = [ordered]@{}
if ($Remove) {
    $NewPath = $Kept -join ';'
} else {
    $OpamRoot = if ($env:OPAMROOT_DEV) { $env:OPAMROOT_DEV } else {
        Join-Path (Join-Path $env:USERPROFILE '.ocaml-dev') 'opam-root' }
    if (-not (Test-Path (Join-Path $OpamRoot 'config'))) {
        throw "No opam root at $OpamRoot. Run C:\ocaml-dev\setup-user.ps1 first."
    }
    $env:OPAMROOT = $OpamRoot
    if (-not $Switch) { $Switch = (& $Opam switch show).Trim() }
    $Vars['OPAMROOT'] = $OpamRoot
    $Vars['DUNE_CACHE'] = 'disabled'
    # Plain sessions have no MSYS2 cygpath; use Windows paths directly.
    $Vars['FLEXLINKFLAGS'] = '-nocygpath'
    # Switch variables, as opam computes them (PATH/MANPATH handled separately).
    foreach ($Line in & $Opam env --switch=$Switch --shell=cmd) {
        if ($Line -match '^set ([A-Za-z_]+)=(.*)$' -and $Managed -contains $Matches[1]) {
            $Vars[$Matches[1]] = $Matches[2]
        }
    }
    $Vars['OCAML_DEV_PERSISTED'] = $Switch
    $Prefix = Join-Path $OpamRoot $Switch
    $NewPath = ((@("$Prefix\bin", "$Root\local\bin") + $Kept + @($Clang)) |
                Where-Object { $_ }) -join ';'
}

Write-Output "User PATH:"
$NewPath -split ';' | ForEach-Object { "  $_" }
foreach ($Name in $Managed) {
    if ($Vars.Contains($Name)) { Write-Output "set   $Name=$($Vars[$Name])" }
    elseif ($null -ne (Get-Item $Key).GetValue($Name)) { Write-Output "unset $Name" }
}
if ($Preview) { Write-Output '(preview only: nothing changed)'; exit 0 }

# Write PATH as REG_EXPAND_SZ so existing %VAR% entries keep working.
Set-ItemProperty -Path $Key -Name Path -Value $NewPath -Type ExpandString
foreach ($Name in $Managed) {
    if ($Vars.Contains($Name)) {
        Set-ItemProperty -Path $Key -Name $Name -Value $Vars[$Name] -Type String
    } else {
        Remove-ItemProperty -Path $Key -Name $Name -ErrorAction SilentlyContinue
    }
}
# Notify Windows (Explorer, new shells) that the environment changed.
[Environment]::SetEnvironmentVariable('OCAML_DEV_NOTIFY', '1', 'User')
[Environment]::SetEnvironmentVariable('OCAML_DEV_NOTIFY', $null, 'User')
if ($Remove) { Write-Output 'Removed. New sessions will not load OCaml.' }
else { Write-Output "Done. New sessions (including SSH) load switch '$Switch'." }
