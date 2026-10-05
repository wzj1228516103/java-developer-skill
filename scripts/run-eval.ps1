param(
    [ValidateSet("codex", "qwen_code")]
    [string]$Engine = "codex",
    [string]$Model = "qwen3-coder-plus",
    [string]$BaseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1",
    [string]$CaseName = "",
    [string]$OutputDir = "./skill-up-results",
    [string]$SkillUpPath = "skill-up",
    [string[]]$EngineKwarg = @(),
    [ValidateRange(1, 50)]
    [int]$Repeats = 1
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command $SkillUpPath -ErrorAction SilentlyContinue)) {
    if (-not (Test-Path -LiteralPath $SkillUpPath)) {
        throw "找不到 skill-up：请将其加入 PATH，或使用 -SkillUpPath 指定 skill-up.exe。"
    }
}

if ($Engine -eq "qwen_code") {
    if ([string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)) {
        throw "qwen_code 需要环境变量 OPENAI_API_KEY；不要把 API Key 写入脚本或仓库。"
    }
    $env:OPENAI_BASE_URL = $BaseUrl
}

if ($Engine -eq "codex" -and -not [string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)) {
    Write-Warning "当前选择 codex，但检测到 OPENAI_API_KEY；Codex 将优先使用其登录态/宿主配置，而不是百炼 Key。需要百炼时请使用 -Engine qwen_code。"
}

$arguments = @(
    "run",
    "evals/eval.yaml",
    "--engine", $Engine,
    "--parallelism", "1"
)

if ($Engine -eq "qwen_code") {
    $arguments += @("--provider", "openai", "--model", $Model)
}

foreach ($kwarg in $EngineKwarg) {
    if (-not [string]::IsNullOrWhiteSpace($kwarg)) {
        $arguments += @("--engine-kwarg", $kwarg)
    }
}

if (-not [string]::IsNullOrWhiteSpace($CaseName)) {
    $arguments += @("--include-case-name", $CaseName)
}

$overallExitCode = 0
for ($iteration = 1; $iteration -le $Repeats; $iteration++) {
    $iterationOutputDir = $OutputDir
    if ($Repeats -gt 1) {
        $iterationOutputDir = Join-Path $OutputDir ("iteration-{0:D2}" -f $iteration)
    }

    $runArguments = @($arguments)
    $runArguments += @("--output-dir", $iterationOutputDir)
    Write-Output ("运行评测 {0}/{1}，输出：{2}" -f $iteration, $Repeats, $iterationOutputDir)
    & $SkillUpPath @runArguments
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
    if ($exitCode -ne 0) {
        $overallExitCode = $exitCode
        Write-Warning ("第 {0} 轮退出码为 {1}；继续保留其他轮次结果。" -f $iteration, $exitCode)
        if ($Engine -eq "codex") {
            Write-Warning "Codex 运行失败时，请检查登录态和当前模型是否可用；若使用百炼，请改用 -Engine qwen_code 并设置 OPENAI_API_KEY。"
        }
    }
}

exit $overallExitCode
