import java.util.Date;

public class SmallTreeTask {
    private static final boolean DEBUG = false;
    private static final boolean VERBOSE = false;

    private static final int INITIAL_NODES = 10000;
    private static final int PERMUTE_NODES = INITIAL_NODES / 200;

    private static final SmallTreeTask taskInstance;

    static {
        taskInstance = new SmallTreeTask();
        taskInstance.build();
    }

    private static class TreeNode {
        public TreeNode left = null;
        public TreeNode right = null;
        public TreeNode parent = null;
        public SmallTreeTask tree = null;

        private int cachedHeight = -1;
        public final int value;

        public TreeNode(int value) {
            this.value = value;
        }

        public void clearCache() {
            cachedHeight = -1;
        }

        public int height() {
            if (cachedHeight >= 0)
                return cachedHeight;

            int leftHeight = 0;
            int rightHeight = 0;
            if (left != null) {
                leftHeight = 1 + left.height();
            }
            if (right != null) {
                rightHeight = 1 + right.height();
            }

            cachedHeight = leftHeight > rightHeight ? leftHeight : rightHeight;

            return cachedHeight;
        }

        public int balanceFactor() {
            int leftHeight = left != null ? left.height() : 0;
            int rightHeight = right != null ? right.height() : 0;
            return leftHeight - rightHeight;
        }

        private TreeNode rotateLeft() {
            if (DEBUG && VERBOSE)
                System.err.println(value + ", rotate left");
            TreeNode newRoot    = right;
            this.right          = newRoot.left;
            if (this.right != null)
                this.right.parent = this;
            newRoot.left        = this;
            newRoot.parent      = this.parent;
            this.parent         = newRoot;
            return newRoot;
        }

        private TreeNode rotateRight() {
            if (DEBUG && VERBOSE)
                System.err.println(value + ", rotate right");
            TreeNode newRoot    = left;
            this.left           = newRoot.right;
            if (this.left != null)
                this.left.parent = this;
            newRoot.right       = this;
            newRoot.parent      = this.parent;
            this.parent         = newRoot;
            return newRoot;
        }

        public TreeNode insert(TreeNode newNode) {
            if (newNode.value < this.value) {
                if (left != null) {
                    left = left.insert(newNode);
                } else {
                    left = newNode;
                }
                left.parent = this;
                clearCache();
            } else if (newNode.value > this.value) {
                if (right != null) {
                    right = right.insert(newNode);
                } else {
                    right = newNode;
                }
                right.parent = this;
                clearCache();
            } else {
                // FIXME: ignore?
            }

            int balance = balanceFactor();
            if (DEBUG && VERBOSE)
                System.err.println("balance = " + balance);
            if (balance < -1) {
                return rotateLeft();
            } else if (balance > 1) {
                return rotateRight();
            } else {
                return this;
            }
        }

        private TreeNode minimumNode() {
            if (left != null)
                return left.minimumNode();
            else
                return this;
        }

        private TreeNode maximumNode() {
            if (right != null)
                return right.maximumNode();
            else
                return this;
        }

        public int minimum() {
            return minimumNode().value;
        }

        public int maximum() {
            return maximumNode().value;
        }

        public void rebalance() {
            rebalance(0);
        }
    
        private void rebalance(int depth) {
            this.clearCache();

            int balance = balanceFactor();

            if (DEBUG && VERBOSE)
                System.err.println(this.value + ", rebalance = " + balance);
            
            TreeNode newRoot = this;
            
            if (balance < (-1)) {
                newRoot = rotateLeft();
            } else if (balance > 1) {
                newRoot = rotateRight();
            }
            
            if (newRoot != this) {
                if (newRoot.parent != null) {
                    if (newRoot.parent.left == this)
                        newRoot.parent.left = newRoot;
                    else if (newRoot.parent.right == this)
                        newRoot.parent.right = newRoot;
                    else
                        assert(false);
                } else {
                    this.tree.root = newRoot;
                }
                newRoot.clearCache();
                this.clearCache();
            }

            if (DEBUG)
                newRoot.validate();

            // FIXME: we don't need to rebalance the whole tree
            if (newRoot.parent != null) {
                assert (depth < 24);
                newRoot.parent.rebalance(depth + 1);
            }
        }

