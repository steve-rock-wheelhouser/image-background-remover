# PowerShell script to push changes to GitHub on a new branch called "windows-mac"

# Check if git is installed
try {
    git --version > $null 2>&1
} catch {
    Write-Host "Error: Git is not installed or not in PATH. Please install Git from https://git-scm.com/" -ForegroundColor Red
    exit 1
}

# Check if we're in a git repository
if (!(Test-Path .git)) {
    Write-Host "Error: Not a git repository. Run 'git init' first." -ForegroundColor Red
    exit 1
}

# Set the remote origin if not already set
$remoteUrl = "https://github.com/steve-rock-wheelhouser/image-background-remover.git"
$existingRemote = git remote get-url origin 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Setting remote origin to $remoteUrl..." -ForegroundColor Green
    git remote add origin $remoteUrl
} else {
    Write-Host "Remote origin already set to: $existingRemote" -ForegroundColor Green
}

# Check if there are any changes to commit
$changes = git status --porcelain
if ($changes -eq $null -or $changes -eq "") {
    Write-Host "No changes to commit" -ForegroundColor Yellow
    exit 0
}

# Create and switch to the new branch "windows-mac"
Write-Host "Creating and switching to branch 'windows-mac'..." -ForegroundColor Green
git checkout -b windows-mac

# Add all changes
Write-Host "Adding all changes..." -ForegroundColor Green
git add .

# Commit with a generic message
Write-Host "Committing changes..." -ForegroundColor Green
git commit -m "Update project files for Windows/Mac compatibility"

# Push the new branch to origin
Write-Host "Pushing branch 'windows-mac' to origin..." -ForegroundColor Green
git push -u origin windows-mac

Write-Host "Successfully pushed to branch 'windows-mac' on GitHub!" -ForegroundColor Green