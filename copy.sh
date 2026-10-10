#!/usr/bin/env bash
# c — copies file contents or stdin to the clipboard, with useful options.

set -euo pipefail

show_help() {
    cat <<'EOF'
Usage: c [options] [files]

Description:
  Copies the contents of one or more files to the clipboard.
  If no files are provided and standard input is available (pipe), reads from stdin.
  Use "-" as a file name to read stdin alongside other files.

Options:
  -s            Silent: do not display output in the terminal (copy only).
  -h            Show this help message.
  -n            Do not add separators between files.
  -d <text>     Set a custom separator between files (escapes like \n are interpreted).
  -o <file>     Also save the output to this file.
  -l            Show the file name before its contents (header).
  -r            Number content lines (similar to 'nl').
  -u            Copy file NAME(S) only (one per line), without their contents.
  -t            Trim trailing newlines (handy for pasting commands in a terminal).

  Options may appear anywhere and can be combined (-lr). Arguments after --
  are always treated as file names (e.g. c -- -weird-name.txt).

Clipboard backends (first available is used):
  wl-copy (Wayland), xsel, xclip (X11), pbcopy (macOS)

Exit status:
  0 on success, 1 if any file could not be read or on usage errors.

Examples:
  c README.md
  c -s *.txt
  c -d "---" a.txt b.txt
  c -o output.txt *.log
  c -l -r *.conf
  c -u *.txt
  ls -l | c
  pwd | c -t
EOF
}

# Defaults
silent=false
no_sep=false
custom_sep=false
separator=$'\n\n\n#######################################################################\n\n\n'
outfile=""
show_label=false
number_lines=false
only_names=false
trim_newline=false

# Parse options (they may appear before, between or after file names)
files=()
while [ $# -gt 0 ]; do
    case "$1" in
        --) shift; files+=("$@"); break ;;
        -)  files+=("$1") ;;
        -?*)
            opts=${1#-}
            while [ -n "$opts" ]; do
                opt=${opts:0:1}
                opts=${opts:1}
                case "$opt" in
                    s) silent=true ;;
                    h) show_help; exit 0 ;;
                    n) no_sep=true ;;
                    l) show_label=true ;;
                    r) number_lines=true ;;
                    u) only_names=true ;;
                    t) trim_newline=true ;;
                    d|o)
                        # Argument is either the rest of this word (-dTEXT) or the next one
                        if [ -n "$opts" ]; then
                            optarg=$opts
                            opts=""
                        elif [ $# -ge 2 ]; then
                            shift
                            optarg=$1
                        else
                            echo "[!] Option -$opt requires an argument." >&2
                            exit 1
                        fi
                        if [ "$opt" = "d" ]; then
                            separator="$optarg\n"
                            custom_sep=true
                        else
                            outfile=$optarg
                        fi
                        ;;
                    *) echo "[!] Invalid option: -$opt" >&2; show_help >&2; exit 1 ;;
                esac
            done
            ;;
        *) files+=("$1") ;;
    esac
    shift
done
if [ ${#files[@]} -gt 0 ]; then
    set -- "${files[@]}"
fi

if $no_sep && $custom_sep; then
    echo "[!] Options -n and -d cannot be used together." >&2
    exit 1
fi

# Pick a clipboard backend
if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
    clip_cmd=(wl-copy)
elif command -v xsel >/dev/null 2>&1; then
    clip_cmd=(xsel --input --clipboard)
elif command -v xclip >/dev/null 2>&1; then
    clip_cmd=(xclip -selection clipboard)
elif command -v pbcopy >/dev/null 2>&1; then
    clip_cmd=(pbcopy)
else
    echo "[!] No clipboard tool found. Install wl-clipboard, xsel or xclip." >&2
    exit 1
fi

# Temporary buffer
tmpfile="$(mktemp)"
tmpfiles=("$tmpfile")
cleanup() { rm -f "${tmpfiles[@]}"; }
trap cleanup EXIT

# Append a newline if the buffer is non-empty and does not end with one
ensure_newline() {
    if [ -s "$tmpfile" ] && [ -n "$(tail -c1 "$tmpfile")" ]; then
        printf '\n' >> "$tmpfile"
    fi
}

# Append stdin or a file to the buffer, numbering lines when -r is used
append_source() {
    if $number_lines; then
        nl -ba -- "$@" >> "$tmpfile"
    else
        cat -- "$@" >> "$tmpfile"
    fi
}

failed=0

# Case 1: names only (-u)
if $only_names; then
    if [ $# -eq 0 ]; then
        echo "[!] No files specified for -u." >&2
        exit 1
    fi
    printf "%s\n" "$@" > "$tmpfile"

# Case 2: provided files
elif [ $# -gt 0 ]; then
    copied=0
    for file in "$@"; do
        if [ "$file" != "-" ]; then
            if [ -d "$file" ]; then
                echo "[!] Is a directory: $file" >&2
                failed=$((failed+1)); continue
            elif [ ! -e "$file" ]; then
                echo "[!] File not found: $file" >&2
                failed=$((failed+1)); continue
            elif [ ! -r "$file" ]; then
                echo "[!] Permission denied: $file" >&2
                failed=$((failed+1)); continue
            fi
        fi

        if [ $copied -gt 0 ]; then
            ensure_newline
            $no_sep || printf "%b" "$separator" >> "$tmpfile"
        fi

        if $show_label; then
            if [ "$file" = "-" ]; then
                printf ">>> (stdin)\n" >> "$tmpfile"
            else
                printf ">>> %s\n" "$file" >> "$tmpfile"
            fi
        fi

        if [ "$file" = "-" ]; then
            append_source
        else
            append_source "$file"
        fi
        copied=$((copied+1))
    done

    # Nothing was read: keep the current clipboard untouched
    if [ $copied -eq 0 ]; then
        echo "[!] Nothing copied; clipboard left unchanged." >&2
        exit 1
    fi

# Case 3: no files, but receiving stdin
elif [ ! -t 0 ]; then
    append_source

# Case 4: no arguments and no stdin
else
    show_help >&2
    exit 1
fi

# Remove trailing newlines when -t is used
if $trim_newline; then
    # Count bytes up to the last non-newline byte without passing file data
    # through a shell variable, which cannot represent NUL bytes.
    keep_bytes="$(od -An -tu1 -v "$tmpfile" | awk '
        { for (i = 1; i <= NF; i++) { count++; if ($i != 10) last = count } }
        END { print last + 0 }
    ')"
    trimmed_file="$(mktemp)"
    tmpfiles+=("$trimmed_file")
    head -c "$keep_bytes" "$tmpfile" > "$trimmed_file"
    tmpfile="$trimmed_file"
fi

# Copy to the clipboard
"${clip_cmd[@]}" < "$tmpfile"

# Save to a file when -o is used
[ -n "$outfile" ] && cp -- "$tmpfile" "$outfile"

# Display in the terminal unless -s is used; status messages go to stderr
if ! $silent; then
    cat -- "$tmpfile"
    # Keep the status message off the last content line when both share the terminal
    if [ -t 1 ] && [ -t 2 ] && [ -s "$tmpfile" ] && [ -n "$(tail -c1 "$tmpfile")" ]; then
        echo >&2
    fi
    if [ -n "$outfile" ]; then
        echo "[+] Content copied to the clipboard and saved to: $outfile" >&2
    else
        echo "[+] Content copied to the clipboard." >&2
    fi
fi

[ $failed -eq 0 ] || exit 1
