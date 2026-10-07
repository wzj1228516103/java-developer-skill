#requires -Version 7.0
param(
    [string]$JudgeShell = "powershell"
)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$fixtureDir = Join-Path $PSScriptRoot "../fixtures"
$fence = [string]::new([char]96, 3)
$nl = [Environment]::NewLine
function Code([string]$Language, [string]$Body) {
    return $fence + $Language + [Environment]::NewLine + $Body + [Environment]::NewLine + $fence
}
$sqlSafe = Code "xml" '<select>SELECT * FROM orders WHERE name LIKE CONCAT(''%'', #{keyword}, ''%'')</select>'
$cacheSafe = Code "java" 'class UserCacheService { ConcurrentHashMap<Long, User> cache = new ConcurrentHashMap<>(); User get(long userId) { return cache.computeIfAbsent(userId, repository::findById); } }'
$serviceValid = @'
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {
    @Mock InventoryService inventoryService;
    @Test void duplicateIdempotencyKey_returnsExistingOrder() { }
    @Test void insufficientStock_failsWithoutSavingOrder() {
        when(inventoryService.reserve(7L, 3))
            .thenThrow(new InsufficientStockException(7L, 3));
    }
    @Test void saveFailure_rollsBack() { }
    @Test void operatorWithoutPermission_cannotAccessOrder() { }
    @Test void concurrentSameRequest_createsOnlyOneOrder() { }
    // authorization: 当前操作者没有权限，必须拒绝。
    // Mockito cannot prove a transaction rollback; use a real database integration test.
    // The integration test uses a unique constraint and a real database transaction.
    // transaction rollback must be asserted with rollback state, not verify counts.
}
'@
$serviceEnglishAuth = @'
@Test void operatorWithoutPermission_shouldBeRejected() {
    assertThrows(AccessDeniedException.class, () -> orderService.getOrder(2001L, 9001L));
}
@Test void duplicateIdempotencyKey_and_insufficientStock_are_rejected() { }
@Test void concurrentSameRequest_createsOnlyOneOrder() { }
@Test void rollbackAfterDatabaseFailure() { /* database exception */ }
Mockito cannot prove transaction rollback; use a real database integration test.
'@
$contractValid = @'
题目没有提供订单访问 API，具体权限异常和返回语义需要按现有契约确认；当前不能假设一个不存在的方法。
应验证操作者权限，并在契约规定时返回 403 或不泄露订单信息。
'@
$orderTemplate = Code "java" 'record CreateOrderRequest(@NotBlank String idempotencyKey) {} @RestController class OrderController { @PostMapping Object create(@Valid CreateOrderRequest r, Principal p) { return service.create(r, p); } } @Service class OrderService { TransactionTemplate tx; Object create(CreateOrderRequest r, Principal p) { return tx.execute(s -> repository.save(r)); } }'
$orderTemplate += $nl + 'idempotency test cases'
$inventoryRecovery = 'UPDATE inventory SET available_qty = available_qty - ?; request_id; @Transactional; Outbox; retry; 保留事件并告警，支持人工重放；消息发送在事务之外；test'
$samples = @(
    @{ Name = "SQL：安全代码附带禁止语法说明"; Judge = "check-sql-parameterization.ps1"; Pass = $true; Message = $sqlSafe + $nl + '禁止使用 ${keyword}。' },
    @{ Name = "SQL：转义值绑定到嵌套参数"; Judge = "check-sql-parameterization.ps1"; Pass = $true; Message = (Code "java" 'String keyword; String likePattern = "%" + escapeLike(keyword) + "%";') + $nl + (Code "xml" '<select>SELECT * FROM orders WHERE name LIKE #{q.likePattern}</select>') },
    @{ Name = "SQL：允许明确标注的反例"; Judge = "check-sql-parameterization.ps1"; Pass = $true; Message = $sqlSafe + $nl + $nl + "不要使用下面这种写法：" + $nl + $nl + (Code "xml" 'AND name LIKE ''%${keyword}%''') },
    @{ Name = "SQL：拒绝实现中的文本替换"; Judge = "check-sql-parameterization.ps1"; Pass = $false; Message = $sqlSafe + $nl + (Code "xml" '<select>SELECT * FROM orders WHERE name LIKE ''%${keyword}%''</select>') },
    @{ Name = "SQL：拒绝只有 Param 注解"; Judge = "check-sql-parameterization.ps1"; Pass = $false; Message = (Code "java" 'List<Order> search(@Param("keyword") String keyword);') },
    @{ Name = "SQL：拒绝 SQL 拼接，即使另一段代码有绑定"; Judge = "check-sql-parameterization.ps1"; Pass = $false; Message = $sqlSafe + $nl + (Code "java" 'String sql = "SELECT * FROM orders WHERE name LIKE ''%" + keyword + "%''";') },
    @{ Name = "SQL：拒绝没有代码的安全宣称"; Judge = "check-sql-parameterization.ps1"; Pass = $false; Message = "keyword 使用参数绑定即可。" },
    @{ Name = "缓存：ConcurrentHashMap 泛型不误判"; Judge = "check-collection-concurrency.ps1"; Pass = $true; Message = $cacheSafe },
    @{ Name = "缓存：说明和注释中的 HashMap 不误判"; Judge = "check-collection-concurrency.ps1"; Pass = $true; Message = "不要用 HashMap<...> 存共享缓存。" + $nl + (Code "java" "// new HashMap<Long, User>() is unsafe") + $nl + $cacheSafe },
    @{ Name = "缓存：拒绝普通共享 HashMap"; Judge = "check-collection-concurrency.ps1"; Pass = $false; Message = (Code "java" 'class UserCacheService { HashMap<Long, User> cache = new HashMap<>(); User get(long id) { User user = repository.findById(id); cache.put(id, user); return user; } }') },
    @{ Name = "缓存：拒绝只有 Future 类型名"; Judge = "check-collection-concurrency.ps1"; Pass = $false; Message = (Code "java" 'ConcurrentHashMap<Long, CompletableFuture<User>> cache = new ConcurrentHashMap<>(); User get(long id) { User user = repository.findById(id); cache.put(id, CompletableFuture.completedFuture(user)); return user; }') },
    @{ Name = "缓存：允许显式锁保护的轻量方案"; Judge = "check-collection-concurrency.ps1"; Pass = $true; Message = (Code "java" 'Map<Long, User> cache = new HashMap<>(); User get(long id) { synchronized(cache) { return cache.computeIfAbsent(id, repository::findById); } }') }
    ,@{ Name = "缓存：拒绝 Java 17 中使用虚拟线程 API"; Judge = "check-collection-concurrency.ps1"; Pass = $false; Message = $cacheSafe + $nl + (Code "java" 'ExecutorService pool = Executors.newVirtualThreadPerTaskExecutor();') }
    ,@{ Name = "Service：接受 InsufficientStockException 作为库存失败"; Judge = "check-service-tests.ps1"; Pass = $true; Message = $serviceValid }
    ,@{ Name = "Service：英文权限异常与测试方法名是合法证据"; Judge = "check-service-tests.ps1"; Pass = $true; Message = $serviceEnglishAuth }
    ,@{ Name = "Contract：缺少 API 时明确标注契约边界"; Judge = "check-contract-boundary.ps1"; Pass = $true; Message = $contractValid }
    ,@{ Name = "订单：接受执行中的 TransactionTemplate"; Judge = "check-order-endpoint.ps1"; Pass = $true; Message = $orderTemplate }
    ,@{ Name = "订单：拒绝只有 TransactionTemplate 类型名"; Judge = "check-order-endpoint.ps1"; Pass = $false; Message = $orderTemplate.Replace('return tx.execute(s -> repository.save(r));', 'return repository.save(r);') }
    ,@{ Name = "库存：接受持久保留与告警人工重放"; Judge = "check-inventory-design.ps1"; Pass = $true; Message = $inventoryRecovery }
    ,@{ Name = "库存：接受失败队列与重新投递"; Judge = "check-inventory-design.ps1"; Pass = $true; Message = 'available_qty; request_id; @Transactional; Outbox; retry; 长期失败进入失败队列并告警，保留事件以便人工或自动重新投递；事务之外；test' }
    ,@{ Name = "库存：恢复描述不依赖告警与保留的词序"; Judge = "check-inventory-design.ps1"; Pass = $true; Message = 'available_qty; request_id; @Transactional; Outbox; retry; 告警通知运维。保留事件供人工重新投递；事务之外；test' }
    ,@{ Name = "库存：接受跨行持久化恢复方案"; Judge = "check-inventory-design.ps1"; Pass = $true; Message = "available_qty; request_id; @Transactional; Outbox; retry; 持久化失败事件${nl}告警后由人工重投；事务之外；test" }
    ,@{ Name = "库存：拒绝只有重试而无恢复路径"; Judge = "check-inventory-design.ps1"; Pass = $false; Message = 'available_qty; request_id; @Transactional; Outbox; retry; 事务之外；test' }
    ,@{ Name = "库存：拒绝告警后丢弃事件"; Judge = "check-inventory-design.ps1"; Pass = $false; Message = 'available_qty; request_id; @Transactional; Outbox; retry; 重试耗尽后告警并丢弃事件；事务之外；test' }
    ,@{ Name = "库存：拒绝只保留错误日志的恢复宣称"; Judge = "check-inventory-design.ps1"; Pass = $false; Message = 'available_qty; request_id; @Transactional; Outbox; retry; 告警并保留错误日志，人工恢复进程，事件丢弃；事务之外；test' }
)
$oldFinal = [Environment]::GetEnvironmentVariable("EVAL_FINAL_MESSAGE", "Process")
$failures = @()
try {
    foreach ($sample in $samples) {
        $env:EVAL_FINAL_MESSAGE = $sample.Message
        $output = & $JudgeShell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $fixtureDir $sample.Judge) 2>&1
        $actual = $LASTEXITCODE -eq 0
        if ($actual -ne $sample.Pass) {
            $failures += $sample.Name
            Write-Output ("FAIL " + $sample.Name + ": " + ($output -join " "))
        } else { Write-Output ("PASS " + $sample.Name) }
    }
} finally {
    [Environment]::SetEnvironmentVariable("EVAL_FINAL_MESSAGE", $oldFinal, "Process")
}
if ($failures.Count -gt 0) { throw ("评分器回归失败：" + ($failures -join "、")) }
Write-Output ("全部 {0} 个 Judge 回归通过（解释器：{1}）。" -f $samples.Count, $JudgeShell)
