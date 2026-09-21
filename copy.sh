#!/bin/bash
# c — copies file contents or stdin to the clipboard (xsel), with useful options.

set -euo pipefail

show_help() {
    cat <<'EOF'
Usage: c [options] [files]

Description:
  Copies the contents of one or more files to the clipboard (xsel).
  If no files are provided and standard input is available (pipe), reads from stdin.

Options:
  -s            Silent: do not display output in the terminal (copy only).
  -h            Show this help message.
  -n            Do not add separators between files.
  -d <text>     Set a custom separator between files.
  -o <file>     Also save the output to this file.
  -l            Show the file name before its contents (header).
  -r            Number content lines (similar to 'nl').
  -u            Copy file NAME(S) only (one per line), without their contents.

Examples:
  c README.md
  c -s *.txt
  c -d "---" a.txt b.txt
  c -o output.txt *.log
  c -l -r *.conf
  c -u *.txt
  ls -l | c
EOF
}

# Defaults
silent=false
no_sep=false
separator=$'\n\n\n#######################################################################\n\n\n'
outfile=""
show_label=false
number_lines=false
only_names=false

# Parse options
while getopts ":shnd:o:lru" opt; do
    case "$opt" in
        s) silent=true ;;
        h) show_help; exit 0 ;;
        n) no_sep=true ;;
        d) separator=$OPTARG ;;
        o) outfile=$OPTARG ;;
        l) show_label=true ;;
        r) number_lines=true ;;
        u) only_names=true ;;
        :) echo "[!] Option -$OPTARG requires an argument." >&2; exit 1 ;;
        \?) echo "[!] Invalid option: -$OPTARG" >&2; show_help; exit 1 ;;
    esac
done
shift $((OPTIND-1))

# Temporary buffer
tmpfile="$(mktemp)"
cleanup() { rm -f "$tmpfile"; }
trap cleanup EXIT

# Case 1: names only (-u)
if $only_names; then
    if [ $# -eq 0 ]; then
        echo "[!] No files specified for -u." >&2
        exit 1
    fi
    printf "%s\n" "$@" > "$tmpfile"

# Case 2: provided files
elif [ $# -gt 0 ]; then
    total=$#
    count=0
    for file in "$@"; do
        count=$((count+1))
        if [ -f "$file" ]; then
            $show_label && printf ">>> %s\n" "$file" >> "$tmpfile"

            if $number_lines; then
                nl -ba -- "$file" >> "$tmpfile"
            else
                cat -- "$file" >> "$tmpfile"
            fi

            if ! $no_sep && [ $count -lt $total ]; then
                printf "%b" "$separator" >> "$tmpfile"
            fi
        else
            echo "[!] File not found: $file" >&2
        fi
    done

# Case 3: no files, but receiving stdin
elif [ ! -t 0 ]; then
    if $number_lines; then
        nl -ba >> "$tmpfile"
    else
        cat >> "$tmpfile"
    fi

# Case 4: no arguments and no stdin
else
    show_help
    exit 1
fi

# Copy to the clipboard
xsel --input --clipboard < "$tmpfile"

# Save to a file when -o is used
[ -n "$outfile" ] && cp -- "$tmpfile" "$outfile"

# Display in the terminal unless -s is used
if ! $silent; then
    cat -- "$tmpfile"
fi

# Final message
if [ -n "$outfile" ]; then
    echo "[+] Content copied to the clipboard and saved to: $outfile"
else
    echo "[+] Content copied to the clipboard."
fi
