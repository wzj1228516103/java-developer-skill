# Service 模板

这是结构示意，不是可直接复制运行的完整类。服务方法应明确事务边界、幂等策略和异常语义；外部调用不要无理由放进数据库事务，状态变更使用条件更新或版本控制。

```java
@Service
public class ResourceApplicationService {
    private final ResourceRepository repository;

    public ResourceApplicationService(ResourceRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public ResourceResponse create(CreateResourceRequest request) {
        // 按项目规则完成校验、幂等、领域对象创建和持久化。
        Resource resource = Resource.create(request);
        Resource saved = repository.save(resource);
        return ResourceResponse.from(saved);
    }
}
```

`Resource.create`、`ResourceResponse.from` 和 Repository 方法是占位示例，必须替换为项目已有模型和接口；不要为了套用模板凭空新增公共框架。

仅在确有本地原子性要求时使用事务，并确认事务管理器覆盖实际 DataSource。需要 Spring 类代理的类和方法不要声明为 `final`。
