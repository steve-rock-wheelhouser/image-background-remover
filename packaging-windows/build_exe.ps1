# PowerShell script to build the executable using PyInstaller

# Activate the virtual environment
Write-Host "Activating virtual environment..."
. ..\activate_venv.ps1

# Install PyInstaller if not already installed
Write-Host "Installing PyInstaller..."
pip install pyinstaller

# Build the executable
Write-Host "Building executable with PyInstaller..."
pyinstaller --onefile --windowed --collect-submodules rembg --collect-all rembg --icon=..\assets\icons\linux\128x128\icon.png ..\remove_background.py

Write-Host "Build completed. Check the dist folder for the executable."