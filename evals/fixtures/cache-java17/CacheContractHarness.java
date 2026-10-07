import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

public final class CacheContractHarness {
    public static void main(String[] args) throws Exception {
        concurrentSuccess();
        retryAfterFailure();
        System.out.println("CACHE_CONTRACT_PASS");
    }

    private static void concurrentSuccess() throws Exception {
        AtomicInteger calls = new AtomicInteger();
        User expected = new User(7L, "test-user");
        UserCacheService cache = new UserCacheService(id -> {
            calls.incrementAndGet();
            try {
                Thread.sleep(80);
            } catch (InterruptedException ex) {
                Thread.currentThread().interrupt();
                throw new IllegalStateException(ex);
            }
            return expected;
        });
        int workers = 16;
        ExecutorService pool = Executors.newFixedThreadPool(workers);
        CountDownLatch ready = new CountDownLatch(workers);
        CountDownLatch start = new CountDownLatch(1);
        try {
            List<Future<User>> futures = new ArrayList<>();
            for (int i = 0; i < workers; i++) {
                futures.add(pool.submit(() -> {
                    ready.countDown();
                    if (!start.await(3, TimeUnit.SECONDS)) {
                        throw new AssertionError("start timeout");
                    }
                    return cache.get(7L);
                }));
            }
            require(ready.await(3, TimeUnit.SECONDS), "workers not ready");
            start.countDown();
            for (Future<User> future : futures) {
                require(expected.equals(future.get(3, TimeUnit.SECONDS)), "wrong user");
            }
            require(expected.equals(pool.submit(() -> cache.get(7L)).get(3, TimeUnit.SECONDS)), "success result not cached");
            require(calls.get() == 1, "same key loaded " + calls.get() + " times");
        } finally {
            start.countDown();
            pool.shutdownNow();
        }
    }

    private static void retryAfterFailure() throws Exception {
        AtomicInteger attempts = new AtomicInteger();
        User expected = new User(8L, "recovered-user");
        UserCacheService cache = new UserCacheService(id -> {
            if (attempts.incrementAndGet() == 1) {
                throw new IllegalStateException("temporary repository failure");
            }
            return expected;
        });
        ExecutorService pool = Executors.newSingleThreadExecutor();
        try {
            Future<Boolean> rejected = pool.submit(() -> {
                try {
                    cache.get(8L);
                    return false;
                } catch (RuntimeException expectedFailure) {
                    return true;
                }
            });
            require(rejected.get(3, TimeUnit.SECONDS), "failure swallowed");
            Future<User> recovered = pool.submit(() -> cache.get(8L));
            require(expected.equals(recovered.get(3, TimeUnit.SECONDS)), "cannot retry");
            require(attempts.get() == 2, "failure permanently cached");
        } finally {
            pool.shutdownNow();
        }
    }

    private static void require(boolean condition, String message) {
        if (!condition) {
            throw new AssertionError(message);
        }
    }
}
