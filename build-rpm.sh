#!/bin/bash
set -e

APP_NAME="remove-background"
VERSION="0.1.0"

# Auto-increment Release (Resets if VERSION changes)
RELEASE_FILE=".release_info"
if [ -f "$RELEASE_FILE" ]; then
    read -r LAST_VERSION LAST_RELEASE < "$RELEASE_FILE" || true
fi
if [ "$VERSION" == "$LAST_VERSION" ] && [ -n "$LAST_RELEASE" ]; then
    RELEASE=$((LAST_RELEASE + 1))
else
    RELEASE="1"
fi
echo "$VERSION $RELEASE" > "$RELEASE_FILE"

ARCH="x86_64"
BINARY_NAME="${APP_NAME}.bin"
SIGN_RPMS="1"
GPG_KEY="8CC02D3C" # Run 'gpg --list-keys' and paste your new Wheelhouser LLC Key ID here

# Check for rpmbuild dependency
if ! command -v rpmbuild &> /dev/null; then
    echo "Error: 'rpmbuild' is not installed. Please install the 'rpm-build' package."
    exit 1
fi

# 1. Compile the binary if it doesn't exist
if [ ! -f "build/$BINARY_NAME" ]; then
    echo "Binary not found in build/. Running compile script..."
    chmod +x compile.sh
    ./compile.sh
fi

# 2. Prepare RPM Build Directory Structure
RPMBUILD_DIR="$PWD/rpmbuild"
echo "--- Cleaning build environment ---"
rm -rf "$RPMBUILD_DIR"
mkdir -p $RPMBUILD_DIR/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Copy project sources that the spec expects into SOURCES so rpmbuild can access them
echo "--- Preparing SOURCES ---"
SOURCE_DIR="remove-background-${VERSION}"
mkdir -p "build/${SOURCE_DIR}"

# Copy files to source dir
cp -f "${PWD}/com.wheelhouser.image-remove-background.desktop" "build/${SOURCE_DIR}/"
# Copy AppStream metadata and normalize filename to .metainfo.xml (AppStream standard)
if [ -f "${PWD}/com.wheelhouser.image-remove-background.metadata.xml" ]; then
    cp -f "${PWD}/com.wheelhouser.image-remove-background.metadata.xml" "build/${SOURCE_DIR}/com.wheelhouser.image-remove-background.metainfo.xml"
elif [ -f "${PWD}/com.wheelhouser.image-remove-background.metainfo.xml" ]; then
    cp -f "${PWD}/com.wheelhouser.image-remove-background.metainfo.xml" "build/${SOURCE_DIR}/com.wheelhouser.image-remove-background.metainfo.xml"
fi
if [ -f "${PWD}/build/${BINARY_NAME}" ]; then
    cp -f "${PWD}/build/${BINARY_NAME}" "build/${SOURCE_DIR}/remove-background.bin"
fi

# Copy full icon directory structure (assets/icons/linux/<size>/icon.png) so spec can install all sizes
if [ -d "${PWD}/assets/icons/linux" ]; then
    mkdir -p "build/${SOURCE_DIR}/assets/icons/linux"
    cp -a "${PWD}/assets/icons/linux/" "build/${SOURCE_DIR}/assets/icons/"
fi

# Handle Screenshots
mkdir -p "build/${SOURCE_DIR}/assets/screenshots"
if [ -d "${PWD}/assets/screenshots" ]; then
    cp -f "${PWD}/assets/screenshots/"*.png "build/${SOURCE_DIR}/assets/screenshots/" || true
fi

# Create Tarball
echo "--- Creating Source Tarball ---"
tar -czf "$RPMBUILD_DIR/SOURCES/remove-background-${VERSION}.tar.gz" -C build "${SOURCE_DIR}"


# Validate AppStream metadata
echo "--- Validating AppStream metadata ---"
if ! command -v appstreamcli &> /dev/null; then
    echo "Warning: 'appstreamcli' is not installed. Skipping metadata validation."
else
    # Validate the copied/normalized metainfo inside the source dir if present
    if [ -f "build/${SOURCE_DIR}/com.wheelhouser.image-remove-background.metainfo.xml" ]; then
        appstreamcli validate "build/${SOURCE_DIR}/com.wheelhouser.image-remove-background.metainfo.xml" || {
            echo "AppStream metadata validation failed. Please fix the errors above."; exit 1; }
    else
        echo "No metainfo found in build source dir; skipping validation."
    fi
fi

# Validate Desktop File
echo "--- Validating Desktop File ---"
if command -v desktop-file-validate &> /dev/null; then
    desktop-file-validate "build/${SOURCE_DIR}/com.wheelhouser.image-remove-background.desktop" || {
        echo "Desktop file validation failed."; exit 1; }
else
    echo "Warning: 'desktop-file-validate' not found. Skipping validation."
