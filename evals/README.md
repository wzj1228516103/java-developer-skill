# 评测说明

评测使用 [Alibaba skill-up](https://github.com/alibaba/skill-up) 对同一批任务进行 `with_skill` / `without_skill` 对照。`eval.yaml` 只安装路由和规则文件，避免 README、模板、项目偏好和历史报告影响上下文。

## 场景分类

| 类别 | 场景 | 关注点 |
|---|---|---|
| 正确性 | Controller、SQL、事务、资源归属、缓存与消息、遗留重构 | 是否识别关键风险并给出可执行方案 |
| 反过度约束 | context-budget、scope-minimal-java | 简单问题是否直接回答，不扫描工作区、不扩展成 Spring 或数据库方案 |
| 稳定性 | 同一配置重复运行 | 通过率、Token、耗时和运行时错误的方差 |

## 本地运行

```powershell
# 先配置凭据；不要把 Key 写进脚本、命令参数或仓库
$env:OPENAI_API_KEY = "<你的百炼 API Key>"
.\scripts\run-eval.ps1 -Engine qwen_code -SkillUpPath "C:\tools\skill-up.exe" -OutputDir .\skill-up-results\run-01

# 重复运行 5 轮（会产生额外模型调用和费用）
.\scripts\run-eval.ps1 -Engine qwen_code -Repeats 5 -SkillUpPath "C:\tools\skill-up.exe" -OutputDir .\skill-up-results\five-runs

# 汇总一次或多次运行生成的 result.json
.\scripts\summarize-eval.ps1 -Path .\skill-up-results -JsonOut .\skill-up-summary.json
```

建议至少运行 5 轮，再比较 `with_skill` 和 `without_skill`。不要把单次运行的耗时或通过率当作统计结论。

## 结果解释

- `PASS`：场景断言通过。
- `FAIL`：模型完成了运行，但没有满足场景断言，应检查规则、提示和断言是否合理。
- `ERROR`：CLI、API、超时或运行环境失败，不应直接归因于 Skill；应单独记录并重跑。
- `SKIP`/`SKIPPED`：引擎明确跳过的场景，不计入通过率分母。
- `PassRateExcludingErrors`：只在有可判定的 PASS/FAIL 时计算。
- `PassRateIncludingErrors`：将 PASS/FAIL/ERROR 纳入分母、排除 SKIP，用于观察整体运行可靠性，不等同于 Skill 正确率。

评测断言应优先匹配语义证据。例如资源归属场景同时接受 `IDOR/BOLA`、认证上下文、资源归属和“不信任请求体 userId”等等价表达，避免把措辞差异误判为能力失败。
