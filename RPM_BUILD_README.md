# Image Resizer RPM Packaging Guide

This document details the process, prerequisites, and structure for packaging the **Image Resizer** application as an RPM for Fedora/RHEL-based systems.

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
*   **`image-resizer.spec`**: The RPM specification file defining dependencies and installation paths.
*   **`com.wheelhouser.image-resizer.desktop`**: System menu integration file.
*   **`com.wheelhouser.image-resizer.metainfo.xml`**: AppStream metadata for software center visibility.
*   **`build_binary.sh`**: (External) Script referenced to compile the Python code into a binary using Nuitka.

## The Build Process

To build the RPM, run the script from the project root:

```bash
./build-rpm.sh
```

### Workflow Breakdown

1.  **Version Management**:
    *   Updates the `Version` in `image-resizer.spec` to `0.3.0`.
    *   Auto-increments the `Release` number in the spec file (e.g., `4%{?dist}` -> `5%{?dist}`) to ensure upgrade paths work correctly.

2.  **Pre-Build Validation**:
    *   Validates the AppStream metadata (`metainfo.xml`) using `appstreamcli`.
    *   Validates the desktop entry (`.desktop`) using `desktop-file-validate`.

3.  **Binary Compilation**:
    *   Executes `./build_binary.sh` to generate the standalone executable.

4.  **Source Preparation**:
    *   Creates a clean build environment in `build/rpm-source`.
    *   Bundles the binary, assets, desktop file, metadata, and license into a tarball (`image-resizer-0.3.0.tar.gz`).
    *   This tarball serves as `Source0` for the RPM build.

5.  **RPM Build**:
    *   Sets up a local `rpmbuild` directory structure (`BUILD`, `RPMS`, `SOURCES`, etc.).
    *   Runs `rpmbuild -ba` using the generated tarball and the spec file.

## RPM Specification Details (`image-resizer.spec`)

The spec file handles the installation logic on the end-user's system.

*   **Binary Placement**: The main binary is installed to `%{_libexecdir}/image-resizer/` (e.g., `/usr/libexec/image-resizer/`) to keep it private and separate from user commands.
*   **Wrapper Script**: A shell script is created at `%{_bindir}/image-resizer` (e.g., `/usr/bin/image-resizer`) to launch the application with specific environment variables:
    *   `GTK_THEME=Adwaita:dark`: Forces dark mode for native dialogs.
    *   `GTK_USE_PORTAL=1`: Requests modern file chooser portals (better view settings retention).
    *   `QT_QPA_PLATFORMTHEME=gtk3`: Ensures Qt uses GTK3 theming for consistency.
*   **Metadata**:
    *   Installs the `.desktop` file to `%{_datadir}/applications`.
    *   Installs the `.metainfo.xml` to `%{_metainfodir}` (usually `/usr/share/metainfo`).
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

*   **"rpmbuild not found"**: Ensure you have installed the `rpm-build` package.
*   **AppStream Validation Failed**: Check `com.wheelhouser.image-resizer.metainfo.xml` for syntax errors or deprecated tags (e.g., `<developer_name>` vs `<developer>`).
*   **Signing Skipped**: Ensure `rpm-sign` is installed and `~/.rpmmacros` contains your GPG key ID.