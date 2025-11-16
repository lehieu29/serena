# Quick Index Script for Large Projects (4600+ files)
# Tối ưu cho 16GB RAM, 4 core CPU

param(
    [string]$ProjectPath = ".",
    [ValidateSet("balanced", "aggressive", "safe")]
    [string]$Mode = "balanced"
)

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "🚀 Serena Large Project Indexing Script" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Configuration theo mode
$configs = @{
    "safe" = @{
        RestartAfter = 15
        SaveEvery = 3
        Description = "Safest, slowest (~2.5h for 4600 files, ~3GB RAM)"
    }
    "balanced" = @{
        RestartAfter = 20
        SaveEvery = 5
        Description = "Recommended (~1.5-2h for 4600 files, ~5GB RAM)"
    }
    "aggressive" = @{
        RestartAfter = 30
        SaveEvery = 10
        Description = "Fastest but needs more RAM (~1h for 4600 files, ~8GB RAM)"
    }
}

$config = $configs[$Mode]

Write-Host "Mode: " -NoNewline
Write-Host $Mode.ToUpper() -ForegroundColor Yellow
Write-Host "Description: $($config.Description)" -ForegroundColor Gray
Write-Host ""

# Check available RAM
$mem = Get-WmiObject Win32_OperatingSystem
$totalGB = [math]::Round($mem.TotalVisibleMemorySize / 1MB, 1)
$freeGB = [math]::Round($mem.FreePhysicalMemory / 1MB, 1)

Write-Host "System Info:" -ForegroundColor Cyan
Write-Host "  Total RAM: $totalGB GB"
Write-Host "  Free RAM: $freeGB GB"

# Warning if free RAM is low
if ($freeGB -lt 4 -and $Mode -eq "aggressive") {
    Write-Host ""
    Write-Host "⚠️  WARNING: Free RAM is low ($freeGB GB)" -ForegroundColor Yellow
    Write-Host "   Recommended to use 'balanced' or 'safe' mode" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y") {
        Write-Host "Aborted." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Starting indexing..." -ForegroundColor Green
Write-Host "Project: $ProjectPath"
Write-Host "Restart after: $($config.RestartAfter) files"
Write-Host "Save cache every: $($config.SaveEvery) files"
Write-Host ""

# Build command
$cmd = "serena project index `"$ProjectPath`" " +
       "--restart-ls-after-n-files $($config.RestartAfter) " +
       "--skip-body " +
       "--save-cache-every $($config.SaveEvery) " +
       "--log-level INFO"

Write-Host "Command: " -ForegroundColor Cyan
Write-Host $cmd -ForegroundColor Gray
Write-Host ""

# Start time
$startTime = Get-Date
Write-Host "⏰ Start time: $($startTime.ToString('HH:mm:ss'))" -ForegroundColor Cyan
Write-Host ""

# Execute
try {
    Invoke-Expression $cmd
    
    # End time
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor Green
    Write-Host "✅ INDEXING COMPLETED!" -ForegroundColor Green
    Write-Host "===============================================" -ForegroundColor Green
    Write-Host "Start time: $($startTime.ToString('HH:mm:ss'))"
    Write-Host "End time: $($endTime.ToString('HH:mm:ss'))"
    Write-Host "Duration: $([math]::Round($duration.TotalMinutes, 1)) minutes"
    Write-Host ""
    Write-Host "Cache location: $ProjectPath\.serena\cache" -ForegroundColor Cyan
    
    # Show cache size
    if (Test-Path "$ProjectPath\.serena\cache") {
        $cacheSize = (Get-ChildItem -Path "$ProjectPath\.serena\cache" -Recurse -File | 
                      Measure-Object -Property Length -Sum).Sum
        $cacheSizeMB = [math]::Round($cacheSize / 1MB, 2)
        Write-Host "Cache size: $cacheSizeMB MB" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host ""
    Write-Host "❌ ERROR: Indexing failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Check error log: $ProjectPath\.serena\logs\indexing.txt" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Verify cache: Get-ChildItem -Path '$ProjectPath\.serena\cache' -Recurse"
Write-Host "  2. Start using Serena with your project"
Write-Host ""
