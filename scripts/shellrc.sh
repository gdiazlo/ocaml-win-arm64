# Bash rcfile used by scripts/shell.sh; starts inside scripts/msys.sh (project root).
[[ -f ~/.bashrc ]] && source ~/.bashrc
OCAML_PROJECT_ROOT=$PWD
ROOT=$PWD; source "$ROOT/scripts/common.sh"
export DUNE_CACHE=disabled
export PATH="$OCAML_PROJECT_ROOT/local/bin:$PATH"
unset OCAMLLIB CAMLLIB CAML_LD_LIBRARY_PATH OCAMLTOP_INCLUDE_PATH FLEXDIR
# persist-env.ps1 disables cygpath for plain sessions; MSYS2 provides it here.
[[ ${FLEXLINKFLAGS:-} == -nocygpath ]] && unset FLEXLINKFLAGS
if [[ -n ${OCAML_PROJECT_SWITCH:-} ]]; then export OPAMSWITCH=$OCAML_PROJECT_SWITCH; fi
eval "$(opam env --shell=bash)"
PS1="(ocaml $(opam switch show)) \w\$ "
printf 'OCaml %s, switch %s. opam root: %s\n' \
  "$(ocamlc -version)" "$(opam switch show)" "$OPAMROOT"
cd "${OCAML_SHELL_CWD:-$HOME}"
