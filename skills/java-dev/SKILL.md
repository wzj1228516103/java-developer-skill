---
name: java-dev
description: 使用当前项目技术栈开发或生成 Java/Spring 后端代码，包括 Controller、DTO、Service、Mapper、SQL 和业务逻辑。Use when the user asks to implement a new backend feature or code skeleton.
---

# /java-dev

先完成用户要求的代码或骨架。只有用户明确指向“当前项目/本仓库/工作区”或提供文件路径时，才读取构建文件、同类代码和项目规范；“一个 Spring Boot 项目”属于自包含需求，不要扫描工作区。每个任务最多读取 2 个支持文件；只有项目已有模板或用户要求时才读取 `templates/`。

输出以实现或代码骨架为主，补充必要假设。只有涉及数据库、权限、支付、库存、消息或事务时，才说明对应风险和验证建议；不要附带无关的全量检查清单，也不要把幂等、缓存、消息、监控等可选增强混入主实现。

共享规则入口：`../../SKILL.md`。
