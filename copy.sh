#!/bin/bash
# c — copia conteúdo de arquivos ou stdin para o clipboard (xsel), com opções úteis.

set -euo pipefail

show_help() {
    cat <<'EOF'
Uso: c [opções] [arquivos]

Descrição:
  Copia o conteúdo de um ou mais arquivos para a área de transferência (xsel).
  Se nenhum arquivo for informado e houver entrada padrão (pipe), lê do stdin.

Opções:
  -s            Silencioso: não exibe no terminal (só copia).
  -h            Mostra esta ajuda.
  -n            Não adiciona separadores entre arquivos.
  -d <texto>    Define separador customizado entre arquivos.
  -o <arquivo>  Também salva a saída nesse arquivo.
  -l            Mostra o nome do arquivo antes do conteúdo (header).
  -r            Numera as linhas do conteúdo (estilo 'nl').
  -u            Copia apenas os NOME(S) dos arquivos (um por linha), sem conteúdo.

Exemplos:
  c README.md
  c -s *.txt
  c -d "---" a.txt b.txt
  c -o saida.txt *.log
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
        :) echo "[!] Opção -$OPTARG requer argumento." >&2; exit 1 ;;
        \?) echo "[!] Opção inválida: -$OPTARG" >&2; show_help; exit 1 ;;
    esac
done
shift $((OPTIND-1))

# Temp buffer
tmpfile="$(mktemp)"
cleanup() { rm -f "$tmpfile"; }
trap cleanup EXIT

# Caso 1: somente nomes (-u)
if $only_names; then
    if [ $# -eq 0 ]; then
        echo "[!] Nenhum arquivo especificado para -u." >&2
        exit 1
    fi
    printf "%s\n" "$@" > "$tmpfile"

# Caso 2: arquivos fornecidos
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
            echo "[!] Arquivo não encontrado: $file" >&2
        fi
    done

# Caso 3: sem arquivos, mas recebendo stdin
elif [ ! -t 0 ]; then
    if $number_lines; then
        nl -ba >> "$tmpfile"
    else
        cat >> "$tmpfile"
    fi

# Caso 4: nenhum argumento e nenhum stdin
else
    show_help
    exit 1
fi

# Copia para o clipboard
xsel --input --clipboard < "$tmpfile"

# Salva em arquivo, se -o
[ -n "$outfile" ] && cp -- "$tmpfile" "$outfile"

# Exibe no terminal, a menos que -s
if ! $silent; then
    cat -- "$tmpfile"
fi

# Mensagem final
if [ -n "$outfile" ]; then
    echo "[+] Conteúdo copiado para o clipboard e salvo em: $outfile"
else
    echo "[+] Conteúdo copiado para o clipboard."
fi
