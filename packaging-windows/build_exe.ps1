# PowerShell script to build the executable using PyInstaller

# Clean previous builds
Write-Host "Cleaning previous builds..."
if (Test-Path build) { Remove-Item build -Recurse -Force }
if (Test-Path dist) { Remove-Item dist -Recurse -Force }
# Don't delete the spec file as we need it
# if (Test-Path *.spec) { Remove-Item *.spec -Force }

# Activate the virtual environment
Write-Host "Activating virtual environment..."
. ..\activate_venv.ps1

# Install PyInstaller if not already installed
Write-Host "Installing PyInstaller..."
pip install pyinstaller

# Build the executable
Write-Host "Building executable with PyInstaller..."
pyinstaller remove_background.spec

Write-Host "Build completed. Check the dist folder for the executable."