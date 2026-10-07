param()

$text = $env:EVAL_FINAL_MESSAGE
if ([string]::IsNullOrWhiteSpace($text)) {
    Write-Error "EVAL_FINAL_MESSAGE is empty"
    exit 1
}

$checks = @(
    @{ Name = "atomic inventory update"; Patterns = @("available_qty", "\u6761\u4ef6\u66f4\u65b0|\u539f\u5b50\u66f4\u65b0|\u53d7\u5f71\u54cd\u884c\u6570") },
    @{ Name = "idempotency"; Patterns = @("request_id|requestId", "\u5e42\u7b49") },
    @{ Name = "local transaction"; Patterns = @("@Transactional", "\u672c\u5730\u4e8b\u52a1|\u4e8b\u52a1") },
    @{ Name = "outbox delivery"; Patterns = @("Outbox|outbox") },
    @{ Name = "retry and durable failure recovery"; Patterns = @("retry", "\u91cd\u8bd5"); Also = @(
        "DEAD|dead|\u6b7b\u4fe1|\u5931\u8d25\u961f\u5217",
        "(?s)(?=.*(?:\u4fdd\u7559|\u6301\u4e45\u5316)[^\r\n;\uFF1B\u3002\uFF0C,]{0,24}(?:\u4e8b\u4ef6|\u6d88\u606f))(?=.*(?:\u544a\u8b66|\u4eba\u5de5))(?=.*(?:\u91cd\u653e|\u6062\u590d|\u91cd\u65b0\u6295\u9012|\u91cd\u6295))"
    ) },
    @{ Name = "remote call boundary"; Patterns = @("\u4e0d\u80fd\u653e\u5728.*\u4e8b\u52a1", "\u4e8b\u52a1.*\u4e0d\u80fd.*MQ", "\u4e8b\u52a1\u5916", "\u4e8b\u52a1\u4e4b\u5916") },
    @{ Name = "test coverage"; Patterns = @("test", "\u6d4b\u8bd5") }
)

$failed = @()
foreach ($check in $checks) {
    $matched = $false
    foreach ($pattern in $check.Patterns) {
        if ($text -match $pattern) { $matched = $true; break }
    }
    if ($matched -and $check.ContainsKey("Also")) {
        $matched = $false
        foreach ($pattern in $check.Also) {
            if ($text -match $pattern) { $matched = $true; break }
        }
    }
    if (-not $matched) { $failed += $check.Name }
}

if ($failed.Count -gt 0) {
    Write-Error ("Missing inventory design evidence: " + ($failed -join ", "))
    exit 1
}

Write-Output "Inventory design rubric passed"
exit 0
