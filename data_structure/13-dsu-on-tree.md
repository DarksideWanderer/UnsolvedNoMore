# DSU on tree

先处理所有轻儿子并清空贡献，再处理重儿子并保留贡献，最后把轻子树重新加入。每个结点作为轻子树成员被重新加入的次数至多 $O(\log n)$。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

template<class AddVertex, class RemoveVertex, class Report>
void dsu_on_tree(const vector<vector<int>>& tree, int root,
                 AddVertex add_vertex, RemoveVertex remove_vertex,
                 Report report) {
    int n = (int)tree.size();
    assert(0 <= root && root < n);
    vector<int> parent(n, -1), subtree_size(n, 1), heavy_child(n, -1);
    vector<int> order{root};
    for (int index = 0; index < (int)order.size(); ++index) {
        int node = order[index];
        for (int next : tree[node]) {
            if (next == parent[node]) continue;
            parent[next] = node;
            order.push_back(next);
        }
    }
    assert((int)order.size() == n);
    for (int index = n - 1; index >= 0; --index) {
        int node = order[index];
        for (int next : tree[node]) {
            if (parent[next] != node) continue;
            subtree_size[node] += subtree_size[next];
            if (heavy_child[node] == -1 ||
                subtree_size[next] > subtree_size[heavy_child[node]]) {
                heavy_child[node] = next;
            }
        }
    }

    vector<int> tin(n), tout(n), euler;
    euler.reserve(n);
    vector<pair<int, int>> stack{{root, 0}};
    while (!stack.empty()) {
        int node = stack.back().first;
        int& next_index = stack.back().second;
        if (next_index == 0) {
            tin[node] = (int)euler.size();
            euler.push_back(node);
        }
        if (next_index == (int)tree[node].size()) {
            tout[node] = (int)euler.size();
            stack.pop_back();
            continue;
        }
        int next = tree[node][next_index++];
        if (parent[next] == node) stack.push_back({next, 0});
    }

    auto add_subtree = [&](int node) {
        for (int index = tin[node]; index < tout[node]; ++index) {
            add_vertex(euler[index]);
        }
    };
    auto remove_subtree = [&](int node) {
        for (int index = tin[node]; index < tout[node]; ++index) {
            remove_vertex(euler[index]);
        }
    };

    auto solve = [&](auto&& self, int node, bool keep) -> void {
        for (int next : tree[node]) {
            if (parent[next] == node && next != heavy_child[node]) {
                self(self, next, false);
            }
        }
        if (heavy_child[node] != -1) self(self, heavy_child[node], true);
        for (int next : tree[node]) {
            if (parent[next] == node && next != heavy_child[node]) {
                add_subtree(next);
            }
        }
        add_vertex(node);
        report(node);
        if (!keep) remove_subtree(node);
    };
    solve(solve, root, false);
}
```

输入必须是连通无根树。若 `add_vertex/remove_vertex` 为 $O(1)$，总复杂度为 $O(n\log n)$，`report` 对每个结点调用一次。典型应用是求每棵子树的颜色频率、众数、出现次数达到阈值的颜色数。它适用于**静态、以子树为单位**的离线统计；带修改或任意路径查询通常应换用莫队、树链剖分或点分树。核心 `solve` 使用递归，链状树且 $n$ 很大时应改成显式事件栈或确保栈空间足够。
