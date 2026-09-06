# 线段树分治模板

把在时间区间 $[l,r)$ 有效的事件放入覆盖该区间的 $O(\log q)$ 个结点。DFS 进入结点时应用事件，离开时按相反顺序撤销。动态连通性最常用的状态就是下面这个可撤销并查集。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

struct RollbackDsu {
    vector<int> parent, size;
    vector<pair<int, int>> history; // 被接入的根、另一个根原来的大小
    int component_count;

    explicit RollbackDsu(int n) : parent(n), size(n, 1), component_count(n) {
        iota(parent.begin(), parent.end(), 0);
    }

    int find(int x) const {
        while (x != parent[x]) x = parent[x];
        return x;
    }

    bool merge(int x, int y) {
        x = find(x);
        y = find(y);
        if (x == y) {
            history.push_back({-1, 0});
            return false;
        }
        if (size[x] < size[y]) swap(x, y);
        history.push_back({y, size[x]});
        parent[y] = x;
        size[x] += size[y];
        --component_count;
        return true;
    }

    void undo() {
        assert(!history.empty());
        auto [child, old_size] = history.back();
        history.pop_back();
        if (child == -1) return;
        int root = parent[child];
        size[root] = old_size;
        parent[child] = child;
        ++component_count;
    }

    bool same(int x, int y) const { return find(x) == find(y); }
};

template<class Event>
class SegmentTreeOverTime {
    int time_count;
    vector<vector<Event>> events;

    void add_interval(int node, int left, int right,
                      int query_left, int query_right, const Event& event) {
        if (query_right <= left || right <= query_left) return;
        if (query_left <= left && right <= query_right) {
            events[node].push_back(event);
            return;
        }
        int middle = left + (right - left) / 2;
        add_interval(node * 2, left, middle, query_left, query_right, event);
        add_interval(node * 2 + 1, middle, right,
                     query_left, query_right, event);
    }

public:
    explicit SegmentTreeOverTime(int initial_time_count)
        : time_count(initial_time_count),
          events(max(1, 4 * initial_time_count)) {
        assert(initial_time_count >= 0);
    }

    void add_interval(int left, int right, const Event& event) {
        assert(0 <= left && left <= right && right <= time_count);
        if (left < right) add_interval(1, 0, time_count, left, right, event);
    }

    template<class Apply, class Rollback, class Answer>
    void traverse(Apply apply, Rollback rollback, Answer answer) const {
        if (time_count == 0) return;
        auto dfs = [&](auto&& self, int node, int left, int right) -> void {
            for (const Event& event : events[node]) apply(event);
            if (right - left == 1) {
                answer(left);
            } else {
                int middle = left + (right - left) / 2;
                self(self, node * 2, left, middle);
                self(self, node * 2 + 1, middle, right);
            }
            for (auto iterator = events[node].rbegin();
                 iterator != events[node].rend(); ++iterator) {
                rollback(*iterator);
            }
        };
        dfs(dfs, 1, 0, time_count);
    }
};
```

并查集不能路径压缩，否则一次撤销会涉及整条路径；只按大小合并即可保证 `find` 为 $O(\log n)$。无论 `merge` 是否真的合并，模板都会向历史栈压入一项，因此每次事件离开时恰好调用一次 `undo()`。

若共有 $k$ 个有效区间，则事件存储量与应用次数均为 $O(k\log q)$。配合可撤销并查集，动态连通性总复杂度为 $O(k\log q\log n)$。典型用法是把边作为 `Event`，进入时 `dsu.merge(edge.u,edge.v)`，退出时 `dsu.undo()`，在叶子回答当前时刻询问。
