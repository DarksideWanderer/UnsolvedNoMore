# Kruskal 重构树

按边权从小到大做 Kruskal。每次合并两个连通块时新建一个虚点，点权等于当前边权，并把两个连通块的根接到虚点下。树上叶子是原图顶点，父亲点权单调不降。

对不同顶点 $u,v$，重构树中 `lca(u,v)` 的点权等于使二者首次连通的最小边权，也等于原图中所有 $u\to v$ 路径的“最大边权最小值”。图不连通时得到森林。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

using i64 = long long;

class KruskalReconstructionTree {
public:
    struct Edge {
        int from;
        int to;
        i64 weight;
    };

private:
    int original_size;
    int node_count;
    int logarithm;
    vector<int> dsu_parent;
    vector<vector<int>> children;
    vector<i64> node_weight;
    vector<int> depth;
    vector<int> component;
    vector<vector<int>> ancestor;

    int find_set(int node) {
        int root = node;
        while (dsu_parent[root] != root) root = dsu_parent[root];
        while (dsu_parent[node] != node) {
            int next = dsu_parent[node];
            dsu_parent[node] = root;
            node = next;
        }
        return root;
    }

public:
    KruskalReconstructionTree(int vertex_count, vector<Edge> edges)
        : original_size(vertex_count), node_count(vertex_count), logarithm(1),
          dsu_parent(max(1, 2 * vertex_count)),
          children(max(1, 2 * vertex_count)),
          node_weight(max(1, 2 * vertex_count),
                      numeric_limits<i64>::lowest()) {
        assert(vertex_count >= 0);
        iota(dsu_parent.begin(), dsu_parent.end(), 0);
        sort(edges.begin(), edges.end(), [](const Edge& left, const Edge& right) {
            return left.weight < right.weight;
        });

        for (const Edge& edge : edges) {
            assert(0 <= edge.from && edge.from < original_size);
            assert(0 <= edge.to && edge.to < original_size);
            int left_root = find_set(edge.from);
            int right_root = find_set(edge.to);
            if (left_root == right_root) continue;

            int merged = node_count++;
            node_weight[merged] = edge.weight;
            children[merged] = {left_root, right_root};
            dsu_parent[left_root] = merged;
            dsu_parent[right_root] = merged;
            dsu_parent[merged] = merged;
        }

        children.resize(node_count);
        node_weight.resize(node_count);
        while ((1 << logarithm) <= max(1, node_count)) ++logarithm;
        depth.assign(node_count, 0);
        component.assign(node_count, -1);
        ancestor.assign(logarithm, vector<int>(node_count, -1));

        for (int node = 0; node < node_count; ++node) {
            if (find_set(node) != node) continue;
            component[node] = node;
            vector<int> stack{node};
            while (!stack.empty()) {
                int current = stack.back();
                stack.pop_back();
                for (int child : children[current]) {
                    depth[child] = depth[current] + 1;
                    component[child] = node;
                    ancestor[0][child] = current;
                    stack.push_back(child);
                }
            }
        }
        for (int level = 1; level < logarithm; ++level) {
            for (int node = 0; node < node_count; ++node) {
                int middle = ancestor[level - 1][node];
                if (middle != -1) {
                    ancestor[level][node] = ancestor[level - 1][middle];
                }
            }
        }
    }

    bool connected(int left, int right) const {
        assert(0 <= left && left < original_size);
        assert(0 <= right && right < original_size);
        return component[left] == component[right];
    }

    int lca_node(int left, int right) const {
        assert(connected(left, right));
        if (depth[left] < depth[right]) swap(left, right);
        int difference = depth[left] - depth[right];
        for (int level = 0; level < logarithm; ++level) {
            if (difference >> level & 1) left = ancestor[level][left];
        }
        if (left == right) return left;
        for (int level = logarithm - 1; level >= 0; --level) {
            if (ancestor[level][left] != ancestor[level][right]) {
                left = ancestor[level][left];
                right = ancestor[level][right];
            }
        }
        return ancestor[0][left];
    }

    i64 minimum_bottleneck(int left, int right) const {
        assert(left != right && connected(left, right));
        return node_weight[lca_node(left, right)];
    }

    int size() const { return node_count; }
    const vector<vector<int>>& forest() const { return children; }
    const vector<i64>& weights() const { return node_weight; }
};
```

排序复杂度 $O(m\log m)$，建树后的倍增预处理为 $O(n\log n)$，单次查询 $O(\log n)$。若改用 Euler 序 RMQ，LCA 可以做到 $O(1)$。

常见离线题还会在重构树上做子树统计：给定边权上限 $w$，从叶子向上倍增到点权不超过 $w$ 的最高祖先，该祖先的叶子集合正是此时的连通块。
