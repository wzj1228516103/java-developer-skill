#requires -Version 7.0
param(
    [string]$Root = (Join-Path $PSScriptRoot "..")
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$rootPath = (Resolve-Path -LiteralPath $Root).Path
$shellPath = Join-Path $PSHOME $(if ($IsWindows) { "pwsh.exe" } else { "pwsh" })
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("java-skills-quality-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $fixtureRoot | Out-Null
$fixturePrefix = [IO.Path]::GetFullPath($fixtureRoot) + [IO.Path]::DirectorySeparatorChar
$script:Checks = 0
$script:Failures = @()
$registry = [IO.File]::ReadAllText((Join-Path $rootPath "skills.registry.json")) | ConvertFrom-Json
$expectedEntries = @($registry.entries).Count
$expectedVersion = $registry.version
$expectedRules = 0
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $rootPath "references") -Recurse -File -Filter "*.md") {
    $expectedRules += [regex]::Matches([IO.File]::ReadAllText($file.FullName), '(?m)^##[ \t]+[A-Z][A-Z0-9]+-\d{3}[ \t]+').Count
}

function Edit-Text([string]$Fixture, [string]$Relative, [scriptblock]$Edit) {
    $path = [IO.Path]::GetFullPath((Join-Path $Fixture $Relative))
    if (-not $path.StartsWith($fixturePrefix, [StringComparison]::Ordinal)) { throw "Fixture path escaped temp directory." }
    $text = [IO.File]::ReadAllText($path)
    $updated = & $Edit $text
    [IO.File]::WriteAllText($path, [string]$updated, [Text.UTF8Encoding]::new($false))
}

function Check-Fixture {
    param(
        [string]$Name,
        [string]$Validator,
        [bool]$ShouldPass,
        [string]$ExpectedMessage,
        [scriptblock]$Mutate = {}
    )
    $script:Checks++
    $fixture = Join-Path $fixtureRoot ("case-" + $script:Checks + " 含空格")
    New-Item -ItemType Directory -Path $fixture | Out-Null
    foreach ($file in Get-ChildItem -LiteralPath $rootPath -File) {
        if ($file.Extension -eq ".md" -or $file.Name -in @("LICENSE", "skills.registry.json")) {
            Copy-Item -LiteralPath $file.FullName -Destination $fixture
        }
    }
    foreach ($directory in @(".codex-plugin", "skills", "references", "templates", "project")) {
        Copy-Item -LiteralPath (Join-Path $rootPath $directory) -Destination $fixture -Recurse
    }
    try {
        & $Mutate $fixture
        $validatorPath = Join-Path $rootPath "scripts/$Validator"
        $output = & $shellPath -NoProfile -NonInteractive -File $validatorPath -Root $fixture 2>&1
        $code = $LASTEXITCODE
        $message = $output | Out-String
        if (($ShouldPass -and $code -ne 0) -or (-not $ShouldPass -and $code -eq 0)) {
            throw "Unexpected exit $code. $message"
        }
        if ($message -notmatch $ExpectedMessage) { throw "Missing expected diagnostic '$ExpectedMessage'. $message" }
        Write-Output "PASS $Name"
    } catch {
        $script:Failures += "$Name -- $($_.Exception.Message)"
        Write-Output "FAIL $Name"
    }
}

