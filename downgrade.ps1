param(
    [string]$currentVersion,
    [string]$targetVersion,
    [string]$targetResourceFolder
)

$cloudMusicProcess = Get-Process -name "cloudmusic" -ErrorAction SilentlyContinue
$cloudMusicProcess = $cloudMusicProcess[0]

if ($cloudMusicProcess -ne $null) {
    $cloudMusicFolder = (Get-Item $cloudMusicProcess.MainModule.FileName).DirectoryName.ToString()
    $cloudMusicPath = $cloudMusicProcess.MainModule.FileName
    
    Write-Host "cloudmusic.exe is running at $cloudMusicPath."
    
    Stop-Process -Name "cloudmusic" -Force
    Start-Sleep -Seconds 1

    Start-Sleep -Seconds 1
    Write-Host "cloudmusic.exe is running at $cloudMusicPath."
    $cloudMusicDllPath = Join-Path $cloudMusicFolder "cloudmusic.dll"

    Write-Host "cloudmusic.dll is located at $cloudMusicDllPath."
    if (-not (Test-Path $cloudMusicDllPath)) {
        Write-Host "cloudmusic.dll not found."
        exit
    }
    $cloudMusicContent = [System.IO.File]::ReadAllBytes($cloudMusicDllPath)
    Write-Host "cloudmusic.dll length: $($cloudMusicContent.Length)"
    $currentVersionBytes = [System.Text.Encoding]::ASCII.GetBytes($currentVersion)
    $targetVersionBytes = [System.Text.Encoding]::ASCII.GetBytes($targetVersion)

    for ($i = 0; $i -lt $cloudMusicContent.Length; $i++) {
        $found = $true
        for ($j = 0; $j -lt $currentVersionBytes.Length; $j++) {
            if ($cloudMusicContent[$i + $j] -ne $currentVersionBytes[$j]) {
                $found = $false
                break
            }
        }
        if ($found) {
            Write-Host "Current version found at $i."
            [System.Array]::Copy($targetVersionBytes, 0, $cloudMusicContent, $i, $targetVersionBytes.Length)
        }
    }

    [System.IO.File]::WriteAllBytes($cloudMusicDllPath, $cloudMusicContent)
    Write-Host "cloudmusic.dll version upgraded from $currentVersion to $targetVersion."

    $currentVersionBytes = [System.Text.Encoding]::UTF8.GetBytes($currentVersion)
    $targetVersionBytes = [System.Text.Encoding]::UTF8.GetBytes($targetVersion)

    $cloudMusicExeContent = [System.IO.File]::ReadAllBytes($cloudMusicPath)
    for ($i = 0; $i -lt $cloudMusicExeContent.Length; $i++) {
        $found = $true
        for ($j = 0; $j -lt $currentVersionBytes.Length; $j++) {
            if ($cloudMusicExeContent[$i + $j] -ne $currentVersionBytes[$j]) {
                $found = $false
                break
            }
        }
        if ($found) {
            Write-Host "Current version found at $i."
            [System.Array]::Copy($targetVersionBytes, 0, $cloudMusicExeContent, $i, $targetVersionBytes.Length)
        }
    }

    [System.IO.File]::WriteAllBytes($cloudMusicPath, $cloudMusicExeContent)
    Write-Host "cloudmusic.exe version upgraded from $currentVersion to $targetVersion."
            
    Write-Host "Copying resources..."
    $currentResourceFolder = Join-Path (Get-Item $cloudMusicPath).DirectoryName "package"
    Copy-Item -Path $targetResourceFolder\default.skin -Destination $currentResourceFolder -Force
    Copy-Item -Path $targetResourceFolder\native.ntpk -Destination $currentResourceFolder -Force
    Copy-Item -Path $targetResourceFolder\orpheus.ntpk -Destination $currentResourceFolder -Force
    Write-Host "Resources copied."
    Start-Sleep -Seconds 1
    Write-Host "Starting cloudmusic.exe..."
    Start-Process $cloudMusicPath
    exit

    if ($found) {} else {
        Write-Host "Current version not found in cloudmusic.dll."
        exit
    }
}
else {
    Write-Host "cloudmusic.exe is not running."
    exit
}
