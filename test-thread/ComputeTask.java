import java.util.Date;

public class ComputeTask {
    private static final boolean DEBUG = false;
    
    static {
    }
    
    public static final void test() {
        int x = 1;
        while (x < 3000000) {
            x *= 2;
            x /= 2;
            x += 1;
        }
    }

    public static void main(String args[]) {
        for (int i = 0; i < 100; ++i) {
            long start = (new Date()).getTime();
            test();
            long end = (new Date()).getTime(); 
            System.out.println("ms    = " + (end - start));
        }
    }
}
