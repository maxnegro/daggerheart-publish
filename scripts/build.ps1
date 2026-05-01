#Requires -Version 5.1
<#
.SYNOPSIS
  Build a daggerheart-publish book to PDF using pandoc + XeLaTeX.

.DESCRIPTION
  Windows-native equivalent of scripts/build.sh.
  Requires pandoc and XeLaTeX (MiKTeX or TeX Live) to be installed and on PATH.

.PARAMETER BookDir
  Path to the book folder (must contain book.md and chapters/).

.PARAMETER OutputPdf
  Path to the output PDF file. Defaults to dist\<book-name>.pdf.

.EXAMPLE
  .\scripts\build.ps1 .\books\example
  .\scripts\build.ps1 .\books\example dist\mio-libro.pdf

.NOTES
  Environment variables:
    ASSETS_DIR   Path to local assets directory containing fonts/photos (default: .\assets)
    KEEP_WORKDIR Set to 1 to keep temporary build directory
    KEEP_TEX     Set to 1 to keep generated .tex alongside the output PDF
    ENABLE_TOC   Set to 0 to disable automatic table of contents
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

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

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

# Natural-sort chapter files (pad all digit sequences for lexicographic equivalence)
$ChapterFiles = Get-ChildItem -Path $ChaptersDir -Filter "*.md" -File |
    Sort-Object { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(20) }) } |
    ForEach-Object { $_.FullName }

if ($ChapterFiles.Count -eq 0) {
    Write-Error "No chapter files found in: $ChaptersDir"
    exit 1
}

# Resolve output path
if ($OutputPdf -eq "") {
    $BookName  = Split-Path -Leaf $BookDir
    $OutputPdf = Join-Path $RootDir "dist\$BookName.pdf"
}
$OutputPdf = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPdf))
$OutputDir = Split-Path -Parent $OutputPdf
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$ClassFile  = Join-Path $RootDir "templates\daggerheart.cls"
$FilterFile = Join-Path $RootDir "filters\daggerheart.lua"
$AssetsDir  = if ($env:ASSETS_DIR) { $env:ASSETS_DIR } else { Join-Path $RootDir "assets" }
$AssetsDir  = [System.IO.Path]::GetFullPath($AssetsDir)

if (-not (Test-Path $ClassFile)) {
    Write-Error "Could not find local class file: $ClassFile"
    exit 1
}
if (-not (Test-Path $FilterFile)) {
    Write-Error "Could not find Lua filter file: $FilterFile"
    exit 1
}
if (-not (Test-Path (Join-Path $AssetsDir "fonts") -PathType Container)) {
    Write-Error "Could not find fonts directory in assets directory: $AssetsDir"
    exit 1
}
if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
    Write-Error "pandoc is required but was not found in PATH."
    exit 1
}

# ---------------------------------------------------------------------------
# Temporary work directory
# ---------------------------------------------------------------------------

$WorkDir = [System.IO.Path]::Combine(
    [System.IO.Path]::GetTempPath(),
    [System.IO.Path]::GetRandomFileName()
)
New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null

function Remove-WorkDir {
    if ($env:KEEP_WORKDIR -ne "1") {
        Remove-Item -Recurse -Force $WorkDir -ErrorAction SilentlyContinue
    } else {
        Write-Host "Temporary build directory kept at: $WorkDir"
    }
}

try {
    # Copy class and fonts
    Copy-Item $ClassFile (Join-Path $WorkDir "daggerheart.cls")
    Copy-Item (Join-Path $AssetsDir "fonts") $WorkDir -Recurse

    New-Item -ItemType Directory -Path (Join-Path $WorkDir "assets") -Force | Out-Null

    $BookAssetsDir = Join-Path $BookDir "assets"
    if (Test-Path $BookAssetsDir -PathType Container) {
        Copy-Item (Join-Path $BookAssetsDir "*") (Join-Path $WorkDir "assets") -Recurse -Force
    }

    $PhotosDir = Join-Path $AssetsDir "photos"
    if (Test-Path $PhotosDir -PathType Container) {
        Copy-Item $PhotosDir $WorkDir -Recurse -Force
        Copy-Item $PhotosDir (Join-Path $WorkDir "assets") -Recurse -Force
    }

    # Font case-sensitivity fallback
    $FontSrc = Join-Path $WorkDir "fonts\LeagueSpartan-ExtraBold.ttf"
    $FontDst = Join-Path $WorkDir "fonts\LeagueSpartan-Extrabold.ttf"
    if ((Test-Path $FontSrc) -and -not (Test-Path $FontDst)) {
        try {
            Copy-Item $FontSrc $FontDst
        } catch {
            Write-Warning "Failed to copy font fallback LeagueSpartan-ExtraBold.ttf -> LeagueSpartan-Extrabold.ttf"
        }
    }

    # Resource path (semicolon-separated on Windows)
    $ResourcePath = "$BookDir;$AssetsDir;$(Join-Path $AssetsDir 'photos');$RootDir"
    if (Test-Path $BookAssetsDir -PathType Container) {
        $ResourcePath += ";$BookAssetsDir"
    }

    # ---------------------------------------------------------------------------
    # Read TOC setting from YAML frontmatter
    # ---------------------------------------------------------------------------
    $TocFrontmatter = ""
    $inFrontmatter  = $false
    $frontmatterDone = $false
    foreach ($line in [System.IO.File]::ReadLines($BookMd)) {
        if (-not $frontmatterDone) {
            if ($line -eq "---") {
                if (-not $inFrontmatter) { $inFrontmatter = $true; continue }
                else { $frontmatterDone = $true; break }
            }
            if ($inFrontmatter -and $line -match '^\s*toc:\s*(\S+)') {
                $TocFrontmatter = $Matches[1]
            }
        }
    }

    $EnableToc = if ($env:ENABLE_TOC) { $env:ENABLE_TOC } else { "1" }

    # ---------------------------------------------------------------------------
    # Build pandoc argument list
    # ---------------------------------------------------------------------------
    $PandocArgs = @(
        "--standalone",
        "--from", "markdown+fenced_divs+bracketed_spans",
        "--pdf-engine=xelatex",
        "--resource-path", $ResourcePath,
        "--template", (Join-Path $RootDir "templates\daggerheart.latex"),
        "--lua-filter", $FilterFile,
        "-V", "documentclass=daggerheart"
    )

    if ($EnableToc -eq "1" -and $TocFrontmatter -ne "false") {
        $PandocArgs += "--toc"
    }

    $PandocInputs = @($BookMd) + $ChapterFiles

    # ---------------------------------------------------------------------------
    # Run pandoc from within WorkDir so LaTeX finds daggerheart.cls and fonts
    # ---------------------------------------------------------------------------
    Push-Location $WorkDir
    try {
        if ($env:KEEP_TEX -eq "1") {
            $TexPath = [System.IO.Path]::ChangeExtension($OutputPdf, ".tex")
            & pandoc @PandocInputs @PandocArgs -t latex -o $TexPath
        }

        & pandoc @PandocInputs @PandocArgs -o $OutputPdf
        if ($LASTEXITCODE -ne 0) {
            Write-Error "pandoc exited with code $LASTEXITCODE"
            exit $LASTEXITCODE
        }
    } finally {
        Pop-Location
    }

    Write-Host "PDF generated: $OutputPdf"

} finally {
    Remove-WorkDir
}
