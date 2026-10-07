#requires -Version 7.0
param(
    [Parameter(Mandatory)][string]$ResultPath,
    [string]$CasePattern = "*",
    [string]$OutputPath
)
$ErrorActionPreference = "Stop"
$resultFile = (Resolve-Path -LiteralPath $ResultPath).Path
$report = [IO.File]::ReadAllText($resultFile) | ConvertFrom-Json
$selected = @($report.case_results | Where-Object { $_.case_id -like $CasePattern })
if ($selected.Count -eq 0) { throw "没有匹配的用例：$CasePattern" }
$rows = @()
foreach ($item in $selected) {
    $infrastructure = $null
    if ($item.status -eq "ERROR") {
        $infrastructure = if ($item.error -match 'auth_unavailable|503|账号池') { "gateway_unavailable" }
                          elseif ($item.error -match 'timeout|deadline') { "timeout" }
                          else { "runner_error" }
    } elseif (($item.grading.assertion_results | Where-Object { -not $_.passed }).evidence -match 'timed out|deadline') {
        $infrastructure = "judge_timeout"
    } elseif (($item.grading.assertion_results | Where-Object { -not $_.passed }).evidence -match 'Judge infrastructure:') {
        $infrastructure = "judge_runtime_error"
    }
    $qualityAssertions = @($item.grading.assertion_results | Where-Object { $_.text -notmatch '^expect\.' })
    $qualityRate = if ($qualityAssertions.Count -gt 0) {
        @($qualityAssertions | Where-Object passed).Count / [double]$qualityAssertions.Count
    } elseif ($item.status -eq 'FAIL') { 0.0 } else { $null }
    $rows += [pscustomobject]@{
        case_id = $item.case_id
        title = $item.title
        configuration = $item.configuration
        status = $item.status
        assertion_pass_rate = if ($item.grading.summary) { [double]$item.grading.summary.pass_rate } else { $null }
        judge_assertion_pass_rate = $qualityRate
        time_seconds = [Math]::Round($item.duration_ms / 1000.0, 3)
        reported_tokens = [long]$item.input_tokens + [long]$item.output_tokens
        infrastructure_error = $infrastructure
    }
}
$incomplete = @()
foreach ($group in ($rows | Group-Object case_id)) {
    if (@($group.Group | Where-Object configuration -EQ "with_skill").Count -ne 1 -or
        @($group.Group | Where-Object configuration -EQ "without_skill").Count -ne 1) {
        $incomplete += $group.Name
    }
}
function Summarize([string]$Configuration) {
    $group = @($rows | Where-Object configuration -EQ $Configuration)
    if ($group.Count -eq 0) { return $null }
    # ERROR is included as zero in the run score, while separately preventing quality claims.
    $rates = @($group | ForEach-Object { if ($null -eq $_.assertion_pass_rate) { 0.0 } else { $_.assertion_pass_rate } })
    return [ordered]@{
        cases = $group.Count
        passed = @($group | Where-Object status -EQ "PASS").Count
        failed = @($group | Where-Object status -EQ "FAIL").Count
        errors = @($group | Where-Object status -EQ "ERROR").Count
        mean_assertion_pass_rate = ($rates | Measure-Object -Average).Average
        worst_assertion_pass_rate = ($rates | Measure-Object -Minimum).Minimum
        mean_judge_assertion_pass_rate = ($group.judge_assertion_pass_rate | Measure-Object -Average).Average
        worst_judge_assertion_pass_rate = ($group.judge_assertion_pass_rate | Measure-Object -Minimum).Minimum
        case_pass_rate = @($group | Where-Object status -EQ "PASS").Count / [double]$group.Count
        mean_time_seconds = ($group.time_seconds | Measure-Object -Average).Average
        mean_reported_tokens = ($group.reported_tokens | Measure-Object -Average).Average
    }
}
$with = Summarize "with_skill"
$without = Summarize "without_skill"
$qualityEligible = $incomplete.Count -eq 0 -and @($rows | Where-Object infrastructure_error).Count -eq 0 -and
    @($rows | Where-Object { $null -eq $_.judge_assertion_pass_rate }).Count -eq 0
$metrics = [ordered]@{
    schema_version = "metrics-v2"
    generated_at_utc = [DateTime]::UtcNow.ToString("o")
    source_iteration = Split-Path (Split-Path $resultFile -Parent) -Leaf
    source_result_sha256 = (Get-FileHash -LiteralPath $resultFile -Algorithm SHA256).Hash.ToLowerInvariant()
    engine = $report.engine_name
    model_recorded_by_report = $report.model_name
    engine_version = $report.observed_configuration.version
    case_pattern = $CasePattern
    selected_cases = @($rows.case_id | Sort-Object -Unique).Count
    excluded_cases = @($report.case_results.case_id | Sort-Object -Unique).Count - @($rows.case_id | Sort-Object -Unique).Count
    runs_per_case_configuration = 1
    incomplete_pairs = $incomplete
    eligible_for_quality_comparison = $qualityEligible
    interpretation = "平均率按用例等权；assertion_pass_rate 包含 expect，judge_assertion_pass_rate 排除 expect 门槛；script Judge 整体计为一个质量断言。基础设施错误或配对不完整时不能发布质量对比。Token 是工具原始记录，不等同于计费金额。"
    summary = [ordered]@{
        with_skill = $with
        without_skill = $without
        delta_pp = if ($qualityEligible -and $null -ne $with -and $null -ne $without) {
            [Math]::Round(100 * ($with.mean_assertion_pass_rate - $without.mean_assertion_pass_rate), 4)
        } else { $null }
        judge_delta_pp = if ($qualityEligible -and $null -ne $with -and $null -ne $without) {
            [Math]::Round(100 * ($with.mean_judge_assertion_pass_rate - $without.mean_judge_assertion_pass_rate), 4)
        } else { $null }
    }
    cases = $rows
}
$json = $metrics | ConvertTo-Json -Depth 10
if ($OutputPath) {
    $destination = [IO.Path]::GetFullPath($OutputPath)
    $parentDir = Split-Path $destination -Parent
    [IO.Directory]::CreateDirectory($parentDir) | Out-Null
    [IO.File]::WriteAllText($destination, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
    Write-Output ("指标已写入：" + $destination)
}
$json
