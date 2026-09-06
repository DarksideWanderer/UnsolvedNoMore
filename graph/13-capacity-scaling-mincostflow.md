# Capacity scaling 最小费用循环流

普通逐次最短路每次增广的流量可能只有 $1$，复杂度会依赖总流量。Capacity scaling 把容量从高位到低位加入：进入下一位时，先把当前容量和流量都乘 $2$，再为这一位为 `1` 的边增加一个单位容量。

维护势能 $p$，约化费用定义为

$$
c_p(u,v)=p(u)+c(u,v)-p(v).
$$

若当前所有残量边的约化费用非负，则残量图没有负圈，当前循环流最优。给原边 $u\to v$ 新增一个单位容量时，只有这条新残量边可能破坏条件：

- 若它原本已有正残量，只增加容量，不会出现一种新的环；
- 否则，在旧残量图中从 $v$ 跑 Dijkstra。若“新边 $u\to v$ + 最短路 $v\leadsto u$”费用为负，就沿该负圈增广一个单位；否则保留新边的残量容量；
- 用最短路距离更新势能后，所有现存残量边的约化费用重新非负。

每条边的每个二进制位至多触发一次 Dijkstra，共 $O(m\log U)$ 次；使用二叉堆时复杂度为 $O(m(n+m)\log n\log U)$，通常写作 $O(m^2\log n\log U)$。这里 $U$ 是最大容量。

## 模板

