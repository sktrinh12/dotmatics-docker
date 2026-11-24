#!/bin/bash
# Dotmatics application entrypoint — idempotent deploy from mounted zip.
set -euo pipefail

ZIP_FILE="${DOTMATICS_ZIP:-/mnt/dotmatics/Dotmatics_Platform_6.2.zip}"
CONFIG_DIR="${DOTMATICS_CONFIG_DIR:-/mnt/dotmatics/config}"
DATA_DIR="${DOTMATICS_DATA_DIR:-/home/dotmatics/dotmatics/data}"
WEBAPPS="${CATALINA_HOME}/webapps"
CFG_HOME="${HOME}/dotmatics/config"
SENTINEL="${WEBAPPS}/.dotmatics-deployed"
FORCE="${DOTMATICS_FORCE_REDEPLOY:-0}"

log() { printf '[entrypoint] %s\n' "$*" >&2; }

# Only run deploy logic when launching Tomcat
if [ "$#" -eq 0 ] || [ "$1" = "catalina.sh" ] || [[ "$1" == catalina.sh* ]]; then
    mkdir -p "${DATA_DIR}" "${CFG_HOME}"

    if [ -f "${SENTINEL}" ] && [ "${FORCE}" != "1" ]; then
        log "Dotmatics already deployed — skipping extraction (set DOTMATICS_FORCE_REDEPLOY=1 to redo)."
    else
        if [ ! -f "${ZIP_FILE}" ]; then
            log "ERROR: Dotmatics zip not found at ${ZIP_FILE}"
            log "Mount it:  -v /path/Dotmatics_Platform_6.2.zip:${ZIP_FILE}:ro"
            exit 1
        fi

        log "Extracting ${ZIP_FILE}"
        tmp="$(mktemp -d)"
        trap 'rm -rf "${tmp}"' EXIT
        unzip -q "${ZIP_FILE}" -d "${tmp}"

        # Deploy WARs
        while IFS= read -r -d '' war; do
            log "  WAR: $(basename "${war}")"
            cp -f "${war}" "${WEBAPPS}/"
        done < <(find "${tmp}" -maxdepth 3 -type f -name '*.war' -print0)

        # Deploy exploded directories (Browser ships as a directory — §6.5.1)
        for d in browser platformservices bioregister inventory; do
            if [ -d "${tmp}/${d}" ] && [ ! -e "${WEBAPPS}/${d}" ]; then
                log "  DIR: ${d}"
                cp -a "${tmp}/${d}" "${WEBAPPS}/"
            fi
        done

        touch "${SENTINEL}"
        log "Extraction complete."
    fi

    # Apply optional config overrides
    if [ -d "${CONFIG_DIR}" ]; then
        log "Applying config overrides from ${CONFIG_DIR}"

        [ -f "${CONFIG_DIR}/license.lic" ] && \
            install -m 0644 "${CONFIG_DIR}/license.lic" "${WEBAPPS}/browser/license.lic" 2>/dev/null || true

        [ -f "${CONFIG_DIR}/browser/browser.properties" ] && \
            install -m 0644 "${CONFIG_DIR}/browser/browser.properties" \
                "${WEBAPPS}/browser/browser.properties" 2>/dev/null || true

        [ -f "${CONFIG_DIR}/platformservices/browser.properties" ] && \
            install -m 0644 "${CONFIG_DIR}/platformservices/browser.properties" \
                "${CFG_HOME}/browser.properties" 2>/dev/null || true

        [ -f "${CONFIG_DIR}/bioregister/bioregister.properties" ] && \
            install -m 0644 "${CONFIG_DIR}/bioregister/bioregister.properties" \
                "${CFG_HOME}/bioregister.properties" 2>/dev/null || true
    fi
fi

log "Starting: $*"
exec "$@"
