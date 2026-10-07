#requires -Version 7.0
$ErrorActionPreference = 'Stop'
$fixtureRoot = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ('java-stability-' + [guid]::NewGuid().ToString('N'))))
[IO.Directory]::CreateDirectory($fixtureRoot) | Out-Null
$extractor = Join-Path $PSScriptRoot '../scripts/extract-stability.ps1'
function Row([string]$Case, [string]$Mode, [bool]$Pass) {
    return @{
        case_id=$Case; title='稳定性测试'; configuration=$Mode; status=$(if($Pass){'PASS'}else{'FAIL'})
        duration_ms=1000; input_tokens=100; output_tokens=10
        grading=@{assertion_results=@(@{text='expect.exit_code';passed=$true;evidence='exit 0'},@{text='质量';passed=$Pass;evidence='fixture'});summary=@{pass_rate=$(if($Pass){1.0}else{0.5})}}
    }
}
function Write-Round([string]$Directory, [int]$Round, [array]$Rows) {
    $iteration = Join-Path $Directory "iteration-$Round"
    [IO.Directory]::CreateDirectory($iteration)|Out-Null
    @{engine_name='codex';model_name='fixture';case_results=$Rows}|ConvertTo-Json -Depth 10|Set-Content -Encoding utf8 (Join-Path $iteration 'result.json')
}
function Extract([string]$Directory) {
    $output = Join-Path $Directory 'summary.json'
    & $extractor -ResultsDirectory $Directory -OutputPath $output | Out-Null
    return Get-Content -Raw $output | ConvertFrom-Json
}
function Require([bool]$Condition, [string]$Name) {
    if(-not $Condition){throw "稳定性指标回归失败：$Name"}
    Write-Output "PASS $Name"
}
try {
    $valid=Join-Path $fixtureRoot 'valid'
    foreach($i in 1..3){Write-Round $valid $i @((Row 'a' 'with_skill' ($i -ne 2)),(Row 'a' 'without_skill' $false),(Row 'b' 'with_skill' $true),(Row 'b' 'without_skill' $true))}
    $metrics=Extract $valid
    Require ($metrics.eligible_for_quality_comparison -and [Math]::Abs($metrics.summary.quality_delta_pp - 33.3333333333) -lt 0.0001) '三轮完整配对等权计算，无拼接最好轮次'
    Require ($metrics.summary.with_skill.flaky_cases -contains 'a' -and $metrics.summary.without_skill.flaky_cases.Count -eq 0) 'flaky 分别按模式计算，恒定失败不算波动'
    $missing=Join-Path $fixtureRoot 'missing'
    Write-Round $missing 1 @((Row 'a' 'with_skill' $true),(Row 'a' 'without_skill' $true))
    $metrics=Extract $missing
    Require (-not $metrics.eligible_for_quality_comparison -and $null -eq $metrics.summary.quality_delta_pp) '不足三轮不能发布三轮对比'
    $mismatch=Join-Path $fixtureRoot 'mismatch'
    foreach($i in 1..3){$case=if($i -eq 3){'different'}else{'a'};Write-Round $mismatch $i @((Row $case 'with_skill' $true),(Row $case 'without_skill' $true))}
    $metrics=Extract $mismatch
    Require (-not $metrics.same_tasks_and_recorded_model -and -not $metrics.eligible_for_quality_comparison) '不同任务集不能汇总成固定采样'
    $errorFixture=Join-Path $fixtureRoot 'error'
    foreach($i in 1..3){$bad=Row 'a' 'without_skill' $true;if($i -eq 2){$bad.status='ERROR';$bad.grading=$null;$bad.error='503 auth_unavailable'};Write-Round $errorFixture $i @((Row 'a' 'with_skill' $true),$bad)}
    $metrics=Extract $errorFixture
    Require (-not $metrics.eligible_for_quality_comparison -and $null -eq $metrics.summary.quality_delta_pp) '基础设施错误不得变成质量提升'
} finally {
    $resolved=(Resolve-Path -LiteralPath $fixtureRoot).Path
    if($resolved -cne $fixtureRoot -or (Get-Item -LiteralPath $resolved).LinkType){throw '拒绝清理路径发生变化的夹具目录。'}
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
Write-Output '全部 5 个稳定性指标回归通过。'
