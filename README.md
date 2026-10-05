# Java Developer Skills

> 面向 Java/Spring 后端项目的可按需加载 Skill：让代码生成、接口设计、数据库变更、代码 Review 和测试补全遵循一致的生产级约束。

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Java](https://img.shields.io/badge/Java-17%2B-orange.svg)](https://www.oracle.com/java/technologies/javase/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-brightgreen.svg)](https://spring.io/projects/spring-boot)

本项目提供一组面向 Java 后端开发的命令式入口。你可以在请求开头使用 `/java-dev`、`/java-review` 等入口，让 Agent 直接进入对应工作模式；入口背后共享同一套规则、公共契约和项目配置。

## 目录

- [为什么需要这个 Skill](#为什么需要这个-skill)
- [七个入口](#七个入口)
- [入口如何配合](#入口如何配合)
- [覆盖范围](#覆盖范围)
- [快速开始](#快速开始)
- [规则等级与裁决顺序](#规则等级与裁决顺序)
- [项目适配](#项目适配)
- [仓库结构](#仓库结构)
- [维护检查](#维护检查)
- [适用边界](#适用边界)
- [参考来源与定位](#参考来源与定位)
- [贡献指南](#贡献指南)
- [版本记录](CHANGELOG.md)
- [安全策略](SECURITY.md)
- [许可证](#许可证)

## 为什么需要这个 Skill

Java 后端代码的问题通常不在“能不能编译”，而在于隐含的工程约束没有被持续执行：

| 问题 | 常见表现 | 可能后果 |
|---|---|---|
| 接口边界混乱 | Controller 直接访问 Mapper，Entity 直接返回前端 | 难以演进，容易泄露内部字段 |
| 数据与事务风险 | 事务包住远程调用、重复提交没有幂等、先查后改 | 数据不一致、重复扣款或状态错乱 |
| 安全缺口 | 信任前端 userId、SQL 拼接、日志记录 Token | 越权、注入、敏感数据泄露 |
| 可靠性不足 | 无超时、无限重试、消息重复消费未处理 | 线程耗尽、消息堆积、级联故障 |
| 规范难以落地 | 规则散落在文档中，生成代码时经常遗漏 | Review 成本高，团队风格漂移 |

**根因**：模型缺少一份**权威、结构化、可按需检索**的后端开发约束。把所有规范一次性塞进上下文会浪费 Token；只让模型凭记忆编码，又容易遗漏事务、安全和并发细节。真正有效的 Skill 需要把规则拆成可路由的主题，并让代码生成、Review 和测试共享同一套契约。

Java Developer Skills 将规则、公共契约和代码模板组合起来，并根据项目实际技术栈按需加载，不把某个团队的实现细节伪装成通用标准。

## 七个入口

| 入口 | 用途 | 主要交付 |
|---|---|---|
| `/java-dev` | 新功能开发和代码生成 | Controller、DTO、Service、Mapper、SQL 或业务代码骨架 |
| `/java-design` | 接口、数据库和架构设计 | 技术方案、数据模型、事务边界、风险清单 |
| `/java-review` | 代码审查和提交前自检 | 按严重级别分类的 Review 报告和修复建议 |
| `/java-test` | 单元测试和集成测试 | 测试用例、Mock 边界、Testcontainers/集成测试计划 |
| `/java-fix` | Bug 定位和修复 | 根因分析、最小修复、回归测试 |
| `/java-refactor` | 遗留代码渐进式重构 | 行为保持说明、重构步骤、风险和验证结果 |
| `/java-rules` | 查询和解释后端约束 | 命中的规则、适用条件、正反例和例外说明 |

入口名称是面向用户的工作模式；所有入口共享根目录的规则、模板、个人偏好和项目配置。当前仓库已经通过 `.codex-plugin/plugin.json` 和 `skills.registry.json` 注册为多入口插件，`/java-dev` 等入口可独立发现；根目录 `SKILL.md` 继续作为不支持插件清单时的兼容入口。

### `/java-dev`：开发和生成代码

适合新增接口、CRUD、Service、Mapper、DTO、SQL 或业务逻辑。只有任务明确指向当前项目时，它才识别项目技术栈和现有代码；自包含需求直接基于题目生成结果。

```text
/java-dev

按当前项目的技术栈实现订单创建接口，包含请求 DTO、参数校验、Service、事务边界和单元测试骨架。
```

### `/java-design`：设计技术方案

适合需求进入开发前的接口、表结构、事务、缓存、消息和模块边界设计。复杂流程应明确状态、失败路径、幂等和回滚策略。

```text
/java-design

设计库存扣减方案：给出表结构、接口、并发控制、幂等键、失败补偿和需要补充的测试。
```

### `/java-review`：审查代码

适合提交前自检、PR Review 和安全/性能专项检查。输出必须包含位置、证据、风险和建议，不把团队偏好直接判定为阻塞问题。

```text
/java-review

Review 当前变更，重点检查权限、SQL 注入、事务边界、重复消费、N+1 查询和敏感日志。
```

### `/java-test`：补充测试

适合为 Controller、Service、Repository、消息消费者和并发逻辑补测试。除了成功路径，还要覆盖边界、异常、权限、幂等和外部依赖失败。

```text
/java-test

为这个订单 Service 补充 JUnit 5 测试，覆盖重复请求、库存不足、事务异常和权限失败。
```

### `/java-fix`：定位和修复问题

适合线上异常、测试失败、慢查询、NPE、事务未生效和缓存不一致等问题。优先给出证据和最小修复，不在未确认影响范围时进行大规模重构。

```text
/java-fix

这个接口偶发返回旧订单状态，请根据日志、事务和缓存代码定位原因，并给出最小可验证修复。
```

### `/java-refactor`：渐进式重构

适合拆分过大的 Service、隔离 DTO/Entity、消除跨层调用和治理重复代码。默认保持已有行为，先建立回归测试再分步修改。

```text
/java-refactor

在不改变接口行为的前提下拆分这个 Service，先给出影响分析、拆分步骤和测试计划。
```

### `/java-rules`：查询规则

适合只想了解某条约束、比较不同实现或确认某个例外是否合理的场景。

```text
/java-rules

事务方法里能不能调用远程 HTTP？请结合当前项目技术栈说明风险、替代方案和允许例外。
```

## 入口如何配合

推荐的后端功能开发路径：

```text
/java-design → /java-dev → /java-review → /java-test
```

典型组合：

- **新功能**：先用 `/java-design` 明确接口、表结构、事务和幂等，再用 `/java-dev` 生成骨架，最后用 `/java-review` 和 `/java-test` 收口。
- **线上问题**：用 `/java-fix` 定位根因，修复后用 `/java-review` 检查副作用，再用 `/java-test` 补回归测试。
- **遗留代码**：用 `/java-refactor` 规划小步重构，每一步都回到 `/java-review` 和 `/java-test` 验证。
- **只查规范**：用 `/java-rules`，不会因为咨询规则而修改代码。

如果任务规模较小，可以直接使用单个入口；涉及权限、支付、库存、数据库迁移、事务或消息一致性时，建议至少经过设计、Review 和测试三个环节。

## 本 Skill 的优势

- 📚 **后端领域覆盖**：Java 核心、Spring Web、异常校验、SQL、事务、Redis、消息队列、安全、并发、测试和架构。
- 🧭 **按需路由，省 Token**：根 `SKILL.md` 和 7 个 `/java-*` 入口只加载当前任务命中的规则，详细内容保存在 `references/`。
- 🎯 **入口精准定位**：`/java-dev`、`/java-design`、`/java-review`、`/java-test` 等入口分别对应开发生命周期中的具体工作模式。
- 🏷️ **保留风险分级**：每个入口使用 `BLOCKER / MUST / SHOULD / MAY` 区分安全红线、生产要求和团队建议。
- ✅ **正例 + 反例导向**：规则和模板同时说明风险、推荐实现和例外条件，Review 时给出可执行修复。
- ⚖️ **冲突解决策略**：用户需求和已有行为优先，其次是安全、数据正确性、可靠性、一致性、性能和代码风格。
- 👁️ **生成与审查分流**：开发、设计、Review、测试、修复、重构和规则查询各有独立入口，但共享同一套公共契约。
- 🎛️ **项目级个性化**：通过 `memory.md` 和 `project/<项目名>.md` 覆盖技术栈、响应、异常、分页和团队编码偏好。

## 覆盖范围

| 模块 | 关注点 | 参考文件 |
|---|---|---|
| Java 核心 | 空值、时间、金额、集合、并发安全、资源释放 | `references/java-core.md` |
| Spring Web/API | Controller、DTO、REST、参数校验、接口兼容 | `references/spring-web.md` |
| 异常与日志 | 错误码、全局异常、日志级别、敏感信息 | `references/exception-validation.md` |
| 数据库与 SQL | 参数绑定、索引、分页、N+1、迁移 | `references/database-sql.md` |
| 事务与一致性 | 事务边界、幂等、状态机、补偿 | `references/transaction-consistency.md` |
| Redis | TTL、缓存一致性、穿透/击穿/雪崩、分布式锁 | `references/redis-cache.md` |
| 消息队列 | 重复消费、重试、死信、顺序、消息协议 | `references/message-queue.md` |
| 安全 | 认证授权、越权、注入、SSRF、脱敏、上传 | `references/security.md` |
| 并发与可靠性 | 线程池、超时、重试、限流、熔断、降级 | `references/concurrency-reliability.md` |
| 测试 | 单元、集成、容器化依赖、幂等和并发测试 | `references/testing.md` |
| 架构 | 分层、模块边界、依赖方向、领域对象隔离 | `references/architecture.md` |

## 快速开始

### 安装到 Codex

使用 Git 安装到 Codex 全局 Skill 目录：

```bash
git clone https://github.com/wzj1228516103/java-developer-skills.git \
  ~/.codex/skills/java-developer-skills
```

Windows PowerShell：

```powershell
git clone https://github.com/wzj1228516103/java-developer-skills.git `
  "$env:USERPROFILE\.codex\skills\java-developer-skills"
```

当前仓库优先支持 Codex Plugin；如果宿主不支持插件清单，可以把仓库目录作为项目级 Skill 放入项目的 `.codex/skills/`。其他 Agent（例如 `.claude/skills/`）的目录结构可能相似，但本项目没有承诺其自动发现、入口菜单或路由行为，使用前请按对应宿主文档验证。

如果宿主支持 Codex 插件清单，请使用仓库根目录的 `.codex-plugin/plugin.json`；入口注册表位于 `skills.registry.json`。新增或重命名入口时，需要同步修改这两个文件和 README 的入口表。

### 第一次使用

在 Java 项目中直接提出任务即可，例如：

```text
按当前项目的技术栈写一个创建订单的 Spring Controller 和 Service。
```

当任务明确指向当前项目时，Skill 会读取相关构建文件和现有代码，再按需加载 Controller、校验、事务或响应契约；自包含问题不会扫描工作区。也可以显式要求专项检查：

```text
Review 这个 Service 的事务边界、幂等性和并发风险。
检查这段 MyBatis SQL 是否有注入、N+1 和索引问题。
为这个消息消费者补充重复消费、重试和死信测试。
```

## 推荐工作流

### 新功能开发

```text
需求澄清 → 技术方案 → 任务拆分 → 代码生成/实现
    → 编译与 Review → 补充测试 → 运行测试 → 文档同步
```

简单改动可以直接从“实现”开始；涉及权限、支付、库存、数据库迁移、事务或消息一致性时，应先形成方案和风险清单。

### 代码 Review

Review 按风险顺序检查：

```text
编译/类型 → 需求行为 → 数据与事务 → 安全
    → 并发可靠性 → SQL 性能 → 可测试性
```

输出示例：

```text
[BLOCKER] SECURITY-OWNERSHIP-001
位置：UserController.java:42
问题：接口直接信任请求中的 userId，没有校验当前登录用户的资源归属。
风险：攻击者可以修改其他用户资料。
建议：从认证上下文获取操作者身份，并在服务层校验资源归属。
例外条件：内部批处理接口必须使用独立的服务身份和审计记录。
```

### 需求变更和遗留代码

先分析影响范围，再修改代码；涉及数据库、公共接口或消息协议时记录兼容性和回滚策略。遗留代码以保持行为不变为第一目标，按风险分阶段改造，不要求一次性清零所有规范问题。

## 规则等级与裁决顺序

| 等级 | 含义 |
|---|---|
| `BLOCKER` | 安全漏洞、数据损坏、严重一致性或线上故障风险 |
| `MUST` | 生产代码默认必须遵守 |
| `SHOULD` | 默认遵守，有明确理由可以例外 |
| `MAY` | 可选建议或团队偏好 |

规则冲突时遵循：

```text
用户明确需求和已有行为
  > 安全与数据正确性
  > 可靠性与一致性
  > 性能
  > 可维护性
  > 纯代码风格
```

不要机械地把“方法行数”“批量大小”“分页偏移量”等阈值判定为缺陷，应结合数据量、调用频率、运行环境和已有基准判断。

## 项目适配

### 个人偏好

`memory.md` 记录跨项目的个人选择，例如：

- Java 版本
- 金额使用 `BigDecimal` 还是最小货币单位
- Lombok 使用范围
- ORM 和测试框架
- API 响应风格

### 项目规范

复制 `project/_template.md` 为 `project/<项目名>.md`，填写项目技术栈和公共契约：

```yaml
java_version: 17
spring_boot: 3.x
orm: mybatis-plus
database: mysql
cache: redis
message_queue: rocketmq
```

项目规范可以覆盖默认命名和实现选择，但不能放宽安全、权限、参数化查询和数据正确性红线。

## 仓库结构

```text
java-developer-skills/
├── .codex-plugin/
│   └── plugin.json             # Codex 插件清单
├── skills.registry.json        # 入口目录的单一事实源
├── skills/                     # 可从 / 菜单发现的独立入口
│   ├── java-dev/
│   ├── java-design/
│   ├── java-review/
│   ├── java-test/
│   ├── java-fix/
│   ├── java-refactor/
│   └── java-rules/
├── SKILL.md                    # 总纲、路由、等级和适用边界
├── agents/openai.yaml          # Agent 界面元数据
├── memory.md                   # 个人偏好
├── project/
│   ├── README.md               # 项目配置说明
│   └── _template.md            # 项目规范模板
├── references/                 # 按主题加载的详细规则
│   └── contracts/              # 响应、异常、错误码、分页、日志契约
├── templates/                  # Controller、DTO、Service 模板
├── scripts/                    # 仓库维护检查脚本
│   ├── validate-content.ps1    # 规则编号和字段完整性检查
│   └── validate-registry.ps1   # 入口注册一致性检查
└── .github/workflows/          # 静态质量检查
```

## 维护检查

提交前建议运行：

```powershell
# 检查入口注册表、插件清单、frontmatter 和 README 是否同步
.\scripts\validate-registry.ps1

# 检查规则编号、级别、适用、正例、反例和例外字段
.\scripts\validate-content.ps1

# 校验 Skill 元数据
py -3 -X utf8 "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py" .

# 检查补丁中是否有空白错误
git diff --check
```

新增入口时只需先创建 `skills/<name>/SKILL.md`，再运行注册表检查；检查失败会明确指出遗漏的目录、名称或 README 入口。

## 适用边界

- 生产代码和 PR Review：完整启用。
- Demo、一次性脚本和临时迁移：保留 `BLOCKER/MUST`，`SHOULD` 可按成本豁免。
- 与项目既有规范冲突时：优先项目契约；涉及安全和数据正确性的规则除外。
- 用户明确要求关闭本 Skill：不再应用本 Skill 的约束。

本项目提供工程指导，不替代组织的安全审计、数据库变更审批、架构评审和发布流程。

## 参考来源与定位

本项目的规约来源与工程实现参考如下：

- [**《Java 开发手册（黄山版）》**](https://github.com/alibaba/p3c)：本 Skill 的规约内容来源，阿里巴巴 Java 社区工程规约的集大成者。
- [Alibaba Java Development Guide](https://github.com/Sxuan-Coder/alibaba-java-development-guide)：按需路由、规则分级、个人和项目配置、实战案例。
- [backend-skill](https://github.com/zhangloveyan/backend-skill)：公共契约、代码模板、开发生命周期、Review 和测试闭环。

规则内容按通用生产后端实践重新组织，不复制上述项目的特定项目实现或业务约定。

## 贡献指南

欢迎提交规则、模板和实战案例。新增内容建议遵循：

1. 说明规则适用场景和风险，不只写结论。
2. 区分 `BLOCKER/MUST/SHOULD/MAY`，避免把团队偏好写成通用硬规则。
3. 同时补充正例、反例或可复现的实战案例。
4. 不引入与具体项目绑定的类名、包名、错误码和数据库字段作为全局规则。
5. 修改后运行 `skill-creator` 的 `quick_validate.py`，并检查相关 YAML 和链接。

## 许可证

[MIT License](LICENSE)
