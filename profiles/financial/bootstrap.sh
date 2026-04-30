#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo bash bootstrap.sh"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[1/1] Setting up VPN split tunnel..."
SPLIT_BASE="https://raw.githubusercontent.com/srt3ch/dotfiles/main/network"
curl -fsSL "$SPLIT_BASE/vpn-split-tunnel" -o /usr/local/bin/vpn-split-tunnel \
  && chmod 755 /usr/local/bin/vpn-split-tunnel \
  || echo "  Warning: vpn-split-tunnel script fetch failed"
curl -fsSL "$SPLIT_BASE/99-vpn-split-tunnel" -o /etc/NetworkManager/dispatcher.d/99-vpn-split-tunnel \
  && chmod 755 /etc/NetworkManager/dispatcher.d/99-vpn-split-tunnel \
  || echo "  Warning: NM dispatcher fetch failed"
curl -fsSL "$SPLIT_BASE/vpn-split-tunnel-refresh.service" -o /etc/systemd/system/vpn-split-tunnel-refresh.service \
  || echo "  Warning: systemd service fetch failed"
curl -fsSL "$SPLIT_BASE/vpn-split-tunnel-refresh.timer" -o /etc/systemd/system/vpn-split-tunnel-refresh.timer \
  || echo "  Warning: systemd timer fetch failed"
curl -fsSL "$SPLIT_BASE/vpn-exclude-domains" -o /etc/vpn-exclude-domains \
  || echo "  Warning: domain list fetch failed"
systemctl daemon-reload \
  || echo "  Warning: systemd daemon-reload failed"

echo "Done."
echo ""
echo "Notes:"
echo "  - ProtonVPN: log in, then disable Advanced Kill Switch (keep Standard Kill Switch on)."
echo "  - Add financial domains to /etc/vpn-exclude-domains as needed."
echo ""
echo "Reboot required. Run: sudo reboot"
