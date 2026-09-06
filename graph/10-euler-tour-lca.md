# Euler 序 RMQ 求 LCA

DFS 每次进入结点以及从儿子返回时都把当前结点加入 Euler 序。两点第一次出现位置之间，深度最小的结点就是 LCA；不要把只记录首次进入的普通 DFS 序误当成这条长度 $2n-1$ 的 Euler 序。下面用迭代 DFS 避免深树递归爆栈，并用 Sparse Table 做 RMQ。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class EulerTourLca {
    vector<int> first;
    vector<int> depth;
    vector<int> component;
    vector<int> euler;
    vector<int> logarithm;
    vector<vector<int>> sparse_table;

public:
    explicit EulerTourLca(const vector<vector<int>>& graph,
                          const vector<int>& preferred_roots = {}) {
        int n = (int)graph.size();
        first.assign(n, -1);
        depth.assign(n, 0);
        component.assign(n, -1);

        vector<int> roots = preferred_roots;
        for (int node = 0; node < n; ++node) roots.push_back(node);
        vector<int> parent(n, -1);

        struct Frame {
            int node;
            int next_edge;
        };

        for (int root : roots) {
            assert(0 <= root && root < n);
            if (component[root] != -1) continue;
            component[root] = root;
            first[root] = (int)euler.size();
            euler.push_back(root);
            vector<Frame> stack{{root, 0}};

            while (!stack.empty()) {
                Frame& frame = stack.back();
                int node = frame.node;
                if (frame.next_edge == (int)graph[node].size()) {
                    stack.pop_back();
                    if (!stack.empty()) euler.push_back(stack.back().node);
                    continue;
                }
                int next = graph[node][frame.next_edge++];
                if (next == parent[node] || component[next] != -1) continue;
                parent[next] = node;
                depth[next] = depth[node] + 1;
                component[next] = root;
                first[next] = (int)euler.size();
                euler.push_back(next);
                stack.push_back({next, 0});
            }
        }

        logarithm.assign(euler.size() + 1, 0);
        for (int length = 2; length <= (int)euler.size(); ++length) {
            logarithm[length] = logarithm[length / 2] + 1;
        }
        int levels = euler.empty() ? 0 : logarithm[euler.size()] + 1;
        sparse_table.assign(levels, vector<int>(euler.size()));
        if (!euler.empty()) sparse_table[0] = euler;
        for (int level = 1; level < levels; ++level) {
            int length = 1 << level;
            for (int begin = 0; begin + length <= (int)euler.size(); ++begin) {
                int left = sparse_table[level - 1][begin];
                int right = sparse_table[level - 1][begin + length / 2];
                sparse_table[level][begin] =
                    depth[left] <= depth[right] ? left : right;
            }
        }
    }

    int lca(int left, int right) const {
        assert(0 <= left && left < (int)first.size());
        assert(0 <= right && right < (int)first.size());
        assert(component[left] == component[right]);
        int begin = first[left];
        int end = first[right];
        if (begin > end) swap(begin, end);
        int level = logarithm[end - begin + 1];
        int lhs = sparse_table[level][begin];
        int rhs = sparse_table[level][end - (1 << level) + 1];
        return depth[lhs] <= depth[rhs] ? lhs : rhs;
    }

    int distance(int left, int right) const {
        int ancestor = lca(left, right);
        return depth[left] + depth[right] - 2 * depth[ancestor];
    }
};
```

预处理时间和空间均为 $O(n\log n)$，查询 $O(1)$。输入可以是森林，但只能查询同一连通分量内的两点。
