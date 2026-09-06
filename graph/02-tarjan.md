# Tarjan 连通性算法

无向图必须用**边编号**跳过 DFS 树中的父边，不能用“跳过父亲节点”代替，否则重边会被误判。下列模板均使用 0-based 点编号，并允许图不连通。

## 有向图强连通分量

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class StronglyConnectedComponents {
    int node_count;
    int timer = 0;
    vector<vector<int>> graph;
    vector<int> dfn;
    vector<int> low;
    vector<int> stack;
    vector<bool> in_stack;

    void dfs(int node) {
        dfn[node] = low[node] = ++timer;
        stack.push_back(node);
        in_stack[node] = true;
        for (int next : graph[node]) {
            if (dfn[next] == 0) {
                dfs(next);
                low[node] = min(low[node], low[next]);
            } else if (in_stack[next]) {
                low[node] = min(low[node], dfn[next]);
            }
        }
        if (low[node] != dfn[node]) return;

        components.push_back({});
        while (true) {
            int current = stack.back();
            stack.pop_back();
            in_stack[current] = false;
            component_of[current] = (int)components.size() - 1;
            components.back().push_back(current);
            if (current == node) break;
        }
    }

public:
    vector<int> component_of;
    vector<vector<int>> components;

    explicit StronglyConnectedComponents(int initial_node_count)
        : node_count(initial_node_count), graph(initial_node_count),
          dfn(initial_node_count), low(initial_node_count),
          in_stack(initial_node_count), component_of(initial_node_count, -1) {}

    void add_edge(int from, int to) {
        graph[from].push_back(to);
    }

    int build() {
        for (int node = 0; node < node_count; ++node) {
            if (dfn[node] == 0) dfs(node);
        }
        return (int)components.size();
    }
};
```

同一个强连通分量中的点可以互相到达。缩点时遍历所有原边，仅在两端分量编号不同的情况下加边；需要简单 DAG 时再排序去重。复杂度为 $O(V+E)$。

## 桥、边双连通分量与桥树

```cpp
class EdgeBiconnectedComponents {
    struct AdjacentEdge {
        int to;
        int edge_id;
    };

    int node_count;
    int timer = 0;
    vector<vector<AdjacentEdge>> graph;
    vector<pair<int, int>> edges;
    vector<int> dfn;
    vector<int> low;

    void find_bridges(int node, int parent_edge) {
        dfn[node] = low[node] = ++timer;
        for (const AdjacentEdge& edge : graph[node]) {
            if (edge.edge_id == parent_edge) continue;
            if (dfn[edge.to] == 0) {
                find_bridges(edge.to, edge.edge_id);
                low[node] = min(low[node], low[edge.to]);
                if (low[edge.to] > dfn[node]) is_bridge[edge.edge_id] = true;
            } else {
                low[node] = min(low[node], dfn[edge.to]);
            }
        }
    }

    void paint_component(int start, int component_id) {
        stack<int> pending;
        pending.push(start);
        component_of[start] = component_id;
        while (!pending.empty()) {
            int node = pending.top();
            pending.pop();
            for (const AdjacentEdge& edge : graph[node]) {
                if (is_bridge[edge.edge_id] || component_of[edge.to] != -1) {
                    continue;
                }
                component_of[edge.to] = component_id;
                pending.push(edge.to);
            }
        }
    }

public:
    vector<bool> is_bridge;
    vector<int> component_of;

    explicit EdgeBiconnectedComponents(int initial_node_count)
        : node_count(initial_node_count), graph(initial_node_count),
          dfn(initial_node_count), low(initial_node_count),
          component_of(initial_node_count, -1) {}

    int add_edge(int lhs, int rhs) {
        int edge_id = (int)edges.size();
        edges.push_back({lhs, rhs});
        graph[lhs].push_back({rhs, edge_id});
        graph[rhs].push_back({lhs, edge_id});
        return edge_id;
    }

