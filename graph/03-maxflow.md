# Dinic 最大流

下列实现是完整、可独立使用的 Dinic。调用 `add_edge(from, to, capacity)` 时会自动加入容量为零的反向边，不要手动补反边。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class Dinic {
    using i64 = long long;

public:
    struct EdgeHandle {
        int from;
        int index;
    };

private:

    struct Edge {
        int to;
        int reverse_id;
        i64 capacity;
    };

    int node_count;
    vector<vector<Edge>> graph;
    vector<int> level;
    vector<int> current_edge;

    bool build_level_graph(int source, int sink) {
        fill(level.begin(), level.end(), -1);
        queue<int> que;
        level[source] = 0;
        que.push(source);
        while (!que.empty()) {
            int node = que.front();
            que.pop();
            for (const Edge& edge : graph[node]) {
                if (edge.capacity > 0 && level[edge.to] == -1) {
                    level[edge.to] = level[node] + 1;
                    que.push(edge.to);
                }
            }
        }
        return level[sink] != -1;
    }

    i64 send_flow(int node, int sink, i64 available) {
        if (node == sink) return available;
        for (int& edge_id = current_edge[node];
             edge_id < (int)graph[node].size(); ++edge_id) {
            Edge& edge = graph[node][edge_id];
            if (edge.capacity == 0 || level[edge.to] != level[node] + 1) {
                continue;
            }
            i64 pushed = send_flow(edge.to, sink, min(available, edge.capacity));
            if (pushed == 0) continue;
            edge.capacity -= pushed;
            graph[edge.to][edge.reverse_id].capacity += pushed;
            return pushed;
        }
        return 0;
    }

public:
    explicit Dinic(int initial_node_count)
        : node_count(initial_node_count), graph(initial_node_count),
          level(initial_node_count), current_edge(initial_node_count) {}

    EdgeHandle add_edge(int from, int to, i64 capacity) {
        assert(0 <= from && from < node_count);
        assert(0 <= to && to < node_count);
        assert(capacity >= 0);
        int from_id = (int)graph[from].size();
        int to_id = (int)graph[to].size() + (from == to);
        graph[from].push_back({to, to_id, capacity});
        graph[to].push_back({from, from_id, 0});
        return {from, from_id};
    }

    i64 flow_on(EdgeHandle handle) const {
        const Edge& edge = graph[handle.from][handle.index];
        return graph[edge.to][edge.reverse_id].capacity;
    }

    void disable_edge(EdgeHandle handle) {
        int to = graph[handle.from][handle.index].to;
        int reverse_id = graph[handle.from][handle.index].reverse_id;
        graph[handle.from][handle.index].capacity = 0;
        graph[to][reverse_id].capacity = 0;
    }

    i64 max_flow(int source, int sink,
                 i64 flow_limit = numeric_limits<i64>::max()) {
        assert(source != sink);
        i64 total_flow = 0;
        while (total_flow < flow_limit && build_level_graph(source, sink)) {
            fill(current_edge.begin(), current_edge.end(), 0);
            while (total_flow < flow_limit) {
                i64 pushed = send_flow(source, sink, flow_limit - total_flow);
                if (pushed == 0) break;
                total_flow += pushed;
            }
        }
        return total_flow;
    }

    vector<bool> min_cut_side(int source) const {
        vector<bool> reachable(node_count);
        queue<int> que;
        reachable[source] = true;
        que.push(source);
        while (!que.empty()) {
            int node = que.front();
            que.pop();
            for (const Edge& edge : graph[node]) {
                if (edge.capacity > 0 && !reachable[edge.to]) {
                    reachable[edge.to] = true;
                    que.push(edge.to);
                }
            }
        }
        return reachable;
    }
};
```

`add_edge` 返回的句柄始终指向这条正向边；`flow_on(handle)` 读取当前流量，`disable_edge(handle)` 同时清空正反残量容量，主要供上下界流删除辅助边。普通最大流不需要保存句柄。

`min_cut_side(source)` 应在 `max_flow` 结束后调用，返回残量网络中源点仍能到达的点，也就是最小割的源侧。一般网络上常用复杂度上界为 $O(V^2E)$；单位容量网络和二分图网络会更快。递归深度可能达到 $V$，若题目给出极深链且栈空间很小，需要改成迭代 DFS 或增大栈空间。
