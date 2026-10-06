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

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$referencesPath = Join-Path $rootPath "references"
if (-not (Test-Path -LiteralPath $referencesPath -PathType Container)) {
    Fail "Missing references directory."
    exit 1
}

$allIds = @{}
$ruleCount = 0
foreach ($file in Get-ChildItem -LiteralPath $referencesPath -Recurse -File -Filter "*.md") {
    $content = Read-Utf8 $file.FullName
    $headings = [regex]::Matches($content, '(?m)^##[ \t]+([^\r\n]+)')
    $fileRuleCount = 0
    for ($index = 0; $index -lt $headings.Count; $index++) {
        $title = $headings[$index].Groups[1].Value.Trim()
        $rule = [regex]::Match($title, '^([A-Z][A-Z0-9]+-\d{3})[ \t]+\S')
        if (-not $rule.Success) {
            if ($title -match '^[A-Z0-9]+-') { Fail "Malformed rule heading: $title in $($file.FullName)" }
            continue
        }
        $id = $rule.Groups[1].Value
        $ruleCount++
        $fileRuleCount++
        if ($allIds.ContainsKey($id)) {
            Fail "Duplicate rule ID: $id in $($file.FullName) and $($allIds[$id])"
        } else {
            $allIds[$id] = $file.FullName
        }
        $start = $headings[$index].Index
        $end = if ($index + 1 -lt $headings.Count) { $headings[$index + 1].Index } else { $content.Length }
        $section = $content.Substring($start, $end - $start)
        foreach ($field in @("级别", "适用", "规则", "正例", "反例", "例外")) {
            $fields = [regex]::Matches($section, "(?m)^$($field)：[ \t]*([^\r\n]*)\r?$")
            if ($fields.Count -ne 1 -or [string]::IsNullOrWhiteSpace($fields[0].Groups[1].Value)) {
                Fail "$id requires exactly one nonempty $field field."
            } elseif ($field -eq "级别" -and $fields[0].Groups[1].Value.Trim() -cnotmatch '^(BLOCKER|MUST|SHOULD|MAY)$') {
                Fail "$id has an invalid rule level."
            }
        }
    }
    if ($file.DirectoryName -eq $referencesPath -and $fileRuleCount -eq 0) {
        Fail "Top-level reference has no numbered rules: $($file.Name)"
    }
}
if ($ruleCount -eq 0) { Fail "No numbered rules found." }

# Guide references must resolve to an actual rule, not an invented example ID.
$guides = @(Get-ChildItem -LiteralPath $rootPath -File -Filter "*.md")
foreach ($directory in @("skills", "references", "templates", "project")) {
    $path = Join-Path $rootPath $directory
    if (Test-Path -LiteralPath $path -PathType Container) {
        $guides += @(Get-ChildItem -LiteralPath $path -Recurse -File -Filter "*.md")
    }
}
foreach ($file in $guides) {
    foreach ($reference in [regex]::Matches((Read-Utf8 $file.FullName), '(?<![A-Z0-9-])[A-Z][A-Z0-9]+-\d{3}(?![A-Z0-9-])')) {
        if (-not $allIds.ContainsKey($reference.Value)) { Fail "Unknown rule ID $($reference.Value) in $($file.FullName)" }
    }
}

if ($script:HasErrors) { exit 1 }
Write-Output ("Rule content and references valid: {0} numbered rules." -f $ruleCount)
exit 0