    int build() {
        is_bridge.assign(edges.size(), false);
        for (int node = 0; node < node_count; ++node) {
            if (dfn[node] == 0) find_bridges(node, -1);
        }
        int component_count = 0;
        for (int node = 0; node < node_count; ++node) {
            if (component_of[node] == -1) {
                paint_component(node, component_count++);
            }
        }
        return component_count;
    }

    vector<vector<int>> bridge_forest(int component_count) const {
        vector<vector<int>> forest(component_count);
        for (int edge_id = 0; edge_id < (int)edges.size(); ++edge_id) {
            if (!is_bridge[edge_id]) continue;
            auto [lhs, rhs] = edges[edge_id];
            int lhs_component = component_of[lhs];
            int rhs_component = component_of[rhs];
            forest[lhs_component].push_back(rhs_component);
            forest[rhs_component].push_back(lhs_component);
        }
        return forest;
    }
};
```

删除所有桥后，每个连通块就是一个边双连通分量；把每个分量缩成点、每座桥保留成边，得到的是森林。复杂度为 $O(V+E)$。

## 点双连通分量与圆方树

一个孤立点也被视为一个点双连通分量。圆方树中前 `components.size()` 个节点代表点双分量，之后的节点代表割点。

```cpp
class VertexBiconnectedComponents {
    struct AdjacentEdge {
        int to;
        int edge_id;
    };

    int node_count;
    int timer = 0;
    int edge_count = 0;
    vector<vector<AdjacentEdge>> graph;
    vector<int> dfn;
    vector<int> low;
    vector<int> vertex_stack;

    void dfs(int node, int parent_edge) {
        dfn[node] = low[node] = ++timer;
        int child_count = 0;
        for (const AdjacentEdge& edge : graph[node]) {
            if (edge.edge_id == parent_edge) continue;
            if (dfn[edge.to] == 0) {
                ++child_count;
                vertex_stack.push_back(edge.to);
                dfs(edge.to, edge.edge_id);
                low[node] = min(low[node], low[edge.to]);
                if (low[edge.to] >= dfn[node]) {
                    if (parent_edge != -1 || child_count > 1) {
                        is_cut_vertex[node] = true;
                    }
                    components.push_back({node});
                    while (components.back().back() != edge.to) {
                        components.back().push_back(vertex_stack.back());
                        vertex_stack.pop_back();
                    }
                }
            } else {
                low[node] = min(low[node], dfn[edge.to]);
            }
        }
        if (parent_edge == -1 && child_count == 0) {
            components.push_back({node});
        }
    }

public:
    vector<bool> is_cut_vertex;
    vector<vector<int>> components;

    explicit VertexBiconnectedComponents(int initial_node_count)
        : node_count(initial_node_count), graph(initial_node_count),
          dfn(initial_node_count), low(initial_node_count),
          is_cut_vertex(initial_node_count) {}

    void add_edge(int lhs, int rhs) {
        int edge_id = edge_count++;
        graph[lhs].push_back({rhs, edge_id});
        graph[rhs].push_back({lhs, edge_id});
    }

    int build() {
        for (int node = 0; node < node_count; ++node) {
            if (dfn[node] != 0) continue;
            vertex_stack.push_back(node);
            dfs(node, -1);
            vertex_stack.clear();
        }
        return (int)components.size();
    }

    vector<vector<int>> block_cut_forest() const {
        int component_count = (int)components.size();
        vector<int> cut_id(node_count, -1);
        int tree_size = component_count;
        for (int node = 0; node < node_count; ++node) {
            if (is_cut_vertex[node]) cut_id[node] = tree_size++;
        }

        vector<vector<int>> forest(tree_size);
        for (int component_id = 0;
             component_id < component_count; ++component_id) {
            for (int node : components[component_id]) {
                if (!is_cut_vertex[node]) continue;
                forest[component_id].push_back(cut_id[node]);
                forest[cut_id[node]].push_back(component_id);
            }
        }
        return forest;
    }
};
```

复杂度为 $O(V+E)$。代码使用递归 DFS；若图可能是一条百万级长链，应改成显式栈或确认评测环境栈空间足够。
