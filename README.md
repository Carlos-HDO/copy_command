# Copy Command (`c`)

A lightweight, versatile Bash terminal utility designed to copy file contents or standard input (`stdin`) directly to the system clipboard (`wl-copy`, `xsel`, `xclip` or `pbcopy`), featuring advanced formatting options, file headers, custom delimiters, and line numbering.

---

## ⚡ Features

- **Fast Clipboard Copying**: Quickly copy single or multiple files directly to your clipboard.
- **Pipe Support (`stdin`)**: Seamlessly chains with terminal pipelines (e.g., `ls -l | c`, `git diff | c`, or `cat server.log | c`).
- **Headers & Custom Separators**: Prepend file names as headers (`-l`) and define custom delimiters between files (`-d`).
- **Line Numbering (`-r`)**: Prefix copied lines with line numbers in `nl` format.
- **Filenames Only (`-u`)**: Copy only the file names (one per line) rather than the file contents.
- **Silent Mode (`-s`)**: Suppress terminal output and copy silently to the clipboard.
- **Dual Output (`-o`)**: Save processed output to a local file while simultaneously copying to the clipboard.
- **Safe Failures**: Missing files are reported and return a non-zero exit code; the clipboard is never overwritten with empty content when nothing could be read.

---

## 📦 Dependencies

This tool needs one clipboard backend. The first one available is used, in this order:

1. `wl-copy` (from `wl-clipboard`), when running under Wayland
2. `xsel` (X11)
3. `xclip` (X11)
4. `pbcopy` (macOS, built in)

### Debian / Ubuntu / Kali / Pop!_OS
```bash
sudo apt update && sudo apt install -y xsel        # X11
sudo apt update && sudo apt install -y wl-clipboard # Wayland
```

### Arch Linux / Manjaro
```bash
sudo pacman -S xsel        # X11
sudo pacman -S wl-clipboard # Wayland
```

### Fedora
```bash
sudo dnf install xsel        # X11
sudo dnf install wl-clipboard # Wayland
```

---

## 🚀 Usage & Examples

Once configured with the `c` command (via alias or `./install.sh`), use it directly anywhere in your terminal:

### Basic Usage
```bash
# Copy a single file to clipboard
c myfile.txt

# Copy from pipeline (stdin)
git status | c
cat /etc/resolv.conf | c

# Silent copy (copies to clipboard without printing to terminal)
c -s config.yml
```

### Advanced Examples
```bash
# Copy multiple files with file headers (-l) and numbered lines (-r)
c -l -r main.py utils.py

# Copy only the filenames matching a pattern
c -u *.log

# Use a custom separator and save the output to a file simultaneously
c -d "--- NEXT FILE ---" -o combined.txt file1.txt file2.txt

# Pipe any command output directly to clipboard silently
curl -s https://api.ipify.org | c -s

# Mix stdin ("-") with regular files
git diff | c -l - notes.md
```

---

## 🛠️ Command-Line Options

| Flag | Description |
| :--- | :--- |
| `-s` | **Silent**: Suppress terminal stdout output; copy only to clipboard |
| `-h` | **Help**: Display the help menu and usage instructions |
| `-n` | **No separator**: Do not insert default separators between files |
| `-d <text>` | **Delimiter**: Set a custom separator string between files |
| `-o <file>` | **Output file**: Save the combined output to the specified file |
| `-l` | **Label/Header**: Display the file name header before its contents |
| `-r` | **Number lines**: Number each line of content (similar to `nl`) |
| `-u` | **Names only**: Copy only the list of file names, excluding content |

Options must come before file names (use `--` to stop option parsing). `-n` and `-d` cannot be combined.

Status messages are written to `stderr`, so `stdout` carries only the copied content. The exit code is `0` on success and `1` if any file could not be read or on usage errors.

---

## 🔗 Global Shell Shortcut (Alias)

To execute the tool from any directory with the simple `c` command, add a generic alias to your `~/.zshrc` or `~/.bashrc`:

```bash
# Generic alias pointing to your clone location
alias c="$HOME/path/to/copy_command/copy.sh"

# Or using relative home path:
alias c="~/projects/copy_command/copy.sh"
```

Alternatively, install it into your user binaries without needing manual aliases. This creates two symlinks, `~/.local/bin/c` and `~/.local/bin/copy-clip`, and warns if no clipboard backend is installed or `~/.local/bin` is not in your `PATH`:
```bash
chmod +x install.sh
./install.sh
```

> **Note:** if your shell already defines `c` (e.g. `alias c=clear`), that alias takes precedence. Remove it or use `copy-clip` instead.

---

## 📄 License

Distributed under the [MIT](LICENSE) License.
