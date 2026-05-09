[CmdletBinding()]
param(
    [string]$SourcePath = (Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Claude-3p\vm_bundles\claudevm.bundle'),
    [string]$DestPath = '',
    [string]$PackageFolderName = '',
    [string[]]$Files = @(
        'rootfs.vhdx',
        'vmlinuz',
        'initrd',
        'smol-bin.vhdx',
        'vmlinuz.zst',
        'initrd.zst',
        'rootfs.vhdx.zst'
    ),
    [switch]$Force
)

function Join-PathParts {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Parts
    )

    $path = $Parts[0]
    for ($i = 1; $i -lt $Parts.Count; $i++) {
        $path = Join-Path -Path $path -ChildPath $Parts[$i]
    }

    return $path
}

function Resolve-DestinationPath {
    if ($DestPath) {
        return $DestPath
    }

    $packagesRoot = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Packages'

    if ($PackageFolderName) {
        return (Join-PathParts -Parts @(
            $packagesRoot,
            $PackageFolderName,
            'LocalCache',
            'Roaming',
            'Claude-3p',
            'vm_bundles',
            'claudevm.bundle'
        ))
    }

    $packageFolders = Get-ChildItem -LiteralPath $packagesRoot -Directory -Filter 'Claude*' -ErrorAction SilentlyContinue
    if (-not $packageFolders) {
        throw "No Claude package folder found under $packagesRoot."
    }

    if ($packageFolders.Count -gt 1) {
        Write-Host "Multiple Claude package folders found; using $($packageFolders[0].Name)." -ForegroundColor Yellow
    }

    return (Join-PathParts -Parts @(
        $packagesRoot,
        $packageFolders[0].Name,
        'LocalCache',
        'Roaming',
        'Claude-3p',
        'vm_bundles',
        'claudevm.bundle'
    ))
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "Source path not found: $SourcePath"
}

$DestPath = Resolve-DestinationPath

if (Test-Path -LiteralPath $DestPath) {
    $destInfo = Get-Item -LiteralPath $DestPath
    if (($destInfo.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Destination is a reparse point. Remove it first and rerun: $DestPath"
    }
} else {
    New-Item -ItemType Directory -Path $DestPath -Force | Out-Null
}

$created = 0
$skipped = 0
$failed = 0

foreach ($fileName in $Files) {
    $srcFile = Join-Path -Path $SourcePath -ChildPath $fileName
    $dstFile = Join-Path -Path $DestPath -ChildPath $fileName

    if (-not (Test-Path -LiteralPath $srcFile)) {
        Write-Warning "Missing source file: $srcFile"
        $failed++
        continue
    }

    if (Test-Path -LiteralPath $dstFile) {
        $dstItem = Get-Item -LiteralPath $dstFile
        if ($dstItem.LinkType -eq 'HardLink') {
            Write-Host "[SKIP] $fileName"
            $skipped++
            continue
        }

        if (-not $Force) {
            Write-Warning "Destination exists but is not a hardlink: $dstFile"
            Write-Warning "Rerun with -Force to replace it."
            $failed++
            continue
        }

        Remove-Item -LiteralPath $dstFile -Force
    }

    try {
        New-Item -ItemType HardLink -Path $dstFile -Target $srcFile | Out-Null
        Write-Host "[OK]   $fileName" -ForegroundColor Green
        $created++
    } catch {
        Write-Host "[FAIL] $fileName : $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "Summary: $created created, $skipped skipped, $failed failed" -ForegroundColor Cyan
Write-Host "Next: restart Claude Desktop and try Cowork again." -ForegroundColor Cyan

if ($failed -gt 0) {
    exit 1
}

