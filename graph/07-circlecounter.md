# 三元环与四元环计数

以下算法要求输入是无自环、无重边的简单无向图。按“度数优先、编号次优先”给点定全序，把每条边从较大的端点定向到较小的端点。

```cpp
#include <bits/stdc++.h>
using namespace std;

using i64 = long long;

i64 count_triangles(int node_count,
                    const vector<pair<int, int>>& edges) {
    vector<int> degree(node_count);
    for (auto [lhs, rhs] : edges) {
        ++degree[lhs];
        ++degree[rhs];
    }
    auto larger = [&](int lhs, int rhs) {
        return pair{degree[lhs], lhs} > pair{degree[rhs], rhs};
    };
    vector<vector<int>> outgoing(node_count);
    for (auto [lhs, rhs] : edges) {
        if (!larger(lhs, rhs)) swap(lhs, rhs);
        outgoing[lhs].push_back(rhs);
    }

    vector<bool> marked(node_count);
    i64 answer = 0;
    for (int largest = 0; largest < node_count; ++largest) {
        for (int next : outgoing[largest]) marked[next] = true;
        for (int middle : outgoing[largest]) {
            for (int smallest : outgoing[middle]) {
                answer += marked[smallest];
            }
        }
        for (int next : outgoing[largest]) marked[next] = false;
    }
    return answer;
}

i64 count_four_cycles(int node_count,
                      const vector<pair<int, int>>& edges) {
    vector<int> degree(node_count);
    vector<vector<int>> graph(node_count);
    for (auto [lhs, rhs] : edges) {
        ++degree[lhs];
        ++degree[rhs];
        graph[lhs].push_back(rhs);
        graph[rhs].push_back(lhs);
    }
    auto order = [&](int node) {
        return pair{degree[node], node};
    };
    vector<vector<int>> outgoing(node_count);
    for (auto [lhs, rhs] : edges) {
        if (order(lhs) < order(rhs)) swap(lhs, rhs);
        outgoing[lhs].push_back(rhs);
    }

    vector<int> path_count(node_count);
    vector<int> touched;
    i64 answer = 0;
    for (int largest = 0; largest < node_count; ++largest) {
        for (int middle : outgoing[largest]) {
            for (int opposite : graph[middle]) {
                if (order(opposite) >= order(largest)) continue;
                if (path_count[opposite] == 0) touched.push_back(opposite);
                answer += path_count[opposite]++;
            }
        }
        for (int node : touched) path_count[node] = 0;
        touched.clear();
    }
    return answer;
}
```

三元环和四元环算法均利用低度定向把枚举量压到 $O(m\sqrt m)$。四元环按顶点集合计数；即使同一组四个点还有对角线，也仍只按其中实际存在的四边环计数。
