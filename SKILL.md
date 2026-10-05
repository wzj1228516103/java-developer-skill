---
name: java-developer-skills
description: 在用户明确请求 Java/Spring 后端代码、设计、Review、测试或修复时提供按需工程约束。优先完成用户任务，只在相关风险会改变答案时读取规则；不用于泛化编程问答或无关语言任务。
---

# Java 后端约束

本 Skill 提供决策支持，不替代用户需求、项目现状或正常工程判断。先交付用户要的代码、方案或结论，再补充当前任务真正需要的规则；不要为了“规范”增加未要求的层、字段、框架、事务、重试或测试。

## 工作方式

1. 先识别交付物和范围，直接回答或实现，不先罗列完整规约。
2. 只有用户明确指向当前项目、仓库、工作区、文件或变更时，才读取构建文件、配置和同类代码；自包含问题不要扫描工作区。
3. 只有项目约定会改变实现时才读取 `memory.md` 或 `project/<项目名>.md`；它们不是每次任务的必读文件。
4. 只读取会改变当前决策的可选支持文件（规则、契约、模板和偏好配置合计）：简单自包含问题通常为 0，普通任务默认最多 2 个，Review 默认最多 3 个。它是上下文预算而不是为了凑数的硬性指标；只有缺少关键约束会改变结论时才继续读取，并说明原因。不要重复读取同一主题或无关入口。
5. 生成代码时按风险验证；权限、SQL、事务、并发、迁移和消息改动才增加专项验证或回归计划。
6. 不要把可选增强混入主实现。幂等、鉴权、缓存、消息、监控和完整异常体系只有在题目或现有代码涉及时才加入。

本文件的相对路径均以仓库根目录为基准。不要把维护文档或 `scripts/` 当作 Java 规则来源，也不要因为参考文件中的链接继续递归读取。

## 路由表

命中关键词且主题会改变当前答案时，读取对应文件；未命中时不要为了“完整”加载规则。

| 任务或关键词 | 首选参考 |
|---|---|
| Java 基础、命名、日期、金额、集合、空值 | `references/java-core.md` |
| Controller、DTO、REST、校验、分页、响应 | `references/spring-web.md`；需要时读 `references/contracts/` 对应契约 |
| 异常、错误码、日志、`@ControllerAdvice` | `references/exception-validation.md`；需要时读 `references/contracts/` |
| SQL、MyBatis、JPA、索引、分页、迁移 | `references/database-sql.md` |
| 事务、幂等、状态机、Outbox、回滚 | `references/transaction-consistency.md` |
| Redis、TTL、缓存、分布式锁、击穿 | `references/redis-cache.md` |
| MQ、重复消费、重试、死信、顺序消息 | `references/message-queue.md` |
| JWT、OAuth、Token、权限、租户、脱敏、上传、注入、SSRF | `references/security.md` |
| 线程池、超时、重试、限流、熔断、锁 | `references/concurrency-reliability.md` |
| JUnit、Mockito、集成测试、Testcontainers | `references/testing.md` |
| 分层、DAO、Repository、DDD、模块、Entity/DTO/VO | `references/architecture.md` |

## 规则等级与裁决

- **BLOCKER**：安全漏洞、数据损坏、严重一致性或线上故障风险；必须处理或明确记录例外。
- **MUST**：生产代码默认必须遵守。
- **SHOULD**：默认遵守；有项目、兼容性或性能理由时可例外并说明。
- **MAY**：可选建议或团队偏好。

用户需求决定目标和范围，已有行为决定兼容约束；实现取舍按安全与数据正确性 > 可靠性与一致性 > 性能 > 可维护性 > 纯代码风格裁决。项目偏好不能放宽安全和数据正确性红线，MUST 仅在其适用条件成立时生效。重构存量代码优先保持行为不变；不要把方法行数、批量大小或分页阈值机械判定为缺陷。

## 入口协作

命令式入口负责任务模式，根规则负责共享边界：

`/java-design → /java-dev → /java-review → /java-test`

线上问题使用 `/java-fix`；遗留代码使用 `/java-refactor`；只咨询约束使用 `/java-rules`。简单任务可以只使用一个入口。

## 生成、Review 与测试

- 生成代码：输出可运行实现和必要假设；只有项目已有模板或用户明确要求时才读取 `templates/`。
- Review：先检查用户点名的风险和需求行为，再按证据补充问题；只报告真实问题，不为了凑清单制造告警。只请求审查时不修改代码。
- Review：题目未提供代码、配置、日志或执行证据时，将结论标为待确认；不要把推测性的性能、认证或架构风险直接升级为 `BLOCKER`。
- 测试：按被测行为选择成功、边界、异常、权限、幂等、并发或外部依赖失败路径，不以覆盖率数字替代风险判断。

Review 输出采用：

```text
[等级] 规则编号
位置：文件:行号（可确定时）
问题：
风险：
建议：
例外条件：
```

事务边界、权限、缓存一致性、数据库迁移和接口行为涉及业务语义时，先说明影响，不擅自大范围修改。

## 适用边界

- 生产代码和 PR Review：完整启用。
- Demo、脚本、一次性迁移：保留 BLOCKER/MUST，SHOULD 可按成本豁免。
- 遗留代码：分阶段改造，不要求一次性清零全部问题。
- 用户明确要求不应用本 Skill：停止应用本 Skill 的约束。

项目特定约定放入 `project/`，个人偏好放入 `memory.md`；不要修改本文件来容纳单个项目的偏好。
