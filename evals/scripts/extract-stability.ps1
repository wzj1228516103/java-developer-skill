#requires -Version 7.0
param(
    [Parameter(Mandatory)][string]$ResultsDirectory,
    [Parameter(Mandatory)][string]$OutputPath,
    [int]$ExpectedSamples = 3
)
$ErrorActionPreference = "Stop"
$resultsRoot = (Resolve-Path -LiteralPath $ResultsDirectory).Path
$iterations = @(Get-ChildItem -LiteralPath $resultsRoot -Directory |
    Where-Object { $_.Name -match '^iteration-\d+$' -and (Test-Path -LiteralPath (Join-Path $_.FullName 'result.json')) } |
    Sort-Object { [int]($_.Name -replace '^iteration-', '') })
if ($iterations.Count -eq 0) { throw '没有完整 result.json。' }
$rounds = @()
$rows = @()
foreach ($iteration in $iterations) {
    $metricPath = Join-Path $iteration.FullName 'metrics.json'
    & (Join-Path $PSScriptRoot 'extract-metrics.ps1') -ResultPath (Join-Path $iteration.FullName 'result.json') -OutputPath $metricPath | Out-Null
    $metrics = Get-Content -Raw -LiteralPath $metricPath | ConvertFrom-Json
    $rounds += [ordered]@{
        iteration = $iteration.Name
        source_result_sha256 = $metrics.source_result_sha256
        eligible_for_quality_comparison = $metrics.eligible_for_quality_comparison
        engine = $metrics.engine
        model = $metrics.model_recorded_by_report
        case_ids = @($metrics.cases.case_id | Sort-Object -Unique)
        summary = $metrics.summary
    }
    foreach ($row in $metrics.cases) {
        $row | Add-Member -NotePropertyName iteration -NotePropertyValue $iteration.Name
        $rows += $row
    }
}
$sameTasks = @($rounds | ForEach-Object { ($_.case_ids -join '|') + ';' + $_.engine + ';' + $_.model } | Sort-Object -Unique).Count -eq 1
$eligible = $iterations.Count -eq $ExpectedSamples -and $sameTasks -and @($rounds | Where-Object { -not $_.eligible_for_quality_comparison }).Count -eq 0
$stability = @()
foreach ($caseGroup in ($rows | Group-Object case_id | Sort-Object Name)) {
    foreach ($mode in @('with_skill','without_skill')) {
        $group = @($caseGroup.Group | Where-Object configuration -EQ $mode)
        $passes = @($group | Where-Object status -EQ 'PASS').Count
        $errors = @($group | Where-Object status -EQ 'ERROR').Count
        $stability += [ordered]@{
            case_id = $caseGroup.Name; configuration = $mode; samples = $group.Count
            passed = $passes; failed = @($group | Where-Object status -EQ 'FAIL').Count; errors = $errors
            flaky = $errors -eq 0 -and $passes -gt 0 -and $passes -lt $group.Count
            mean_quality_assertion_rate = ($group.judge_assertion_pass_rate | Measure-Object -Average).Average
            worst_sample_quality_assertion_rate = ($group.judge_assertion_pass_rate | Measure-Object -Minimum).Minimum
        }
    }
}
function Summarize([string]$Mode) {
    $group = @($rows | Where-Object configuration -EQ $Mode)
    $caseAverages = @($stability | Where-Object configuration -EQ $Mode)
    return [ordered]@{
        runs = $group.Count
        passed = @($group | Where-Object status -EQ 'PASS').Count
        failed = @($group | Where-Object status -EQ 'FAIL').Count
        errors = @($group | Where-Object status -EQ 'ERROR').Count
        mean_quality_assertion_rate = ($group.judge_assertion_pass_rate | Measure-Object -Average).Average
        case_pass_rate = @($group | Where-Object status -EQ 'PASS').Count / [double]$group.Count
        worst_case_mean_quality_rate = ($caseAverages.mean_quality_assertion_rate | Measure-Object -Minimum).Minimum
        worst_sample_quality_rate = ($group.judge_assertion_pass_rate | Measure-Object -Minimum).Minimum
        mean_time_seconds = ($group.time_seconds | Measure-Object -Average).Average
        mean_reported_tokens = ($group.reported_tokens | Measure-Object -Average).Average
        flaky_cases = @($caseAverages | Where-Object flaky | ForEach-Object case_id)
    }
}
$with = Summarize 'with_skill'
$without = Summarize 'without_skill'
$result = [ordered]@{
    schema_version = 'stability-metrics-v1'
    generated_at_utc = [DateTime]::UtcNow.ToString('o')
    source_directory = $resultsRoot
    expected_samples = $ExpectedSamples; actual_samples = $iterations.Count
    same_tasks_and_recorded_model = $sameTasks
    eligible_for_quality_comparison = $eligible
    interpretation = '每轮完整配对，质量断言排除 expect；汇总用例和采样等权。是否可发布仍需人工确认 Judge、冻结输入和版本。Token/耗时只含被测 Agent，不能换算计费。flaky 分组分别按 with_skill 和 without_skill 计算。'
    rounds = $rounds
    summary = [ordered]@{
        with_skill = $with; without_skill = $without
        quality_delta_pp = if ($eligible) { 100 * ($with.mean_quality_assertion_rate - $without.mean_quality_assertion_rate) } else { $null }
        case_pass_delta_pp = if ($eligible) { 100 * ($with.case_pass_rate - $without.case_pass_rate) } else { $null }
    }
    case_stability = $stability
}
$absoluteOutput = [IO.Path]::GetFullPath($OutputPath)
[IO.Directory]::CreateDirectory((Split-Path $absoluteOutput -Parent)) | Out-Null
[IO.File]::WriteAllText($absoluteOutput, ($result | ConvertTo-Json -Depth 15), [Text.UTF8Encoding]::new($false))
Write-Output ($result.summary | ConvertTo-Json -Depth 8)
