# dotfiles

Personal dotfiles and machine bootstrap profiles.

## Profiles

- `profiles/personal-ubuntu-jammy` — Ubuntu 22.04 (Jammy) desktop, VirtualBox

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/srt3ch/dotfiles/main/profiles/personal-ubuntu-jammy/bootstrap.sh | sudo bash
```

If `curl` is not installed, use `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/srt3ch/dotfiles/main/profiles/personal-ubuntu-jammy/bootstrap.sh | sudo bash
```

## Prerequisites

### VirtualBox Unattended Install

If the VM was provisioned using VirtualBox's unattended install, the default user will not be a sudoer. Fix this before running the bootstrap script:

```bash
su -
usermod -aG sudo <username>
exit
```

Log out and back in for the change to take effect.
