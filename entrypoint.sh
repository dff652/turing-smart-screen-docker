#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/turing-smart-screen-python}"
CONFIG_DIR="${CONFIG_DIR:-/config}"
CONFIG_FILE="${CONFIG_FILE:-${CONFIG_DIR}/config.yaml}"
CUSTOM_THEMES_DIR="${CUSTOM_THEMES_DIR:-${CONFIG_DIR}/themes}"

mkdir -p "${CONFIG_DIR}" "${CUSTOM_THEMES_DIR}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  cp "${APP_DIR}/config.yaml.dist" "${CONFIG_FILE}"
  echo "Created ${CONFIG_FILE} from upstream defaults."
fi

rm -f "${APP_DIR}/config.yaml"
ln -s "${CONFIG_FILE}" "${APP_DIR}/config.yaml"

for theme_dir in "${CUSTOM_THEMES_DIR}"/*; do
  [[ -d "${theme_dir}" ]] || continue
  ln -sfn "${theme_dir}" "${APP_DIR}/res/themes/$(basename "${theme_dir}")"
done

exec "$@"

