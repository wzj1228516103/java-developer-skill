#requires -Version 7.0
param(
    [string]$Root = (Join-Path $PSScriptRoot "..")
)

$ErrorActionPreference = "Stop"
$script:HasErrors = $false

function Fail([string]$Message) {
    $script:HasErrors = $true
    Write-Error $Message -ErrorAction Continue
}

function Read-Utf8([string]$Path) {
    return [IO.File]::ReadAllText($Path, [Text.UTF8Encoding]::new($false, $true))
}

function Assert-SkillHeader([string]$Path, [string]$ExpectedName) {
    $content = Read-Utf8 $Path
    $header = [regex]::Match($content, '(?ms)\A---[ \t]*\r?\n(?<body>.*?)^---[ \t]*\r?$')
    if (-not $header.Success) {
        Fail "Missing or unclosed frontmatter: $Path"
        return
    }
    foreach ($key in @("name", "description")) {
        $fields = [regex]::Matches($header.Groups['body'].Value, "(?m)^$($key):[ \t]*([^\r\n]*)\r?$")
        if ($fields.Count -ne 1) {
            Fail "Frontmatter must contain exactly one $($key): $Path"
            continue
        }
        $value = $fields[0].Groups[1].Value.Trim()
        if ($value.StartsWith('"') -or $value.StartsWith("'")) {
            if ($value.Length -lt 2 -or $value[-1] -ne $value[0]) {
                Fail "Unclosed $($key) scalar: $Path"
                continue
            }
            $value = $value.Substring(1, $value.Length - 2)
        } elseif ($value -match '^[>|#\[\]{},&*!]' -or $value -match ':[ \t]' -or $value -match '^(?:null|~|true|false|yes|no|on|off|[+-]?\d+(?:\.\d+)?)$') {
            Fail "$key must be a nonempty single-line YAML string: $Path"
            continue
        }
        if ([string]::IsNullOrWhiteSpace($value)) {
            Fail "Empty $($key): $Path"
        } elseif ($key -eq "name" -and $value -cne $ExpectedName) {
            Fail "Name mismatch: expected $ExpectedName in $Path"
        }
    }
}

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$rootPrefix = $rootPath.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$requiredFiles = @("skills.registry.json", ".codex-plugin/plugin.json", "SKILL.md", "README.md", "CHANGELOG.md")
foreach ($relative in $requiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $rootPath $relative) -PathType Leaf)) {
        Fail "Missing required file: $relative"
    }
}
$skillsPath = Join-Path $rootPath "skills"
if (-not (Test-Path -LiteralPath $skillsPath -PathType Container)) { Fail "Missing skills directory." }
if ($script:HasErrors) { exit 1 }

try {
    $registry = Read-Utf8 (Join-Path $rootPath "skills.registry.json") | ConvertFrom-Json
    $plugin = Read-Utf8 (Join-Path $rootPath ".codex-plugin/plugin.json") | ConvertFrom-Json
} catch {
    Fail "Invalid registration JSON: $($_.Exception.Message)"
    exit 1
}

