_check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: Required tool '$1' is not installed or not in PATH."
        return 1
    fi
}

obuild() {
    _check_tool "odin" || return 1
    _check_tool "date" || return 1

    local CONF_FILE="odin.build"
    if [ ! -f "$CONF_FILE" ]; then
        echo "Error: $CONF_FILE not found."
        return 1
    fi

    local NAME=$(grep "NAME=" "$CONF_FILE" | cut -d'=' -f2)
    local ENTRY=$(grep "ENTRY=" "$CONF_FILE" | cut -d'=' -f2)
    local OUTPUT_ROOT=$(grep "OUTPUT_DIR=" "$CONF_FILE" | cut -d'=' -f2)
    local ASSET_SRC=$(grep "ASSET_DIR=" "$CONF_FILE" | cut -d'=' -f2)

    local HOST_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    local HOST_ARCH=$(uname -m)
    local TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    
    local BATCH_DIR="$OUTPUT_ROOT/build-$TIMESTAMP"
    local T_DIR="$BATCH_DIR/${HOST_OS}_${HOST_ARCH}"
    local LATEST_LINK="$OUTPUT_ROOT/latest"

    mkdir -p "$T_DIR"
    
    local BIN_PATH="$T_DIR/$NAME"
    [[ "$HOST_OS" == *"mingw"* || "$HOST_OS" == *"msys"* ]] && BIN_PATH+=".exe"

    echo "--- Building for Host: $HOST_OS ($HOST_ARCH) ---"

    odin build "$ENTRY" -file -out:"$BIN_PATH"
    
    if [ $? -ne 0 ]; then
        echo "Build failed."
        return 1
    fi

    if [ -d "$ASSET_SRC" ]; then
        echo "Copying assets..."
        cp -ru "$ASSET_SRC/." "$T_DIR/"
    fi

    [ -L "$LATEST_LINK" ] || [ -e "$LATEST_LINK" ] && rm -rf "$LATEST_LINK"
    ln -s "build-$TIMESTAMP" "$LATEST_LINK"

    echo "--------------------------------"
    echo "Build complete: $T_DIR"
}
