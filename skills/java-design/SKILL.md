---
name: java-design
description: 设计 Java 后端接口、数据库、事务、缓存、消息和模块架构。Use before implementing a medium or high-risk backend feature.
---

# /java-design

先确认需求边界并给出可执行方案。“一个/某个 Spring Boot 项目”的泛化题直接基于题目作答；只有用户明确说“当前项目/本仓库/工作区”或提供文件路径时，才读取已有接口和技术栈。每个任务最多读取 2 个支持文件；只输出与方案有关的数据模型、接口契约、状态、失败路径和验证计划，不在方案阶段擅自修改代码。

复杂流程使用时序、状态或流程描述；数据库变更必须说明兼容、迁移和回滚策略。

共享规则入口：`../../SKILL.md`。
