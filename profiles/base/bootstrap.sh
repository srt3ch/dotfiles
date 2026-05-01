#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo bash bootstrap.sh"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get install -y curl

sed -i 's/Prompt=lts/Prompt=never/' /etc/update-manager/release-upgrades || true

echo "[1/6] Updating system..."
apt-get update -q
apt-get upgrade -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  || echo "  Warning: upgrade had failures — check output above"
apt-get autoremove -y
apt-get install -y curl wget gpg apt-transport-https ca-certificates

echo "[2/6] Installing base packages..."
apt-get install -y --fix-missing -o Acquire::Retries=3 \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  linux-headers-$(uname -r) \
  build-essential \
  dkms \
  flatpak \
  htop \
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

echo "[3/6] Removing bloat..."
apt-get remove -y thunderbird rhythmbox shotwell cheese gnome-games || true
snap remove snap-store || true
apt-get autoremove -y || true

echo "[4/6] Hardening system..."

SSHD_CONF="/etc/ssh/sshd_config"
if [ -f "$SSHD_CONF" ]; then
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONF"
  sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' "$SSHD_CONF"
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONF"
  grep -q '^PubkeyAuthentication' "$SSHD_CONF" \
    && sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONF" \
    || echo "PubkeyAuthentication yes" >> "$SSHD_CONF"
  systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null \
    || echo "  Warning: could not restart SSH — verify manually"
else
  echo "  sshd_config not found — skipping SSH hardening (openssh-server not installed)"
fi

passwd -l root

systemctl disable --now cups cups.socket cups.path 2>/dev/null || true

apt-get install -y fail2ban
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled = true
bantime = 24h
maxretry = 3
EOF
systemctl enable --now fail2ban

apt-get install -y unattended-upgrades
dpkg-reconfigure -f noninteractive unattended-upgrades
systemctl enable --now unattended-upgrades || true

ufw --force reset > /dev/null
ufw --force enable

echo "[5/6] Configuring display for host environment..."
HOST_OS=$(VBoxControl guestproperty get /VirtualBox/HostInfo/HostOSType 2>/dev/null | awk '/^Value:/{print $2}')
if [[ "$HOST_OS" == Linux* ]]; then
  sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf \
    || echo "  Warning: could not disable Wayland in GDM config"
else
  cat > /etc/xdg/autostart/vboxdrmclient.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=VirtualBox DRM Client
Exec=/usr/bin/VBoxDRMClient
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
fi

echo "[6/6] Applying shell aliases..."
curl -fsSL https://raw.githubusercontent.com/srt3ch/dotfiles/main/shell/aliases.sh \
  >> "$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)/.bashrc" \
  || echo "  Warning: aliases fetch failed — add manually from shell/aliases.sh"

echo "Done."
echo ""
echo "Base image is now ready. Be sure to save this and clone before bootstrapping another profile."
