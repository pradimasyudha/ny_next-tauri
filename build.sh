#!/bin/sh

set -euo pipefail

log() {
    local MSG="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $MSG"
}

setup_scripts() {
    log "Creating scripts directory and files"

    SCRIPTS_PATH="./src-tauri/scripts"
    if [ ! -d "$SCRIPTS_PATH" ]; then
        mkdir -p $SCRIPTS_PATH
        touch $SCRIPTS_PATH/postinstall.sh $SCRIPTS_PATH/preinstall.sh $SCRIPTS_PATH/preremove.sh $SCRIPTS_PATH/postremove.sh
    fi
}

run_bun_tauri_build() {
    log "Building project for native Windows or Linux"
    bun tauri build
}

run_macos_specific_builds() {
    log "Building DMG bundle for macOS"
    bun tauri build --bundles dmg

    WINDOWS_TARGETS="x86_64-pc-windows-msvc i686-pc-windows-msvc aarch64-pc-windows-msvc"
    for TARGET in $WINDOWS_TARGETS; do
        log "Building Windows version for target $TARGET"
        bun tauri build --runner cargo-xwin --target "$TARGET"
    done
}

OS="$(uname -s)"
case "${OS}" in
    Linux*)     OS_TYPE=Linux;;
    Darwin*)    OS_TYPE=macOS;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*) OS_TYPE=Windows;;
    *)          OS_TYPE="UNKNOWN:${OS}"
esac

log "Detected OS: ${OS_TYPE}"

setup_scripts
run_bun_tauri_build

if [ "${OS_TYPE}" = "macOS" ]; then
    run_macos_specific_builds
fi