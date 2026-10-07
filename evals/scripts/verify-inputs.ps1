#requires -Version 7.0
param([Parameter(Mandatory)][string]$ManifestPath, [Parameter(Mandatory)][string]$OutputPath)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$manifestFile = (Resolve-Path -LiteralPath $ManifestPath).Path
$manifest = Get-Content -Raw -LiteralPath $manifestFile | ConvertFrom-Json
$rows = @($manifest.files | ForEach-Object {
    $path = [IO.Path]::GetFullPath((Join-Path $root $_.path))
    if(-not $path.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)){throw '输入路径越界。'}
    $actual = if(Test-Path -LiteralPath $path){(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}else{$null}
    [ordered]@{path=$_.path;expected_sha256=$_.sha256;actual_sha256=$actual;matched=$actual -eq $_.sha256}
})
$result=[ordered]@{
    schema_version='input-verification-v1';checked_at_utc=[DateTime]::UtcNow.ToString('o')
    evaluation_revision=$manifest.evaluation_revision
    manifest_sha256=(Get-FileHash -LiteralPath $manifestFile -Algorithm SHA256).Hash.ToLowerInvariant()
    total=$rows.Count;matched=@($rows|Where-Object matched).Count
    all_match=@($rows|Where-Object{-not $_.matched}).Count -eq 0
    files=$rows
}
$destination=[IO.Path]::GetFullPath($OutputPath)
[IO.Directory]::CreateDirectory((Split-Path $destination -Parent))|Out-Null
[IO.File]::WriteAllText($destination,($result|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))
Write-Output "冻结输入核验：$($result.matched)/$($result.total)；$($manifest.evaluation_revision)"
if(-not $result.all_match){throw '输入已改变，不能称为同一冻结版本。'}
