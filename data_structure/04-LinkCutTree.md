# Link–Cut Tree

维护动态森林，支持连边、删边、单点修改和路径异或查询。点编号为 1-based；0 是空节点。所有公开函数均会维护辅助树状态。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class LinkCutTree {
    struct Node {
        int child[2]{0, 0};
        int parent = 0;
        int value = 0;
        int path_xor = 0;
        bool reversed = false;
    };

    vector<Node> nodes;

    bool is_splay_root(int node) const {
        int parent = nodes[node].parent;
        return parent == 0 ||
               (nodes[parent].child[0] != node &&
                nodes[parent].child[1] != node);
    }

    void pull(int node) {
        nodes[node].path_xor =
            nodes[nodes[node].child[0]].path_xor ^
            nodes[node].value ^
            nodes[nodes[node].child[1]].path_xor;
    }

    void apply_reverse(int node) {
        if (node == 0) return;
        swap(nodes[node].child[0], nodes[node].child[1]);
        nodes[node].reversed = !nodes[node].reversed;
    }

    void push(int node) {
        if (!nodes[node].reversed) return;
        apply_reverse(nodes[node].child[0]);
        apply_reverse(nodes[node].child[1]);
        nodes[node].reversed = false;
    }

    void rotate(int node) {
        int parent = nodes[node].parent;
        int grandparent = nodes[parent].parent;
        int direction = nodes[parent].child[1] == node;
        int middle = nodes[node].child[direction ^ 1];

        if (!is_splay_root(parent)) {
            nodes[grandparent].child[nodes[grandparent].child[1] == parent] =
                node;
        }
        nodes[node].parent = grandparent;
        nodes[node].child[direction ^ 1] = parent;
        nodes[parent].parent = node;
        nodes[parent].child[direction] = middle;
        if (middle != 0) nodes[middle].parent = parent;
        pull(parent);
        pull(node);
    }

    void splay(int node) {
        vector<int> ancestors{node};
        for (int current = node; !is_splay_root(current); ) {
            current = nodes[current].parent;
            ancestors.push_back(current);
        }
        while (!ancestors.empty()) {
            push(ancestors.back());
            ancestors.pop_back();
        }

        while (!is_splay_root(node)) {
            int parent = nodes[node].parent;
            int grandparent = nodes[parent].parent;
            if (!is_splay_root(parent)) {
                bool node_direction = nodes[parent].child[1] == node;
                bool parent_direction =
                    nodes[grandparent].child[1] == parent;
                rotate(node_direction == parent_direction ? parent : node);
            }
            rotate(node);
        }
    }

    void access(int node) {
        int preferred_child = 0;
        for (int current = node; current != 0;
             current = nodes[current].parent) {
            splay(current);
            nodes[current].child[1] = preferred_child;
            pull(current);
            preferred_child = current;
        }
        splay(node);
    }

public:
    explicit LinkCutTree(int node_count) : nodes(node_count + 1) {}

    void set_value(int node, int value) {
        access(node);
        nodes[node].value = value;
        pull(node);
    }

    void make_root(int node) {
        access(node);
        apply_reverse(node);
    }

    int find_root(int node) {
        access(node);
        while (true) {
            push(node);
            if (nodes[node].child[0] == 0) break;
            node = nodes[node].child[0];
        }
        splay(node);
        return node;
    }

    bool connected(int lhs, int rhs) {
        if (lhs == rhs) return true;
        make_root(lhs);
        return find_root(rhs) == lhs;
    }

    bool link(int lhs, int rhs) {
        make_root(lhs);
        if (find_root(rhs) == lhs) return false;
        nodes[lhs].parent = rhs;
        return true;
    }

    bool cut(int lhs, int rhs) {
        make_root(lhs);
        access(rhs);
        if (nodes[rhs].child[0] != lhs ||
            nodes[lhs].child[1] != 0) {
            return false;
        }
        nodes[rhs].child[0] = 0;
        nodes[lhs].parent = 0;
        pull(rhs);
        return true;
    }

    optional<int> query_path_xor(int lhs, int rhs) {
        if (!connected(lhs, rhs)) return nullopt;
        make_root(lhs);
        access(rhs);
        return nodes[rhs].path_xor;
    }
};
```

每个操作的均摊复杂度为 $O(\log n)$。这里只维护可交换的路径异或；改为路径和、最大值等信息时修改 `pull` 即可。若维护有方向的非交换信息，需要同时保存正序和逆序聚合值。
