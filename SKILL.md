---
name: java-developer-skill
description: 为 Java/Spring 后端开发、设计、Review、测试、修复、重构和规则查询提供按需工程约束；不用于无关语言或泛化编程问答。
---

# Java 后端约束

按用户要求交付代码、方案或结论；规则只用于改变当前决策，不替代业务需求和项目契约，不额外增加层、框架、字段或工作流程。

## 工作方式

1. 自包含题直接基于题目处理，不扫描工作区。任务指向项目、文件或变更时，只读取相关代码和构建配置。
2. 简单题通常不读支持文件；普通任务先选 1 个主题，必要时最多 2 个，Review 通常最多 3 个。规则、契约、模板和偏好都计入预算；确缺关键约束时可补读并说明原因，不重复或递归扩展无关文件。
3. 项目规范 > 个人偏好 > 通用建议；只在影响实现时读取 `project/<项目名>.md` 或 `memory.md`，空白和候选值不代表已确认选择。不要未经用户要求写入个人或项目配置。
4. 按任务风险验证，区分实际运行结果与未执行的验证建议；只咨询、设计或 Review 时不修改代码。鉴权、缓存、幂等、消息等只在需求或代码涉及时处理。

下列路径以本文件所在的仓库根目录为基准，而不是用户 Java 项目的工作目录；`data/maintenance/` 不是 Java 规则来源。

## 路由表

仅在主题会改变当前答案时读取；关键词不是强制加载指令。

| 任务或关键词 | 首选参考 |
|---|---|
| Java 基础、命名、日期、金额、集合、空值 | `data/references/java-core.md` |
| Controller、DTO、REST、校验、分页、响应 | `data/references/spring-web.md`；需要时读 `data/references/contracts/` 对应契约 |
| 异常、错误码、日志、`@ControllerAdvice` | `data/references/exception-validation.md`；需要时读 `data/references/contracts/` |
| SQL、MyBatis、JPA、索引、分页、迁移 | `data/references/database-sql.md` |
| 事务、幂等、状态机、Outbox、回滚 | `data/references/transaction-consistency.md` |
| Redis、TTL、缓存、分布式锁、击穿 | `data/references/redis-cache.md` |
| MQ、重复消费、重试、死信、顺序消息 | `data/references/message-queue.md` |
| JWT、OAuth、Token、权限、租户、脱敏、上传、注入、SSRF | `data/references/security.md` |
| 线程池、超时、重试、限流、熔断、锁 | `data/references/concurrency-reliability.md` |
| JUnit、Mockito、集成测试、Testcontainers | `data/references/testing.md` |
| 分层、DAO、Repository、DDD、模块、Entity/DTO/VO | `data/references/architecture.md` |

## 规则等级与裁决

- **BLOCKER**：已证实的安全、数据或严重可靠性风险，需处理或明确其适用例外。
- **MUST**：适用条件成立时的生产要求。
- **SHOULD**：默认建议，允许有依据的项目、兼容性或性能例外。
- **MAY**：可选偏好。

用户需求决定范围，已有行为决定兼容；实现取舍按安全与数据正确性 > 可靠性与一致性 > 性能 > 可维护性 > 风格裁决。偏好不能放宽安全红线；重构保持行为，不凭方法行数、固定阈值或架构名词判定缺陷。

## 入口协作

按需选择 `/java-design`、`/java-dev`、`/java-review`、`/java-test`；故障用 `/java-fix`，重构用 `/java-refactor`，咨询用 `/java-rules`。无需为简单任务依次加载全部入口。

## 生成、Review 与测试

- 生成：遵守现有类型、接口及指定的 JDK/框架版本；跨包使用的类型、成员需有匹配的可见性。仅需要示意结构时读取 `data/templates/`，明确骨架的占位依赖，不把未验证的示意代码称为可运行实现。
- Review：需求行为和用户点名风险优先。按证据报告问题，未知项标为待确认；缺少文件不证明认证缺失，没有执行计划不证明查询慢。规则等级不自动等于本次缺陷严重性。
- 测试：围绕相关行为选择边界、异常、权限、并发和外部失败路径；Mock 调用次数和覆盖率不能证明数据库事务或协议行为。事务验证包含成功提交与失败回滚对照，明确异常类型及适用回滚规则，并从独立读取确认各步最终状态；未展示的配置标为待确认。涉及远程副作用时检验外部最终状态，缺少恢复协议时标注契约缺口。

Review 可按下面的精简格式输出；只在确有例外时补充例外条件，不编造编号或行号：

```text
[严重性] 规则编号（存在对应规则时）
位置与证据：文件:行号（可确定时）
问题：
风险：
建议：
```

## 适用边界

- 生产代码：仅应用相关规则；Demo、脚本和一次性迁移保留安全及数据正确性边界，允许轻量结构。
- 遗留代码：只改授权范围内的问题，分阶段验证，不一次性重写或清零全部规则。
- 用户明确要求不应用本 Skill：停止应用本 Skill 的约束。
