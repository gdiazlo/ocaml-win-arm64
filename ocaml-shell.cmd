@echo off
rem Interactive CLANGARM64 Bash with your own opam root and switch (from cmd.exe or SSH).
rem Usage: C:\ocaml-dev\ocaml-shell.cmd [switch]
setlocal
set "ROOT=%~dp0"
set "ROOT_FWD=%ROOT:\=/%"
set "PATH=%ROOT%tools\msys64\usr\bin;%PATH%"
"%ROOT%tools\msys64\usr\bin\bash.exe" "%ROOT_FWD%scripts/shell.sh" %*
