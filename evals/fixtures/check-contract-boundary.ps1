param()

$text = $env:EVAL_FINAL_MESSAGE
if ([string]::IsNullOrWhiteSpace($text)) {
    Write-Error "EVAL_FINAL_MESSAGE is empty"
    exit 1
}

if ($text -notmatch "\u4e0d\u5b58\u5728|\u5f53\u524d.{0,12}(\u6ca1\u6709|\u672a|\u7f3a\u5c11)|\u5f85\u786e\u8ba4|\u5047\u8bbe|\u5951\u7ea6") {
    Write-Error "The answer does not mark the missing authorization API as an explicit contract boundary"
    exit 1
}

if ($text -notmatch "\u6743\u9650|\u6388\u6743|\u8bbf\u95ee|Unauthorized") {
    Write-Error "The answer does not address the requested authorization scenario"
    exit 1
}

Write-Output "Contract boundary regression passed"
exit 0