try {
    Check-Fixture "registry baseline" "validate-registry.ps1" $true "$expectedEntries entries"
    Check-Fixture "rule baseline" "validate-content.ps1" $true "$expectedRules numbered rules"
    Check-Fixture "reordered quoted header" "validate-registry.ps1" $true "$expectedEntries entries" {
        param($fixture)
        Edit-Text $fixture "skills/java-dev/SKILL.md" {
            param($text)
            return [regex]::Replace($text, '(?s)\A---.*?---', ("---" + [char]10 + "description: 'Java backend development'" + [char]10 + 'name: "java-dev"' + [char]10 + "---"))
        }
    }
    Check-Fixture "CRLF and UTF8 BOM header" "validate-registry.ps1" $true "$expectedEntries entries" {
        param($fixture)
        $path = Join-Path $fixture "SKILL.md"
        $text = [IO.File]::ReadAllText($path) -replace '\r?\n', ([string][char]13 + [char]10)
        [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($true))
    }
    Check-Fixture "CRLF rule fields" "validate-content.ps1" $true "$expectedRules numbered rules" {
        param($fixture)
        Edit-Text $fixture "references/java-core.md" { param($text); return $text -replace '\r?\n', ([string][char]13 + [char]10) }
    }
    Check-Fixture "missing root skill" "validate-registry.ps1" $false "Missing required file: SKILL.md" {
        param($fixture)
        Remove-Item -LiteralPath (Join-Path $fixture "SKILL.md")
    }
    Check-Fixture "invalid registration JSON" "validate-registry.ps1" $false "Invalid registration JSON" {
        param($fixture)
        Edit-Text $fixture "skills.registry.json" { param($text); return '{"entries":' }
    }
    Check-Fixture "version mismatch" "validate-registry.ps1" $false "version mismatch" {
        param($fixture)
        Edit-Text $fixture ".codex-plugin/plugin.json" {
            param($text); $json = $text | ConvertFrom-Json; $json.version = "9.9.9"; return $json | ConvertTo-Json -Depth 15
        }
    }
    Check-Fixture "missing version history" "validate-registry.ps1" $false "no section for version" {
        param($fixture)
        Edit-Text $fixture "CHANGELOG.md" { param($text); return $text.Replace("## [$expectedVersion]", '## [Unreleased]') }
    }
    Check-Fixture "duplicate registry entry" "validate-registry.ps1" $false "Duplicate entry name" {
        param($fixture)
        Edit-Text $fixture "skills.registry.json" {
            param($text); $json = $text | ConvertFrom-Json; $json.entries += $json.entries[0]; return $json | ConvertTo-Json -Depth 15
        }
    }
    Check-Fixture "registry order does not matter" "validate-registry.ps1" $true "$expectedEntries entries" {
        param($fixture)
        Edit-Text $fixture "skills.registry.json" {
            param($text); $json = $text | ConvertFrom-Json; [array]::Reverse($json.entries); return $json | ConvertTo-Json -Depth 15
        }
    }
    Check-Fixture "registry path escape" "validate-registry.ps1" $false "Entry path must be" {
        param($fixture)
        Edit-Text $fixture "skills.registry.json" {
            param($text); $json = $text | ConvertFrom-Json; $json.entries[0].path = "../outside"; return $json | ConvertTo-Json -Depth 15
        }
    }
    Check-Fixture "body description is not frontmatter" "validate-registry.ps1" $false "exactly one description" {
        param($fixture)
        Edit-Text $fixture "skills/java-dev/SKILL.md" {
            param($text); return ([regex]::Replace($text, '(?m)^description:[^\r\n]*\r?\n', '')) + [char]10 + "description: body only"
        }
    }
    Check-Fixture "duplicate metadata" "validate-registry.ps1" $false "exactly one name" {
        param($fixture)
        Edit-Text $fixture "skills/java-dev/SKILL.md" { param($text); return $text.Replace('name: java-dev', ("name: java-dev" + [char]10 + "name: java-dev")) }
    }
    Check-Fixture "unclosed frontmatter" "validate-registry.ps1" $false "unclosed frontmatter" {
        param($fixture)
        Edit-Text $fixture "skills/java-dev/SKILL.md" { param($text); return [regex]::new('(?m)^---[ \t]*\r?\n').Replace($text, '', 1) }
    }
    Check-Fixture "empty quoted description" "validate-registry.ps1" $false "Empty description" {
        param($fixture)
        Edit-Text $fixture "skills/java-dev/SKILL.md" { param($text); return [regex]::Replace($text, '(?m)^description:[^\r\n]*', 'description: ""') }
    }
    Check-Fixture "collection description" "validate-registry.ps1" $false "single-line YAML string" {
        param($fixture)
        Edit-Text $fixture "skills/java-dev/SKILL.md" { param($text); return [regex]::Replace($text, '(?m)^description:[^\r\n]*', 'description: []') }
    }
    Check-Fixture "boolean description" "validate-registry.ps1" $false "single-line YAML string" {
        param($fixture)
        Edit-Text $fixture "skills/java-dev/SKILL.md" { param($text); return [regex]::Replace($text, '(?m)^description:[^\r\n]*', 'description: true') }
    }
    Check-Fixture "wrong entry name" "validate-registry.ps1" $false "Name mismatch" {
        param($fixture)
        Edit-Text $fixture "skills/java-dev/SKILL.md" { param($text); return $text.Replace('name: java-dev', 'name: java-wrong') }
    }
    Check-Fixture "README entry table mismatch" "validate-registry.ps1" $false "entry table is missing /java-dev" {
        param($fixture)
        Edit-Text $fixture "README.md" { param($text); return $text.Replace('/java-dev', '/missing-java-dev') }
    }
    Check-Fixture "missing root route" "validate-registry.ps1" $false "Missing root route" {
        param($fixture)
        Edit-Text $fixture "SKILL.md" { param($text); return $text.Replace('references/java-core.md', 'references/missing.md') }
    }
    Check-Fixture "root route path escape" "validate-registry.ps1" $false "Root route escapes repository" {
        param($fixture)
        Edit-Text $fixture "SKILL.md" { param($text); return $text.Replace('references/java-core.md', 'references/../../outside.md') }
    }
    Check-Fixture "broken shared link" "validate-registry.ps1" $false "Broken local file link" {
        param($fixture)
        Edit-Text $fixture "skills/java-dev/SKILL.md" { param($text); return $text.Replace('../../SKILL.md', '../../MISSING.md') }
    }
    Check-Fixture "local link path escape" "validate-registry.ps1" $false "Local link escapes repository" {
        param($fixture)
        Edit-Text $fixture "README.md" { param($text); return $text + [char]10 + '[outside](../outside.md)' }
    }
    Check-Fixture "duplicate rule ID" "validate-content.ps1" $false "Duplicate rule ID" {
        param($fixture)
        Edit-Text $fixture "references/java-core.md" { param($text); return $text.Replace('## JAVA-002 ', '## JAVA-001 ') }
    }
    Check-Fixture "invalid rule level" "validate-content.ps1" $false "invalid rule level" {
        param($fixture)
        Edit-Text $fixture "references/java-core.md" { param($text); return $text.Replace('级别：MUST', '级别：INVALID') }
    }
    Check-Fixture "empty rule field" "validate-content.ps1" $false "nonempty 规则 field" {
        param($fixture)
        Edit-Text $fixture "references/java-core.md" { param($text); return [regex]::Replace($text, '(?m)^规则：[^\r\n]*', '规则：') }
    }
    Check-Fixture "missing rule field" "validate-content.ps1" $false "nonempty 反例 field" {
        param($fixture)
        Edit-Text $fixture "references/java-core.md" { param($text); return [regex]::new('(?m)^反例：[^\r\n]*\r?\n').Replace($text, '', 1) }
    }
    Check-Fixture "duplicate rule field" "validate-content.ps1" $false "exactly one nonempty 适用 field" {
        param($fixture)
        Edit-Text $fixture "references/java-core.md" { param($text); return $text.Replace('级别：MUST', ("适用：duplicate" + [char]10 + "级别：MUST")) }
    }
    Check-Fixture "empty rule topic" "validate-content.ps1" $false "no numbered rules" {
        param($fixture)
        Edit-Text $fixture "references/java-core.md" { param($text); return "# Empty topic" }
    }
    Check-Fixture "malformed rule ID" "validate-content.ps1" $false "Malformed rule heading" {
        param($fixture)
        Edit-Text $fixture "references/java-core.md" { param($text); return $text.Replace('## JAVA-001 ', '## JAVA-01 ') }
    }
    Check-Fixture "unknown guide rule reference" "validate-content.ps1" $false "Unknown rule ID SEC-999" {
        param($fixture)
        Edit-Text $fixture "README.md" { param($text); return $text.Replace('SEC-001', 'SEC-999') }
    }
} finally {
    if ($script:Failures.Count -eq 0) {
        # Only delete the uniquely created, resolved fixture directory.
        $resolved = (Resolve-Path -LiteralPath $fixtureRoot).Path
        if ($resolved -cne [IO.Path]::GetFullPath($fixtureRoot) -or (Get-Item -LiteralPath $resolved).LinkType) {
            throw "Refusing cleanup of a changed fixture target."
        }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    } else {
        Write-Output "Failed fixtures retained at: $fixtureRoot"
    }
}

if ($script:Failures.Count -gt 0) {
    foreach ($failure in $script:Failures) { Write-Error $failure -ErrorAction Continue }
    exit 1
}
Write-Output ("All {0} offline quality checks passed." -f $script:Checks)
exit 0
