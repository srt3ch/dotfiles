# dotfiles

Personal dotfiles and machine bootstrap profiles.

## Profiles

- `profiles/base` — foundation for all VMs; run this first on any fresh Jammy install
- `profiles/personal-ubuntu-jammy` — personal Ubuntu 22.04 desktop (browsers, Signal, ProtonVPN, dock)
- `profiles/financial` — financial VM (VPN split tunnel for bypassing IP blocks on financial sites)

## Usage

All bootstraps must run as root. Switch to root first:

```bash
sudo su -
```

### 1. Base (run on every fresh VM)

```bash
wget -qO- https://raw.githubusercontent.com/srt3ch/dotfiles/main/profiles/base/bootstrap.sh | bash
```

### 2. Profile (run after base, on the cloned VM)

**Personal:**
```bash
wget -qO- https://raw.githubusercontent.com/srt3ch/dotfiles/main/profiles/personal-ubuntu-jammy/bootstrap.sh | bash
```

**Financial:**
```bash
wget -qO- https://raw.githubusercontent.com/srt3ch/dotfiles/main/profiles/financial/bootstrap.sh | bash
```

Then reboot:
```bash
reboot
```

## What each profile does

### Base
1. Updates and upgrades system packages
2. Installs core tools — build essentials, networking tools, HWE kernel, flatpak, pipx, and more
3. Removes bloat (Thunderbird, Rhythmbox, Shotwell, Cheese, snap-store)
4. Hardens system — locks root password, disables CUPS, installs fail2ban, enables ufw (deny all inbound), enables unattended upgrades
5. Configures display for host environment (Linux vs Windows host)
6. Appends shell aliases to `.bashrc`

### Personal
1. Adds third-party apt repositories (Brave Nightly, Mullvad, Proton, Signal)
2. Installs Twingate
3. Installs packages — Brave Nightly, Mullvad Browser, ProtonVPN, Signal, GNOME appindicator, Chinese input methods
4. Configures GNOME dock favorites and autostart for Signal and ProtonVPN
5. Installs Proton Mail snap

### Financial
1. Installs VPN split tunnel — NetworkManager dispatcher, systemd refresh timer, domain bypass list

## Post-reboot checklist

- **ProtonVPN** — log in, then go to Settings and disable Advanced Kill Switch (keep Standard Kill Switch on). Advanced Kill Switch blocks the split tunnel bypass routes.
- **Twingate** — re-authenticate after install.
- **Flatpak apps** — not included in the bootstrap; reinstall manually.

## VPN split tunnel (financial profile)

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
