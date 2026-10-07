#requires -Version 7.0
param(
    [Parameter(Mandatory)][string]$SourceDirectory,
    [Parameter(Mandatory)][string]$DestinationDirectory
)
$ErrorActionPreference = 'Stop'
$source = (Resolve-Path -LiteralPath $SourceDirectory).Path.TrimEnd([IO.Path]::DirectorySeparatorChar)
$destination = [IO.Path]::GetFullPath($DestinationDirectory).TrimEnd([IO.Path]::DirectorySeparatorChar)
if ($source -eq $destination -or $destination.StartsWith($source + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw '归档目录必须与来源目录分离。'
}
$keepNames = @('result.json','benchmark.json','benchmark.md','report.html','grading.json','response.md',
    'prompt.txt','last-message.txt','stdout.json','final_message.txt','manifest.json','transcript.json','generated_files.txt')
$files = @(Get-ChildItem -LiteralPath $source -Recurse -File | Where-Object { $_.Name -in $keepNames })
if ($files.Count -eq 0) { throw '没有可归档结果。' }
$records = @()
foreach ($file in $files) {
    $relative = $file.FullName.Substring($source.Length + 1)
    $target = Join-Path $destination $relative
    [IO.Directory]::CreateDirectory((Split-Path $target -Parent)) | Out-Null
    if (Test-Path -LiteralPath $target) {
        if ((Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash) {
            throw "拒绝覆盖内容不同的已有归档：$relative"
        }
    } else { Copy-Item -LiteralPath $file.FullName -Destination $target }
    $sourceHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $destinationHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($sourceHash -ne $destinationHash) { throw "归档校验和不一致：$relative" }
    $records += [ordered]@{path=$relative.Replace('\','/');sha256=$sourceHash}
}
$index = [ordered]@{
    schema_version='archived-results-v1'
    archived_at_utc=[DateTime]::UtcNow.ToString('o')
    source_directory=$source
    files=$records
    interpretation='复制原始报告、评分、最终答案和 Agent/Judge 输入输出；每份文件的来源与归档 SHA-256 相同。'
}
[IO.File]::WriteAllText((Join-Path $destination 'index.json'), ($index|ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
Write-Output "已归档并核验 $($records.Count) 份文件：$destination"
