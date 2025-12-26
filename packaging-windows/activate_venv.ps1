# PowerShell script to activate the virtual environment, creating it if necessary

# Deactivate if currently in a virtual environment
if ($env:VIRTUAL_ENV) {
    Write-Host "Deactivating current virtual environment..."
    deactivate
}

# Check if venv exists
if (Test-Path "venv") {
    Write-Host "Virtual environment exists. Activating..."
} else {
    # Create new virtual environment
    Write-Host "Creating new virtual environment..."
    python -m venv venv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to create virtual environment. Ensure Python is installed and available."
        exit 1
    }
}

# Activate the virtual environment
Write-Host "Activating virtual environment..."
. .\venv\Scripts\Activate.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to activate virtual environment."
    exit 1
}

# Check if requirements are installed by checking for pyinstaller
Write-Host "Checking if requirements are installed..."
python -c "import pyinstaller" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing requirements..."
    if (Test-Path "$PSScriptRoot\..\requirements.txt") {
        pip install -r "$PSScriptRoot\..\requirements.txt"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to install requirements."
            exit 1
        }
    }
} else {
    Write-Host "Requirements already installed."
}

Write-Host "Virtual environment activated successfully."