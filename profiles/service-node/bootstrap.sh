#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo bash bootstrap.sh"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[1/3] Hardening SSH..."
SSHD_CONF="/etc/ssh/sshd_config"
if ! dpkg -l openssh-server &>/dev/null; then
  apt-get install -y openssh-server
fi
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONF"
sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' "$SSHD_CONF"
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONF"
grep -q '^PubkeyAuthentication' "$SSHD_CONF" \
  && sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONF" \
  || echo "PubkeyAuthentication yes" >> "$SSHD_CONF"
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null \
  || echo "  Warning: could not restart SSH — verify manually"
echo "  PermitRootLogin no, X11Forwarding no, PasswordAuthentication no, PubkeyAuthentication yes"

echo "[2/3] Installing and configuring fail2ban..."
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
echo "  SSH jail: 24h ban after 3 failed attempts"

echo "[3/3] Opening SSH in firewall..."
ufw allow 22/tcp
echo "  ufw: port 22 allowed"

echo "Done."
echo ""
echo "Service node hardening complete."
echo "  - SSH: pubkey-only, no root login, no X11"
echo "  - fail2ban: 24h SSH ban after 3 attempts"
echo "  - ufw: port 22 open"
