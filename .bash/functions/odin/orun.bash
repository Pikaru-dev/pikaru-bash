orun () {	
CONF_FILE="odin.build"

if [ ! -f "$CONF_FILE" ]; then
    echo "Error: $CONF_FILE not found. Cannot determine binary name."
    return 1
fi

NAME=$(grep "NAME=" "$CONF_FILE" | cut -d'=' -f2 | tr -d '\r')
OUTPUT_ROOT=$(grep "OUTPUT_DIR=" "$CONF_FILE" | cut -d'=' -f2 | tr -d '\r')
LATEST_LINK="$OUTPUT_ROOT/latest"

if [ ! -L "$LATEST_LINK" ] && [ ! -e "$LATEST_LINK" ]; then
    echo "Error: No 'latest' build found at $LATEST_LINK"
    return 1
fi

TARGET_DIR=$(readlink -f "$LATEST_LINK")
HOST_ARCH=$(uname -m)
HOST_OS=$(uname -s | tr '[:upper:]' '[:lower:]')

ARCH_DIR="$TARGET_DIR/${HOST_OS}_${HOST_ARCH}"
EXEC_PATH="$ARCH_DIR/$NAME"
[[ "$HOST_OS" == *"mingw"* || "$HOST_OS" == *"msys"* ]] && EXEC_PATH+=".exe"

if [ ! -f "$EXEC_PATH" ]; then
    echo "Error: Executable not found at $EXEC_PATH"
    echo "Expected binary name: $NAME"
    return 1
fi

echo "--- Running: $NAME ---"
"$EXEC_PATH" "$@"
}
