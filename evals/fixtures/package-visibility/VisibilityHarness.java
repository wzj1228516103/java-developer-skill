import com.example.application.OrderService;
import com.example.domain.ClaimResult;
import com.example.domain.ClaimStatus;

public final class VisibilityHarness {
    public static void main(String[] args) {
        OrderService service = new OrderService();
        if (!service.accepts(ClaimResult.newRequest())) {
            throw new AssertionError("NEW must be accepted");
        }
        if (service.accepts(new ClaimResult(ClaimStatus.COMPLETED))) {
            throw new AssertionError("COMPLETED must be rejected");
        }
        System.out.println("VISIBILITY_CONTRACT_PASS");
    }
}
