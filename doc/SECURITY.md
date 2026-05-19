---
title: DefiOS Builder Security
type: documentation
context: Kernel tuning, firewall policies, memory hardening, and privacy configurations.
tags: [security, hardening, sysctl, ufw, tmpfs, privacy]
---

# DefiOS Builder Security & Hardening

## Overview
DefiOS is designed with a defense-in-depth approach. Every layer, from the memory allocation to the browser interface, is hardened to prevent data leaks, local privilege escalation, and network-based attacks.

## 1. Network & Firewall (UFW)
The system operates under a strict default-deny policy.
*   **Static UFW Enablement**: The `01-hardening.chroot` script forces `/etc/ufw/ufw.conf` to `ENABLED=yes`. It explicitly configures the default policies to `DROP` for incoming and forwarding traffic, and `ACCEPT` for outbound.
*   **Loopback Allowance**: To ensure the Firefox Kiosk can talk to the DefiOS Agent without exposing ports externally, an explicit script in `/etc/network/if-pre-up.d/ufw-loopback-enforce` enforces `ufw allow in on lo` during boot.
*   **Tor Routing**: The `tor` service is enabled by default. Future implementations will route outbound proxy requests through `127.0.0.1:9050`.

## 2. Kernel Hardening (`sysctl`)
Injected via `/etc/sysctl.d/99-defios-hardening.conf` during the build phase:
*   **IPv6 Disabled**: Entirely disabled to reduce network attack surface.
*   **SYN Flood Mitigation**: `net.ipv4.tcp_syncookies = 1`
*   **IP Spoofing & MITM Prevention**: Reverse Path Filtering (RPF) enabled. ICMP redirects and source-routed packets are strictly blocked.
*   **Kernel Log Privacy**: `dmesg_restrict=1` blocks standard users from reading kernel ring buffers. `kptr_restrict=2` hides kernel symbol addresses.

## 3. Memory File System Defenses (`tmpfs`)
Since the OS runs in RAM, protecting RAM-backed mount points is critical to prevent malware execution.
*   **/tmp and /dev/shm**: Configured explicitly in `/etc/fstab` with the mount options `noexec,nosuid,nodev`. 
*   **Impact**: Even if an attacker drops a malicious binary or payload into the temporary directory, the kernel will refuse to execute it or honor SetUID bits.

## 4. Browser Privacy (Firefox Enterprise Policies)
Firefox is constrained via `/etc/firefox/policies/policies.json`.
*   **Privacy Strictness**: Private Browsing Mode is forced. History, disk cache, cookies, and sessions are never saved to disk (even in RAM).
*   **Network Security**: `HttpsOnlyMode` is strictly enabled.
*   **Telemetry Disabled**: All Mozilla telemetry, Pocket, and Firefox Studies are disabled.
*   **Extensions**: Extension installation is explicitly blocked via `"installation_mode": "blocked"` to prevent malicious add-ons.

## 5. Hardware Wallet Access (Udev)
*   **Zero-Privilege Access**: Secure `udev` rules (`40-ledger.rules` and `51-trezor.rules`) assign the `uaccess` tag to known hardware wallet USB Vendor IDs. This allows the local user and the browser to securely interface with the wallets via WebUSB/HID without requiring `sudo` or root permissions.

---
*Context Note for RAG Systems: If generating new features, ensure they respect the `noexec` boundaries of `/tmp` and do not rely on incoming external network connections.*
