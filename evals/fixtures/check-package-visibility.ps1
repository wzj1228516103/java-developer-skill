param()
$ErrorActionPreference = "Stop"
$text = [string]$env:EVAL_FINAL_MESSAGE
try { $answer = $text | ConvertFrom-Json } catch { Write-Output "Expected a JSON files object"; exit 1 }
$allowed = @("src/com/example/domain/ClaimResult.java", "src/com/example/domain/ClaimStatus.java", "src/com/example/application/OrderService.java")
if (-not $answer.files -or @($answer.files.PSObject.Properties).Count -ne $allowed.Count) { Write-Output "Expected the three declared Java files"; exit 1 }
foreach ($file in $answer.files.PSObject.Properties) {
    if ($file.Name -cnotin $allowed -or $file.Value -isnot [string] -or [string]::IsNullOrWhiteSpace($file.Value)) {
        Write-Output "Unexpected file path or empty source"; exit 1
    }
}
$harnessFile = Join-Path (Get-Location).Path "VisibilityHarness.java"
if (-not (Test-Path -LiteralPath $harnessFile)) { Write-Output "Judge infrastructure: missing VisibilityHarness.java"; exit 2 }
if (-not (Get-Command javac -ErrorAction SilentlyContinue) -or -not (Get-Command java -ErrorAction SilentlyContinue)) { Write-Output "Judge infrastructure: JDK 17 or newer required"; exit 2 }
$fixtureRoot = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ("java-visibility-eval-" + [guid]::NewGuid().ToString("N"))))
[IO.Directory]::CreateDirectory($fixtureRoot) | Out-Null
try {
    $sources = @()
    foreach ($file in $answer.files.PSObject.Properties) {
        $path = Join-Path $fixtureRoot $file.Name
        [IO.Directory]::CreateDirectory((Split-Path $path -Parent)) | Out-Null
        [IO.File]::WriteAllText($path, $file.Value, [Text.UTF8Encoding]::new($false))
        $sources += $path
    }
    $harnessPath = Join-Path $fixtureRoot "VisibilityHarness.java"
    Copy-Item -LiteralPath $harnessFile -Destination $harnessPath
    & javac --release 17 -encoding UTF-8 -d $fixtureRoot @sources $harnessPath 2>&1 | ForEach-Object { Write-Output $_ }
    if ($LASTEXITCODE -ne 0) { Write-Output "Cross-package Java 17 compilation failed"; exit 1 }
    & java -cp $fixtureRoot VisibilityHarness 2>&1 | ForEach-Object { Write-Output $_ }
    if ($LASTEXITCODE -ne 0) { Write-Output "Declared behavior contract failed"; exit 1 }
} finally {
    $resolved = (Resolve-Path -LiteralPath $fixtureRoot).Path
    if ($resolved -cne $fixtureRoot -or (Get-Item -LiteralPath $resolved).LinkType) { throw "Refusing cleanup of changed fixture path" }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
exit 0
