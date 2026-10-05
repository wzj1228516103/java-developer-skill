# 规则索引

根 `SKILL.md` 根据任务关键词选择参考文件；这个索引服务于维护者和人工查阅，不是每次任务的默认读取内容。

## 编号规则

| 文件 | 编号范围 | 典型触发词 |
|---|---|---|
| `java-core.md` | `JAVA-001` ~ `JAVA-005` | 日期、金额、BigDecimal、Optional、集合、equals |
| `spring-web.md` | `WEB-001` ~ `WEB-004` | Controller、DTO、REST、校验、分页、响应 |
| `security.md` | `SEC-001` ~ `SEC-004` | 权限、租户、JWT、Token、注入、上传、SSRF |
| `database-sql.md` | `DB-001` ~ `DB-004` | SQL、MyBatis、JPA、索引、分页、迁移 |
| `transaction-consistency.md` | `TX-001` ~ `TX-004` | 事务、幂等、状态机、Outbox、回滚 |
| `concurrency-reliability.md` | `CON-001` ~ `CON-005` | 线程池、超时、重试、限流、熔断、锁 |
| `testing.md` | `TEST-001` ~ `TEST-005` | JUnit、Mockito、集成测试、Testcontainers |
| `architecture.md` | `ARCH-001` ~ `ARCH-004` | 分层、模块、Repository、DDD、重构 |
| `redis-cache.md` | `CACHE-001` ~ `CACHE-005` | Redis、TTL、缓存、击穿、分布式锁 |
| `message-queue.md` | `MQ-001` ~ `MQ-005` | MQ、消费者、重复消费、死信、顺序消息 |
| `exception-validation.md` | `ERR-001` ~ `ERR-004` | 异常、错误码、日志、ControllerAdvice |

高风险规则统一使用“级别 / 适用 / 规则 / 正例 / 反例 / 例外”结构。编号可用于 Review、评测结果、项目例外和 Changelog，但不应取代对具体代码证据的说明。

## 公共契约

仅在接口契约会改变当前实现时读取对应文件：

- `contracts/response.md`：响应结构和敏感字段暴露；
- `contracts/exception.md`：业务异常、系统异常和回滚映射；
- `contracts/error-code.md`：错误码语义和模块分段；
- `contracts/pagination.md`：分页上限、排序和深分页；
- `contracts/logging.md`：日志级别、字段和脱敏。

不要因为参考文件存在就全部读取；项目已有契约优先，安全和数据正确性红线除外。
