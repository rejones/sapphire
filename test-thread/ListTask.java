import java.util.Date;

public class ListTask {
    private static final boolean DEBUG = false;

    private static final int ELEMENTS = 32;
    private static final int SORTS = 1;

    private static final class ListElement {
        public final int n;
        private ListElement next = null;

        public ListElement(int n) { this.n = n; }
        public ListElement getNext() { return next; }
        public void setNext(ListElement e) { next = e; }
        public String toString() { return "[" + n + "]"; }
    } 
    
    private ListElement head = null;
    private ListElement tail = null;

    public ListTask() {
    }

    public void insert(ListElement e) {
        if (DEBUG)
            System.out.println("insert " + e);

        e.setNext(head);
        head = e;
        if (tail == null)
            tail = e;
    }

    public void append(ListElement e) {
        if (DEBUG)
            System.out.println("append " + e);
        
        e.setNext(null);
        if (tail == null) {
            head = e;
            tail = e;
        } else {
            tail.setNext(e);
            tail = e;
        }
    }

    public void reverse() {
        if (DEBUG)
            System.out.println("reversing...");

        ListElement curr = head, prev = null;
        for (;;) {
            ListElement next = curr.getNext();
            curr.setNext(prev);
            prev = curr;
            curr = next;
            if (curr == null)
                break;
        }
        prev = head;
        head = tail;
        tail = head;

        if (DEBUG)
            System.out.println("reversed");
    }

    public void sort() {
        if (DEBUG)
            System.out.println("sorting...");
        
        int total_swaps = 0;
        int swaps;
        do {
            swaps = 0;

            ListElement curr = head, prev = null;
            while (curr.getNext() != null) {
                ListElement next = curr.getNext();
                if (curr.n > next.n) {
                    if (prev != null) {
                        prev.setNext(next);
                    } else {
                        head = next;    
                    }
                    curr.setNext(next.getNext());
                    next.setNext(curr);
                    prev = next;
                    swaps++;
                } else {
                    prev = curr;
                    curr = next;
                }
            }
            tail = curr;
            
            total_swaps += swaps;
        } while(swaps > 0);

        if (DEBUG)
            System.out.println("sorted, swaps = " + total_swaps);
    }

    public void clear() {
        head = null;
        tail = null;
    }

    public void run(final int elements, final int sorts) {
        if (DEBUG)
            System.out.println("running, elements = " + elements + ", sorts = " + sorts);

        for (int i = 0, n = 42; i < elements; ++i) {
            insert(new ListElement(n));
            n = (n + 1) * 37;
            sort();
            reverse();
        }

        for (int i = 0; i < sorts; ++i) {
            sort();
            reverse();
        }
        
        if (DEBUG)
            System.out.println("complete");
    }
    
    public static final void test() {
        ListTask instance = new ListTask();
        instance.run(ELEMENTS, SORTS);
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
