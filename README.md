# Copy Command (`c`)

A lightweight, versatile Bash terminal utility designed to copy file contents or standard input (`stdin`) directly to the system clipboard via `xsel`, featuring advanced formatting options, file headers, custom delimiters, and line numbering.

---

## ⚡ Features

- **Fast Clipboard Copying**: Quickly copy single or multiple files directly to your clipboard.
- **Pipe Support (`stdin`)**: Seamlessly chains with terminal pipelines (e.g., `ls -l | c`, `git diff | c`, or `cat server.log | c`).
- **Headers & Custom Separators**: Prepend file names as headers (`-l`) and define custom delimiters between files (`-d`).
- **Line Numbering (`-r`)**: Prefix copied lines with line numbers in `nl` format.
- **Filenames Only (`-u`)**: Copy only the file names (one per line) rather than the file contents.
- **Silent Mode (`-s`)**: Suppress terminal output and copy silently to the clipboard.
- **Dual Output (`-o`)**: Save processed output to a local file while simultaneously copying to the clipboard.

---

## 📦 Dependencies

This tool requires `xsel` to interact with the X11 clipboard:

### Debian / Ubuntu / Kali / Pop!_OS
```bash
sudo apt update && sudo apt install -y xsel
```

### Arch Linux / Manjaro
```bash
sudo pacman -S xsel
```

### Fedora
```bash
sudo dnf install xsel
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

---

## 🔗 Global Shell Shortcut (Alias)

To execute the tool from any directory with the simple `c` command, add a generic alias to your `~/.zshrc` or `~/.bashrc`:

```bash
# Generic alias pointing to your clone location
alias c="$HOME/path/to/copy_command/copy.sh"

# Or using relative home path:
alias c="~/projects/copy_command/copy.sh"
```

Alternatively, install it into your user binaries (`~/.local/bin/c`) without needing manual aliases:
```bash
chmod +x install.sh
./install.sh
```

---

## 📄 License

Distributed under the [MIT](LICENSE) License.
