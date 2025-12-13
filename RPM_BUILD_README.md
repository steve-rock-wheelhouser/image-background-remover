# Image Background Remover RPM Packaging Guide

This document details the process, prerequisites, and structure for packaging the **Image Background Remover** application as an RPM for Fedora/RHEL-based systems. It documents the exact filenames and steps required so the GNOME Software (Software Center) will read AppStream metadata and display screenshots.

## Overview

The packaging process is automated via `build-rpm.sh`. Unlike traditional source builds, this process bundles a pre-compiled binary (generated via Nuitka) along with necessary assets, desktop integration files, and AppStream metadata into a standard RPM package.

## Prerequisites

The build script automatically attempts to install dependencies using `dnf`. You will need:

*   **OS:** Fedora, RHEL, or compatible derivative.
*   **Tools:**
    *   `rpm-build`
    *   `rpmdevtools`
    *   `desktop-file-utils`
    *   `libappstream-glib`
    *   `rpm-sign` (optional, for signing)
    *   `appstream` (provides `appstreamcli` for validation)

## Project Structure

*   **`build-rpm.sh`**: The main orchestration script.
*   **`remove-background.spec`**: The RPM specification file defining dependencies and installation paths (this repo uses `remove-background.spec`).
*   **`com.wheelhouser.image-remove-background.desktop`**: System menu integration file (desktop ID must match the AppStream `<launchable>` value).
*   **`com.wheelhouser.image-remove-background.metadata.xml`** (packaged/installed as `com.wheelhouser.image-remove-background.appdata.xml`): AppStream metadata for Software Center visibility.

## The Build Process

To build the RPM, run the script from the project root:

```bash
./build-rpm.sh
```

### Workflow Breakdown

1.  **Version Management**:
    *   The build script increments the `Release` number stored in `.release_info` so repeated builds of the same `Version` produce incremented `Release` values.

2.  **Pre-Build Validation**:
    *   Validates the AppStream metadata (`metainfo.xml`) using `appstreamcli`.
    *   Validates the desktop entry (`.desktop`) using `desktop-file-validate`.

3.  **Binary Compilation**:
    *   Executes `./build_binary.sh` to generate the standalone executable.

4.  **Source Preparation**:
    *   The script prepares a local `rpmbuild` tree under the repository (`./rpmbuild`) and copies the files the spec expects into `rpmbuild/SOURCES/` (desktop file, metadata, binary, icon).
    *   The spec does not rely on a Source0 tarball in this repository layout — files are supplied to `rpmbuild/SOURCES/` directly by `build-rpm.sh`.

5.  **RPM Build**:
    *   Sets up a local `rpmbuild` directory structure (`BUILD`, `RPMS`, `SOURCES`, etc.).
    *   Runs `rpmbuild -ba` using the generated tarball and the spec file.

## RPM Specification Details (`remove-background.spec`)

The spec file handles the installation logic on the end-user's system.

*   **Binary Placement**: The main binary is installed to `%{_bindir}/remove-background` (see spec for exact path).
*   **Metadata**:
    *   Installs the `.desktop` file to `%{_datadir}/applications`.
    *   Installs the AppStream metadata file as `/usr/share/metainfo/com.wheelhouser.image-remove-background.appdata.xml` (this is required — the `.appdata.xml` extension and the component `<id>` must match the desktop ID `<launchable>`).
*   **Icons**: Installs the application icon to `/usr/share/icons/hicolor/256x256/apps/`.

## RPM Signing

The script supports automatic GPG signing of the generated packages.

### Configuration
To enable signing, you must have a GPG key configured in your `~/.rpmmacros` file:

```
%_gpg_name <Your Key ID>
```

If configured, the script will:
1.  Export your public key to a temporary file `RPM-GPG-KEY-image-resizer`.
2.  Import it into the local RPM database (requires `sudo`).
3.  Sign both the Binary and Source RPMs using `rpm --addsign`.
4.  Verify the signature immediately after signing.

## Output

Upon success, the artifacts are copied to the `dist/` directory in the project root:

*   **Binary RPM**: `dist/image-resizer-0.3.0-<release>.<arch>.rpm`
*   **Source RPM**: `dist/image-resizer-0.3.0-<release>.src.rpm`

## Installation

To install the resulting package on a Fedora/RHEL system:

```bash
sudo dnf install dist/image-resizer-0.3.0-*.rpm
```

## Troubleshooting

- **"rpmbuild not found"**: Install `rpm-build` (and `rpmdevtools`) before running `./build-rpm.sh`.
- **AppStream Validation Failed**: Run `appstreamcli validate com.wheelhouser.image-remove-background.metadata.xml` and fix any reported errors. Do not add invalid `file:///` screenshot entries — AppStream expects web URLs for the primary screenshot entries.
- **No screenshots in GNOME Software when opening an RPM file**: Common causes and steps:
    - Ensure the RPM actually contains `/usr/share/metainfo/com.wheelhouser.image-remove-background.appdata.xml` (the spec in this repo installs the metadata under that name).
    - Rebuild the RPM with `./build-rpm.sh`, then run `sudo bash scripts/verify_rpm_and_refresh.sh` on your Fedora host. That script will:
        - Inspect the RPM contents, extract and validate the packaged AppStream file, refresh the AppStream cache, update desktop/icon caches, restart PackageKit, and restart GNOME Software.
    - If PackageKit logs show `Failed to get cache filename for <id>` while opening the RPM, run the verify script as root and capture the output; the script already saves useful commands and hints to follow.

If you'd like, I can also update the spec/build flow to produce a `Source0` tarball instead of copying files into `rpmbuild/SOURCES/`, but the current flow in this repo uses direct `SOURCES/` copies from the project root.