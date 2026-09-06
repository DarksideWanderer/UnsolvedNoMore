# 笛卡尔树

给定数组 $a_0,a_1,\ldots,a_{n-1}$，最小笛卡尔树同时满足：

1. 中序遍历的顶点顺序恰好是原数组下标顺序；
2. 每个父亲的键值不大于儿子的键值。

当键值互不相同时，这棵树唯一。下面对相等键值不弹栈，因此区间最小值有多个位置时，较靠左者更接近根；这个稳定规则使树也唯一。

## 单调栈线性构造

```cpp
#include <bits/stdc++.h>
using namespace std;

struct CartesianTree {
    int root = -1;
    vector<int> parent;
    vector<int> left_child;
    vector<int> right_child;
};

template<class Value>
CartesianTree build_min_cartesian_tree(const vector<Value>& values) {
    int size = (int)values.size();
    CartesianTree tree;
    tree.parent.assign(size, -1);
    tree.left_child.assign(size, -1);
    tree.right_child.assign(size, -1);
    vector<int> stack;

    for (int index = 0; index < size; ++index) {
        int last_popped = -1;
        while (!stack.empty() && values[stack.back()] > values[index]) {
            last_popped = stack.back();
            stack.pop_back();
        }
        if (!stack.empty()) {
            tree.right_child[stack.back()] = index;
            tree.parent[index] = stack.back();
        }
        if (last_popped != -1) {
            tree.left_child[index] = last_popped;
            tree.parent[last_popped] = index;
        }
        stack.push_back(index);
    }
    if (!stack.empty()) tree.root = stack.front();
    return tree;
}
```

每个下标只入栈、出栈一次，时间和空间复杂度都是 $O(n)$。最大笛卡尔树只需把比较号改成 `<`。

## 为什么能做 RMQ

区间 $[l,r]$ 的最小值位置等于笛卡尔树上 `lca(l,r)`。原因是中序遍历保证 $[l,r]$ 对应两点之间的一段连续序列，而小根堆性质保证它们 LCA 的键值最小。

因此：

- 数组 RMQ 可以转成树上 LCA；
- 任意区间的最小值对分治结构，等价于以笛卡尔树根分割左右区间；
- 单调栈构造过程也常用于求每个元素作为区间最小值时能控制的最远左右边界。

递增数组会得到一条向右的链，递减数组会得到一条向左的链。后续 DFS 可能达到 $O(n)$ 深度，应使用迭代遍历或确保栈空间足够。
