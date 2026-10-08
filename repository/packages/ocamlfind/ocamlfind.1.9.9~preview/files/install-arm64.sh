#!/bin/sh
# The upstream configure script only recognises mingw/mingw64 for ';' paths.
set -eu
lib=$(cygpath -am "$1")
printf 'destdir="%s"\npath="%s;%s/ocaml"\nocamlc="ocamlc.opt.exe"\nocamlopt="ocamlopt.opt.exe"\nocamldep="ocamldep.opt.exe"\nocamldoc="ocamldoc.opt.exe"\n' \
  "$lib" "$lib" "$lib" > "$lib/findlib.conf"
