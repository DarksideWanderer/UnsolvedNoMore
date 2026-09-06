# 重链剖分

按子树大小选择重儿子，使任意根路径至多经过 $O(\log n)$ 条重链。`path_vertices` 把点路径拆成若干个 `[left,right)` 的 DFS 序区间，适合配合线段树做交换律成立的路径加、路径和或路径最值。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

struct HeavyLightDecomposition {
    int n, timer = 0;
    vector<int> parent, depth, size, heavy, head, position;

    HeavyLightDecomposition(const vector<vector<int>>& tree, int root = 0)
        : n((int)tree.size()), parent(n, -1), depth(n), size(n),
          heavy(n, -1), head(n), position(n) {
        assert(0 <= root && root < n);
        auto get_size = [&](auto&& self, int u, int p) -> void {
            parent[u] = p;
            size[u] = 1;
            for (int v : tree[u]) if (v != p) {
                depth[v] = depth[u] + 1;
                self(self, v, u);
                size[u] += size[v];
                if (heavy[u] == -1 || size[v] > size[heavy[u]]) heavy[u] = v;
            }
        };
        auto decompose = [&](auto&& self, int u, int top) -> void {
            head[u] = top;
            position[u] = timer++;
            if (heavy[u] != -1) self(self, heavy[u], top);
            for (int v : tree[u]) {
                if (v != parent[u] && v != heavy[u]) self(self, v, v);
            }
        };
        get_size(get_size, root, -1);
        decompose(decompose, root, root);
        assert(timer == n);
    }

    int lca(int u, int v) const {
        while (head[u] != head[v]) {
            if (depth[head[u]] < depth[head[v]]) swap(u, v);
            u = parent[head[u]];
        }
        return depth[u] < depth[v] ? u : v;
    }

    template<class Work>
    void path_vertices(int u, int v, Work work) const {
        while (head[u] != head[v]) {
            if (depth[head[u]] < depth[head[v]]) swap(u, v);
            work(position[head[u]], position[u] + 1);
            u = parent[head[u]];
        }
        if (depth[u] > depth[v]) swap(u, v);
        work(position[u], position[v] + 1);
    }

    template<class Work>
    void path_edges(int u, int v, Work work) const {
        while (head[u] != head[v]) {
            if (depth[head[u]] < depth[head[v]]) swap(u, v);
            work(position[head[u]], position[u] + 1);
            u = parent[head[u]];
        }
        if (depth[u] > depth[v]) swap(u, v);
        if (u != v) work(position[u] + 1, position[v] + 1);
    }

    pair<int, int> subtree(int u) const {
        return {position[u], position[u] + size[u]};
    }
};
```

两次 DFS 为 $O(n)$；一条路径拆成 $O(\log n)$ 段。若线段树单段操作为 $O(\log n)$，路径操作就是 $O(\log^2 n)$。代码使用递归 DFS，链状树且 $n$ 很大时需要留意栈空间。

上面的区间回调不保证按 $u\to v$ 的方向出现，所以只适合加法、最大值等满足交换律的操作。维护矩阵乘积或字符串这类有方向的信息时，需要分别保存 `u` 侧和 `v` 侧区间并反转其中一侧。边权通常存到较深端点；最后一段排除 LCA 的 `position[lca]` 即可。

直接接线段树时通常只写下面几行，其中线段树也统一使用 `[left,right)`：

```text
// 点权路径和
long long answer = 0;
hld.path_vertices(u, v, [&](int left, int right) {
    answer += segment_tree.query(left, right);
});

// 子树加
auto [left, right] = hld.subtree(u);
segment_tree.add(left, right, delta);

// 边权路径查询：每条边的权值存在较深端点
long long answer = 0;
hld.path_edges(u, v, [&](int left, int right) {
    answer += segment_tree.query(left, right);
});
```

`path_edges` 会在最后一条链上直接排除 LCA，因此求和、最大值等操作都能使用；当 `u==v` 时路径没有边，不会调用回调。
