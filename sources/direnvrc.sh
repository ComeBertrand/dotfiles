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
      py_bin="$(command -v python)"
      if command -v uv >/dev/null 2>&1; then
          uv venv --python "$py_bin" "$VIRTUAL_ENV"
      else
          "$py_bin" -m venv "$VIRTUAL_ENV"
      fi
  fi
  export VIRTUAL_ENV
  PATH="${VIRTUAL_ENV}/bin:${PATH}"
  export PATH
}
