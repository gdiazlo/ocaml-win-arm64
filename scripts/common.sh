# Sourced by the project scripts. C:/ocaml-dev holds the shared toolchain,
# sources and archives; every Windows user gets a private opam root and temp
# directory under their profile. Override with OCAML_DEV_HOME or OPAMROOT_DEV.
OCAML_DEV_HOME=${OCAML_DEV_HOME:-$(cygpath -u "$USERPROFILE")/.ocaml-dev}
mkdir -p "$OCAML_DEV_HOME/tmp"
export OCAML_DEV_HOME
export OPAMROOT=$(cygpath -am "${OPAMROOT_DEV:-$OCAML_DEV_HOME/opam-root}")
export OPAMROOT_UNIX=$(cygpath -u "$OPAMROOT")
