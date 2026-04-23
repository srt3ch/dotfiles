# dotfiles

Personal dotfiles and machine bootstrap profiles.

## Profiles

- `profiles/personal-ubuntu-jammy` — Ubuntu 22.04 (Jammy) desktop, VirtualBox

## Usage

```bash
wget -qO- https://raw.githubusercontent.com/srt3ch/dotfiles/main/profiles/personal-ubuntu-jammy/bootstrap.sh | sudo bash
```

If `wget` is not available:

```bash
curl -fsSL https://raw.githubusercontent.com/srt3ch/dotfiles/main/profiles/personal-ubuntu-jammy/bootstrap.sh | sudo bash
```

## What the bootstrap does

1. Adds third-party apt repositories (Brave Nightly, Mullvad, Proton, Signal)
2. Installs packages — Brave Nightly, Mullvad Browser, ProtonVPN, Signal, build tools, networking tools, Chinese input methods, HWE kernel
3. Removes bloat (Thunderbird, Rhythmbox, Shotwell, Cheese, snap-store)
4. Configures GNOME dock favorites and autostart for Signal and ProtonVPN
5. Disables Wayland (required for VirtualBox guest display resizing under X11)
6. Installs VPN split tunnel — NetworkManager dispatcher, systemd refresh timer, domain bypass list
7. Appends shell aliases to `.bashrc`
8. Installs Proton Mail snap
9. Detects the host VirtualBox version and installs matching Guest Additions from the official ISO (enables clipboard, drag-and-drop, and dynamic window resizing)

Reboot is required after the script completes.

## Post-reboot checklist

- **ProtonVPN** — log in, then go to Settings and disable Advanced Kill Switch (keep Standard Kill Switch on). Advanced Kill Switch blocks the split tunnel bypass routes.
- **Twingate** — re-authenticate after install.
- **Flatpak apps** — not included in the bootstrap; reinstall manually.

## VPN split tunnel

Financial and credit sites are routed outside the VPN tunnel to avoid IP-based blocks. Bypass domains are defined in `network/vpn-exclude-domains`:

- `creditkarma.com`
- `chase.com`
- `navyfederal.org`
- `capitalone.com`
- `americanexpress.com`

Both the bare domain and `www.` are resolved automatically. Routes refresh every 15 minutes while the VPN is connected.

To add a domain:

```bash
sudo nano /etc/vpn-exclude-domains
```

Then manually trigger a refresh:

```bash
sudo /usr/local/bin/vpn-split-tunnel
```

## Prerequisites

### VirtualBox unattended install

If the VM was provisioned using VirtualBox's unattended install, the default user will not be a sudoer. Fix this before running the bootstrap:

```bash
su -
usermod -aG sudo <username>
exit
```

Log out and back in for the change to take effect.
