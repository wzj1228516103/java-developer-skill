# Controller 模板

这是结构示意，不是可直接复制运行的完整类。生成前读取项目的响应、鉴权、异常和校验约定，并替换示例类型和路径。

默认使用普通构造器注入，不假设项目已经引入 Lombok。

```java
@RestController
@RequestMapping("/resources") // 按项目 API 版本和资源命名约定替换
public class ResourceController {
    private final ResourceApplicationService service;

    public ResourceController(ResourceApplicationService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<ResourceResponse> create(
            @Valid @RequestBody CreateResourceRequest request) {
        ResourceResponse response = service.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
```

自检：无数据库调用、无复杂业务分支、入参有校验、响应不直接暴露 Entity、鉴权由项目统一机制完成。项目已有 Lombok 时可以按项目约定改用构造器注解。
