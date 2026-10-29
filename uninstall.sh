#!/usr/bin/env bash
# Stops and removes organizador. Files it already moved stay where they are;
# the move log and your config are kept (delete them by hand if you want).
set -euo pipefail

units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

systemctl --user disable --now organizador.service 2>/dev/null || true
rm -f "$units/organizador.service" "$HOME/.local/bin/organizador"
systemctl --user daemon-reload

echo "organizador removed. Kept:"
echo "  ${XDG_STATE_HOME:-$HOME/.local/state}/organizador/movimentos.jsonl  (every move, to undo by hand)"
echo "  ${XDG_CONFIG_HOME:-$HOME/.config}/organizador/  (your config, if any)"
