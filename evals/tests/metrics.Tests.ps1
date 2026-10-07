#requires -Version 7.0
$ErrorActionPreference = "Stop"
$fixtureRoot = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ("java-metrics-eval-" + [guid]::NewGuid().ToString("N"))))
[IO.Directory]::CreateDirectory($fixtureRoot) | Out-Null
$extractor = Join-Path $PSScriptRoot "../scripts/extract-metrics.ps1"
function Row([string]$Mode, [bool]$QualityPass, [string]$Evidence = "quality evidence") {
    return [ordered]@{
        case_id = "test"; title = "指标回归"; configuration = $Mode
        status = $(if ($QualityPass) {"PASS"} else {"FAIL"})
        duration_ms = 1000; input_tokens = 100; output_tokens = 10
        grading = [ordered]@{
            assertion_results = @(@{text="expect.exit_code";passed=$true;evidence="all checks passed"}, @{text="script: test";passed=$QualityPass;evidence=$Evidence})
            summary = @{pass_rate=$(if($QualityPass){1.0}else{0.5})}
        }
    }
}
function Extract([string]$Name, [array]$Rows) {
    $inputPath = Join-Path $fixtureRoot ($Name + "-result.json")
    $outputPath = Join-Path $fixtureRoot ($Name + "-metrics.json")
    [IO.File]::WriteAllText($inputPath, (@{engine_name="codex";model_name="fixture";case_results=$Rows}|ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    & $extractor -ResultPath $inputPath -OutputPath $outputPath | Out-Null
    return [IO.File]::ReadAllText($outputPath) | ConvertFrom-Json
}
function Require([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw ("指标回归失败：" + $Name) }
    Write-Output ("PASS " + $Name)
}
try {
    $metrics = Extract "quality" @((Row "with_skill" $true), (Row "without_skill" $false))
    Require ($metrics.eligible_for_quality_comparison -and $metrics.summary.delta_pp -eq 50 -and $metrics.summary.judge_delta_pp -eq 100) "质量率排除 expect 门槛，百分点计算正确"
    $metrics = Extract "incomplete" @((Row "with_skill" $true))
    Require (-not $metrics.eligible_for_quality_comparison -and $null -eq $metrics.summary.judge_delta_pp) "缺少基线不得发布差值"
    $errorRow = Row "without_skill" $false
    $errorRow.status = "ERROR"; $errorRow.error = "503 auth_unavailable"; $errorRow.grading = $null
    $metrics = Extract "gateway" @((Row "with_skill" $true), $errorRow)
    Require (-not $metrics.eligible_for_quality_comparison -and $metrics.cases[1].infrastructure_error -eq "gateway_unavailable") "网关错误单列，不解释为质量"
    $metrics = Extract "timeout" @((Row "with_skill" $true), (Row "without_skill" $false "script timed out after 1m0s"))
    Require (-not $metrics.eligible_for_quality_comparison -and $metrics.cases[1].infrastructure_error -eq "judge_timeout") "Judge 超时不得发布质量对比"
    $metrics = Extract "jdk" @((Row "with_skill" $true), (Row "without_skill" $false "Judge infrastructure: JDK 17 or newer required"))
    Require (-not $metrics.eligible_for_quality_comparison -and $metrics.cases[1].infrastructure_error -eq "judge_runtime_error") "缺少 JDK 属于 Judge 环境错误"
    $metrics = Extract "duplicate" @((Row "with_skill" $true), (Row "with_skill" $true), (Row "without_skill" $true))
    Require (-not $metrics.eligible_for_quality_comparison -and $metrics.incomplete_pairs.Count -eq 1) "重复配对不能冒充单次采样"
} finally {
    $resolved = (Resolve-Path -LiteralPath $fixtureRoot).Path
    if ($resolved -cne $fixtureRoot -or (Get-Item -LiteralPath $resolved).LinkType) { throw "Refusing cleanup of changed fixture path" }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
Write-Output "全部 6 个指标提取回归通过。"
