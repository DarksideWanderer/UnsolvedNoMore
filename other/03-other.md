# 其他图算法

## 全局最小割：Stoer--Wagner

适用于无向图、非负边权；重边权值应相加。返回最小割权值，并保存其中一侧的原始顶点集合。复杂度 $O(n^3)$，会在对象内部复制并缩点，不修改调用者的数据。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

using i64 = long long;

class StoerWagner {
    int vertex_count;
    vector<vector<i64>> weight;

public:
    explicit StoerWagner(int initial_vertex_count)
        : vertex_count(initial_vertex_count),
          weight(initial_vertex_count, vector<i64>(initial_vertex_count)) {}

    void add_edge(int lhs, int rhs, i64 edge_weight) {
        assert(0 <= lhs && lhs < vertex_count);
        assert(0 <= rhs && rhs < vertex_count);
        assert(lhs != rhs && edge_weight >= 0);
        weight[lhs][rhs] += edge_weight;
        weight[rhs][lhs] += edge_weight;
    }

    pair<i64, vector<int>> minimum_cut() const {
        if (vertex_count <= 1) return {0, {}};

        vector<vector<i64>> current_weight = weight;
        vector<int> active(vertex_count);
        iota(active.begin(), active.end(), 0);
        vector<vector<int>> group(vertex_count);
        for (int vertex = 0; vertex < vertex_count; ++vertex) {
            group[vertex] = {vertex};
        }

        i64 answer = numeric_limits<i64>::max();
        vector<int> answer_side;
        while (active.size() > 1) {
            vector<i64> connection_weight(vertex_count);
            vector<bool> added(vertex_count);
            int previous = -1;

            for (int step = 0; step < (int)active.size(); ++step) {
                int selected = -1;
                for (int vertex : active) {
                    if (!added[vertex] &&
                        (selected == -1 ||
                         connection_weight[vertex] >
                             connection_weight[selected])) {
                        selected = vertex;
                    }
                }

                if (step + 1 == (int)active.size()) {
                    if (connection_weight[selected] < answer) {
                        answer = connection_weight[selected];
                        answer_side = group[selected];
                    }
                    for (int vertex : active) {
                        if (vertex == selected || vertex == previous) continue;
                        current_weight[previous][vertex] +=
                            current_weight[selected][vertex];
                        current_weight[vertex][previous] =
                            current_weight[previous][vertex];
                    }
                    group[previous].insert(group[previous].end(),
                                           group[selected].begin(),
                                           group[selected].end());
                    active.erase(find(active.begin(), active.end(), selected));
                    break;
                }

                added[selected] = true;
                previous = selected;
                for (int vertex : active) {
                    if (!added[vertex]) {
                        connection_weight[vertex] +=
                            current_weight[selected][vertex];
                    }
                }
            }
        }
        return {answer, answer_side};
    }
};
```

权值相加及缩点过程中可能达到所有边权之和，因此必须保证它不超过 `i64`。若只需要割值，可以忽略返回集合的第二项。

## 最大独立集：精确搜索

下面实现适用于至多 63 个顶点的简单无向图。它在候选集中依次决定选取哪个顶点，并用“当前答案 + 剩余候选数”剪枝；返回一个最大独立集的位掩码。最坏复杂度仍为指数级，适合规模较小或图较稠密的场景。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

using u64 = unsigned long long;

class MaximumIndependentSet {
    int vertex_count;
    vector<u64> compatible;
    int best_size = 0;
    u64 best_set = 0;

    void search(u64 candidates, u64 selected) {
        int selected_size = popcount(selected);
        if (selected_size + popcount(candidates) <= best_size) return;

        while (candidates != 0) {
            if (selected_size + popcount(candidates) <= best_size) return;
            int vertex = countr_zero(candidates);
            u64 vertex_bit = u64{1} << vertex;
            candidates ^= vertex_bit;
            search(candidates & compatible[vertex], selected | vertex_bit);
        }
        if (selected_size > best_size) {
            best_size = selected_size;
            best_set = selected;
        }
    }

public:
    explicit MaximumIndependentSet(int initial_vertex_count)
        : vertex_count(initial_vertex_count), compatible(initial_vertex_count) {
        assert(0 <= initial_vertex_count && initial_vertex_count <= 63);
        u64 all_vertices = initial_vertex_count == 0
            ? 0 : (u64{1} << initial_vertex_count) - 1;
        for (int vertex = 0; vertex < initial_vertex_count; ++vertex) {
            compatible[vertex] = all_vertices ^ (u64{1} << vertex);
        }
    }

    void add_edge(int lhs, int rhs) {
        assert(0 <= lhs && lhs < vertex_count);
        assert(0 <= rhs && rhs < vertex_count);
        assert(lhs != rhs);
        compatible[lhs] &= ~(u64{1} << rhs);
        compatible[rhs] &= ~(u64{1} << lhs);
    }

    pair<int, u64> solve() {
        best_size = 0;
        best_set = 0;
        u64 all_vertices = vertex_count == 0
            ? 0 : (u64{1} << vertex_count) - 1;
        search(all_vertices, 0);
        return {best_size, best_set};
    }
};
```

一般图无权最大匹配见 `graph/06-match.md`。一般图最大权匹配的带权花树实现很长且极易因边权约定、完美匹配要求和花展开细节而出错，因此不保留未经独立验证的旧代码；比赛需要时应针对题目语义引入经过压力测试的版本。