这是**最小费用循环流**：没有源汇，每个点流量守恒，允许算法主动增广负圈。`add_edge` 返回输入边编号，答案中的 `edge_flow[id]` 与之对应。容量和费用用 `long long` 保存，距离、势能和总费用临时使用 `__int128`。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class CapacityScalingMinCostCirculation {
    using i64 = long long;
    using i128 = __int128_t;
    static constexpr i128 infinity = (i128(1) << 120);

    struct Arc {
        int from, to;
        i64 original_capacity;
        i64 residual_capacity;
        i64 cost;
    };

    int node_count;
    bool solved = false;
    vector<Arc> arcs;
    vector<vector<int>> graph;
    vector<int> original_arcs;
    vector<i128> potential, distance;
    vector<int> previous_arc;

    i128 reduced_cost(int arc_id) const {
        const Arc& arc = arcs[arc_id];
        return potential[arc.from] + arc.cost - potential[arc.to];
    }

    void dijkstra(const vector<i128>& initial_distance) {
        using State = pair<i128, int>;
        priority_queue<State, vector<State>, greater<State>> que;
        distance = initial_distance;
        previous_arc.assign(node_count, -1);
        for (int node = 0; node < node_count; ++node) {
            if (distance[node] != infinity) {
                que.push({distance[node], node});
            }
        }

        while (!que.empty()) {
            auto [current_distance, node] = que.top();
            que.pop();
            if (current_distance != distance[node]) continue;
            for (int arc_id : graph[node]) {
                const Arc& arc = arcs[arc_id];
                if (arc.residual_capacity == 0) continue;
                i128 length = reduced_cost(arc_id);
                assert(length >= 0);
                i128 next_distance = current_distance + length;
                if (next_distance < distance[arc.to]) {
                    distance[arc.to] = next_distance;
                    previous_arc[arc.to] = arc_id;
                    que.push({next_distance, arc.to});
                }
            }
        }
    }

    // 势能只差一个整体常数；重新取虚拟源到各点的最短路，防止其不断漂移。
    void normalize_potential() {
        i128 maximum = *max_element(potential.begin(), potential.end());
        vector<i128> initial_distance(node_count);
        for (int node = 0; node < node_count; ++node) {
            initial_distance[node] = maximum - potential[node];
        }
        dijkstra(initial_distance);
        for (int node = 0; node < node_count; ++node) {
            potential[node] += distance[node] - maximum;
        }
    }

    void add_one_capacity(int arc_id) {
        Arc& added_arc = arcs[arc_id];
        if (added_arc.residual_capacity > 0) {
            ++added_arc.residual_capacity;
            return;
        }

        int from = added_arc.from;
        int to = added_arc.to;
        i128 added_length = reduced_cost(arc_id);
        vector<i128> initial_distance(node_count, infinity);
        initial_distance[to] = 0;
        dijkstra(initial_distance);

        if (distance[from] != infinity &&
            distance[from] + added_length < 0) {
            // 使用新边，并沿最短路 to -> from 增广一个单位。
            ++arcs[arc_id ^ 1].residual_capacity;
            for (int node = from; node != to; ) {
                int path_arc = previous_arc[node];
                assert(path_arc != -1);
                --arcs[path_arc].residual_capacity;
                ++arcs[path_arc ^ 1].residual_capacity;
                node = arcs[path_arc].from;
            }
        } else {
            ++arcs[arc_id].residual_capacity;
        }

        i128 maximum_distance = 0;
        for (i128 value : distance) {
            if (value != infinity) maximum_distance = max(maximum_distance, value);
        }
        i128 unreachable_distance =
            maximum_distance + max<i128>(0, -added_length);
        for (int node = 0; node < node_count; ++node) {
            potential[node] += distance[node] == infinity
                ? unreachable_distance : distance[node];
        }
        normalize_potential();
    }

public:
    struct Result {
        i128 cost;
        vector<i64> edge_flow;
    };

    explicit CapacityScalingMinCostCirculation(int initial_node_count)
        : node_count(initial_node_count), graph(initial_node_count),
          potential(initial_node_count) {
        assert(node_count > 0);
    }

    int add_edge(int from, int to, i64 capacity, i64 cost) {
        assert(!solved);
        assert(0 <= from && from < node_count);
        assert(0 <= to && to < node_count);
        assert(capacity >= 0);
        assert(cost != numeric_limits<i64>::min());
        int arc_id = (int)arcs.size();
        arcs.push_back({from, to, capacity, 0, cost});
        arcs.push_back({to, from, 0, 0, -cost});
        graph[from].push_back(arc_id);
        graph[to].push_back(arc_id ^ 1);
        original_arcs.push_back(arc_id);
        return (int)original_arcs.size() - 1;
    }

    Result solve() {
        assert(!solved);
        solved = true;
        int highest_bit = -1;
        for (int arc_id : original_arcs) {
            unsigned long long capacity = arcs[arc_id].original_capacity;
            if (capacity > 0) {
                highest_bit = max(highest_bit,
                    63 - __builtin_clzll(capacity));
            }
        }

        for (int bit = highest_bit; bit >= 0; --bit) {
            for (Arc& arc : arcs) arc.residual_capacity *= 2;
            for (int arc_id : original_arcs) {
                unsigned long long capacity = arcs[arc_id].original_capacity;
                if ((capacity >> bit) & 1ULL) add_one_capacity(arc_id);
            }
        }

        Result result{0, vector<i64>(original_arcs.size())};
        for (int id = 0; id < (int)original_arcs.size(); ++id) {
            int arc_id = original_arcs[id];
            i64 flow = arcs[arc_id ^ 1].residual_capacity;
            result.edge_flow[id] = flow;
            result.cost += (i128)flow * arcs[arc_id].cost;
        }
        return result;
    }
};
```

`solve()` 只能调用一次。模板允许平行边、自环和负费用边；`cost == LLONG_MIN` 被排除，因为建立反向边时 `-cost` 无法放进 `long long`。应另写 `__int128` 输出函数打印总费用。

## 从循环流得到最小费用最大流

文章中的做法是加辅助边 `sink -> source`，容量取流量上界，费用取一个绝对值足够大的负数，然后求最小费用循环流；辅助边流量就是最大流量。不过“足够大”必须有证明。若所有原边满足 $|c|\le C$，则简单增广路至多有 $n-1$ 条边，可取

$$
K=(n-1)C+1,
$$

并令辅助边费用为 $-K$。还必须保证 $K$、辅助容量及答案均不会溢出；不能直接写 `-1e18`。

更稳妥的赛场方案是分两步：先忽略费用求最大流值 $F$，再加入 `sink -> source`、下界和上界都为 $F$、费用为 $0$ 的边，把问题变成固定流量的最小费用可行循环流。这样不依赖人造负费用常数。

## 有负费用边、负圈时的上下界做法

逐次最短路只从源点增广，可能漏掉与源汇无关的负圈。对有限上下界边

$$
u\to v,\qquad l\le f\le r,\qquad \text{费用 }c,
$$

可以先把每条边放在局部费用最小的端点，从而把剩余调整边全部变成非负费用：

- 若 $c\ge 0$，预先令 $f=l$，加入 `u -> v`、容量 $r-l$、费用 $c$ 的调整边；
- 若 $c<0$，预先令 $f=r$，加入 `v -> u`、容量 $r-l$、费用 $-c$ 的调整边。调整边上的流量表示从满流中撤回多少；
- 预流为 $f_0$ 时，更新 `balance[u] -= f0`、`balance[v] += f0`，基础费用加上 $f_0c$。

此时所有调整边费用非负。对 `balance[v] > 0` 加 `super_source -> v`，对 `balance[v] < 0` 加 `v -> super_sink`，用最小费用最大流把超级源的所有需求送满：送不满则无可行解，送满时就是全局最小费用解。恢复原边流量时：

- $c\ge0$：$f=l+x$；
- $c<0$：$f=r-x$；

其中 $x$ 是对应调整边的流量。最终费用也可写成“基础费用 + 调整费用”。这个变换已经把原问题中可能出现的负圈吸收到“负费用边默认取上界”里，因此不能只做一次普通可行流后就停下。

要求固定 $s\to t$ 流量为 $F$ 时，再加入 `t -> s`、下界和上界均为 $F$、费用为 $0$ 的边，然后做同一套变换即可。求最小费用最大流时，先求最大流值 $F$，再固定 $F$，最不容易踩边界。

参考：[ouuan 的推导与实现](https://ouuan.github.io/post/%E5%9F%BA%E4%BA%8E-capacity-scaling-%E7%9A%84%E5%BC%B1%E5%A4%9A%E9%A1%B9%E5%BC%8F%E5%A4%8D%E6%9D%82%E5%BA%A6%E6%9C%80%E5%B0%8F%E8%B4%B9%E7%94%A8%E6%B5%81%E7%AE%97%E6%B3%95/)，[MIT 6.854 Min-Cost Flow 讲义](https://ocw.mit.edu/courses/6-854j-advanced-algorithms-fall-2005/resources/n10_mincostflow/)。
