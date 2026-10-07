#requires -Version 7.0
param([string]$JudgeShell = "powershell")
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$fixtures = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../fixtures"))
$fence = [string]::new([char]96, 3)
function Java-Answer([string]$Source) { return $fence + "java`n" + $Source + "`n" + $fence }
$cacheGood = @'
import java.util.HashMap;
import java.util.Map;
public final class UserCacheService {
    private final UserRepository repository;
    private final Map<Long, User> cache = new HashMap<>();
    public UserCacheService(UserRepository repository) { this.repository = repository; }
    public synchronized User get(long userId) {
        return cache.computeIfAbsent(userId, repository::findById);
    }
}
'@
$cacheDuplicate = $cacheGood.Replace('return cache.computeIfAbsent(userId, repository::findById);', 'return repository.findById(userId);')
$cachePoison = @'
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
public final class UserCacheService {
    private final UserRepository repository;
    private final ConcurrentHashMap<Long, CompletableFuture<User>> cache = new ConcurrentHashMap<>();
    public UserCacheService(UserRepository repository) { this.repository = repository; }
    public User get(long userId) {
        return cache.computeIfAbsent(userId, id -> {
            CompletableFuture<User> future = new CompletableFuture<>();
            try { future.complete(repository.findById(id)); }
            catch (RuntimeException error) { future.completeExceptionally(error); }
            return future;
        }).join();
    }
}
'@
$cacheVirtual = $cacheGood.Replace('private final UserRepository repository;', 'private final UserRepository repository; private final java.util.concurrent.ExecutorService pool = java.util.concurrent.Executors.newVirtualThreadPerTaskExecutor();')
$visible = [ordered]@{ files = [ordered]@{
    "src/com/example/domain/ClaimResult.java" = 'package com.example.domain; public record ClaimResult(ClaimStatus status) { public static ClaimResult newRequest() { return new ClaimResult(ClaimStatus.NEW); } }'
    "src/com/example/domain/ClaimStatus.java" = 'package com.example.domain; public enum ClaimStatus { NEW, COMPLETED }'
    "src/com/example/application/OrderService.java" = 'package com.example.application; import com.example.domain.*; public final class OrderService { public boolean accepts(ClaimResult result) { return result.status() == ClaimStatus.NEW; } }'
}}
$visibleJson = $visible | ConvertTo-Json -Depth 5 -Compress
$privateEnumJson = $visibleJson.Replace('public enum ClaimStatus', 'enum ClaimStatus')
$changedBehaviorJson = $visibleJson.Replace('return result.status() == ClaimStatus.NEW;', 'return true;')
$samples = @(
    @{ Name = "Java 17：锁保护缓存可编译并通过行为测试"; Judge = "check-cache-java17.ps1"; Cwd = "cache-java17"; Pass = $true; Answer = (Java-Answer $cacheGood) },
    @{ Name = "Java 17：拒绝虚拟线程 API"; Judge = "check-cache-java17.ps1"; Cwd = "cache-java17"; Pass = $false; Answer = (Java-Answer $cacheVirtual) },
    @{ Name = "并发：拒绝每次访问重复加载"; Judge = "check-cache-java17.ps1"; Cwd = "cache-java17"; Pass = $false; Answer = (Java-Answer $cacheDuplicate) },
    @{ Name = "恢复：拒绝永久缓存失败"; Judge = "check-cache-java17.ps1"; Cwd = "cache-java17"; Pass = $false; Answer = (Java-Answer $cachePoison) },
    @{ Name = "跨包：公开枚举可编译并保持语义"; Judge = "check-package-visibility.ps1"; Cwd = "package-visibility"; Pass = $true; Answer = $visibleJson },
    @{ Name = "跨包：拒绝包内可见枚举"; Judge = "check-package-visibility.ps1"; Cwd = "package-visibility"; Pass = $false; Answer = $privateEnumJson },
    @{ Name = "跨包：拒绝编译成功但业务语义改变"; Judge = "check-package-visibility.ps1"; Cwd = "package-visibility"; Pass = $false; Answer = $changedBehaviorJson }
)
$previousMessage = $env:EVAL_FINAL_MESSAGE
$failures = @()
try {
    foreach ($sample in $samples) {
        $env:EVAL_FINAL_MESSAGE = $sample.Answer
        Push-Location (Join-Path $fixtures $sample.Cwd)
        try {
            $output = & $JudgeShell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $fixtures $sample.Judge) 2>&1
            $actual = $LASTEXITCODE -eq 0
        } finally { Pop-Location }
        if ($actual -ne $sample.Pass) {
            $failures += $sample.Name
            Write-Output ("FAIL " + $sample.Name + ": " + ($output -join " "))
        } else { Write-Output ("PASS " + $sample.Name) }
    }
} finally { $env:EVAL_FINAL_MESSAGE = $previousMessage }
if ($failures.Count -gt 0) { throw ("编译 Judge 回归失败：" + ($failures -join "、")) }
Write-Output ("全部 {0} 个编译及行为 Judge 回归通过（解释器：{1}）。" -f $samples.Count, $JudgeShell)
