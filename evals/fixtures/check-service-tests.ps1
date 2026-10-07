param()

$text = $env:EVAL_FINAL_MESSAGE
if ([string]::IsNullOrWhiteSpace($text)) {
    Write-Error "EVAL_FINAL_MESSAGE is empty"
    exit 1
}

$checks = @(
    @{ Name = "JUnit and Mockito"; Patterns = @("JUnit|@Test"); Also = @("Mockito|@Mock|verify") },
    # Equivalent domain names and exception-based reserve failures are valid.
    @{ Name = "idempotency and stock failures"; Patterns = @("idempotency|\u5e42\u7b49"); Also = @("StockInsufficient|InsufficientStock|reserve.*false|reserve.*throw|\u5e93\u5b58\u4e0d\u8db3|\u5e93\u5b58.*(\u4e0d\u8db3|\u5931\u8d25)") },
    @{ Name = "database failure"; Patterns = @("database|DataAccess|save.*exception|\u6570\u636e\u5e93\u5f02\u5e38|\u4fdd\u5b58.*\u5f02\u5e38") },
    @{ Name = "authorization boundary"; Patterns = @("Unauthorized|\u65e0\u6743|\u65e0\u6743\u9650|\u6743\u9650|\u6388\u6743|WithoutPermission|AccessDenied"); Also = @("\u5f53\u524d.*(\u6ca1\u6709|\u672a)|\u4e0d\u5b58\u5728|\u5f85\u786e\u8ba4|\u5047\u8bbe|\u5951\u7ea6|WithoutPermission|AccessDenied|\u65e0\u6743\u9650") },
    @{ Name = "concurrency consistency"; Patterns = @("concurren|\u5e76\u53d1"); Also = @("unique|Testcontainers|integration|\u552f\u4e00\u7ea6\u675f|\u96c6\u6210\u6d4b\u8bd5|\u771f\u5b9e\u6570\u636e\u5e93") },
    @{ Name = "Mockito limitation"; Patterns = @("Mockito|Mock"); Also = @("cannot prove|cannot replace|\u4e0d\u80fd\u8bc1\u660e|\u4e0d\u80fd\u66ff\u4ee3|\u65e0\u6cd5\u8bc1\u660e") },
    @{ Name = "transaction rollback"; Patterns = @("transaction|\u4e8b\u52a1"); Also = @("rollback|\u56de\u6eda") }
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
    Write-Error ("Missing service test evidence: " + ($failed -join ", "))
    exit 1
}

Write-Output "Service test rubric passed"
exit 0
