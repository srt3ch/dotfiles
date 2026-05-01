#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo bash bootstrap.sh"
  exit 1
fi

CODENAME="jammy"
export DEBIAN_FRONTEND=noninteractive

rm -f /etc/apt/sources.list.d/proton*.list /etc/apt/sources.list.d/protonvpn*.list

hostnamectl set-hostname personal

echo "[1/6] Adding third-party repositories..."

# Brave Nightly
curl -fsSL --connect-timeout 30 --max-time 60 \
  -o /usr/share/keyrings/brave-browser-nightly-archive-keyring.gpg \
  https://brave-browser-apt-nightly.s3.brave.com/brave-browser-nightly-archive-keyring.gpg \
  || echo "  Warning: Brave keyring fetch failed — brave-browser-nightly repo may not install"
echo "deb [signed-by=/usr/share/keyrings/brave-browser-nightly-archive-keyring.gpg arch=amd64] https://brave-browser-apt-nightly.s3.brave.com/ stable main" \
  > /etc/apt/sources.list.d/brave-browser-nightly.list

# Mullvad Browser
curl -fsSL --connect-timeout 30 --max-time 60 \
  -o /usr/share/keyrings/mullvad-keyring.asc \
  https://repository.mullvad.net/deb/mullvad-keyring.asc \
  || echo "  Warning: Mullvad keyring fetch failed — mullvad-browser repo may not install"
echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=amd64] https://repository.mullvad.net/deb/stable ${CODENAME} main" \
  > /etc/apt/sources.list.d/mullvad.list

# Proton (mail + VPN)
gpg --keyserver keyserver.ubuntu.com --recv-keys EDA3E22630349F1C \
  || echo "  Warning: Proton GPG keyserver fetch failed — Proton repo may not install"
gpg --export EDA3E22630349F1C | tee /usr/share/keyrings/proton-keyring.gpg > /dev/null \
  || echo "  Warning: Proton GPG export failed"
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/proton-keyring.gpg] https://repo.protonvpn.com/debian stable main" \
  > /etc/apt/sources.list.d/proton-vpn-stable.list

# Signal
wget -qO- https://updates.signal.org/desktop/apt/keys.asc \
  | gpg --dearmor > /usr/share/keyrings/signal-desktop-keyring.gpg \
  || echo "  Warning: Signal key fetch failed — Signal repo may not install"
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" \
  > /etc/apt/sources.list.d/signal-xenial.list

# Twingate
if ! command -v twingate &>/dev/null; then
  curl -fsSL "https://binaries.twingate.com/client/linux/install.sh" | bash \
    || echo "  Warning: Twingate install failed — install manually after reboot"
fi

echo "[2/6] Updating package lists..."
apt-get update -q \
  || echo "  Warning: apt update had failures — some third-party repos may be unreachable"

echo "[3/6] Installing packages..."
apt-get install -y --fix-missing -o Acquire::Retries=3 \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  mullvad-browser \
  proton-vpn-gnome-desktop \
  signal-desktop \
  gnome-shell-extension-appindicator \
  gir1.2-ayatanaappindicator3-0.1 \
  libayatana-appindicator3-1 \
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
  m17n-db \
  || echo "  Warning: one or more packages failed — check output above for details"

apt-get install -y -o Acquire::Retries=5 brave-browser-nightly \
  || echo "  Warning: brave-browser-nightly failed — retry manually: sudo apt-get install -y brave-browser-nightly"

echo "[4/6] Configuring GNOME dock and autostart..."
cat > /usr/share/glib-2.0/schemas/99_custom.gschema.override << 'EOF'
[org.gnome.shell]
favorite-apps = ['brave-browser-nightly.desktop', 'mullvad-browser.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop']
EOF
glib-compile-schemas /usr/share/glib-2.0/schemas/ \
  || echo "  Warning: glib-compile-schemas failed — dock favorites may not apply"

cat > /etc/xdg/autostart/signal-desktop-autostart.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Signal
Exec=signal-desktop --start-in-tray
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

cat > /etc/xdg/autostart/protonvpn-autostart.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=ProtonVPN
Exec=protonvpn-app --start-minimized
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

echo "[5/6] Installing Snap packages..."
snap install proton-mail \
  || echo "  Warning: proton-mail snap failed — retry manually: snap install proton-mail"

echo "Done."
echo ""
echo "Notes:"
echo "  - Flatpak apps are not included — reinstall those manually after reboot."
echo "  - Twingate requires re-authentication after install."
echo "  - ProtonVPN: log in, then disable Advanced Kill Switch (keep Standard Kill Switch on)."
echo ""
echo "Reboot required. Run: sudo reboot"
