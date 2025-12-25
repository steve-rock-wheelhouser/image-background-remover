# PowerShell script to build the executable using PyInstaller

# Clean previous builds
Write-Host "Cleaning previous builds..."
if (Test-Path build) { Remove-Item build -Recurse -Force }
if (Test-Path dist) { Remove-Item dist -Recurse -Force }
if (Test-Path *.spec) { Remove-Item *.spec -Force }

# Activate the virtual environment
Write-Host "Activating virtual environment..."
. ..\activate_venv.ps1

# Install PyInstaller if not already installed
Write-Host "Installing PyInstaller..."
pip install pyinstaller

# Build the executable
Write-Host "Building executable with PyInstaller..."
pyinstaller --onefile --windowed --collect-submodules rembg --collect-all rembg --add-data "..\assets;assets" --icon=..\assets\icons\icon.ico ..\remove_background.py

Write-Host "Build completed. Check the dist folder for the executable."