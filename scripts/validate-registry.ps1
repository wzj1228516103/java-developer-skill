param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot ".."))
)

$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
    Write-Error $Message
    $script:HasErrors = $true
}

function Read-Utf8([string]$Path) {
    return [IO.File]::ReadAllText($Path, [Text.UTF8Encoding]::new($false))
}

$script:HasErrors = $false
$rootPath = (Resolve-Path -LiteralPath $Root).Path
$registryPath = Join-Path $rootPath "skills.registry.json"
$pluginPath = Join-Path $rootPath ".codex-plugin/plugin.json"
$readmePath = Join-Path $rootPath "README.md"
$skillsPath = Join-Path $rootPath "skills"

foreach ($required in @($registryPath, $pluginPath, $readmePath, $skillsPath)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Fail "缺少必需路径：$required"
    }
}

if (-not $script:HasErrors) {
    try {
        $registry = Read-Utf8 $registryPath | ConvertFrom-Json
        $plugin = Read-Utf8 $pluginPath | ConvertFrom-Json
    } catch {
        Fail "注册文件不是有效 JSON：$($_.Exception.Message)"
    }
}

if (-not $script:HasErrors) {
    $entries = @($registry.entries)
    if ([string]$registry.name -ne [string]$plugin.name) {
        Fail "注册表 name 与插件 name 不一致：$($registry.name) / $($plugin.name)"
    }
    if ([string]$registry.version -ne [string]$plugin.version) {
        Fail "注册表 version 与插件 version 不一致：$($registry.version) / $($plugin.version)"
    }
    if ($entries.Count -eq 0) {
        Fail "skills.registry.json 没有 entries。"
    }

    $entryNames = @($entries | ForEach-Object { [string]$_.name })
    $entryPaths = @($entries | ForEach-Object { [string]$_.path })

    if (($entryNames | Sort-Object -Unique).Count -ne $entryNames.Count) {
        Fail "skills.registry.json 存在重复入口 name。"
    }
    if (($entryPaths | Sort-Object -Unique).Count -ne $entryPaths.Count) {
        Fail "skills.registry.json 存在重复入口 path。"
    }

    foreach ($entry in $entries) {
        if ([string]::IsNullOrWhiteSpace($entry.name) -or [string]::IsNullOrWhiteSpace($entry.path)) {
            Fail "入口必须同时包含 name 和 path。"
            continue
        }

        $entryDir = Join-Path $rootPath ([string]$entry.path)
        $entrySkillPath = Join-Path $entryDir "SKILL.md"
        if (-not (Test-Path -LiteralPath $entrySkillPath)) {
            Fail "注册入口缺少 SKILL.md：$($entry.name) -> $($entry.path)"
            continue
        }

        $content = Read-Utf8 $entrySkillPath
        $match = [regex]::Match($content, '(?ms)^---\s*\r?\nname:\s*([^\r\n]+)')
        if (-not $match.Success) {
            Fail "入口缺少可解析的 frontmatter name：$entrySkillPath"
        } elseif ($match.Groups[1].Value.Trim() -ne [string]$entry.name) {
            Fail "入口名称不一致：注册表=$($entry.name)，SKILL.md=$($match.Groups[1].Value.Trim())"
        }
        $description = [regex]::Match($content, '(?m)^description:\s*([^\r\n]+)')
        if (-not $description.Success -or [string]::IsNullOrWhiteSpace($description.Groups[1].Value)) {
            Fail "入口缺少非空 frontmatter description：$entrySkillPath"
        }
    }

    $actualDirs = @(Get-ChildItem -LiteralPath $skillsPath -Directory | ForEach-Object { "skills/$($_.Name)" })
    $registeredDirs = @($entryPaths | Sort-Object)
    $actualSorted = @($actualDirs | Sort-Object)
    if ((Compare-Object -ReferenceObject $actualSorted -DifferenceObject $registeredDirs)) {
        Fail "skills/ 目录与 skills.registry.json 的入口集合不一致。"
    }

    if ([string]$plugin.skills -ne "./skills/") {
        Fail ".codex-plugin/plugin.json 的 skills 必须指向 ./skills/。"
    }

    $rootSkillPath = Join-Path $rootPath "SKILL.md"
    if (Test-Path -LiteralPath $rootSkillPath) {
        $rootSkill = Read-Utf8 $rootSkillPath
        $rootName = [regex]::Match($rootSkill, '(?m)^name:\s*([^\r\n]+)')
        $rootDescription = [regex]::Match($rootSkill, '(?m)^description:\s*([^\r\n]+)')
        if (-not $rootName.Success -or $rootName.Groups[1].Value.Trim() -ne [string]$registry.name) {
            Fail "根 SKILL.md 的 frontmatter name 必须为 $($registry.name)。"
        }
        if (-not $rootDescription.Success -or [string]::IsNullOrWhiteSpace($rootDescription.Groups[1].Value)) {
            Fail "根 SKILL.md 缺少非空 frontmatter description。"
        }

        $routePaths = [regex]::Matches($rootSkill, '`((?:references|templates|project)/[^`]+)`')
        foreach ($routePath in $routePaths) {
            if ($routePath.Groups[1].Value.Contains('<') -or $routePath.Groups[1].Value.Contains('>')) {
                continue
            }
            $relativePath = $routePath.Groups[1].Value -replace '/', [IO.Path]::DirectorySeparatorChar
            $targetPath = Join-Path $rootPath $relativePath
            if (-not (Test-Path -LiteralPath $targetPath)) {
                Fail "根 SKILL.md 引用了不存在的支持文件：$($routePath.Groups[1].Value)"
            }
        }
    }

    $readme = Read-Utf8 $readmePath
    foreach ($name in $entryNames) {
        if ($readme -notmatch [regex]::Escape("/$name")) {
            Fail "README.md 未出现入口 /$name。"
        }
    }
}

if ($script:HasErrors) {
    exit 1
}

Write-Output ("注册表校验通过：{0} 个入口。" -f @($registry.entries).Count)
exit 0
