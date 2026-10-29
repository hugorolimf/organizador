#!/usr/bin/env bash
# Installs organizador for the current user and starts its watcher service.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
bin="$HOME/.local/bin"
units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
config="${XDG_CONFIG_HOME:-$HOME/.config}/organizador/config.toml"

if ! python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))' 2>/dev/null; then
  echo "organizador needs Python 3.11 or newer." >&2
  exit 1
fi

# command -> Arch package
missing=()
for pair in inotifywait:inotify-tools pdftotext:poppler pdftoppm:poppler tesseract:tesseract \
            unzip:unzip notify-send:libnotify ollama:ollama; do
  command -v "${pair%%:*}" >/dev/null || missing+=("${pair#*:}")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing tools. On Arch / Omarchy:"
  echo "  sudo pacman -S --needed $(printf '%s\n' "${missing[@]}" | sort -u | tr '\n' ' ')tesseract-data-por tesseract-data-eng"
  echo "(ollama-cuda or ollama-rocm instead of ollama for GPU acceleration.)"
  echo
fi

install -Dm755 "$here/organizador" "$bin/organizador"
install -Dm644 "$here/systemd/organizador.service" "$units/organizador.service"
echo "Installed $bin/organizador and $units/organizador.service"

if [ ! -f "$config" ]; then
  echo "No config file: using the Portuguese defaults."
  echo "  English: mkdir -p ${config%/*} && cp $here/config.en.toml $config"
fi

model=$(ORGANIZADOR_CONFIG="$config" python3 -c '
import os, tomllib
p = os.environ["ORGANIZADOR_CONFIG"]
print(tomllib.load(open(p, "rb")).get("model", "qwen3.5:4b") if os.path.isfile(p) else "qwen3.5:4b")')
if command -v ollama >/dev/null && ! ollama list 2>/dev/null | awk 'NR > 1 { print $1 }' | grep -qx "$model"; then
  echo "Download the model once: ollama pull $model"
fi

systemctl --user daemon-reload
systemctl --user enable --now organizador.service
echo "Watching ~/Downloads. Follow it with: journalctl --user -u organizador -f"
