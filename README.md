# DefiOS: Secure Amnesic Live OS Builder 🛠️

[![OS: Debian Bookworm](https://img.shields.io/badge/OS-Debian%20Bookworm-blue.svg)](https://www.debian.org/)
[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CI: Build ISO](https://github.com/thiegocarvalho/defios/actions/workflows/build-iso.yml/badge.svg)](https://github.com/thiegocarvalho/defios/actions)

**DefiOS Builder** is a highly secure, automated compiler designed to build a custom amnesic Debian GNU/Linux Live OS (`amd64`). The operating system is purpose-built to run entirely in RAM, offering a zero-trust, ultra-hardened, and single-purpose environment optimized strictly for hardware wallet operations (Ledger, Trezor) and decentralized application nodes.

---

## 🌟 Core System Pillars

*   **🧠 Amnesic Execution (`toram`)**: The entire operating system SquashFS image is copied directly into RAM during the early boot process. Once booted, the USB drive can be physically removed. Zero logs, state, or temp files are ever written to the host computer's storage media, leaving no forensic traces upon shutdown.
*   **🛡️ Defense-in-Depth Hardening**: Uses strict kernel controls (`sysctl`), temporary filesystem mounts locked down with execution restrictions (`tmpfs` with `noexec,nosuid,nodev` for `/tmp`), and pre-configured Firewalls (`UFW`) blocking all external ingress.
*   **🔒 Local Isolation**: Loopback traffic only. The system serves the local control daemon (DefiOS Agent) on port `80` while ensuring loopback communication is exclusively allowed to keep incoming threats completely locked out.
*   **📟 Barebones Kiosk Experience**: Strips away traditional desktop environments (GNOME, KDE). It starts a bare X11 server using `nodm` and `IceWM`, immediately spawning a hardened, Enterprise-Policied Firefox ESR instance in full screen (`--kiosk --private-window`).
*   **🔌 Native Hardware Wallets**: Pre-packaged, zero-privilege `udev` rules allow direct, secure WebUSB/WebHID connections to **Ledger** and **Trezor** hardware wallets directly inside the browser sandbox, without requiring root access.

---

## 📂 Repository Structure

The layout closely aligns with Debian's `live-build` specification:

```text
defios-builder/
  ├── Makefile                     # Developer interface (config, build, clean)
  ├── auto/                        # live-build automation wrappers
  │    ├── config                  # System configurations (bookworm, zstd, toram)
  │    ├── build                   # ISO builder trigger
  │    └── clean                   # Cache remover
  ├── config/
  │    ├── package-lists/          # Defines packages installed (Tor, Docker, IceWM)
  │    ├── hooks/
  │    │    └── normal/            # Scripts executed during build
  │    │         ├── 01-hardening.chroot        # Kernel, UFW, and Firefox restrictions
  │    │         ├── 02-docker-setup.chroot     # Docker limits & optimizations
  │    │         └── 02-install-defios-agent.chroot  # Dynamic agent installer
  │    └── includes.chroot/        # Direct overlay files copied to root (/)
  │         └── etc/               # Custom configuration overrides (nodm, systemd)
  └── doc/                         # Comprehensive engineering documentation
       ├── ARCHITECTURE.md         # Live OS and pipeline design
       ├── SECURITY.md             # Firewall, sysctl, and tmpfs details
       └── FILE_STRUCTURE.md       # Full mapping of the file assets
```

---

## 🛠️ How to Compile the Live OS

To build the ISO, you will need a Debian-based host environment (Debian, Ubuntu, Linux Mint) with `live-build` tools installed.

### 1. Install Build Dependencies
```bash
sudo apt update
sudo apt install -y git make live-build debootstrap squashfs-tools
```

### 2. Configure the Pipeline
Initialize the `live-build` environment and auto-create the necessary directory scaffolds:
```bash
make config
```

### 3. Build the ISO (Requires root permissions)
Run the compilation process. This will download base packages, compile the chroot, execute security hardening hooks, dynamically clone the DefiOS Agent daemon, package the SquashFS using `zstd-19` compression, and output the final hybrid bootable ISO:
```bash
sudo make build
```

Upon successful completion, your bootable ISO will be generated at the root of your directory:
`defios-secure-live.iso`

### 4. Cleanup Workspace
Clean up build-time caches:
```bash
make clean
```
To purge all caches completely (chroot base, downloads):
```bash
make purge
```

---

## 💿 Installation & Deployment

To write the image to a physical USB flash drive:

### Using dd (Linux/macOS)
```bash
# Double check your USB device path (e.g. /dev/sdX) using lsblk!
sudo dd if=defios-secure-live.iso of=/dev/sdX bs=4M status=progress oflag=sync
```
*Alternatively, you can write the ISO using graphical tools like BalenaEtcher or Rufus (in DD mode).*

---

## 📖 Deep-Dive Engineering Docs

For an in-depth understanding of the architectural details, check our specialized engineering guides:
*   📚 **[OS Architecture & Performance Guide](./doc/ARCHITECTURE.md)**: Explore the in-memory swapping (ZRAM), SquashFS configurations, and IceWM polling mechanics.
*   🔒 **[OS Security & Hardening Model](./doc/SECURITY.md)**: Deep-dive into Kernel tuning parameters (`sysctl.conf`), UFW rules, `/tmp` mounts, and Firefox Enterprise restrictions.
*   🗺️ **[System Component Layout](./doc/FILE_STRUCTURE.md)**: A complete directory outline mapped to execution layers.

---

## 🤝 Contributing

Contributions are highly welcomed. Please follow these principles:
1. Ensure all `chroot` hooks fail-fast (`set -euo pipefail`).
2. Do not introduce packages that open listening network ports by default.
3. Test changes locally in a Virtual Machine (QEMU/VirtualBox) before pushing updates.

---

## 📄 License

This project is licensed under the GPLv3 License. See [LICENSE](LICENSE) for details.
