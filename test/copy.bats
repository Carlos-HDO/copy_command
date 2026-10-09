#!/usr/bin/env bats
# Tests for copy.sh. A fake xsel writes the clipboard to $CLIP so the real
# clipboard is never touched.

setup() {
    SCRIPT="$BATS_TEST_DIRNAME/../copy.sh"
    WORK="$(mktemp -d)"
    CLIP="$WORK/clipboard"
    export CLIP

    mkdir -p "$WORK/bin"
    cat > "$WORK/bin/xsel" <<'FAKE'
#!/usr/bin/env bash
cat > "$CLIP"
FAKE
    chmod +x "$WORK/bin/xsel"
    PATH="$WORK/bin:$PATH"
    unset WAYLAND_DISPLAY

    printf 'OLD' > "$CLIP"
    printf 'aaa' > "$WORK/a.txt"      # no trailing newline
    printf 'bbb\n' > "$WORK/b.txt"
    mkdir "$WORK/dir"
    cd "$WORK" || return 1
}

teardown() {
    rm -rf "$WORK"
}

# Run copy.sh with stdin closed to a pipe, so it never waits on a terminal
c() {
    bash "$SCRIPT" "$@" </dev/null
}

@test "copies a single file" {
    run c -s b.txt
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
    [ "$(cat "$CLIP")" = "bbb" ]
}

@test "missing file keeps the clipboard and fails" {
    run c missing.txt
    [ "$status" -eq 1 ]
    [[ "$output" == *"File not found: missing.txt"* ]]
    [ "$(cat "$CLIP")" = "OLD" ]
}

@test "directory is reported and clipboard is kept" {
    run c dir
    [ "$status" -eq 1 ]
    [[ "$output" == *"Is a directory: dir"* ]]
    [ "$(cat "$CLIP")" = "OLD" ]
}

@test "partial failure copies what was read, without a stray separator" {
    run c -s a.txt missing.txt
    [ "$status" -eq 1 ]
    [ "$(cat "$CLIP")" = "aaa" ]
}

@test "headers go on their own lines even without a trailing newline" {
    run c -s -l -n a.txt b.txt
    [ "$status" -eq 0 ]
    [ "$(cat "$CLIP")" = $'>>> a.txt\naaa\n>>> b.txt\nbbb' ]
}

@test "custom separator sits on its own line" {
    run c -s -d "---" a.txt b.txt
    [ "$status" -eq 0 ]
    [ "$(cat "$CLIP")" = $'aaa\n---\nbbb' ]
}

@test "escapes in the custom separator are interpreted" {
    run c -s -d '--\n--' a.txt b.txt
    [ "$(cat "$CLIP")" = $'aaa\n--\n--\nbbb' ]
}

@test "-n and -d together are rejected" {
    run c -n -d x a.txt
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot be used together"* ]]
    [ "$(cat "$CLIP")" = "OLD" ]
}

@test "options are accepted after file names" {
    run c b.txt -s
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
    [ "$(cat "$CLIP")" = "bbb" ]
}

@test "combined short options work" {
    run c -snl a.txt b.txt
    [ "$status" -eq 0 ]
    [ "$(cat "$CLIP")" = $'>>> a.txt\naaa\n>>> b.txt\nbbb' ]
}

@test "attached option argument works (-dTEXT)" {
    run c -s -d=== a.txt b.txt
    [ "$(cat "$CLIP")" = $'aaa\n===\nbbb' ]
}

@test "-- makes dash-prefixed names files" {
    printf 'weird\n' > -w.txt
    run c -s -- -w.txt
    [ "$status" -eq 0 ]
    [ "$(cat "$CLIP")" = "weird" ]
}

@test "invalid option fails" {
    run c -x a.txt
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid option: -x"* ]]
}

@test "option missing its argument fails" {
    run c a.txt -o
    [ "$status" -eq 1 ]
    [[ "$output" == *"Option -o requires an argument"* ]]
}

@test "-u copies only file names" {
    run c -s -u a.txt b.txt
    [ "$(cat "$CLIP")" = $'a.txt\nb.txt' ]
}

@test "-o saves the output to a file" {
    run c -s -o out.txt b.txt
    [ "$status" -eq 0 ]
    [ "$(cat out.txt)" = "bbb" ]
    [ "$(cat "$CLIP")" = "bbb" ]
}

@test "stdin is read when no files are given" {
    run bash -c 'echo hi | bash "$1"' _ "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" == hi* ]]
    [ "$(cat "$CLIP")" = "hi" ]
}

@test "- mixes stdin with files, with header and numbering" {
    run bash -c 'echo piped | bash "$1" -s -l -r - a.txt' _ "$SCRIPT"
    [ "$status" -eq 0 ]
    grep -qx '>>> (stdin)' "$CLIP"
    grep -q 'piped' "$CLIP"
    grep -qx '>>> a.txt' "$CLIP"
}

@test "-t trims trailing newlines" {
    run bash -c 'printf "ls -la\n\n" | bash "$1" -s -t' _ "$SCRIPT"
    [ "$status" -eq 0 ]
    [ "$(od -An -c "$CLIP" | tr -d ' \n')" = "ls-la" ]
}

@test "without -t the trailing newline is kept" {
    run bash -c 'echo "ls" | bash "$1" -s' _ "$SCRIPT"
    [ "$(wc -c < "$CLIP")" -eq 3 ]
}

@test "status message goes to stderr" {
    run bash -c 'bash "$1" b.txt 2>/dev/null </dev/null' _ "$SCRIPT"
    [ "$status" -eq 0 ]
    [ "$output" = "bbb" ]
}

@test "no clipboard tool is reported" {
    mkdir empty
    run env PATH="$WORK/empty" "$BASH" "$SCRIPT" b.txt
    [ "$status" -eq 1 ]
    [[ "$output" == *"No clipboard tool found"* ]]
}
