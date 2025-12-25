obuild() {
    local CONF_FILE="odin.build"

    if [ ! -f "$CONF_FILE" ]; then
        return 1
    fi

    local NAME=$(grep "NAME=" "$CONF_FILE" | cut -d'=' -f2)
    local ENTRY=$(grep "ENTRY=" "$CONF_FILE" | cut -d'=' -f2)
    local OUTPUT_ROOT=$(grep "OUTPUT_DIR=" "$CONF_FILE" | cut -d'=' -f2)
    local ASSET_SRC=$(grep "ASSET_DIR=" "$CONF_FILE" | cut -d'=' -f2)

    local TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    local BATCH_DIR="$OUTPUT_ROOT/build-$TIMESTAMP"
    local LATEST_LINK="$OUTPUT_ROOT/latest"
    
    local TARGETS=("linux_amd64" "windows_amd64" "darwin_amd64" "darwin_arm64") 

    for T_STR in "${TARGETS[@]}"; do
        local T_OS=$(echo "$T_STR" | cut -d'_' -f1)
        local T_ARCH=$(echo "$T_STR" | cut -d'_' -f2)
        local T_DIR="$BATCH_DIR/${T_OS}_${T_ARCH}"
        
        echo "--- Building Target: $T_STR ---"

		case $T_OS in
            "windows")
                local BIN_PATH="$T_DIR/$NAME.exe"
                mkdir -p "$T_DIR"

                # -linker-path: points to ld.lld
                # -subsystem:console: ensures a terminal opens (standard for C-alternatives)
                odin build "$ENTRY" -file \
                    -out:"$BIN_PATH" \
                    -target:"$T_STR" \
                    -linker-path:$(which ld.lld) \
                    -subsystem:console

                if [ -d "$ASSET_SRC" ]; then cp -ru "$ASSET_SRC/." "$T_DIR/"; fi
                ;;

            "darwin")
                local APP_DIR="$T_DIR/$NAME.app/Contents"
                local BIN_DIR="$APP_DIR/MacOS"
                local RES_DIR="$APP_DIR/Resources"
                mkdir -p "$BIN_DIR" "$RES_DIR"

                # macOS cross-linking often requires the ld64.lld flavor
                odin build "$ENTRY" -file \
                    -out:"$BIN_DIR/$NAME" \
                    -target:"$T_STR" \
                    -linker-path:$(which ld64.lld)

                if [ -d "$ASSET_SRC" ]; then cp -ru "$ASSET_SRC/." "$RES_DIR/"; fi
                ;;

            "linux")
                local BIN_PATH="$T_DIR/$NAME"
                mkdir -p "$T_DIR"
                
                odin build "$ENTRY" -file -out:"$BIN_PATH" -target:"$T_STR"
                
                if [ -d "$ASSET_SRC" ]; then cp -ru "$ASSET_SRC/." "$T_DIR/"; fi
                ;;
        esac

        if [ $? -ne 0 ]; then
            echo "Error: Failed build for $T_STR"
            return 1
        fi
    done

    if [ -L "$LATEST_LINK" ] || [ -e "$LATEST_LINK" ]; then
        rm -rf "$LATEST_LINK"
    fi

    ln -s "build-$TIMESTAMP" "$LATEST_LINK"

    echo "--------------------------------"
    echo "Batch build complete: $BATCH_DIR"
}
