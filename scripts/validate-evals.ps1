param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot ".."))
)

$ErrorActionPreference = "Stop"
$script:HasErrors = $false

function Fail([string]$Message) {
    Write-Error $Message
    $script:HasErrors = $true
}

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$evalPath = Join-Path $rootPath "evals/eval.yaml"
$casesPath = Join-Path $rootPath "evals/cases"
if (-not (Test-Path -LiteralPath $evalPath)) { Fail "缺少评测配置：$evalPath" }
if (-not (Test-Path -LiteralPath $casesPath)) { Fail "缺少评测目录：$casesPath" }
if ($script:HasErrors) { exit 1 }

$evalContent = Get-Content -Raw -LiteralPath $evalPath
$listedPaths = @([regex]::Matches($evalContent, '(?m)^\s*-\s+(evals/cases/[^\s#]+\.yaml)\s*$') | ForEach-Object { $_.Groups[1].Value })
if ($listedPaths.Count -eq 0) { Fail "eval.yaml 没有列出任何 cases。" }

$listedIds = @{}
foreach ($relativePath in $listedPaths) {
    if ($listedIds.ContainsKey($relativePath)) { Fail "eval.yaml 重复列出 case：$relativePath" }
    $listedIds[$relativePath] = $true

    $casePath = Join-Path $rootPath $relativePath
    if (-not (Test-Path -LiteralPath $casePath)) {
        Fail "eval.yaml 引用了不存在的 case：$relativePath"
        continue
    }

    $caseContent = Get-Content -Raw -LiteralPath $casePath
    $idMatch = [regex]::Match($caseContent, '(?m)^id:\s*([^\r\n#]+)')
    if (-not $idMatch.Success) {
        Fail "case 缺少 id：$relativePath"
        continue
    }

    $caseId = $idMatch.Groups[1].Value.Trim()
    $expectedId = [IO.Path]::GetFileNameWithoutExtension($casePath)
    if ($caseId -ne $expectedId) {
        Fail "case id 与文件名不一致：$relativePath（id=$caseId，期望=$expectedId）"
    }
    foreach ($required in @("input:", "prompt:", "expect:")) {
        if ($caseContent -notmatch [regex]::Escape($required)) {
            Fail "$relativePath 缺少字段：$required"
        }
    }
}

$actualPaths = @(Get-ChildItem -LiteralPath $casesPath -File -Filter "*.yaml" | ForEach-Object {
    "evals/cases/$($_.Name)"
})
foreach ($actualPath in $actualPaths) {
    if (-not $listedIds.ContainsKey($actualPath)) {
        Fail "存在未被 eval.yaml 引用的 case：$actualPath"
    }
}

if ($script:HasErrors) { exit 1 }
Write-Output ("评测引用校验通过：{0} 个 case。" -f $listedPaths.Count)
exit 0
