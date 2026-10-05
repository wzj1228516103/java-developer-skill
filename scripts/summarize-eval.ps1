param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [string]$JsonOut = ""
)

$ErrorActionPreference = "Stop"

function Get-ResultFiles([string]$InputPath) {
    $resolved = Resolve-Path -LiteralPath $InputPath
    if ((Get-Item -LiteralPath $resolved).PSIsContainer) {
        return @(Get-ChildItem -LiteralPath $resolved -Recurse -File -Filter "result.json")
    }
    return @((Get-Item -LiteralPath $resolved))
}

$files = @(Get-ResultFiles $Path)
if ($files.Count -eq 0) {
    throw "未找到 result.json：$Path"
}

$rows = [System.Collections.Generic.List[object]]::new()
$errors = [System.Collections.Generic.List[object]]::new()

foreach ($file in $files) {
    try {
        $report = Get-Content -Raw -LiteralPath $file.FullName | ConvertFrom-Json
    } catch {
        $errors.Add([pscustomobject]@{
            report = $file.FullName
            message = "无法解析 JSON：$($_.Exception.Message)"
        })
        continue
    }

    foreach ($case in @($report.case_results)) {
        $status = ([string]$case.status).ToUpperInvariant()
        $configuration = [string]$case.configuration
        if ([string]::IsNullOrWhiteSpace($configuration)) {
            $configuration = "<unspecified>"
        }
        $row = [pscustomobject]@{
            Report = $file.FullName
            Run = [string]$report.start_time
            Engine = [string]$report.engine_name
            Model = [string]$report.model_name
            Configuration = $configuration
            CaseId = [string]$case.case_id
            Status = $status
            DurationMs = [double]$case.duration_ms
            InputTokens = [double]$case.input_tokens
            OutputTokens = [double]$case.output_tokens
            Error = [string]$case.error
        }
        $rows.Add($row)
        if ($status -eq "ERROR") {
            $errors.Add([pscustomobject]@{
                report = $file.FullName
                configuration = $row.Configuration
                case_id = $row.CaseId
                message = $row.Error
            })
        }
    }
}

if ($rows.Count -eq 0) {
    throw "报告中没有 case_results：$Path"
}

$summary = @(
    $rows | Group-Object Configuration | ForEach-Object {
        $group = @($_.Group)
        $pass = @($group | Where-Object Status -eq "PASS").Count
        $fail = @($group | Where-Object Status -eq "FAIL").Count
        $error = @($group | Where-Object Status -eq "ERROR").Count
        $skipped = @($group | Where-Object { $_.Status -in @("SKIP", "SKIPPED") }).Count
        $judged = $pass + $fail
        $observed = $judged + $error
        [pscustomobject]@{
            Configuration = $_.Name
            Runs = @($group | Select-Object -ExpandProperty Run -Unique).Count
            Cases = $group.Count
            Passed = $pass
            Failed = $fail
            Errors = $error
            Skipped = $skipped
            PassRateExcludingErrors = if ($judged -gt 0) { [math]::Round($pass / $judged, 4) } else { $null }
            PassRateIncludingErrors = if ($observed -gt 0) { [math]::Round($pass / $observed, 4) } else { $null }
            AvgDurationSeconds = [math]::Round((($group | Measure-Object DurationMs -Average).Average / 1000), 2)
            AvgInputTokens = [math]::Round(($group | Measure-Object InputTokens -Average).Average, 0)
            AvgOutputTokens = [math]::Round(($group | Measure-Object OutputTokens -Average).Average, 0)
        }
    }
)

$caseSummary = @(
    $rows | Group-Object Configuration, CaseId | ForEach-Object {
        $group = @($_.Group)
        $pass = @($group | Where-Object Status -eq "PASS").Count
        $fail = @($group | Where-Object Status -eq "FAIL").Count
        $error = @($group | Where-Object Status -eq "ERROR").Count
        $skipped = @($group | Where-Object { $_.Status -in @("SKIP", "SKIPPED") }).Count
        [pscustomobject]@{
            Configuration = [string]$group[0].Configuration
            CaseId = [string]$group[0].CaseId
            Runs = $group.Count
            Passed = $pass
            Failed = $fail
            Errors = $error
            Skipped = $skipped
            AvgDurationSeconds = [math]::Round((($group | Measure-Object DurationMs -Average).Average / 1000), 2)
            AvgInputTokens = [math]::Round(($group | Measure-Object InputTokens -Average).Average, 0)
        }
    }
)

$result = [pscustomobject]@{
    GeneratedAt = (Get-Date).ToUniversalTime().ToString("o")
    Reports = $files.Count
    Summary = $summary
    Cases = $caseSummary
    Errors = $errors
}

$summary | Format-Table -AutoSize
Write-Output ""
Write-Output ("报告文件：{0}；场景结果：{1}；运行时错误：{2}" -f $files.Count, $rows.Count, $errors.Count)
Write-Output "说明：PassRateExcludingErrors 只计算 PASS/FAIL；运行时 ERROR 单独列出，不当作 Skill 质量失败。"

if (-not [string]::IsNullOrWhiteSpace($JsonOut)) {
    $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $JsonOut -Encoding utf8
    Write-Output "已写入：$JsonOut"
}
