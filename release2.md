# Loaf v0.2.0 Release Notes

**Loaf v0.2.0** is a major architectural and feature release, rewriting core engine subsystems into modular, high-performance components while introducing network shares, peer-to-peer file sharing, tabs, split views, and rich desktop file operations.

---

## 🌟 Highlights & Major Features

### 🌐 SMB / CIFS Network Storage Support
Connect to remote Windows network shares and SMB servers directly from Loaf:
- **SMB URI & Server Connection**: Navigate and connect directly to `smb://<server>/<share>` or browse network locations.
- **Named SMB Profile Manager**: Create, edit, and manage friendly aliases/profiles for network shares directly in Settings.
- **Secure Keyring Authentication**: Secure credential storage using the system secret service / FreeDesktop keyring (`libsecret` / `secret-tool`) with guest fallback options.
- **Remote Browsing & Operations**: Seamless remote folder navigation, file operations, and mount handling.

### 🔗 Peer-to-Peer File Sharing via Link
Share any file or folder instantly from your machine without uploading to third-party file locker hosts:
- **Instant Cloudflare Tunnel**: Spawns an on-demand, encrypted Cloudflare tunnel straight to your machine.
- **On-the-fly Compression**: Select between direct streaming or instant archiving in `.zip`, `.tar.gz`, or `.7z`.
- **Security & Access Controls**: Optional password encryption, customizable expiration timers, and bandwidth rate-limiting controls.
- **Share Manager**: Dedicated management interface to track active shares and cancel tunnels at any moment.

### 🗂️ Tabs & Dual Split View
- **Tabbed Browsing (`Ctrl+T` / `Ctrl+W`)**: Open multiple directories in fluid tabs with session restoration on next launch.
- **Dual Container Split View (`F3`)**: Side-by-side file panes allowing concurrent management, comparison, and cross-pane drag-and-drop operations.
- **This PC & Settings Routing**: In-tab integration for system settings and storage dashboards.

### ⚡ Modular Multithreaded Engine & Async Thumbnails
- **Modular Rust Architecture**: Split the monolithic bridge into purpose-built modules (`pane.rs`, `core.rs`, `fsops.rs`, `trash.rs`, `archive.rs`, `watcher.rs`, `search.rs`, `apps.rs`, `xdg.rs`, `drives.rs`, `smb.rs`, `share.rs`).
- **Async C++ & FreeDesktop Thumbnailing**: Background thumbnail generation for images, video frames (`ffmpegthumbnailer`), PDFs (`evince-thumbnailer`), and fonts.
- **Inotify Live Watchers**: Incremental folder diffing that updates only changed items instead of reloading full lists.

### 🛠️ File Operations, Batch Renamer & Quick Look
- **Batch Multi-File Renaming (`F2` with multiple items)**: Pattern search/replace and sequential numbering dialog.
- **Quick Look (`Space`)**: Instant modal preview with video playback, PDF display, image zooming, and archive directory inspection.
- **Conflict Resolution Dialog**: Visual side-by-side size/date comparison with overwrite, auto-rename, skip, and replace-all actions.
- **Direct Symlink Dialog & Context Action**: Create relative or absolute symbolic links with a dedicated dialog.
- **Archive Navigation**: Directly browse into archive files without extracting them first.

---

## 📦 Packaging & Installation

### Official Interactive Installer
```bash
curl -sSL https://raw.githubusercontent.com/m-uvex/loaf-fm/main/install.sh | bash
```

### Manual Packages
- **AppImage**: `Loaf-v0.2.0-x86_64.AppImage`
- **Debian / Ubuntu**: `loaf_0.2.0_amd64.deb`
- **Arch Linux**: `loaf-0.2.0-1-x86_64.pkg.tar.zst`
- **Fedora / RHEL / openSUSE**: `loaf-0.2.0-1.fc44.x86_64.rpm`
- **Portable Tarball**: `loaf-v0.2.0-linux-x86_64.tar.gz`
- **Nix Flake**: `nix run github:m-uvex/loaf-fm`
