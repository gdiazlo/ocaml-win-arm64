@echo off
rem Load your own OCaml/opam environment into the CURRENT cmd.exe session
rem (also an SSH session). Does not change the current directory.
rem Usage: C:\ocaml-dev\ocaml-env.cmd [switch]   (default: your current opam switch)
rem Your opam root is %USERPROFILE%\.ocaml-dev\opam-root (override: OPAMROOT_DEV).
if not defined OCAML_DEV_HOME set "OCAML_DEV_HOME=%USERPROFILE%\.ocaml-dev"
if defined OPAMROOT_DEV (set "OPAMROOT=%OPAMROOT_DEV%") else (set "OPAMROOT=%OCAML_DEV_HOME%\opam-root")
if not exist "%OPAMROOT%\config" (
  echo No opam root at %OPAMROOT%. Run: powershell -ExecutionPolicy Bypass -File %~dp0setup-user.ps1
  exit /b 1
)
set "DUNE_CACHE=disabled"
set "MSYSTEM=CLANGARM64"
set "OCAMLLIB="
set "CAMLLIB="
set "CAML_LD_LIBRARY_PATH="
set "FLEXDIR="
if not "%~1"=="" set "OPAMSWITCH=%~1"
rem opam, the native Clang toolchain, and the MSYS2 tools (sh, make) used by builds.
set "PATH=%~dp0local\bin;%~dp0tools\msys64\clangarm64\bin;%~dp0tools\msys64\usr\bin;%PATH%"
for /f "usebackq delims=" %%L in (`opam.exe env --shell=cmd`) do %%L
for /f "usebackq delims=" %%S in (`opam.exe switch show`) do echo OCaml environment loaded: switch %%S, root %OPAMROOT%
