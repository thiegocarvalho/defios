---
title: DefiOS Builder Architecture
type: documentation
context: Architectural patterns, performance mechanisms, and live-build configurations for DefiOS.
tags: [architecture, live-build, zram, squashfs, kiosk, amnesic]
---

# DefiOS Builder Architecture & Infrastructure

## Overview
The architecture of DefiOS revolves around building a customized Debian Live OS that operates with maximum efficiency entirely from RAM. It sheds desktop bloat to provide a precise, targeted execution environment for the DefiOS Agent.

## 1. Live-Build Pipeline
The project uses Debian `live-build` to orchestrate the ISO compilation. The pipeline is abstracted via a custom `Makefile`.

*   **Make Targets**: `make config`, `make build`, `make clean`, `make purge`.
*   **Base Distribution**: Debian Bookworm (Stable) - `amd64`.
*   **SquashFS Compression**: The system is compressed using `zstd` with compression level 19 (`-Xcompression-level 19`). This achieves an extremely small image size on disk (USB) while providing blazing fast decompression speeds into RAM upon boot.
*   **Boot Parameters (`--bootappend-live`)**:
    *   `toram`: Instructs the live bootloader to copy the entire filesystem into memory before handing over control to systemd. This permits the USB drive to be removed post-boot.
    *   `integrity-check`: Validates the squashfs payload before execution.

## 2. Display & Kiosk Layer
To minimize the attack surface and maximize performance, DefiOS does not ship with GNOME, KDE, or XFCE.

*   **Window Manager**: `IceWM` provides a barebones graphical environment.
*   **Display Manager**: `nodm` handles X11 initialization. It is configured to auto-login the default `user` without prompting for credentials.
*   **Kiosk Interface**: Firefox ESR is the sole interface. An IceWM startup script disables screen blanking/DPMS and launches Firefox with `--kiosk --private-window http://127.0.0.1`.

## 3. RAM Optimization (ZRAM)
Because the OS resides entirely in RAM alongside its active state, memory pressure can occur.
*   **Zram-Tools**: Configured in `/etc/default/zram-tools`, it creates a high-performance compressed block device in RAM that acts as swap space.
*   **Allocation**: Automatically provisions up to 60% of total system RAM using the `zstd` algorithm. This is critical for environments like Virtual Machines (VMs) with restricted memory ceilings.

## 4. DefiOS Agent Daemon Integration
The bridge between the hardware wallet and the user interface.
*   **Execution**: Managed by a systemd service (`defios-agent.service`). It starts as root to bind to privileged ports and perform block-device encryption tasks (`cryptsetup`).
*   **Resilience**: The IceWM kiosk script actively polls `http://127.0.0.1` and will only launch the browser once the Agent responds, preventing "Connection Refused" UX errors.

---
*Reference: Refer to [SECURITY.md](./SECURITY.md) to understand how the network and kernel restrict this architecture.*
