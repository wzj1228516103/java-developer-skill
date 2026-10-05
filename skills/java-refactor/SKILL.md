---
name: java-refactor
description: 在保持已有行为和接口兼容的前提下，渐进式重构 Java 后端遗留代码。Use when splitting services, isolating layers, or reducing duplication.
---

# /java-refactor

先读取[共享总纲](../../SKILL.md)，按其中的任务边界和路由选择支持文件。

明确不可改变的行为，对有真实风险的调用方、事务、权限、序列化和数据库边界建立基线。按可回滚的小步计划改造并验证，不为了风格一次性重写模块；只请求方案时不修改代码。
