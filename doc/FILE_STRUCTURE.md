---
title: DefiOS Builder File Structure
type: documentation
context: Mapping of the repository layout, hooks, and build configuration files.
tags: [structure, layout, hooks, packages]
---

# DefiOS File Structure & Components

## Directory Layout
The repository is rooted at `defios-builder/`. It closely follows the standard directory layout expected by Debian's `live-build` toolkit.

```text
/defios-builder
  ├── Makefile
  ├── auto/
  │    ├── config
  │    ├── build
  │    └── clean
  └── config/
       ├── package-lists/
       │    └── defios.list.chroot
       ├── hooks/
       │    └── normal/
       │         ├── 01-hardening.chroot
       │         └── 02-docker-setup.chroot
       └── includes.chroot/
            ├── etc/
            │    ├── default/
            │    │    ├── nodm
            │    │    └── zram-tools
            │    ├── skel/
            │    │    └── .icewm/
            │    │         └── startup
            │    ├── systemd/
            │    │    └── system/
            │    │         └── defios-agent.service
            │    └── udev/
            │         └── rules.d/
            │              ├── 40-ledger.rules
            │              └── 51-trezor.rules
```

## Component Mapping

### 1. Build Automation
*   **`Makefile`**: The entry point for developers. Wraps the `live-build` commands into `make config`, `make build`, and `make clean`.
*   **`auto/config`**: Core definitions for the OS generation. Specifies Debian Bookworm, amd64 architecture, firmware inclusion, and critical boot flags (`toram`, `zstd` squashfs compression).
*   **`auto/build` & `auto/clean`**: Standard wrapper scripts that execute `lb build` and `lb clean`.

### 2. Package Management
*   **`config/package-lists/defios.list.chroot`**: Defines every Debian package installed in the live image. Divided conceptually into System Core, X11 Minimal Graphics, Hardware Drivers, and Security/Crypto utilities (Tor, UFW, Docker).

### 3. Execution Hooks (`config/hooks/normal/`)
These bash scripts execute as `root` inside the uncompressed filesystem *during* the build phase.
*   **`01-hardening.chroot`**: The most critical file for security. It injects sysctl rules, configures the UFW firewall, writes the Firefox enterprise `policies.json`, locks down `/etc/fstab` (for `/tmp` `noexec`), and enables systemd services.
*   **`02-docker-setup.chroot`**: Enables the Docker daemon and limits its logging size in `/etc/docker/daemon.json` to prevent RAM exhaustion.
*   **`02-install-defios-agent.chroot`**: Dynamically downloads curl/unzip/git, installs the Bun runtime, clones the real `defios-agent` from GitHub, and runs `bun install` under `/opt/defios-agent` inside the chroot environment.

### 4. Overlaid Files (`config/includes.chroot/`)
Any file placed here is directly copied to the root (`/`) of the Live OS.
*   **`etc/default/nodm`**: Configures the display manager to bypass login screens and instantly load the X session for the user `user`.
*   **`etc/default/zram-tools`**: Allocates RAM for compressed swapping.
*   **`etc/skel/.icewm/startup`**: Since the live user's home directory is created dynamically on boot, files in `/etc/skel` are copied to `/home/user`. This script starts the browser in Kiosk mode.
*   **`etc/systemd/system/defios-agent.service`**: The systemd unit file that launches the Agent on boot from `/opt/defios-agent`.

---
*Context Note for RAG Systems: To modify the behavior of the built OS, edit the files within `config/includes.chroot/`. To modify the software installed, edit `defios.list.chroot`. To modify kernel/boot behavior, edit `auto/config`. The Agent Daemon code is pulled dynamically during build-time by the `02-install-defios-agent.chroot` hook.*
