# 贡献指南

感谢参与 Java Developer Skill。贡献应尽量让 Skill 更准确、更轻量，而不是机械增加规则数量。参与讨论和提交贡献时请遵守[行为准则](CODE_OF_CONDUCT.md)。

## 本地验证

维护检查需要 PowerShell 7。完整评测回归还需要 JDK 17+、Python 3.12 和 PyYAML 6.0.2；这些检查不调用模型，也不需要 API Key。

```powershell
pwsh -NoProfile -File ./data/maintenance/scripts/validate-registry.ps1
pwsh -NoProfile -File ./data/maintenance/scripts/validate-content.ps1
pwsh -NoProfile -File ./data/maintenance/tests/quality.Tests.ps1
pwsh -NoProfile -File ./evals/tests/judges.Tests.ps1 -JudgeShell pwsh
pwsh -NoProfile -File ./evals/tests/java-judges.Tests.ps1 -JudgeShell pwsh
pwsh -NoProfile -File ./evals/tests/metrics.Tests.ps1
pwsh -NoProfile -File ./evals/tests/stability.Tests.ps1
python -m pip install PyYAML==6.0.2
python ./evals/tests/config.Tests.py
git diff --check
```

评测回归的作用和目录说明见 [`evals/README.md`](evals/README.md)。CI 会在 Pull Request 上自动运行同一组检查。

## 规则编写约定

- 安全、数据正确性和严重可靠性问题使用 `BLOCKER`；一般生产要求使用 `MUST`；项目可覆盖的建议使用 `SHOULD`；偏好使用 `MAY`。
- 高风险规则使用稳定编号，并说明适用条件、正例、反例和例外。
- 不把某个项目的类名、包名、错误码或技术栈写成全局强制规则。
- 保持 `SKILL.md` 作为路由器，详细内容放到按主题加载的 `data/references/` 中。
- 简单问题不应触发工作区扫描或无关规则读取。
- 维护检查使用 PowerShell 7，无需 API Key 或模型服务。Skill 的 `name` 和 `description` 使用非空单行 YAML 字符串；新增入口同步注册表和 README，版本同步插件清单、注册表和 CHANGELOG。
- 修改校验器时补充成功和失败样本，确认退出码及错误原因；这些是离线结构回归，不是模型效果评测。

## Pull Request

PR 描述请包含变更目的、影响范围、验证命令和未覆盖风险。规则或入口变更应同时更新 README、CHANGELOG 或对应文档。贡献者无需在 PR 中粘贴敏感日志或生产数据；提交前请先脱敏。
