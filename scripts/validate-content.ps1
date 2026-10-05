param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot ".."))
)

$ErrorActionPreference = "Stop"
$script:HasErrors = $false

function Fail([string]$Message) {
    Write-Error $Message
    $script:HasErrors = $true
}

function Read-Utf8([string]$Path) {
    return [IO.File]::ReadAllText($Path, [Text.UTF8Encoding]::new($false))
}

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$referencesPath = Join-Path $rootPath "references"
if (-not (Test-Path -LiteralPath $referencesPath)) {
    Fail "缺少 references 目录：$referencesPath"
    exit 1
}

$rulePattern = '(?m)^##\s+([A-Z][A-Z0-9]+-\d{3})\s+.+$'
$allIds = @{}
$ruleCount = 0

foreach ($file in @(Get-ChildItem -LiteralPath $referencesPath -Recurse -File -Filter "*.md")) {
    $content = Read-Utf8 $file.FullName
    $matches = [regex]::Matches($content, $rulePattern)
    if ($matches.Count -eq 0) {
        continue
    }

    $ruleCount += $matches.Count
    foreach ($match in $matches) {
        $id = $match.Groups[1].Value
        if ($allIds.ContainsKey($id)) {
            Fail "规则编号重复：$id（$($allIds[$id]) 与 $($file.FullName)）"
        } else {
            $allIds[$id] = $file.FullName
        }
    }

    for ($index = 0; $index -lt $matches.Count; $index++) {
        $start = $matches[$index].Index
        $end = if ($index + 1 -lt $matches.Count) { $matches[$index + 1].Index } else { $content.Length }
        $section = $content.Substring($start, $end - $start)
        $id = $matches[$index].Groups[1].Value
        foreach ($required in @("级别：", "适用：", "规则：", "正例：", "反例：", "例外：")) {
            if ($section -notmatch [regex]::Escape($required)) {
                Fail "$id 缺少字段“$required”：$($file.FullName)"
            }
        }
    }
}

if ($ruleCount -eq 0) {
    Fail "references/ 中没有发现带编号的规则。"
}

if ($script:HasErrors) {
    exit 1
}

Write-Output ("规则内容校验通过：{0} 条编号规则。" -f $ruleCount)
exit 0