fi


# 3. Build the RPM
echo "--- Building RPM ---"

# Ensure changelog exists to avoid warnings
if ! grep -q "%changelog" remove-background.spec; then
    echo "Adding default %changelog to spec file..."
    cat <<EOF >> remove-background.spec

%changelog
* $(date "+%a %b %d %Y") User <user@example.com> - ${VERSION}-${RELEASE}
- Automated build
EOF
fi

# Update Version and Release in spec file
sed -i "s/^Version:[[:space:]]*.*/Version:    ${VERSION}/" remove-background.spec
sed -i "s/^Release:[[:space:]]*.*/Release:    ${RELEASE}/" remove-background.spec

rpmbuild -ba \
    --define "_topdir $RPMBUILD_DIR" \
    --define "__os_install_post %{nil}" \
    remove-background.spec

echo "--- Done! RPMs located at: ---"
find $RPMBUILD_DIR/RPMS -name "*.rpm"

# Optional GPG signing
# To enable signing set SIGN_RPMS=1 and optionally set GPG_KEY to your key id/name.
# Optionally set GPG_HOMEDIR to point to a GnuPG home directory to use for signing.
if [ "${SIGN_RPMS:-0}" = "1" ]; then
    echo "--- Signing RPMs (SIGN_RPMS=1) ---"

    # If user specified a GPG home dir, export GNUPGHOME so gpg/rpmsign use it
    if [ -n "${GPG_HOMEDIR:-}" ]; then
        export GNUPGHOME="$GPG_HOMEDIR"
        echo "Using GNUPGHOME=$GNUPGHOME"
    fi

    # If rpm --addsign will be used and GPG_KEY is provided, create a temporary ~/.rpmmacros
    RPMMACROS_BACKUP=""
    if command -v rpm >/dev/null 2>&1 && command -v rpmsign >/dev/null 2>&1; then
        # rpmsign available; no need to write rpmmacros
        :
    else
        # If only rpm --addsign is available, ensure %_gpg_name is set
        if command -v rpm >/dev/null 2>&1 && [ -n "${GPG_KEY:-}" ]; then
            if [ -f "$HOME/.rpmmacros" ]; then
                RPMMACROS_BACKUP="$HOME/.rpmmacros.$(date +%s)"
                cp -f "$HOME/.rpmmacros" "$RPMMACROS_BACKUP"
                echo "Backed up existing ~/.rpmmacros to $RPMMACROS_BACKUP"
            fi
            cat > "$HOME/.rpmmacros" <<EOF
%_signature gpg
%_gpg_name ${GPG_KEY}
EOF
            echo "Wrote temporary ~/.rpmmacros with GPG key ${GPG_KEY}"
            # Ensure we restore rpmmacros on exit
            restore_rpmmacros() {
                if [ -n "$RPMMACROS_BACKUP" ] && [ -f "$RPMMACROS_BACKUP" ]; then
                    mv -f "$RPMMACROS_BACKUP" "$HOME/.rpmmacros"
                    echo "Restored original ~/.rpmmacros"
                else
                    rm -f "$HOME/.rpmmacros"
                    echo "Removed temporary ~/.rpmmacros"
                fi
            }
            trap restore_rpmmacros EXIT
        fi
    fi

    # Helper to sign a single file
    sign_file() {
        local file="$1"
        echo "Signing $file"
        if command -v rpmsign >/dev/null 2>&1; then
            if [ -n "${GPG_KEY:-}" ]; then
                rpmsign --key-id "$GPG_KEY" --addsign "$file" || echo "rpmsign failed for $file"
            else
                rpmsign --addsign "$file" || echo "rpmsign failed for $file"
            fi
        elif command -v rpm >/dev/null 2>&1; then
            echo "Using 'rpm --addsign' (requires ~/.rpmmacros with %_gpg_name set and gpg agent available)"
            rpm --addsign "$file" || echo "rpm --addsign failed for $file"
        else
            echo "No rpm signing tool available (rpmsign/rpm). Skipping signing for $file"
        fi
    }

    # Sign binary RPMs
    find "$RPMBUILD_DIR/RPMS" -type f -name "*.rpm" -print0 | while IFS= read -r -d '' rpm; do
        sign_file "$rpm"
    done

    # Sign source RPMs
    find "$RPMBUILD_DIR/SRPMS" -type f -name "*.src.rpm" -print0 | while IFS= read -r -d '' srpm; do
        sign_file "$srpm"
    done

    # If we set a trap to restore rpmmacros, call it now to clean up (trap will also run on exit)
    if declare -f restore_rpmmacros >/dev/null 2>&1; then
        restore_rpmmacros
        trap - EXIT
    fi

    echo "--- Signing complete ---"
else
    echo "SIGN_RPMS not set or not 1; skipping GPG signing step."
fi