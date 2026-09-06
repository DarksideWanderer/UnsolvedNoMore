# 点分树：动态最近标记点

对原树做点分治，把每个重心连向递归子块的重心，得到高度 $O(\log n)$ 的点分树。对每个原树结点保存它到所有点分树祖先的距离；每个重心维护其管辖标记点到它的距离集合。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class CentroidNearestMarked {
    int size;
    vector<vector<int>> graph;
    vector<bool> blocked;
    vector<int> subtree_size;
    vector<int> traversal_parent;
    vector<int> decomposition_parent;
    vector<vector<pair<int, int>>> routes;
    vector<multiset<int>> distances;
    vector<bool> active;

    void decompose(int entry, int parent_centroid) {
        vector<int> component;
        traversal_parent[entry] = -1;
        vector<int> stack{entry};
        while (!stack.empty()) {
            int node = stack.back();
            stack.pop_back();
            component.push_back(node);
            for (int next : graph[node]) {
                if (blocked[next] || next == traversal_parent[node]) continue;
                traversal_parent[next] = node;
                stack.push_back(next);
            }
        }

        for (int index = (int)component.size() - 1; index >= 0; --index) {
            int node = component[index];
            subtree_size[node] = 1;
            for (int next : graph[node]) {
                if (blocked[next] || traversal_parent[next] != node) continue;
                subtree_size[node] += subtree_size[next];
            }
        }

        int total = (int)component.size();
        int centroid = entry;
        for (int node : component) {
            int largest_part = total - subtree_size[node];
            for (int next : graph[node]) {
                if (blocked[next] || traversal_parent[next] != node) continue;
                largest_part = max(largest_part, subtree_size[next]);
            }
            if (2 * largest_part <= total) {
                centroid = node;
                break;
            }
        }

        decomposition_parent[centroid] = parent_centroid;
        struct DistanceState { int node, parent, distance; };
        vector<DistanceState> distance_stack{{centroid, -1, 0}};
        while (!distance_stack.empty()) {
            auto [node, parent, distance] = distance_stack.back();
            distance_stack.pop_back();
            routes[node].push_back({centroid, distance});
            for (int next : graph[node]) {
                if (blocked[next] || next == parent) continue;
                distance_stack.push_back({next, node, distance + 1});
            }
        }

        blocked[centroid] = true;
        for (int next : graph[centroid]) {
            if (!blocked[next]) decompose(next, centroid);
        }
    }

public:
    explicit CentroidNearestMarked(const vector<vector<int>>& tree)
        : size((int)tree.size()), graph(tree), blocked(size),
          subtree_size(size), traversal_parent(size, -1),
          decomposition_parent(size, -1), routes(size), distances(size),
          active(size) {
        if (size > 0) decompose(0, -1);
    }

    void toggle(int node) {
        assert(0 <= node && node < size);
        active[node] = !active[node];
        for (auto [centroid, distance] : routes[node]) {
            if (active[node]) {
                distances[centroid].insert(distance);
            } else {
                auto iterator = distances[centroid].find(distance);
                assert(iterator != distances[centroid].end());
                distances[centroid].erase(iterator);
            }
        }
    }

    int nearest_distance(int node) const {
        assert(0 <= node && node < size);
        int answer = numeric_limits<int>::max();
        for (auto [centroid, distance] : routes[node]) {
            if (!distances[centroid].empty()) {
                answer = min(answer, distance + *distances[centroid].begin());
            }
        }
        return answer == numeric_limits<int>::max() ? -1 : answer;
    }

    const vector<int>& parents() const { return decomposition_parent; }
};
```

输入必须是连通无根树。建树时间与路线总空间为 $O(n\log n)$；工作数组在各子块之间复用，不能在每次 `decompose` 中重新初始化长度为 $n$ 的数组，否则最坏会退化到 $O(n^2)$。一次开关会在 $O(\log n)$ 个 `multiset` 中插入/删除，复杂度 $O(\log^2 n)$；查询访问 $O(\log n)$ 个重心，每次只取集合最小值，复杂度 $O(\log n)$。

若只有“加入标记、永不删除”，每个重心只维护一个最小距离即可把修改也降到 $O(\log n)$。
