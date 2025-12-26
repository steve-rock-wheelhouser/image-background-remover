# PowerShell script to push changes to GitHub

# Function to find git executable
function Find-Git {
    # Check if git is in PATH
    try {
        $gitPath = (Get-Command git -ErrorAction Stop).Source
        return $gitPath
    } catch {
        # Common git installation paths
        $possiblePaths = @(
            "C:\Program Files\Git\bin\git.exe",
            "C:\Program Files\Git\cmd\git.exe",
            "${env:ProgramFiles(x86)}\Git\bin\git.exe",
            "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
            "${env:LOCALAPPDATA}\Programs\Git\bin\git.exe",
            "${env:LOCALAPPDATA}\Programs\Git\cmd\git.exe"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                return $path
            }
        }
        
        return $null
    }
}

# Find git
$gitPath = Find-Git
if ($null -eq $gitPath) {
    Write-Host "Error: Git is not installed or not found in common locations. Please install Git from https://git-scm.com/" -ForegroundColor Red
    exit 1
}

Write-Host "Using Git at: $gitPath" -ForegroundColor Green

# Function to run git commands
function Invoke-Git {
    param([string[]]$arguments)
    $result = & $gitPath @arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Git command failed: git $($arguments -join ' ')" -ForegroundColor Red
        Write-Host "Output: $result" -ForegroundColor Red
        exit 1
    }
    return $result
}

# Check if we're in a git repository
if (!(Test-Path .git)) {
    Write-Host "Error: Not a git repository. Run 'git init' first." -ForegroundColor Red
    exit 1
}

# Get the current branch name
$currentBranch = Invoke-Git @("rev-parse", "--abbrev-ref", "HEAD")
$currentBranch = $currentBranch.Trim()
Write-Host "Current branch: $currentBranch" -ForegroundColor Green

# Check if remote origin exists
try {
    $existingRemote = Invoke-Git @("remote", "get-url", "origin")
    $existingRemote = $existingRemote.Trim()
    Write-Host "Remote origin: $existingRemote" -ForegroundColor Green
} catch {
    Write-Host "Error: No remote 'origin' found. Please set up your GitHub repository first." -ForegroundColor Red
    Write-Host "Example: git remote add origin https://github.com/yourusername/yourrepo.git" -ForegroundColor Yellow
    exit 1
}

# Check if there are any changes to commit
$changes = Invoke-Git @("status", "--porcelain")
if ($changes -eq $null -or $changes.Trim() -eq "") {
    Write-Host "No changes to commit" -ForegroundColor Yellow
    exit 0
}

# Show the changes
Write-Host "Changes to be committed:" -ForegroundColor Cyan
Invoke-Git @("status", "--short")

# Add all changes (you can modify this to be more selective)
Write-Host "Adding all changes..." -ForegroundColor Green
Invoke-Git @("add", ".")

# Commit with a descriptive message
$commitMessage = "Update build scripts and configuration for Windows packaging"
Write-Host "Committing changes with message: '$commitMessage'" -ForegroundColor Green
Invoke-Git @("commit", "-m", $commitMessage)

# Push to the current branch
Write-Host "Pushing to branch '$currentBranch'..." -ForegroundColor Green
Invoke-Git @("push", "-u", "origin", $currentBranch)

Write-Host "Successfully pushed changes to GitHub!" -ForegroundColor Green