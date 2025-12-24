osetup() {
    local TOOL_ROOT="$HOME/.bash/functions/odin"
    local STUB_DIR="$TOOL_ROOT/stubs"

    if [ -f "odin.build" ]; then
        return 1
    fi

    mkdir -p assets
    mkdir -p build

    if [ -d "$STUB_DIR" ]; then
        cp "$STUB_DIR/odin.build.stub" "./odin.build"
        cp "$STUB_DIR/main.odin.stub" "./main.odin"
    else
        echo "Error: Stub directory not found at $STUB_DIR"
        return 1
    fi

    echo "Project initialized in $PWD"
}
