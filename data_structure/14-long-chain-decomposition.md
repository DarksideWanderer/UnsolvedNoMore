# 长链剖分与 O(1) 级祖先

重链剖分选择“子树最大”的儿子，长链剖分则选择“向下最深”的儿子。它主要用于与深度有关的问题：

- 预处理后 $O(1)$ 查询结点的第 $k$ 个祖先；
- 合并形如 `dp[u][distance]` 的树 DP。重儿子的数组可直接把指针平移一格复用，轻儿子的数组总合并量可做到 $O(n)$；典型问题是统计每个点子树内各种深度的结点数、求最常见深度。

下面给出较容易直接复用的 $O(1)$ 级祖先版本。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class LongChainAncestors {
    int size;
    int logarithm;
    vector<int> parent;
    vector<int> depth;
    vector<int> height;
    vector<int> heavy_child;
    vector<int> chain_top;
    vector<vector<int>> binary_ancestor;
    vector<vector<int>> downward;
    vector<vector<int>> upward;

public:
    LongChainAncestors(const vector<vector<int>>& tree, int root)
        : size((int)tree.size()), logarithm(1), parent(size, -1), depth(size),
          height(size, 1), heavy_child(size, -1), chain_top(size),
          downward(size), upward(size) {
        assert(0 <= root && root < size);
        vector<int> order{root};
        for (int index = 0; index < (int)order.size(); ++index) {
            int node = order[index];
            for (int next : tree[node]) {
                if (next == parent[node]) continue;
                parent[next] = node;
                depth[next] = depth[node] + 1;
                order.push_back(next);
            }
        }
        assert((int)order.size() == size);
        for (int index = size - 1; index >= 0; --index) {
            int node = order[index];
            for (int next : tree[node]) {
                if (parent[next] != node) continue;
                if (heavy_child[node] == -1 ||
                    height[next] > height[heavy_child[node]]) {
                    heavy_child[node] = next;
                }
            }
            if (heavy_child[node] != -1) {
                height[node] = height[heavy_child[node]] + 1;
            }
        }

        chain_top[root] = root;
        for (int node : order) {
            for (int next : tree[node]) {
                if (parent[next] != node) continue;
                chain_top[next] =
                    next == heavy_child[node] ? chain_top[node] : next;
            }
        }

        while ((1 << logarithm) <= max(1, size)) ++logarithm;
        binary_ancestor.assign(logarithm, vector<int>(size, -1));
        binary_ancestor[0] = parent;
        for (int level = 1; level < logarithm; ++level) {
            for (int node = 0; node < size; ++node) {
                int middle = binary_ancestor[level - 1][node];
                if (middle != -1) {
                    binary_ancestor[level][node] =
                        binary_ancestor[level - 1][middle];
                }
            }
        }

        for (int head : order) {
            if (chain_top[head] != head) continue;
            int node = head;
            while (node != -1) {
                downward[head].push_back(node);
                node = heavy_child[node];
            }
            upward[head].resize(downward[head].size(), -1);
            node = head;
            for (int distance = 0; distance < (int)upward[head].size();
                 ++distance) {
                upward[head][distance] = node;
                if (node != -1) node = parent[node];
            }
        }
    }

    int kth_ancestor(int node, int distance) const {
        assert(0 <= node && node < size && distance >= 0);
        if (distance > depth[node]) return -1;
        if (distance == 0) return node;

        int level = 31 - __builtin_clz((unsigned)distance);
        int jumped = binary_ancestor[level][node];
        int remaining = distance - (1 << level);
        int head = chain_top[jumped];
        int inside_chain = depth[jumped] - depth[head];
        if (remaining <= inside_chain) {
            return downward[head][inside_chain - remaining];
        }
        int above_head = remaining - inside_chain;
        assert(above_head < (int)upward[head].size());
        return upward[head][above_head];
    }
};
```

上述实现预处理 $O(n\log n)$、空间 $O(n\log n)$，查询只做一次二进制跳跃和一次链内数组访问，为 $O(1)$。`upward` 为每条长链只保存与链长相同的一段祖先；所有链长之和为 $n$。

如果只需要普通 LCA 或路径加和，长链剖分没有优势，使用倍增或按子树大小的树链剖分更自然。它真正的价值是“深度/距离维 DP 的数组复用”和大量级祖先查询。
