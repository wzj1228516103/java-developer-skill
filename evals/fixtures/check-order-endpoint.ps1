param()
$ErrorActionPreference = "Stop"
$text = [string]$env:EVAL_FINAL_MESSAGE
if ([string]::IsNullOrWhiteSpace($text)) { Write-Output "Missing final answer"; exit 1 }
$blocks = [regex]::Matches($text, '(?ms)^\s*\x60{3}java[^\r\n]*\r?\n(.*?)^\s*\x60{3}\s*$')
$code = if ($blocks.Count -gt 0) { ($blocks | ForEach-Object { $_.Groups[1].Value }) -join [Environment]::NewLine } else { $text }
$code = [regex]::Replace($code, '(?s)/\*.*?\*/', '')
$code = [regex]::Replace($code, '(?m)//.*$', '')
$missing = @()
if ($code -notmatch '\b(?:class|record)\s+\w*(?:Request|DTO)\b' -or $code -notmatch '@Valid\b' -or $code -notmatch '@NotBlank\b') { $missing += 'request type and validation' }
if ($code -notmatch '@RestController\b' -or $code -notmatch '@PostMapping\b' -or $code -notmatch '@Service\b') { $missing += 'Controller and Service boundaries' }
$declarative = $code -match '@Transactional\b'
$programmatic = ($code -match '\bTransactionTemplate\b') -and ($code -match '\.execute(?:WithoutResult)?\s*\(')
if (-not ($declarative -or $programmatic)) { $missing += 'actual transaction declaration or TransactionTemplate execution' }
if ($code -notmatch 'SecurityContext|\bPrincipal\b|Authentication|currentUser|CurrentUser') { $missing += 'trusted actor context' }
if ($text -notmatch 'idempoten|\u5e42\u7b49' -or $text -notmatch '@Test|test|\u6d4b\u8bd5') { $missing += 'idempotency and test scenarios' }
if ($missing.Count -gt 0) { Write-Output ('Missing order endpoint evidence: ' + ($missing -join ', ')); exit 1 }
Write-Output "Order endpoint structural checks passed"
exit 0
