#Requires -Version 5.1
<#
.SYNOPSIS
  Build a daggerheart-publish book to PDF using Docker.

.DESCRIPTION
  Windows-native equivalent of scripts/docker-build.sh.
  Builds the local Docker image and runs the Linux build script inside the container.

.PARAMETER BookDir
  Path to the book folder (must contain book.md and chapters/).

.PARAMETER OutputPdf
  Path to the output PDF file. Defaults to dist\<book-name>.pdf.

.EXAMPLE
  .\scripts\docker-build.ps1 .\books\example
  .\scripts\docker-build.ps1 .\books\example dist\mio-libro.pdf

.NOTES
  Environment variables:
    IMAGE_NAME  Docker image tag (default: daggerheart-publish:latest)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$BookDir,
    [Parameter(Mandatory=$false, Position=1)]
    [string]$OutputPdf = ""
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ScriptDir

$BookDir = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $BookDir))
if (-not (Test-Path $BookDir -PathType Container)) {
    Write-Error "Book directory not found: $BookDir"
    exit 1
}

$BookMd = Join-Path $BookDir "book.md"
if (-not (Test-Path $BookMd)) {
    Write-Error "Missing book definition file: $BookMd"
    exit 1
}

$ChaptersDir = Join-Path $BookDir "chapters"
if (-not (Test-Path $ChaptersDir -PathType Container)) {
    Write-Error "Missing chapters directory: $ChaptersDir"
    exit 1
}

if ($OutputPdf -eq "") {
    $BookName  = Split-Path -Leaf $BookDir
    $OutputPdf = Join-Path $RootDir "dist\$BookName.pdf"
}

$OutputPdf = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPdf))
$OutputDir = Split-Path -Parent $OutputPdf
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "docker is required but was not found in PATH."
    exit 1
}

$OutputFile = Split-Path -Leaf $OutputPdf
$ImageName = if ($env:IMAGE_NAME) { $env:IMAGE_NAME } else { "daggerheart-publish:latest" }

$BookDirInContainer = "/workspace/book"
$OutputInContainer = "/workspace/out/$OutputFile"

& docker build -f (Join-Path $RootDir "docker/Dockerfile") -t $ImageName $RootDir
if ($LASTEXITCODE -ne 0) {
    Write-Error "docker build exited with code $LASTEXITCODE"
    exit $LASTEXITCODE
}

& docker run --rm `
    -v "${RootDir}:/workspace/project" `
    -v "${BookDir}:${BookDirInContainer}:ro" `
    -v "${OutputDir}:/workspace/out" `
    $ImageName `
    /workspace/project/scripts/build.sh $BookDirInContainer $OutputInContainer

if ($LASTEXITCODE -ne 0) {
    Write-Error "docker run exited with code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "PDF generated via Docker: $OutputPdf"