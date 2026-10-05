# Changelog

本项目遵循“规则按需加载、评测结果可复现”的小版本记录方式。

## [0.3.1] - 2026-10-05

- 增加 `run-eval.ps1 -Repeats`，支持显式多轮评测。
- 增加评测结果汇总脚本，区分 PASS、FAIL、ERROR 和 SKIP。
- 增加 `evals/README.md`，说明评测分类、结果解释和统计边界。

## [0.3.0] - 2026-10-05

- 为安全、SQL、Web、异常和事务规则增加稳定编号。
- 统一高风险规则的适用条件、正例、反例和例外结构。
- 增加 `context-budget` 评测场景，检查简单问题是否触发无关工作区读取。
- 增加 `scripts/validate-registry.ps1`，校验入口目录、frontmatter、插件清单和 README 同步。
- 增加维护与贡献文档。
- 增加 `evals/README.md` 和 `scripts/summarize-eval.ps1`，支持多轮评测结果汇总并区分 PASS、FAIL、ERROR、SKIP。

## [0.2.0]

- 增加七个命令式入口、按需路由、项目配置和 skill-up 评测场景。
