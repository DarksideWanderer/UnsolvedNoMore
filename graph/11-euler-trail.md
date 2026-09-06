# Hierholzer 欧拉路

Hierholzer 的关键是为每个点维护一个只增指针。每条邻接弧只会被指针越过一次，因此有向图为 $O(V+E)$，无向图虽然每条边存两条弧，仍是 $O(V+E)$，不能在每一步从 `vector` 中线性删除边。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class EulerTrail {
public:
    struct Result {
        vector<int> vertices;
        vector<int> edge_ids;
    };

private:
    struct Arc {
        int to;
        int edge_id;
    };

    int vertex_count;
    bool directed;
    int edge_count = 0;
    vector<vector<Arc>> graph;
    vector<int> indegree;
    vector<int> outdegree;

public:
    EulerTrail(int initial_vertex_count, bool is_directed)
        : vertex_count(initial_vertex_count), directed(is_directed),
          graph(initial_vertex_count), indegree(initial_vertex_count),
          outdegree(initial_vertex_count) {
        assert(initial_vertex_count >= 0);
    }

    int add_edge(int from, int to) {
        assert(0 <= from && from < vertex_count);
        assert(0 <= to && to < vertex_count);
        int id = edge_count++;
        graph[from].push_back({to, id});
        ++outdegree[from];
        ++indegree[to];
        if (!directed) {
            graph[to].push_back({from, id});
            ++outdegree[to];
            ++indegree[from];
        }
        return id;
    }

    optional<Result> find_trail() const {
        if (vertex_count == 0) {
            if (edge_count == 0) return Result{};
            return nullopt;
        }

        int start = -1;
        if (directed) {
            int start_candidates = 0;
            int end_candidates = 0;
            for (int node = 0; node < vertex_count; ++node) {
                int difference = outdegree[node] - indegree[node];
                if (difference == 1) {
                    start = node;
                    ++start_candidates;
                } else if (difference == -1) {
                    ++end_candidates;
                } else if (difference != 0) {
                    return nullopt;
                }
            }
            if (start_candidates != end_candidates || start_candidates > 1) {
                return nullopt;
            }
            if (start == -1) {
                for (int node = 0; node < vertex_count; ++node) {
                    if (outdegree[node] > 0) {
                        start = node;
                        break;
                    }
                }
            }
        } else {
            int odd_count = 0;
            for (int node = 0; node < vertex_count; ++node) {
                if (outdegree[node] & 1) {
                    start = node;
                    ++odd_count;
                }
            }
            if (odd_count != 0 && odd_count != 2) return nullopt;
            if (start == -1) {
                for (int node = 0; node < vertex_count; ++node) {
                    if (outdegree[node] > 0) {
                        start = node;
                        break;
                    }
                }
            }
        }

        if (start == -1) return Result{{0}, {}};

        vector<int> next_arc(vertex_count);
        vector<bool> used(edge_count);
        vector<int> vertex_stack{start};
        vector<int> incoming_edge{-1};
        Result reversed;

        while (!vertex_stack.empty()) {
            int node = vertex_stack.back();
            while (next_arc[node] < (int)graph[node].size() &&
                   used[graph[node][next_arc[node]].edge_id]) {
                ++next_arc[node];
            }
            if (next_arc[node] == (int)graph[node].size()) {
                reversed.vertices.push_back(node);
                int edge_id = incoming_edge.back();
                if (edge_id != -1) reversed.edge_ids.push_back(edge_id);
                vertex_stack.pop_back();
                incoming_edge.pop_back();
                continue;
            }

            Arc arc = graph[node][next_arc[node]++];
            if (used[arc.edge_id]) continue;
            used[arc.edge_id] = true;
            vertex_stack.push_back(arc.to);
            incoming_edge.push_back(arc.edge_id);
        }

        if ((int)reversed.edge_ids.size() != edge_count) return nullopt;
        reverse(reversed.vertices.begin(), reversed.vertices.end());
        reverse(reversed.edge_ids.begin(), reversed.edge_ids.end());
        return reversed;
    }
};
```

度数条件只解决局部平衡；非零度顶点若不连通，最终使用的边数会小于 `edge_count`，模板会返回无解。返回的 `edge_ids[i]` 对应 `vertices[i] -> vertices[i+1]`，因此平行边和自环也能区分。
