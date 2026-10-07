#requires -Version 7.0
param(
    [string]$SkillUp = "skill-up",
    [string]$EvalPath = "./evals/eval.yaml",
    [string[]]$CaseNames = @(),
    [int]$Parallelism = 2,
    [int]$Samples = 0,
    [string]$OutputDirectory
)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$previousThreshold = $env:SKILL_UP_PROMPT_INLINE_MAX_BYTES
Push-Location $root
try {
    # 通过 stdin 文件传递完整提示词，避免 Windows bash 内联长参数引号截断。
    $env:SKILL_UP_PROMPT_INLINE_MAX_BYTES = "1"
    & $SkillUp validate $EvalPath
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $arguments = @("run", $EvalPath, "--parallelism", [string]$Parallelism, "--iteration", [string]$Samples, "--no-delete")
    foreach ($caseName in $CaseNames) { $arguments += @("--include-case-name", $caseName) }
    # 语义 Judge 在 Windows 的相对输出目录可能触发材料路径越界；统一传绝对路径。
    if ($OutputDirectory) { $arguments += @("--output-dir", [IO.Path]::GetFullPath($OutputDirectory)) }
    & $SkillUp @arguments
    $runExitCode = $LASTEXITCODE
} finally {
    [Environment]::SetEnvironmentVariable("SKILL_UP_PROMPT_INLINE_MAX_BYTES", $previousThreshold, "Process")
    Pop-Location
}
exit $runExitCode
