# 最小费用最大流

实现使用势能加 Dijkstra。第一次用 SPFA 计算合法初始势能，因此允许负费用边；残量网络中不得存在从源点可达的负费用环。每次调用 `add_edge` 会自动加入容量为零、费用取反的反向边。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class MinCostMaxFlow {
    using i64 = long long;
    static constexpr i64 inf = numeric_limits<i64>::max() / 4;

    struct Edge {
        int to;
        int reverse_id;
        i64 capacity;
        i64 cost;
    };

    int node_count;
    vector<vector<Edge>> graph;

    vector<i64> initial_potential(int source) const {
        vector<i64> distance(node_count, inf);
        vector<bool> in_queue(node_count, false);
        queue<int> que;
        distance[source] = 0;
        in_queue[source] = true;
        que.push(source);
        while (!que.empty()) {
            int node = que.front();
            que.pop();
            in_queue[node] = false;
            for (const Edge& edge : graph[node]) {
                if (edge.capacity == 0 || distance[node] == inf) continue;
                if (distance[edge.to] > distance[node] + edge.cost) {
                    distance[edge.to] = distance[node] + edge.cost;
                    if (!in_queue[edge.to]) {
                        in_queue[edge.to] = true;
                        que.push(edge.to);
                    }
                }
            }
        }
        for (i64& value : distance) {
            if (value == inf) value = 0;
        }
        return distance;
    }

public:
    explicit MinCostMaxFlow(int initial_node_count)
        : node_count(initial_node_count), graph(initial_node_count) {}

    void add_edge(int from, int to, i64 capacity, i64 cost) {
        assert(0 <= from && from < node_count);
        assert(0 <= to && to < node_count);
        assert(capacity >= 0);
        int from_id = (int)graph[from].size();
        int to_id = (int)graph[to].size();
        graph[from].push_back({to, to_id, capacity, cost});
        graph[to].push_back({from, from_id, 0, -cost});
    }

    pair<i64, i64> min_cost_max_flow(
        int source, int sink,
        i64 flow_limit = numeric_limits<i64>::max()) {
        vector<i64> potential = initial_potential(source);
        vector<i64> distance(node_count);
        vector<int> previous_node(node_count);
        vector<int> previous_edge(node_count);
        i64 total_flow = 0;
        i64 total_cost = 0;

        while (total_flow < flow_limit) {
            fill(distance.begin(), distance.end(), inf);
            priority_queue<pair<i64, int>,
                           vector<pair<i64, int>>,
                           greater<pair<i64, int>>> que;
            distance[source] = 0;
            que.push({0, source});
            while (!que.empty()) {
                auto [current_distance, node] = que.top();
                que.pop();
                if (current_distance != distance[node]) continue;
                for (int edge_id = 0;
                     edge_id < (int)graph[node].size(); ++edge_id) {
                    const Edge& edge = graph[node][edge_id];
                    if (edge.capacity == 0) continue;
                    i64 reduced_cost =
                        edge.cost + potential[node] - potential[edge.to];
                    i64 next_distance = current_distance + reduced_cost;
                    if (next_distance < distance[edge.to]) {
                        distance[edge.to] = next_distance;
                        previous_node[edge.to] = node;
                        previous_edge[edge.to] = edge_id;
                        que.push({next_distance, edge.to});
                    }
                }
            }
            if (distance[sink] == inf) break;

            for (int node = 0; node < node_count; ++node) {
                if (distance[node] != inf) potential[node] += distance[node];
            }

            i64 pushed = flow_limit - total_flow;
            for (int node = sink; node != source; node = previous_node[node]) {
                const Edge& edge = graph[previous_node[node]][previous_edge[node]];
                pushed = min(pushed, edge.capacity);
            }
            for (int node = sink; node != source; node = previous_node[node]) {
                Edge& edge = graph[previous_node[node]][previous_edge[node]];
                edge.capacity -= pushed;
                graph[node][edge.reverse_id].capacity += pushed;
            }
            total_flow += pushed;
            total_cost += pushed * potential[sink];
        }
        return {total_flow, total_cost};
    }
};
```

设最终增广次数为 $F$，复杂度约为 $O(VE+F E\log V)$；第一项来自初始 SPFA 的常见估计，SPFA 的理论最坏复杂度为 $O(VE)$。容量乘费用以及总费用必须能装入 `long long`。若只需要恰好发送 $k$ 单位流，传入 `flow_limit=k` 并检查返回流量是否等于 $k$。
