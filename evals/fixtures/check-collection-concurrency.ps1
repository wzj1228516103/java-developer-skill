param()

$ErrorActionPreference = "Stop"
$text = [string]$env:EVAL_FINAL_MESSAGE
if ([string]::IsNullOrWhiteSpace($text)) {
    Write-Output "Missing final answer"
    exit 1
}
$blocks = [regex]::Matches($text, '(?ms)^\s*\x60{3}[^\r\n]*\r?\n(.*?)^\s*\x60{3}\s*$')
$code = if ($blocks.Count -gt 0) {
    ($blocks | ForEach-Object { $_.Groups[1].Value }) -join [Environment]::NewLine
} else { $text }
$code = [regex]::Replace($code, '(?s)/\*.*?\*/', '')
$code = [regex]::Replace($code, '(?m)//.*$', '')

# Java 17 does not provide the Java 21 virtual-thread APIs.
if ($code -match '\b(?:newVirtualThreadPerTaskExecutor|ofVirtual|startVirtualThread)\s*\(') {
    Write-Output "Java 21 virtual-thread API is incompatible with the requested Java 17"
    exit 1
}

$concurrentMap = $code -match '\b(?:ConcurrentHashMap|ConcurrentMap)\b'
$atomicMapCall = $code -match '\.(?:computeIfAbsent|putIfAbsent)\s*\('
$locked = $code -match '\bsynchronized\s*\('
if (-not (($concurrentMap -and $atomicMapCall) -or $locked)) {
    Write-Output "Missing concurrent map with atomic initialization or an explicit lock"
    exit 1
}
# A word boundary cannot match the HashMap suffix inside ConcurrentHashMap.
if (($code -match '\bHashMap\s*(?:<|\()') -and -not $locked) {
    Write-Output "Unprotected HashMap in shared-cache implementation"
    exit 1
}
Write-Output "Concurrent-cache static checks passed"
exit 0
