#!/usr/bin/env bats

setup() {
    INSTALL="$BATS_TEST_DIRNAME/../install.sh"
    SCRIPT_TARGET="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/copy.sh"
    WORK="$(mktemp -d)"
    mkdir -p "$WORK/.local/bin"
}

teardown() {
    rm -rf "$WORK"
}

@test "installer creates links and can be run again" {
    run env HOME="$WORK" bash "$INSTALL"
    [ "$status" -eq 0 ]
    [ "$(readlink "$WORK/.local/bin/c")" = "$SCRIPT_TARGET" ]
    [ "$(readlink "$WORK/.local/bin/copy-clip")" = "$SCRIPT_TARGET" ]

    run env HOME="$WORK" bash "$INSTALL"
    [ "$status" -eq 0 ]
}

@test "installer preserves conflicting command and creates no partial links" {
    printf 'existing command\n' > "$WORK/.local/bin/copy-clip"

    run env HOME="$WORK" bash "$INSTALL"
    [ "$status" -eq 1 ]
    [[ "$output" == *"already exists"* ]]
    [ ! -e "$WORK/.local/bin/c" ]
    [ "$(cat "$WORK/.local/bin/copy-clip")" = "existing command" ]
}
