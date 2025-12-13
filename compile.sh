#!/bin/bash
set -e

echo "--- Setting up Compilation Environment ---"
source .venv/bin/activate

# Ensure compiler tools are installed
pip install nuitka patchelf

echo "--- Cleaning previous builds ---"
rm -rf build

echo "--- Compiling with Nuitka ---"
# --onefile: Creates a single executable file
# --enable-plugin=pyside6: Essential for Qt GUI support
# --include-module=rembg: Ensures the AI library is bundled correctly
python3 -m nuitka --standalone --onefile --enable-plugin=pyside6 \
    --jobs=$(nproc) \
    --output-dir=build \
    --output-filename=remove-background.bin \
    --include-module=rembg \
    remove_background.py

echo "--- Success! Binary created: build/remove-background.bin ---"