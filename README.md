# Java Developer Skill

<div align="center">
  <img src="data/images/java-developer-skill-logo.png" alt="Java Developer Skill 项目视觉图" width="260">
  <p><strong>基于 AI 的 Java 开发全流程助手</strong></p>
</div>

> 面向 Java/Spring 后端项目的可按需加载 Skill：让代码生成、接口设计、数据库变更、代码 Review 和测试补全遵循一致的生产级约束。

> **核心规约基线：**《Java 开发手册（黄山版）》是本项目理解 Java 工程规范的起点。它把多年生产实践沉淀为可执行的编码、异常、测试、安全、数据库、工程结构和设计约束；本 Skill 在此基础上做按场景路由和项目化补充。

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Java](https://img.shields.io/badge/Java-17%2B-orange.svg)](https://www.oracle.com/java/technologies/javase/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-brightgreen.svg)](https://spring.io/projects/spring-boot)

## 项目总览

![Java Developer Skill 项目整体介绍：七个开发流程入口、技术栈与工程能力](data/images/java-developer-skill-overview.png)

本项目提供七种 Java 后端工作模式，覆盖开发、设计、Review、测试、修复、重构和规则查询。记不住入口名称也没关系，直接用日常语言描述任务即可。安装和使用方法见[安装](#安装)与[使用示例](#使用示例)。

## 目录

- [为什么需要这个 Skill](#为什么需要这个-skill)
- [为什么以黄山版为核心基线](#为什么以黄山版为核心基线)
- [项目总览](#项目总览)
- [七个入口](#七个入口)
- [本 Skill 的优势](#本-skill-的优势)
- [效果验证](#效果验证)
- [覆盖范围](#覆盖范围)
- [安装](#安装)
- [使用示例](#使用示例)
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
| 接口边界混乱 | HTTP 层编排复杂写操作、持久化对象暴露未授权字段 | 难以演进，容易泄露内部字段 |
| 数据与事务风险 | 事务包住远程调用、重复提交没有幂等、先查后改 | 数据不一致、重复扣款或状态错乱 |
| 安全缺口 | 信任前端 userId、SQL 拼接、日志记录 Token | 越权、注入、敏感数据泄露 |
| 可靠性不足 | 无超时、无限重试、消息重复消费未处理 | 线程耗尽、消息堆积、级联故障 |
| 规范难以落地 | 规则散落在文档中，生成代码时经常遗漏 | Review 成本高，团队风格漂移 |

**设计目标**：将容易遗漏的项目契约和工程风险整理成**结构化、可按需检索**的约束。整份手册一次性加载会增加上下文成本，因此只在相关规则会改变答案时读取它。Skill 不保证比模型原有能力更好，效果需要用真实任务验证。

Java Developer Skills 将规则、公共契约和代码模板组合起来，并根据项目实际技术栈按需加载，不把某个团队的实现细节伪装成通用标准。

## 为什么以黄山版为核心基线

### 它解决的是“能运行”之外的工程问题

Java 代码通过编译、接口返回 200，并不代表它适合长期运行。命名、异常处理、日志、数据库访问、事务边界和安全校验中的小偏差，往往会在并发、故障恢复或数据规模上来之后变成线上问题。**《Java 开发手册（黄山版）》的价值在于，它把这些容易依赖个人经验的判断，整理成团队可以共同执行和 Review 的工程基线。**

本项目以黄山版公开内容为 Java 基础规约参考，重点吸收其中的七个维度：

| 黄山版维度 | 在本 Skill 中的落地 | 典型收益 |
|---|---|---|
| 编程规约 | Java 核心类型、命名、集合、并发和资源使用 | 减少隐患写法和风格漂移 |
| 异常日志规约 | 错误码、异常边界、日志级别和敏感信息保护 | 让故障可定位、可恢复 |
| 单元测试规约 | 边界、异常、权限、幂等和集成验证 | 避免只测成功路径 |
| 安全规约 | 认证授权、越权、SQL 注入、脱敏和外部输入 | 把安全检查前移到开发和 Review |
| MySQL 数据库规约 | 参数绑定、索引、分页、事务和迁移 | 降低数据错误与性能风险 |
| 工程结构规约 | Controller、Service、Repository、DTO/VO 分层 | 保持职责清晰、便于演进 |
| 设计规约 | 依赖方向、模块边界、低耦合和可测试性 | 防止局部实现逐步失控 |

### 为什么要做成 Skill，而不是只放一份手册

手册适合人系统学习，模型却需要在具体任务中快速命中相关条款。把整本手册一次性塞入上下文会增加噪声和成本；完全依赖模型记忆又容易遗漏诸如日期时间 API、字符串比较、异常吞掉、SQL 拼接和 DTO/Entity 边界等细节。因此本 Skill 做了三层工程化处理：

1. **按需路由**：只读取会改变当前实现或 Review 结论的主题，避免无关规则干扰任务。
2. **保留适用条件和例外**：不把所有建议机械升级为阻塞项，结合项目契约、已有行为和风险证据判断。
3. **连接到交付动作**：规则不仅用于解释，还会落实到接口设计、代码实现、Review 清单、回归测试和故障修复。

黄山版是基础线，不是业务需求的替代品，也不是“照抄阿里代码”的模板。项目已有契约优先于一般实现建议；涉及安全、权限、参数化查询和数据正确性的底线不能被个人偏好放宽。本 Skill 也会明确区分黄山版参考内容、本项目工程补充和具体项目约束，避免把不同来源混为官方原文。

## 七个入口

| 入口 | 用途 | 主要交付 |
|---|---|---|
| `/java-dev` | 写新功能 | 按项目现有写法实现接口、业务逻辑或代码骨架 |
| `/java-design` | 先做设计 | 梳理接口、表结构、事务和可能的风险 |
| `/java-review` | 检查代码 | 找出有证据的问题，并说明位置和修改建议 |
| `/java-test` | 补充测试 | 覆盖正常情况、边界和失败情况 |
| `/java-fix` | 排查问题 | 找原因，做必要的修复，并补回归测试 |
| `/java-refactor` | 整理旧代码 | 分步骤改善代码，同时尽量保持原有行为 |
| `/java-rules` | 查询规范 | 用具体例子解释规则和适用条件 |

表里的 `/java-dev` 等是入口名称，不一定是你使用的 AI 工具自带的斜杠命令。不会用这些名称也没关系，启用 Skill 后直接说清楚要做什么就行。

## 本 Skill 的优势

- 📚 **后端领域覆盖**：Java 核心、Spring Web、异常校验、SQL、事务、Redis、消息队列、安全、并发、测试和架构。
- 📖 **以黄山版为基础**：以《Java 开发手册（黄山版）》作为 Java 通用规约基线，再补充现代 Spring 后端的事务、缓存、消息和可靠性实践。
- 🧭 **渐进加载**：总纲与入口引导 Agent 按需读取 `data/references/`，不默认加载全部主题；简单自包含题通常不读额外规则。这比全量加载轻，但不等于比不用 Skill 更省 Token。
- 🎯 **入口精准定位**：`/java-dev`、`/java-design`、`/java-review`、`/java-test` 等入口分别对应开发生命周期中的具体工作模式。
- 🏷️ **保留风险分级**：每个入口使用 `BLOCKER / MUST / SHOULD / MAY` 区分安全红线、生产要求和团队建议。
- ✅ **正例 + 反例导向**：规则和模板同时说明风险、推荐实现和例外条件，Review 时给出可执行修复。
- ⚖️ **冲突解决策略**：用户需求确定范围、现有行为确定兼容；范围内的实现取舍以安全、数据正确性、可靠性、一致性、性能和风格排序。
- 👁️ **生成与审查分流**：开发、设计、Review、测试、修复、重构和规则查询各有独立入口，但共享同一套公共契约。
- 🎛️ **项目级个性化**：通过 `memory.md` 和 `project/<项目名>.md` 覆盖技术栈、响应、异常、分页和团队编码偏好。

## 效果验证

> 通过 **with_skill vs without_skill** 基准对比评测：同一批 Java/Spring 后端任务，分别在有/无本 Skill 的情况下运行，由 `skill-up` Judge 逐条核对事务、安全、并发、SQL、测试和可靠性约束。

### 关键指标

| **指标** | **用本 Skill** | **不用 Skill** | **提升** |
|---|---:|---:|---:|
| **平均规约通过率（holdout-v6）** | **100.00%** | 88.89% | **+11.11pp** |
| **整例通过率（holdout-v6）** | **100.00%**（15/15） | 73.33%（11/15） | **+26.67pp** |
| **最差用例平均通过率** | **100.00%** | 77.78% | **+22.22pp** |
| **平均规约通过率（eval-v9）** | **100.00%** | 91.67% | **+8.33pp** |

### 实测对比：Spring 事务回滚验证

同一需求“验证两个本地写操作是否真正提交或回滚”，是否使用本 Skill，测试要求的完整性明显不同：

**❌ 不用 Skill** —— 只描述“让第二步失败，再检查第一步是否回滚”，没有明确异常类型、成功提交对照，也可能被测试外层事务掩盖：

```text
让 appendLedger 失败；
检查 markPaid 是否回滚。
```

**✅ 用本 Skill** —— 明确验证生产事务边界和最终数据库状态：

```text
通过 Spring 容器代理调用真实 Bean，不给测试套外层事务；
正常路径：新事务读取，确认 markPaid 与 appendLedger 都已提交；
失败路径：抛出未捕获 RuntimeException，新事务读取，确认两步都未提交；
检查型异常：按实际 rollbackFor 规则验证，不能笼统声称任意异常都会回滚。
```

> 这是本轮发现并修复的影响最大的问题：注解、自调用判断和 Mock 调用次数都不能证明生产事务已经提交或回滚。修订后，事务定向回归的 with_skill 结果为 **3/3**，独立事务回归为 **1/1**。

### 评测可复现

评测用例、Judge、评分脚本和原始结果已随仓库收录在 [`evals/`](evals/README.md) 目录；完整指标见[留出稳定性报告](evals/results/2026-10-07-holdout-stability-report.md)和[主套件指标](evals/results/2026-10-07-main-v9/metrics.json)。上述来源任务已经参与优化，因此这些数据用于回归验证，不代表独立泛化收益。

## 覆盖范围

| 模块 | 关注点 | 参考文件 |
|---|---|---|
| Java 核心 | 空值、时间、金额、集合、并发安全、资源释放 | `data/references/java-core.md` |
| Spring Web/API | Controller、DTO、REST、参数校验、接口兼容 | `data/references/spring-web.md` |
| 异常与日志 | 错误码、全局异常、日志级别、敏感信息 | `data/references/exception-validation.md` |
| 数据库与 SQL | 参数绑定、索引、分页、N+1、迁移 | `data/references/database-sql.md` |
| 事务与一致性 | 事务边界、幂等、状态机、补偿 | `data/references/transaction-consistency.md` |
| Redis | TTL、缓存一致性、穿透/击穿/雪崩、分布式锁 | `data/references/redis-cache.md` |
| 消息队列 | 重复消费、重试、死信、顺序、消息协议 | `data/references/message-queue.md` |
| 安全 | 认证授权、越权、注入、SSRF、脱敏、上传 | `data/references/security.md` |
| 并发与可靠性 | 线程池、超时、重试、限流、熔断、降级 | `data/references/concurrency-reliability.md` |
| 测试 | 单元、集成、容器化依赖、幂等和并发测试 | `data/references/testing.md` |
| 架构 | 分层、模块边界、依赖方向、领域对象隔离 | `data/references/architecture.md` |

## 安装

在终端运行这条命令，就能把 Java Developer Skill 安装到 Codex：

```bash
npx skills add https://github.com/wzj1228516103/java-developer-skill -g -a codex -y
```

Windows PowerShell 也可以直接运行同一条命令。安装后运行下面的命令，检查它是否已经装好：

```bash
npx skills list -g -a codex
```

看到 `java-developer-skill` 就表示安装完成。重新打开 Codex，在消息里输入 `$java-developer-skill`，再接着写你的任务。若找不到它，重启 Codex 后再检查一次。

## 使用示例

启用 Skill 后，像平时一样把需求说清楚就行，不用背入口名称：

| 你可以这样说 | 它会帮你做什么 |
|---|---|
| “按这个项目现在的写法，帮我加一个创建订单的接口，写完跑相关测试。” | 先看项目已有代码和技术栈，再实现功能并验证。 |
| “帮我检查这次改动有没有权限、事务或 SQL 问题；只检查，先别改代码。” | 根据代码证据指出问题、位置和建议，不会擅自修改。 |
| “库存扣减应该怎么设计？请说明并发控制和失败后怎么处理，先给方案。” | 先梳理方案和风险，不直接开始写代码。 |
| “这个接口偶尔读到旧订单状态，帮我找原因、修复并补一个回归测试。” | 排查原因，做必要修改，再检查相关测试。 |
| “给这个 Service 补测试，尤其覆盖参数边界和调用失败的情况。” | 补充正常、边界和失败路径的测试。 |
| “帮我拆一下这个过大的 Service，但不要改变接口行为。” | 分步骤整理代码，并验证原有行为没有改变。 |
| “金额字段为什么一般用 `BigDecimal`？什么情况下可以用整数分？” | 查找相关规则，用当前问题解释推荐做法和例外。 |

任务越具体，结果通常越贴合项目。比如说清楚“只检查，不要修改”，或“按当前项目写法实现并运行测试”，AI 就更容易按你的预期交付。

## 规则等级与裁决顺序

| 等级 | 含义 |
|---|---|
| `BLOCKER` | 安全漏洞、数据损坏、严重一致性或线上故障风险 |
| `MUST` | 生产代码默认必须遵守 |
| `SHOULD` | 默认遵守，有明确理由可以例外 |
| `MAY` | 可选建议或团队偏好 |

规则冲突时遵循：

```text
范围和兼容：用户明确需求 + 已有行为
范围内取舍：安全与数据正确性 > 可靠性与一致性
          > 性能 > 可维护性 > 纯代码风格
```

偏好不能放宽安全和数据正确性红线。规则级别也不自动等于本次问题的严重性：Review 必须结合适用条件、证据和例外，不凭方法行数、固定阈值或缺少其他文件判定缺陷。

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

配置优先级为“项目规范 > 个人偏好 > 通用建议”；留空或候选列表不是已确认的配置。生成/修改这些文件需用户要求或确认，不自动把聊天中的一次性选择写成长期规则。不要提交内部项目细节、个人信息或凭据。

## 仓库结构

```text
java-developer-skill/
├── .codex-plugin/
│   └── plugin.json             # Codex 插件清单
├── .github/                    # Issue、PR 模板和 CI
├── agents/openai.yaml          # Agent 界面元数据
├── data/
│   ├── images/                  # README 项目图片
│   ├── references/              # 按主题加载的规则与公共契约
│   ├── templates/               # Controller、DTO、Service 模板
│   └── maintenance/             # 仓库校验脚本与离线测试
├── skills.registry.json        # 本项目的入口维护索引
├── skills/                     # 七种工作模式；发现方式由宿主决定
│   ├── java-dev/
│   ├── java-design/
│   ├── java-review/
│   ├── java-test/
│   ├── java-fix/
│   ├── java-refactor/
│   └── java-rules/
├── SKILL.md                    # 总纲、路由、等级和适用边界
├── memory.md                   # 个人偏好
├── project/
│   ├── README.md               # 项目配置说明
│   └── _template.md            # 项目规范模板
└── evals/                      # Skill-up 配置、用例、Judge 与精选结果
```

## 维护检查

维护检查需要 PowerShell 7（`pwsh`），不需要 API Key、模型接口或 skill-up。提交前运行：

```powershell
# 检查版本、入口、frontmatter、路由和本地文件链接
pwsh -NoProfile -File ./data/maintenance/scripts/validate-registry.ps1

# 检查规则编号、级别、适用、正例、反例和例外字段
pwsh -NoProfile -File ./data/maintenance/scripts/validate-content.ps1

# 用临时副本验证错误样本会被拦截，不修改仓库
pwsh -NoProfile -File ./data/maintenance/tests/quality.Tests.ps1

# 检查补丁中是否有空白错误
git diff --check
```

新增入口时同步 `skills.registry.json` 和 README；清单的 `skills` 目录不变时无需逐项重复登记。修改版本时同步插件清单、注册表和 CHANGELOG。维护脚本位于 `data/maintenance/`，验证 `name`、`description` 等仓库约定，但不是通用 YAML 解析器。若本机已安装 skill-creator，还可以用其 `quick_validate.py` 做补充检查。

CI 检查入口与规则结构，不等于验证所有 Java 示例可编译、插件已经安装或模型一定更准确。此前小样本对照未见明显正确性退化，也未证实稳定增益；Spring/MySQL 真实事务和并发行为尚未完成运行验证，不公布虚构通过率。

## 适用边界

- 生产代码和 PR Review：只应用当前任务相关规则。
- Demo、一次性脚本和临时迁移：保留安全与数据正确性边界，允许轻量结构。
- 与项目既有规范冲突时：优先项目契约；涉及安全和数据正确性的规则除外。
- 用户明确要求关闭本 Skill：不再应用本 Skill 的约束。

本项目提供工程指导，不替代组织的安全审计、数据库变更审批、架构评审和发布流程。

## 参考来源与定位

本项目的规约来源与工程实现参考如下：

- [**《Java 开发手册（黄山版）》**](https://github.com/alibaba/p3c)：本项目的 Java 通用规约基线。它将阿里巴巴长期生产实践总结为一套广泛采用的工程规范，是本 Skill 处理命名、异常、日志、测试、安全、数据库和工程结构问题时的重要参考。当前仓库只选取并重新组织适用于 AI 辅助开发的内容，不表示全文收录，也不表示所有规则均为手册原文。
- [Alibaba Java Development Guide](https://github.com/Sxuan-Coder/alibaba-java-development-guide)：按需路由、规则分级、个人和项目配置、实战案例。
- [backend-skill](https://github.com/zhangloveyan/backend-skill)：公共契约、代码模板、开发生命周期、Review 和测试闭环。

规则按通用后端实践重新组织，包含事务、缓存、消息等工程总结；`BLOCKER/MUST/SHOULD/MAY` 是本项目的分级，不与阿里手册条文级别一一等同。本项目非阿里巴巴官方产品，也未获其背书。

## 贡献指南

欢迎提交规则、模板和实战案例。新增内容建议遵循：

1. 说明规则适用场景和风险，不只写结论。
2. 区分 `BLOCKER/MUST/SHOULD/MAY`，避免把团队偏好写成通用硬规则。
3. 同时补充正例、反例或可复现的实战案例。
4. 不引入与具体项目绑定的类名、包名、错误码和数据库字段作为全局规则。
5. 修改后运行仓库内的维护检查与回归测试，并记录未验证的行为。

## 许可证

[MIT License](LICENSE)

MIT 适用于本项目原创封装和整理；引用来源的商标、手册原文及第三方素材仍遵循各自权利和许可，不因本仓库的 MIT 声明而改变。
