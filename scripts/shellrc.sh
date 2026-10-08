# Bash rcfile used by scripts/shell.sh; run inside scripts/msys.sh.
[[ -f ~/.bashrc ]] && source ~/.bashrc
OCAML_PROJECT_ROOT=$PWD
export OPAMROOT="$OCAML_PROJECT_ROOT/opam-root" DUNE_CACHE=disabled
export PATH="$OCAML_PROJECT_ROOT/local/bin:$PATH"
unset OCAMLLIB CAMLLIB CAML_LD_LIBRARY_PATH OCAMLTOP_INCLUDE_PATH FLEXDIR
if [[ -n ${OCAML_PROJECT_SWITCH:-} ]]; then export OPAMSWITCH=$OCAML_PROJECT_SWITCH; fi
eval "$(opam env --shell=bash)"
PS1="(ocaml $(opam switch show)) \w\$ "
printf 'OCaml %s, switch %s. opam root: %s\n' \
  "$(ocamlc -version)" "$(opam switch show)" "$OPAMROOT"
