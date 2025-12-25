oclean() {
    local CONF_FILE="odin.build"
    if [ ! -f "$CONF_FILE" ]; then return 1; fi
    
    local OUTPUT_ROOT=$(grep "OUTPUT_DIR=" "$CONF_FILE" | cut -d'=' -f2)
    
    echo "Cleaning $OUTPUT_ROOT..."
    rm -rf "$OUTPUT_ROOT"
    mkdir -p "$OUTPUT_ROOT"
}