$name = [string]$registry.name
$version = [string]$registry.version
if ($name -cnotmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$' -or $name.Length -gt 64) { Fail "Invalid skill name: $name" }
if ($name -cne [string]$plugin.name) { Fail "Registry/plugin name mismatch." }
if ($version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$') {
    Fail "Version must use major.minor.patch: $version"
}
if ($version -cne [string]$plugin.version) { Fail "Registry/plugin version mismatch." }
if ((Read-Utf8 (Join-Path $rootPath "CHANGELOG.md")) -notmatch ("(?m)^## \[" + [regex]::Escape($version) + "\]")) {
    Fail "CHANGELOG.md has no section for version $version."
}
if ([string]$plugin.skills -cne "./skills/") { Fail "Plugin skills must point to ./skills/." }

$entries = @($registry.entries)
$entryNames = @($entries | ForEach-Object { [string]$_.name })
$entryPaths = @($entries | ForEach-Object { [string]$_.path })
if ($entries.Count -eq 0) { Fail "No registered entries." }
if (@($entryNames | Sort-Object -Unique).Count -ne $entryNames.Count) { Fail "Duplicate entry name." }
if (@($entryPaths | Sort-Object -Unique).Count -ne $entryPaths.Count) { Fail "Duplicate entry path." }

Assert-SkillHeader (Join-Path $rootPath "SKILL.md") $name
$readme = Read-Utf8 (Join-Path $rootPath "README.md")
foreach ($entry in $entries) {
    $entryName = [string]$entry.name
    if ($entryName -cnotmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$' -or $entryName.Length -gt 64) {
        Fail "Invalid entry name: $entryName"
        continue
    }
    if ([string]$entry.path -cne "skills/$entryName") {
        Fail "Entry path must be skills/$($entryName): $($entry.path)"
        continue
    }
    if ([string]::IsNullOrWhiteSpace([string]$entry.description)) { Fail "Empty registry description: $entryName" }
    $entryFile = Join-Path $rootPath "$($entry.path)/SKILL.md"
    if (Test-Path -LiteralPath $entryFile -PathType Leaf) {
        Assert-SkillHeader $entryFile $entryName
    } else {
        Fail "Missing entry SKILL.md: $entryName"
    }
    $tablePattern = '(?m)^\|[ \t]*' + [regex]::Escape([string][char]96 + "/" + $entryName + [char]96) + '[ \t]*\|'
    if ($readme -notmatch $tablePattern) { Fail "README entry table is missing /$entryName." }
}
$actualDirs = @(Get-ChildItem -LiteralPath $skillsPath -Directory | ForEach-Object { "skills/$($_.Name)" })
$actualSorted = @($actualDirs | Sort-Object)
$entrySorted = @($entryPaths | Sort-Object)
if (@(Compare-Object $actualSorted $entrySorted).Count -gt 0) { Fail "Skills directories and registry entries differ." }

# Validate concrete root routes. The documented project placeholder is not a file.
$rootSkill = Read-Utf8 (Join-Path $rootPath "SKILL.md")
$tick = [regex]::Escape([string][char]96)
foreach ($route in [regex]::Matches($rootSkill, ($tick + '((?:references|templates|project)/[^' + $tick + '\r\n]+|memory\.md)' + $tick))) {
    $relative = $route.Groups[1].Value
    if ($relative -eq 'project/<项目名>.md') { continue }
    $resolvedRoute = [IO.Path]::GetFullPath((Join-Path $rootPath $relative))
    if (-not $resolvedRoute.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        Fail "Root route escapes repository: $relative"
    } elseif (-not (Test-Path -LiteralPath $resolvedRoute)) {
        Fail "Missing root route: $relative"
    }
}

# Local file links are checked offline; external URLs and anchors are not fetched.
$markdownFiles = @(Get-ChildItem -LiteralPath $rootPath -File -Filter "*.md")
foreach ($directory in @("skills", "references", "templates", "project", ".github", "docs")) {
    $path = Join-Path $rootPath $directory
    if (Test-Path -LiteralPath $path -PathType Container) {
        $markdownFiles += @(Get-ChildItem -LiteralPath $path -Recurse -File -Filter "*.md")
    }
}
foreach ($file in $markdownFiles) {
    foreach ($link in [regex]::Matches((Read-Utf8 $file.FullName), '\[[^\]\r\n]*\]\(([^)\r\n]+)\)')) {
        $target = $link.Groups[1].Value.Trim()
        if ($target -match '^(?:[A-Za-z][A-Za-z0-9+.-]*:|#)') { continue }
        if ($target.StartsWith('<')) {
            $target = ($target -split '>')[0].Substring(1)
        } else {
            $target = ($target -split '[ \t]+')[0]
        }
        $relative = [Uri]::UnescapeDataString(($target -split '#')[0])
        if ([string]::IsNullOrWhiteSpace($relative)) { continue }
        $resolved = [IO.Path]::GetFullPath((Join-Path $file.DirectoryName $relative))
        if (-not $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            Fail "Local link escapes repository: $target in $($file.FullName)"
        } elseif (-not (Test-Path -LiteralPath $resolved)) {
            Fail "Broken local file link: $target in $($file.FullName)"
        }
    }
}

if ($script:HasErrors) { exit 1 }
Write-Output ("Registry, frontmatter and local links valid: {0} entries, version {1}." -f $entries.Count, $version)
exit 0
