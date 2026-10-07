# Java Developer Skill 评测

本目录使用 [skill-up](https://github.com/alibaba/skill-up) 对同一批 Java/Spring 后端任务进行 `with_skill` 与 `without_skill` 配对评测。配置、用例、Judge、回归脚本和精简后的指标文件随仓库发布；原始答案、Agent/Judge trace、HTML 报告和运行日志不纳入仓库。

## 最新结果

评测固定使用 `skill-up 0.12.0`、Codex CLI `0.160.0`、`gpt-6.1-sol`。`holdout-v6` 是 5 个来源任务的 3 轮开发回归，`eval-v9` 是 15 个任务的单轮主套件；来源任务参与过优化，结果用于回归验证，不代表未触碰任务上的独立泛化收益。

| 指标 | with_skill | without_skill | 提升 |
|---|---:|---:|---:|
| holdout-v6 平均质量断言通过率 | **100.00%** | 88.89% | **+11.11pp** |
| holdout-v6 整例通过率 | **15/15（100.00%）** | 11/15（73.33%） | **+26.67pp** |
| holdout-v6 最差用例平均质量率 | **100.00%** | 77.78% | **+22.22pp** |
| eval-v9 平均质量断言通过率 | **100.00%** | 91.67% | **+8.33pp** |

详细说明见[留出稳定性报告](results/2026-10-07-holdout-stability-report.md)。机器可读指标和输入核验如下：

- [holdout-v6 稳定性指标](results/2026-10-07-holdout-v6/stability-metrics.json)
- [holdout-v6 输入核验](results/2026-10-07-holdout-v6/input-verification.json)
- [eval-v9 主套件指标](results/2026-10-07-main-v9/metrics.json)
- [eval-v9 输入核验](results/2026-10-07-main-v9/input-verification.json)
- [Judge 校准摘要](results/2026-10-07-judge-calibration-summary.json)
- [事务定向回归稳定性指标](results/2026-10-07-transaction-targeted-v5/stability-metrics.json)
- [独立事务回归指标](results/2026-10-07-transaction-regression-v5/metrics.json)

## 目录结构

```text
evals/
├── eval.yaml                    # 主套件：15 个任务，with/without 成对运行
├── holdout.yaml                 # 5 个留出来源任务，支持多轮稳定性采样
├── transaction-regression.yaml  # 独立事务验证回归
├── cases/                       # 任务提示、断言和 Judge 配置
├── fixtures/                    # 脚本 Judge、编译夹具和 Judge 校准样本
├── scripts/                     # 运行、校验和指标提取脚本
├── tests/                       # Judge、指标和配置离线回归
└── results/                     # 仅保留摘要指标和输入核验，不含原始输出
```

用例覆盖日期时间、金额、空值、SQL 参数绑定、集合并发、分层、事务、权限、安全 Review、测试设计、批处理、资源生命周期、远程副作用恢复和 Java 17 编译行为。确定性规则优先使用 `rule_based` 或 `script`，需要开放式工程判断的用例使用经过正反例校准的 `agent_judge`。

## 本地复跑

先确认已安装 `skill-up`（当前验证版本为 `0.12.0`）和 JDK 17+，再在仓库根目录执行：

```powershell
skill-up validate ./evals/eval.yaml
skill-up validate ./evals/holdout.yaml
skill-up validate ./evals/transaction-regression.yaml

# 主套件
skill-up run ./evals/eval.yaml --parallelism 2

# 三轮留出稳定性采样；输出目录建议放在仓库外
& ./evals/scripts/run-eval.ps1 -EvalPath ./evals/holdout.yaml -Samples 3 -Parallelism 4 -OutputDirectory '../Java开发约束-holdout-samples'

# 独立事务回归
& ./evals/scripts/run-eval.ps1 -EvalPath ./evals/transaction-regression.yaml -Samples 1 -OutputDirectory '../Java开发约束-transaction-regression'
```

运行结束后，可使用仓库内脚本提取配对指标：

```powershell
pwsh -NoProfile -File ./evals/scripts/extract-metrics.ps1 `
  -ResultPath '../Java开发约束-workspace/iteration-N/result.json' `
  -OutputPath './evals/results/latest.json'

pwsh -NoProfile -File ./evals/scripts/extract-stability.ps1 `
  -ResultsDirectory '../Java开发约束-holdout-samples' `
  -ExpectedSamples 3 `
  -OutputPath './evals/results/holdout-stability.json'
```

不应把服务不可用、引擎超时、Judge 超时或不完整配对计为 Skill 行为失败。发布质量对比前应确认 `eligible_for_quality_comparison: true`、输入清单全部匹配，并人工复核开放式 Judge 的评分证据。

## 离线回归

Judge、编译夹具、指标计算和配置解析不需要模型或 API：

```powershell
pwsh -NoProfile -File ./evals/tests/judges.Tests.ps1
pwsh -NoProfile -File ./evals/tests/java-judges.Tests.ps1
pwsh -NoProfile -File ./evals/tests/metrics.Tests.ps1
pwsh -NoProfile -File ./evals/tests/stability.Tests.ps1
python ./evals/tests/config.Tests.py
```

配置和仓库维护检查：

```powershell
pwsh -NoProfile -File ./scripts/validate-registry.ps1
pwsh -NoProfile -File ./scripts/validate-content.ps1
pwsh -NoProfile -File ./tests/quality.Tests.ps1
git diff --check
```

这些检查验证配置、评分器和规则结构；它们不能替代真实 Spring 容器、数据库、消息队列或完整项目构建验证。
