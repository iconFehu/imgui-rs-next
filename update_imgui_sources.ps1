# PowerShell script to update imgui sources in imgui-rs
# This script copies imgui files from third_party/imgui to imgui-rs directories

$ErrorActionPreference = "Stop"

$ProjectRoot = "C:\Users\fehu\CLionProjects\imgui-rs-next"
$ImGuiSource = Join-Path $ProjectRoot "third_party\imgui"
$ImGuiRsThirdParty = Join-Path $ProjectRoot "third_party\imgui-rs\imgui-sys\third-party"

Write-Host "Updating imgui sources from $ImGuiSource to imgui-rs..." -ForegroundColor Green

# Function to copy imgui files to target directory
function Copy-ImGuiFiles {
    param(
        [string]$SourceDir,
        [string]$TargetDir
    )
    
    Write-Host "Copying files to $TargetDir..." -ForegroundColor Yellow
    
    # Create target directory if it doesn't exist
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
    
    # Create misc/freetype directory
    $FreetypeDir = Join-Path $TargetDir "misc\freetype"
    if (-not (Test-Path $FreetypeDir)) {
        New-Item -ItemType Directory -Path $FreetypeDir -Force | Out-Null
    }
    
    # Copy LICENSE.txt
    Copy-Item -Path (Join-Path $SourceDir "LICENSE.txt") -Destination $TargetDir -Force
    
    # Copy all .h and .cpp files
    Get-ChildItem -Path $SourceDir -Filter "*.h" | Copy-Item -Destination $TargetDir -Force
    Get-ChildItem -Path $SourceDir -Filter "*.cpp" | Copy-Item -Destination $TargetDir -Force
    
    # Copy misc/freetype directory
    $SourceFreetype = Join-Path $SourceDir "misc\freetype"
    if (Test-Path $SourceFreetype) {
        Copy-Item -Path "$SourceFreetype\*" -Destination $FreetypeDir -Recurse -Force
    }
    
    Write-Host "  ✓ Completed $TargetDir" -ForegroundColor Green
}

# Update imgui-master
$MasterTarget = Join-Path $ImGuiRsThirdParty "imgui-master\imgui"
Copy-ImGuiFiles -SourceDir $ImGuiSource -TargetDir $MasterTarget

# Update imgui-master-freetype
$MasterFreetypeTarget = Join-Path $ImGuiRsThirdParty "imgui-master-freetype\imgui"
Copy-ImGuiFiles -SourceDir $ImGuiSource -TargetDir $MasterFreetypeTarget

# For docking branch, we need to check if we have it
$DockingBranch = "docking"
$ImGuiGitDir = Join-Path $ImGuiSource ".git"

if (Test-Path $ImGuiGitDir) {
    Write-Host "Checking for docking branch..." -ForegroundColor Yellow
    Push-Location $ImGuiSource
    
    # Check if docking branch exists
    $DockingExists = git branch -a 2>&1 | Select-String -Pattern "docking" | Measure-Object | Select-Object -ExpandProperty Count
    
    if ($DockingExists -gt 0) {
        Write-Host "Found docking branch, checking it out temporarily..." -ForegroundColor Yellow
        
        # Save current branch
        $CurrentBranch = git rev-parse --abbrev-ref HEAD
        
        # Checkout docking branch
        git checkout $DockingBranch 2>&1 | Out-Null
        
        # Update imgui-docking
        $DockingTarget = Join-Path $ImGuiRsThirdParty "imgui-docking\imgui"
        Copy-ImGuiFiles -SourceDir $ImGuiSource -TargetDir $DockingTarget
        
        # Update imgui-docking-freetype
        $DockingFreetypeTarget = Join-Path $ImGuiRsThirdParty "imgui-docking-freetype\imgui"
        Copy-ImGuiFiles -SourceDir $ImGuiSource -TargetDir $DockingFreetypeTarget
        
        # Restore original branch
        git checkout $CurrentBranch 2>&1 | Out-Null
        Write-Host "Restored to branch: $CurrentBranch" -ForegroundColor Green
    } else {
        Write-Host "Warning: Docking branch not found. Skipping docking variants." -ForegroundColor Yellow
        Write-Host "You may need to manually update imgui-docking and imgui-docking-freetype" -ForegroundColor Yellow
    }
    
    Pop-Location
} else {
    Write-Host "Warning: $ImGuiSource is not a git repository." -ForegroundColor Yellow
    Write-Host "Cannot update docking variants. Using master for all variants." -ForegroundColor Yellow
    
    # Use master for docking as well
    $DockingTarget = Join-Path $ImGuiRsThirdParty "imgui-docking\imgui"
    Copy-ImGuiFiles -SourceDir $ImGuiSource -TargetDir $DockingTarget
    
    $DockingFreetypeTarget = Join-Path $ImGuiRsThirdParty "imgui-docking-freetype\imgui"
    Copy-ImGuiFiles -SourceDir $ImGuiSource -TargetDir $DockingFreetypeTarget
}

Write-Host "`nAll imgui sources updated successfully!" -ForegroundColor Green
Write-Host "Next step: Generate cimgui bindings" -ForegroundColor Cyan
