#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo bash bootstrap.sh"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get install -y curl

sed -i 's/Prompt=lts/Prompt=never/' /etc/update-manager/release-upgrades || true

echo "[1/5] Updating system..."
apt-get update -q
apt-get upgrade -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  || echo "  Warning: upgrade had failures — check output above"
apt-get autoremove -y
apt-get install -y curl wget gpg apt-transport-https ca-certificates

echo "[2/5] Installing base packages..."
apt-get install -y --fix-missing -o Acquire::Retries=3 \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  linux-headers-$(uname -r) \
  build-essential \
  dkms \
  flatpak \
  htop \
  linux-generic-hwe-22.04 \
  mtr \
  net-tools \
  nmap \
  pipx \
  python3-pip \
  snmp \
  openssh-client \
  dnsutils \
  ubuntu-restricted-addons \
  wbritish \
  || echo "  Warning: one or more packages failed — check output above"

echo "[3/5] Removing bloat..."
apt-get remove -y thunderbird rhythmbox shotwell cheese gnome-games || true
snap remove snap-store || true
apt-get autoremove -y || true

echo "[4/5] Configuring VBoxDRMClient autostart..."
cat > /etc/xdg/autostart/vboxdrmclient.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=VirtualBox DRM Client
Exec=/usr/bin/VBoxDRMClient
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

echo "[5/5] Applying shell aliases..."
curl -fsSL https://raw.githubusercontent.com/srt3ch/dotfiles/main/shell/aliases.sh \
  >> "$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)/.bashrc" \
  || echo "  Warning: aliases fetch failed — add manually from shell/aliases.sh"

echo "Done."
echo ""
echo "Base image is now ready. Be sure to save this and clone before bootstrapping another profile."
