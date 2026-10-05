# DTO/Response 模板

请求 DTO 只表达输入契约，使用项目已启用的校验框架；Response 只输出允许公开的字段。不要复用数据库 Entity 作为双向输入输出模型。

```java
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;

public record CreateResourceRequest(
        @NotBlank String name,
        @Positive int quantity) {}
```

注解、字段和错误响应必须按项目现有版本替换；如果项目没有启用 Bean Validation，不要仅为套用模板引入新依赖。
