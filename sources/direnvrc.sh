realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

start-venv() {
  if [[ -n $VIRTUAL_ENV ]]; then
      VIRTUAL_ENV=$(realpath "${VIRTUAL_ENV}")
  else
      VIRTUAL_ENV=$PWD/.venv
  fi
  if [[ ! -d $VIRTUAL_ENV ]]; then
      python -m venv "$VIRTUAL_ENV"
  fi
  export VIRTUAL_ENV
  PATH="${VIRTUAL_ENV}/bin:${PATH}"
  export PATH
}
