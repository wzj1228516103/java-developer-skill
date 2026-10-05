# 贡献指南

感谢参与 Java Developer Skills。贡献应尽量让 Skill 更准确、更轻量，而不是机械增加规则数量。

## 提交前检查

```powershell
.\scripts\validate-registry.ps1
.\scripts\validate-content.ps1
py -3 -X utf8 "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py" .
git diff --check
```

## 规则编写约定

- 安全、数据正确性和严重可靠性问题使用 `BLOCKER`；一般生产要求使用 `MUST`；项目可覆盖的建议使用 `SHOULD`；偏好使用 `MAY`。
- 高风险规则使用稳定编号，并说明适用条件、正例、反例和例外。
- 不把某个项目的类名、包名、错误码或技术栈写成全局强制规则。
- 保持 `SKILL.md` 作为路由器，详细内容放到按主题加载的 `references/` 中。
- 简单问题不应触发工作区扫描或无关规则读取。

## Pull Request

PR 描述请包含变更目的、影响范围、验证命令和未覆盖风险。规则或入口变更应同时更新 README、CHANGELOG 或对应文档。
