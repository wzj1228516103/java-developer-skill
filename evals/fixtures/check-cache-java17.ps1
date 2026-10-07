param()
$ErrorActionPreference = "Stop"
$text = [string]$env:EVAL_FINAL_MESSAGE
if ([string]::IsNullOrWhiteSpace($text)) { Write-Output "Missing final answer"; exit 1 }
$blocks = [regex]::Matches($text, '(?ms)^\s*\x60{3}java\s*\r?\n(.*?)^\s*\x60{3}\s*$')
if ($blocks.Count -ne 1) { Write-Output "Expected one complete Java code block"; exit 1 }
$source = $blocks[0].Groups[1].Value
if ($source -notmatch '\bpublic\s+(?:final\s+)?class\s+UserCacheService\b') {
    Write-Output "Missing public UserCacheService implementation"; exit 1
}
# context.repo_fixture is copied into the case workspace, the Judge working directory.
$harnessFile = Join-Path (Get-Location).Path "CacheContractHarness.java"
if (-not (Test-Path -LiteralPath $harnessFile)) {
    Write-Output "Judge infrastructure: missing CacheContractHarness.java"; exit 2
}
if (-not (Get-Command javac -ErrorAction SilentlyContinue) -or -not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Output "Judge infrastructure: JDK 17 or newer required"; exit 2
}
$fixtureRoot = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ("java-cache-eval-" + [guid]::NewGuid().ToString("N"))))
[IO.Directory]::CreateDirectory($fixtureRoot) | Out-Null
try {
    [IO.File]::WriteAllText((Join-Path $fixtureRoot "UserCacheService.java"), $source, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $fixtureRoot "User.java"), 'public record User(long id, String name) {}', [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $fixtureRoot "UserRepository.java"), 'public interface UserRepository { User findById(long userId); }', [Text.UTF8Encoding]::new($false))
    Copy-Item -LiteralPath $harnessFile -Destination (Join-Path $fixtureRoot "CacheContractHarness.java")
    & javac --release 17 -encoding UTF-8 -d $fixtureRoot (Join-Path $fixtureRoot "User.java") (Join-Path $fixtureRoot "UserRepository.java") (Join-Path $fixtureRoot "UserCacheService.java") (Join-Path $fixtureRoot "CacheContractHarness.java") 2>&1 | ForEach-Object { Write-Output $_ }
    if ($LASTEXITCODE -ne 0) { Write-Output "Java 17 compilation failed"; exit 1 }
    $javaProcess = New-Object System.Diagnostics.Process
    $javaProcess.StartInfo.FileName = (Get-Command java).Source
    $javaProcess.StartInfo.Arguments = '-cp "' + $fixtureRoot + '" CacheContractHarness'
    $javaProcess.StartInfo.UseShellExecute = $false
    $javaProcess.StartInfo.CreateNoWindow = $true
    $javaProcess.StartInfo.RedirectStandardOutput = $true
    $javaProcess.StartInfo.RedirectStandardError = $true
    try {
        [void]$javaProcess.Start()
        $stdoutTask = $javaProcess.StandardOutput.ReadToEndAsync()
        $stderrTask = $javaProcess.StandardError.ReadToEndAsync()
        if (-not $javaProcess.WaitForExit(20000)) {
            $javaProcess.Kill()
            $javaProcess.WaitForExit()
            Write-Output "Cache implementation blocked for over 20 seconds"
            exit 1
        }
        Write-Output $stdoutTask.Result
        Write-Output $stderrTask.Result
        if ($javaProcess.ExitCode -ne 0) { Write-Output "Cache behavior contract failed"; exit 1 }
    } finally { $javaProcess.Dispose() }
} finally {
    $resolved = (Resolve-Path -LiteralPath $fixtureRoot).Path
    if ($resolved -cne $fixtureRoot -or (Get-Item -LiteralPath $resolved).LinkType) { throw "Refusing cleanup of changed fixture path" }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
exit 0
