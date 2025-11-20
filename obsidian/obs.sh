#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: obs.sh [--vault PATH] [--] [nvim args...]

Optional arguments:
  --vault PATH  Directory containing your Obsidian/Markdown vault. The script
                `cd`s into it before launching Neovim so the language server
                uses that folder as the workspace root.
  -h, --help    Show this help message.
USAGE
}

VAULT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--vault)
      shift
      [[ $# -gt 0 ]] || { echo "Error: --vault requires a path" >&2; exit 1; }
      VAULT_PATH="$1"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"
APP_NAME="markdown-oxide-nvim"

CONFIG_HOME="${PROJECT_ROOT}"
DATA_HOME="${PROJECT_ROOT}/.local/share"
STATE_HOME="${PROJECT_ROOT}/.local/state"
CACHE_HOME="${PROJECT_ROOT}/.cache"

mkdir -p "${DATA_HOME}" "${STATE_HOME}" "${CACHE_HOME}"

if [[ -n "${VAULT_PATH}" ]]; then
  if [[ ! -d "${VAULT_PATH}" ]]; then
    echo "Error: vault path '${VAULT_PATH}' does not exist or is not a directory" >&2
    exit 1
  fi
  cd "${VAULT_PATH}"
fi

env \
  XDG_CONFIG_HOME="${CONFIG_HOME}" \
  XDG_DATA_HOME="${DATA_HOME}" \
  XDG_STATE_HOME="${STATE_HOME}" \
  XDG_CACHE_HOME="${CACHE_HOME}" \
  NVIM_APPNAME="${APP_NAME}" \
  nvim "$@"