        public void remove() {
            if (left == null && right == null) {
                if (parent != null) {
                    if (parent.left == this)
                        parent.left = null;
                    else if (parent.right == this)
                        parent.right = null;
                    else
                        assert(false);
                    parent.rebalance();
                } else {
                    tree.root = null;
                }
            } else {
                TreeNode replacement = null;
                TreeNode subtree = null;
                TreeNode balancePoint = null;
                
                if (left != null) {
                    replacement = left.maximumNode();
                    subtree = replacement.left;
                    if (replacement != left) {
                        replacement.parent.right = subtree;
                        if (subtree != null)
                            subtree.parent = replacement.parent;
                        balancePoint = replacement.parent;
                    } else {
                        left = subtree;
                        if (subtree != null)
                            subtree.parent = replacement;
                        balancePoint = replacement;
                    }
                } else if (right != null) {
                    replacement = right.minimumNode();
                    subtree = replacement.right;
                    if (replacement != right) {
                        replacement.parent.left = subtree;
                        if (subtree != null)
                            subtree.parent = replacement.parent;
                        balancePoint = replacement.parent;
                    } else {
                        right = subtree;
                        if (subtree != null)
                            subtree.parent = replacement;
                        balancePoint = replacement;
                    }
                } else {
                    assert(false);
                }

                if (DEBUG && VERBOSE) {
                    summary();
                    replacement.summary();
                    if (subtree != null)
                        subtree.summary();
                }

                if (this.parent != null) {
                    if (this.parent.left == this) {
                        this.parent.left = replacement;
                    } else if (this.parent.right == this) {
                        this.parent.right = replacement;
                    } else {
                        assert(false);
                    }
                } else {
                    this.tree.root = replacement;
                }

                replacement.parent = this.parent;
                replacement.left = this.left;
                if (this.left != null)
                    this.left.parent = replacement;
                replacement.right = this.right;
                if (this.right != null)
                    this.right.parent = replacement;

                if (DEBUG) {
                    replacement.validate();
                    balancePoint.validate();
                }

                balancePoint.rebalance();
            }

            left = null;
            right = null;
            parent = null;
            tree = null;
        }

        public TreeNode find(int value) {
            if (value == this.value)
                return this;
            else if (value < this.value && left != null)
                return left.find(value);
            else if (value > this.value && right != null)
                return right.find(value);
            else
                return null;
        }
        
        public TreeNode findClosest(int value) {
            if (value == this.value)
                return this;
            else if (value < this.value && left != null)
                return left.findClosest(value);
            else if (value > this.value && right != null)
                return right.findClosest(value);
            else
                return this;
        }

        public void summary() {
            System.err.println(value + ", parent: " + (parent != null ? parent.value : "") + ", left: " + (left != null ? left.value : "") + ", right: " + (right != null ? right.value : ""));
        }

        public void debugSummary() {
            summary();
            if (left != null)
                left.debugSummary();
            if (right != null)
                right.debugSummary();
        }

        public void validate() {
            assert(this.parent != this);
            assert(left != this);
            assert(right != this);
            if (left != null) {
                assert(left.tree == this.tree);
                assert(left.value < this.value);
                assert(left.parent == this);
                left.validate();
            }
            if (right != null) {
                assert(right.tree == this.tree);
                assert(right.value > this.value);
                assert(right.parent == this);
                right.validate();
            }
        }

        public void print() {
            print("");
        }

        public void print(String indent) {
            if (left != null)
                left.print(indent + " ");
            System.out.println(indent + value);
            if (right != null)
                right.print(indent + " ");
        }
    }

    private TreeNode root = null;
    private int nextValue = 1;
    private int nodeCount = 0;

    public SmallTreeTask() {
    }

    private TreeNode newNode() {
        TreeNode node = new TreeNode(nextValue++);
        return node;
    }
    
    private TreeNode newNode(int value) {
        TreeNode node = new TreeNode(value);
        return node;
    }

    public TreeNode findNode(int value) {
        if (root != null)
            return root.find(value);
        else
            return null;
    }

    public TreeNode findClosest(int value) {
        if (root != null)
            return root.findClosest(value);
        else
            return null;
    }

    public void validate() {
        if (root != null)
            root.validate();
    }

    public void insertNode(TreeNode node) {
        if (DEBUG && VERBOSE)
            System.err.println("insert: " + node.value);

        node.left = null;
        node.right = null;
        node.tree = this;
        node.parent = null;
        node.clearCache();
        
        if (root == null) {
            root = node;
        } else {
            root = root.insert(node);
            root.parent = null;
        }

        nodeCount += 1;

        if (DEBUG)
            validate();
    }

    public void removeNode(TreeNode node) {
        if (DEBUG && VERBOSE)
            System.err.println("remove: " + node.value);
        
        assert(node.tree == this);
        node.remove();
        nodeCount -= 1;
        
        if (DEBUG)
            validate();
    }

    public void build() {
        if (DEBUG)
            System.err.println("building...");
        for (int i = 0; i < INITIAL_NODES; ++i) {
            insertNode(newNode());
        }
        if (DEBUG) {
            validate();
            System.err.println("built.");
        }
    }

    public void permute(int nNodes) {
        assert (nodeCount >= nNodes);
        
        if (DEBUG)
            System.err.println("permuting...");

        int min = root.minimum();
        int max = root.maximum();
        int step = (max - min) / nNodes;
        assert(step > 0);

        if (DEBUG) {
            System.err.println(
                "min = " + min + 
                ", max = " + max + 
                ", step = " + step + 
                ", nodes = " + nodeCount);
        }

        for (int i = min; i <= max; i += step) {
            TreeNode node = findClosest(i);
            if (node != null) {
                removeNode(node);
                insertNode(newNode(node.value));
            }
        }

        if (DEBUG) {
            validate();
            System.err.println("permuted.");
            if (VERBOSE)
                root.debugSummary();
        }
    }

    public void print() {
        if (root != null)
            root.print();
    }
    
    public static final void test() {
        SmallTreeTask tree = taskInstance;
        tree.permute(PERMUTE_NODES);
        //tree.print();
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
