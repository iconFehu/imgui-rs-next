# PowerShell script to generate cimgui bindings for imgui-rs
# This script generates C bindings from C++ ImGui code using cimgui

$ErrorActionPreference = "Stop"

$ProjectRoot = "C:\Users\fehu\CLionProjects\imgui-rs-next"
$CImGuiDir = Join-Path $ProjectRoot "third_party\cimgui"
$ImGuiRsThirdParty = Join-Path $ProjectRoot "third_party\imgui-rs\imgui-sys\third-party"

# Check if cimgui exists
if (-not (Test-Path $CImGuiDir)) {
    Write-Host "Error: cimgui not found at $CImGuiDir" -ForegroundColor Red
    Write-Host "Please run: git clone --recursive https://github.com/cimgui/cimgui.git $CImGuiDir" -ForegroundColor Yellow
    exit 1
}

# Check if luajit is available
try {
    $luajitPath = (Get-Command luajit -ErrorAction Stop).Source
    Write-Host "Found luajit at: $luajitPath" -ForegroundColor Green
} catch {
    Write-Host "Error: luajit not found. Please install luajit." -ForegroundColor Red
    exit 1
}

# Find and setup Visual Studio environment
$vsWherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWherePath) {
    $vsPath = & $vsWherePath -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($vsPath) {
        Write-Host "Found Visual Studio at: $vsPath" -ForegroundColor Green
        $vcvarsPath = Join-Path $vsPath "VC\Auxiliary\Build\vcvars64.bat"
        if (Test-Path $vcvarsPath) {
            Write-Host "Setting up Visual Studio environment..." -ForegroundColor Gray
            # We'll call vcvars in each generator invocation
        }
    }
} else {
    Write-Host "Warning: vswhere.exe not found. Will try to use cl.exe directly." -ForegroundColor Yellow
}

# Function to generate cimgui bindings for a variant
function Generate-CImGuiBindings {
    param(
        [string]$VariantName,
        [string]$VariantDir
    )
    
    Write-Host "`nGenerating cimgui bindings for $VariantName..." -ForegroundColor Cyan
    
    $ImGuiSourceDir = Join-Path $VariantDir "imgui"
    
    if (-not (Test-Path $ImGuiSourceDir)) {
        Write-Host "  Warning: $ImGuiSourceDir not found, skipping..." -ForegroundColor Yellow
        return
    }
    
    $GeneratorDir = Join-Path $CImGuiDir "generator"
    
    # Save current location
    Push-Location $GeneratorDir
    
    try {
        # Check if cimgui/imgui exists and handle it
        $CImGuiImGuiLink = Join-Path $CImGuiDir "imgui"
        
        if (Test-Path $CImGuiImGuiLink) {
            # Remove it (whether it's a directory, file, or junction)
            if ((Get-Item $CImGuiImGuiLink).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                # It's a junction/symlink
                cmd /c "rmdir `"$CImGuiImGuiLink`""
            } else {
                Remove-Item -Path $CImGuiImGuiLink -Recurse -Force
            }
        }
        
        # Create junction (Windows equivalent of symlink)
        Write-Host "  Creating junction: $CImGuiImGuiLink -> $ImGuiSourceDir" -ForegroundColor Gray
        cmd /c "mklink /J `"$CImGuiImGuiLink`" `"$ImGuiSourceDir`"" | Out-Null
        
        # Run the generator
        Write-Host "  Running luajit generator..." -ForegroundColor Gray
        
        # Find Visual Studio vcvars
        $vsWherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        if (Test-Path $vsWherePath) {
            $vsPath = & $vsWherePath -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
            $vcvarsPath = Join-Path $vsPath "VC\Auxiliary\Build\vcvars64.bat"
            
            # Run generator with Visual Studio environment
            # We need to run vcvars and then luajit in the same cmd session
            # Note: Don't pass any backend implementations (no third argument)
            $cmdScript = @"
call "$vcvarsPath" > nul 2>&1
luajit generator.lua cl false
"@
            $cmdScript | Out-File -FilePath "$env:TEMP\run_luajit.bat" -Encoding ASCII
            & cmd /c "$env:TEMP\run_luajit.bat"
            Remove-Item "$env:TEMP\run_luajit.bat" -ErrorAction SilentlyContinue
        } else {
            # Fallback to direct luajit call
            & luajit generator.lua cl false
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "luajit generator failed with exit code $LASTEXITCODE"
        }
        
        # Copy generated files back to variant directory
        Write-Host "  Copying generated files..." -ForegroundColor Gray
        Copy-Item -Path (Join-Path $CImGuiDir "cimgui.h") -Destination $VariantDir -Force
        Copy-Item -Path (Join-Path $CImGuiDir "cimgui.cpp") -Destination $VariantDir -Force
        Copy-Item -Path (Join-Path $GeneratorDir "output\*") -Destination $VariantDir -Force
        
        Write-Host "  ✓ Completed $VariantName" -ForegroundColor Green
        
    } catch {
        Write-Host "  Error generating bindings for $VariantName : $_" -ForegroundColor Red
        throw
    } finally {
        # Clean up junction
        $CImGuiImGuiLink = Join-Path $CImGuiDir "imgui"
        if (Test-Path $CImGuiImGuiLink) {
            cmd /c "rmdir `"$CImGuiImGuiLink`""
        }
        
        Pop-Location
    }
}

# Generate bindings for all variants
Write-Host "Starting cimgui bindings generation..." -ForegroundColor Green

# imgui-master
$MasterDir = Join-Path $ImGuiRsThirdParty "imgui-master"
Generate-CImGuiBindings -VariantName "imgui-master" -VariantDir $MasterDir

# imgui-master-freetype
$MasterFreetypeDir = Join-Path $ImGuiRsThirdParty "imgui-master-freetype"
Generate-CImGuiBindings -VariantName "imgui-master-freetype" -VariantDir $MasterFreetypeDir

# imgui-docking
$DockingDir = Join-Path $ImGuiRsThirdParty "imgui-docking"
Generate-CImGuiBindings -VariantName "imgui-docking" -VariantDir $DockingDir

# imgui-docking-freetype
$DockingFreetypeDir = Join-Path $ImGuiRsThirdParty "imgui-docking-freetype"
Generate-CImGuiBindings -VariantName "imgui-docking-freetype" -VariantDir $DockingFreetypeDir

Write-Host "`nAll cimgui bindings generated successfully!" -ForegroundColor Green
Write-Host "Next step: Run 'cargo xtask bindgen' to generate Rust FFI bindings" -ForegroundColor Cyan
