# PowerShell script to rebuild and activate the virtual environment from scratch

# Deactivate if currently in a virtual environment
if ($env:VIRTUAL_ENV) {
    Write-Host "Deactivating current virtual environment..."
    deactivate
}

# Remove existing venv if it exists
if (Test-Path "venv") {
    Write-Host "Removing existing virtual environment..."
    try {
        Remove-Item -Recurse -Force "venv" -ErrorAction Stop
    } catch {
        Write-Host "Could not remove existing venv. It may be in use by another process. Please close other terminals or deactivate manually and try again."
        exit 1
    }
}

# Create new virtual environment
Write-Host "Creating new virtual environment..."
python -m venv venv
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create virtual environment. Ensure Python is installed and available."
    exit 1
}

# Activate the virtual environment
Write-Host "Activating virtual environment..."
. .\venv\Scripts\Activate.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to activate virtual environment."
    exit 1
}

# Install requirements if requirements.txt exists
if (Test-Path "$PSScriptRoot\requirements.txt") {
    Write-Host "Installing requirements..."
    pip install -r "$PSScriptRoot\requirements.txt"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install requirements."
        exit 1
    }
}

Write-Host "Virtual environment rebuilt and activated successfully."