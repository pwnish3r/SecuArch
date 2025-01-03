<!-- PROJECT TITLE & BADGES -->
<h1 align="center">SecuArch: Automated Arch Linux BTRFS Installation for Pentesters</h1>
<p align="center">
  <img src="https://img.shields.io/badge/ArchLinux-BTRFS-informational?style=flat&logo=arch-linux&color=1793D1" alt="ArchLinux BTRFS"/>
  <img src="https://img.shields.io/badge/Focus-OffSec/CyberSec-success?style=flat"/>
  <img src="https://img.shields.io/github/license/YourUsername/YourRepoName?style=flat" alt="License"/>
  <img src="https://img.shields.io/github/issues/YourUsername/YourRepoName?style=flat" alt="Issues"/>
  <img src="https://img.shields.io/github/forks/YourUsername/YourRepoName?style=flat" alt="Forks"/>
  <img src="https://img.shields.io/github/stars/YourUsername/YourRepoName?style=flat" alt="Stars"/>
</p>

<p align="center">
  An automated Arch Linux install script with a BTRFS layout, focusing on Cyber Security, Penetration Testing, and OffSec tooling.
  <br/>
  <strong>Explore the docs »</strong>
  <br/>
  <a href="#-features">Features</a>
  ·
  <a href="#-prerequisites-before-install">Prerequisites</a>
  ·
  <a href="#-installation-process">Installation</a>
  ·
  <a href="#-known-issues">Known Issues</a>
  ·
  <a href="#-roadmap--future-improvements">Future</a>
</p>

---

## ✨ Overview

**SecuArch** is a streamlined, **script-based** installation process for Arch Linux. It automatically sets up **BTRFS** subvolumes, **encrypted partitions** (optional), and pre-installs a curated collection of pentesting and defensive tools. My goal: provide a minimal yet powerful base for cybersecurity professionals, students, and enthusiasts.

### Why SecuArch?
- **BTRFS** for snapshotting & rollback—great for testing out risky software or experiments.
- **Pentesting Tools** out of the box, inspired by Kali/BlackArch, but with full Arch flexibility.
- **Focus on Security**: optional LUKS encryption, hardened configs, user-friendly scripts.

---

## 🔒 Key Features

- **Automated Partitioning & BTRFS**: Create separate subvolumes for `/root`, `/home`, `/var`, etc.
- **Optional LUKS Encryption**: Secure your data at rest with full-disk encryption.
- **Pentesting Tools**: Installs essential packages (Metasploit, nmap, Wireshark, sqlmap, etc.).
- **Blue Team & OffSec**: Suricata, OpenVAS, Tor, i2p, Firejail, etc.
- **Customizable**: Pick and choose which tools to install during or after setup.
- **Post-Install Scripts**: Automatic configuration of sudoers, network, display manager, or security tweaks.

---

## 📁 Repository Structure

