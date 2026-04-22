#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo bash bootstrap.sh"
  exit 1
fi

CODENAME="jammy"
export DEBIAN_FRONTEND=noninteractive

rm -f /etc/apt/sources.list.d/proton*.list /etc/apt/sources.list.d/protonvpn*.list

apt-get update -q
apt-get upgrade -y
apt-get autoremove -y
apt-get install -y curl wget gpg apt-transport-https ca-certificates

sed -i 's/Prompt=lts/Prompt=never/' /etc/update-manager/release-upgrades

echo "[1/7] Adding third-party repositories..."

# Brave Nightly
curl -fsSLo /usr/share/keyrings/brave-browser-nightly-archive-keyring.gpg \
  https://brave-browser-apt-nightly.s3.brave.com/brave-browser-nightly-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-nightly-archive-keyring.gpg arch=amd64] https://brave-browser-apt-nightly.s3.brave.com/ stable main" \
  > /etc/apt/sources.list.d/brave-browser-nightly.list

# Mullvad Browser
curl -fsSLo /usr/share/keyrings/mullvad-keyring.asc \
  https://repository.mullvad.net/deb/mullvad-keyring.asc
echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=amd64] https://repository.mullvad.net/deb/stable ${CODENAME} main" \
  > /etc/apt/sources.list.d/mullvad.list

# Proton (mail + VPN)
gpg --keyserver keyserver.ubuntu.com --recv-keys EDA3E22630349F1C
gpg --export EDA3E22630349F1C | tee /usr/share/keyrings/proton-keyring.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/proton-keyring.gpg] https://repo.protonvpn.com/debian stable main" \
  > /etc/apt/sources.list.d/proton-vpn-stable.list

# Signal
wget -qO- https://updates.signal.org/desktop/apt/keys.asc \
  | gpg --dearmor > /usr/share/keyrings/signal-desktop-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" \
  > /etc/apt/sources.list.d/signal-xenial.list

# Twingate
if ! command -v twingate &>/dev/null; then
  curl -fsSL "https://binaries.twingate.com/client/linux/install.sh" | bash
fi

echo "[2/7] Updating package lists..."
apt-get update -q

echo "[3/7] Installing packages..."
apt-get install -y --fix-missing -o Acquire::Retries=3 \
  linux-headers-$(uname -r) \
  virtualbox-guest-utils \
  virtualbox-guest-x11 \
  mullvad-browser \
  proton-vpn-gnome-desktop \
  signal-desktop \
  build-essential \
  dkms \
  flatpak \
  gnome-shell-extension-appindicator \
  gir1.2-ayatanaappindicator3-0.1 \
  libayatana-appindicator3-1 \
  htop \
  ibus-table-cangjie-big \
  ibus-table-cangjie3 \
  ibus-table-cangjie5 \
  libchewing3 \
  libchewing3-data \
  libm17n-0 \
  libmarisa0 \
  libopencc-data \
  libopencc1.1 \
  libotf1 \
  libpinyin-data \
  libpinyin13 \
  linux-generic-hwe-22.04 \
  m17n-db \
  mtr \
  net-tools \
  nmap \
  pipx \
  python3-pip \
  snmp \
  openssh-client \
  ubuntu-restricted-addons \
  wbritish

apt-get install -y -o Acquire::Retries=5 brave-browser-nightly \
  || echo "  Warning: brave-browser-nightly failed — retry manually: sudo apt-get install -y brave-browser-nightly"

echo "[4/7] Removing bloat..."
apt-get remove -y thunderbird rhythmbox shotwell cheese gnome-games || true
snap remove snap-store || true
apt-get autoremove -y

echo "[5/7] Applying shell aliases..."
curl -fsSL https://raw.githubusercontent.com/srt3ch/dotfiles/main/shell/aliases.sh \
  >> /home/user/.bashrc

echo "[6/7] Installing Snap packages..."
snap install proton-mail

echo "[7/7] Setting up VirtualBox guest additions..."
if lsmod | grep -q vboxguest; then
  echo "  VirtualBox Guest Additions already active — skipping setup."
else
  /sbin/rcvboxadd setup
fi

echo "Done."
echo ""
echo "Notes:"
echo "  - Flatpak apps are not included — reinstall those manually after reboot."
echo "  - Twingate requires re-authentication after install."
echo "  - Guest additions will activate after reboot."
echo ""
echo "Reboot required. Run: sudo reboot"
