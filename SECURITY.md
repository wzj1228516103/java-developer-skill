# Security Policy

## Supported Versions

当前维护 `master` 分支和最新版本标签。旧版本不会自动获得规则或工作流安全修复。

## Reporting a Vulnerability

请不要在公开 Issue、Pull Request、评测报告或聊天记录中提交真实 API Key、Token、密码、生产地址或可利用漏洞细节。

发现项目自身的安全问题时，优先通过 GitHub Security Advisories 私下报告；如果无法使用该功能，可以先提交不包含敏感细节的 Issue，说明需要私下沟通。报告应包含：

- 受影响的版本或 commit；
- 可复现步骤和最小示例；
- 影响范围和可能的修复建议；
- 已采取的临时缓解措施。

## Secrets and Evaluation Data

- 本地评测从 `OPENAI_API_KEY` 或 GitHub Actions Secret 读取凭据，不把 Key 写入脚本、命令参数或仓库。
- 如果 Key 已经出现在聊天、终端历史、日志、Issue 或评测报告中，应立即在模型平台撤销并重新生成。
- `skill-up` 报告可能包含用户提示和模型输出，分享前应检查路径、业务数据、凭据和个人信息。
- 规则中的安全示例使用虚构标识，不应替换为真实生产凭据或内部地址。
