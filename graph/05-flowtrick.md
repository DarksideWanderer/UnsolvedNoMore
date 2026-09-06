# 网络流建模技巧

本文件代码直接使用 `03-maxflow.md` 中的 `Dinic`。

```cpp
using flow_i128 = __int128_t;
```

## 最大权闭合子图

有向图中选择点集 $S$，并要求 $u\in S$ 且存在依赖边 $u\to v$ 时必有 $v\in S$。点有正负权，目标是最大化点权和。

- 权值 $w_i>0$：连 `source -> i`，容量 $w_i$；
- 权值 $w_i<0$：连 `i -> sink`，容量 $-w_i$；
- 依赖 $u\to v$：连容量 `infinity` 的 `u -> v`。

答案是“所有正权之和减最小割”。最大流结束后残量网络中源点可达的原图点就是一组最优解。

```cpp
struct ClosureResult {
    long long value;
    vector<int> selected;
};

ClosureResult maximum_weight_closure(
    const vector<long long>& weight,
    const vector<pair<int, int>>& dependencies) {
    int n = (int)weight.size();
    int source = n, sink = n + 1;
    flow_i128 positive_sum = 0;
    for (long long value : weight) {
        if (value > 0) positive_sum += value;
        assert(value != numeric_limits<long long>::min());
    }
    assert(positive_sum < numeric_limits<long long>::max());
    long long infinity = (long long)positive_sum + 1;

    Dinic flow(n + 2);
    for (int i = 0; i < n; ++i) {
        if (weight[i] > 0) flow.add_edge(source, i, weight[i]);
        if (weight[i] < 0) flow.add_edge(i, sink, -weight[i]);
    }
    for (auto [u, v] : dependencies) {
        assert(0 <= u && u < n && 0 <= v && v < n);
        flow.add_edge(u, v, infinity);
    }

    long long cut = flow.max_flow(source, sink);
    vector<bool> source_side = flow.min_cut_side(source);
    vector<int> selected;
    for (int i = 0; i < n; ++i) {
        if (source_side[i]) selected.push_back(i);
    }
    return {(long long)positive_sum - cut, selected};
}
```

`infinity = positive_sum + 1` 已经足够：空集给出容量至多 `positive_sum` 的有限割，所以最小割绝不会切断依赖边。代码要求正权总和能放入 `long long`；否则最大流容量本身也需要换成 `__int128`。

## 最大密度子图

对无自环无向图选择非空点集 $S$，密度定义为诱导子图边数除以点数：

$$
\rho(S)=\frac{|E(S)|}{|S|}.
$$

判断是否存在 $\rho(S)>g$ 时，为每个点建立网络：

- `source -> v` 容量 $m$；
- `v -> sink` 容量 $m+2g-\deg(v)$；
- 每条无向边 $(u,v)$ 加容量为 1 的 `u -> v` 和 `v -> u`。

若割的源侧原图点集为 $S$，割容量恰为

$$
nm+2g|S|-2|E(S)|.
$$

因此最小割小于 $nm$ 当且仅当存在密度大于 $g$ 的非空子图。下面把所有容量乘 `scale` 后做整数二分，避免浮点容量误差；返回值绝对误差不超过 $1/(2\,scale)$。

```cpp
long double maximum_density_subgraph(
    int n, const vector<pair<int, int>>& edges,
    long long scale = 1000000) {
    assert(n > 0 && scale > 0);
    int m = (int)edges.size();
    vector<int> degree(n);
    for (auto [u, v] : edges) {
        assert(0 <= u && u < n && 0 <= v && v < n && u != v);
        ++degree[u];
        ++degree[v];
    }

    flow_i128 capacity_bound = (flow_i128)3 * m * scale;
    flow_i128 total_bound = (flow_i128)n * m * scale;
    assert(capacity_bound <= numeric_limits<long long>::max());
    assert(total_bound <= numeric_limits<long long>::max());
    long long base_capacity = (long long)((flow_i128)m * scale);
    long long baseline = (long long)total_bound;

    auto feasible = [&](long long density_scaled) {
        int source = n, sink = n + 1;
        Dinic flow(n + 2);
        for (int v = 0; v < n; ++v) {
            flow.add_edge(source, v, base_capacity);
            long long sink_capacity =
                (long long)(m - degree[v]) * scale + 2 * density_scaled;
            flow.add_edge(v, sink, sink_capacity);
        }
        for (auto [u, v] : edges) {
            flow.add_edge(u, v, scale);
            flow.add_edge(v, u, scale);
        }
        return flow.max_flow(source, sink, baseline) < baseline;
    };

    long long low = -1;
    long long high = (long long)m * scale;
    while (high - low > 1) {
        long long middle = low + (high - low) / 2;
        if (feasible(middle)) low = middle;
        else high = middle;
    }
    if (m == 0) return 0;
    return (low + high) / (2.0L * scale);
}
```

一次判定是一遍最大流，总复杂度再乘 $O(\log(m\,scale))$。平行边可以保留并分别计数；自环应预先按题意处理。若题目要求输出点集，在最终可行的 `low` 上再跑一次流并取 `min_cut_side(source)`。

## 上下界可行流

对边 $u\to v$ 的流量限制 $lower\le f\le upper$，先让它流过 `lower`，残量边容量变成 `upper-lower`。令 `balance[v]` 为下界造成的“流入减流出”：

- `balance[v] > 0`：加 `super_source -> v`；
- `balance[v] < 0`：加 `v -> super_sink`。

超级源的边全部满流，当且仅当存在可行环流。

```cpp
struct BoundedEdge {
    int from, to;
    long long lower, upper;
};

bool feasible_circulation(int n, const vector<BoundedEdge>& edges) {
    int super_source = n, super_sink = n + 1;
    Dinic flow(n + 2);
    vector<flow_i128> balance(n);
    for (const BoundedEdge& edge : edges) {
        assert(0 <= edge.from && edge.from < n);
        assert(0 <= edge.to && edge.to < n);
        assert(0 <= edge.lower && edge.lower <= edge.upper);
        flow.add_edge(edge.from, edge.to, edge.upper - edge.lower);
        balance[edge.from] -= edge.lower;
        balance[edge.to] += edge.lower;
    }

    flow_i128 demand = 0;
    for (int v = 0; v < n; ++v) {
        if (balance[v] > 0) {
            assert(balance[v] <= numeric_limits<long long>::max());
            flow.add_edge(super_source, v, (long long)balance[v]);
            demand += balance[v];
        } else if (balance[v] < 0) {
            assert(-balance[v] <= numeric_limits<long long>::max());
            flow.add_edge(v, super_sink, (long long)-balance[v]);
        }
    }
    assert(demand <= numeric_limits<long long>::max());
    return flow.max_flow(super_source, super_sink, (long long)demand) == demand;
}
```

## 有源汇上下界最大流 / 最小流

约定流值非负。先加辅助边 `sink -> source`，求出一组可行环流；辅助边上的流量就是当前 $s\to t$ 流值。随后必须在**同一张残量网络**里同时删除辅助边的正反残量边以及超级源汇的边：

- 最大流再跑 `source -> sink`；
- 最小流再跑 `sink -> source`，但最多撤回当前流值，避免把流值减成负数。

`Dinic::flow_on(handle)` 读取一条原始正向边当前已经流过的量。返回结果同时恢复每条输入边的实际流量。代码要求所有边容量总和能放进 `long long`；这也是当前 Dinic 能安全保存总流量的条件。

```cpp
struct BoundedFlowResult {
    long long value;
    vector<long long> edge_flow;
};

optional<BoundedFlowResult> bounded_st_flow(
    int n, int source, int sink,
    const vector<BoundedEdge>& edges, bool maximize) {
    assert(0 <= source && source < n);
    assert(0 <= sink && sink < n && source != sink);
    int super_source = n, super_sink = n + 1;
    Dinic flow(n + 2);
    vector<flow_i128> balance(n);
    vector<Dinic::EdgeHandle> original_edges;
    flow_i128 capacity_sum = 0;

    for (const BoundedEdge& edge : edges) {
        assert(0 <= edge.from && edge.from < n);
        assert(0 <= edge.to && edge.to < n);
        assert(0 <= edge.lower && edge.lower <= edge.upper);
        original_edges.push_back(
            flow.add_edge(edge.from, edge.to, edge.upper - edge.lower));
        balance[edge.from] -= edge.lower;
        balance[edge.to] += edge.lower;
        capacity_sum += edge.upper;
    }
    assert(capacity_sum <= numeric_limits<long long>::max());
    long long infinity = (long long)max<flow_i128>(1, capacity_sum);
    auto auxiliary = flow.add_edge(sink, source, infinity);

    vector<Dinic::EdgeHandle> super_edges;
    flow_i128 demand = 0;
    for (int v = 0; v < n; ++v) {
        if (balance[v] > 0) {
            assert(balance[v] <= numeric_limits<long long>::max());
            super_edges.push_back(flow.add_edge(
                super_source, v, (long long)balance[v]));
            demand += balance[v];
        } else if (balance[v] < 0) {
            assert(-balance[v] <= numeric_limits<long long>::max());
            super_edges.push_back(flow.add_edge(
                v, super_sink, (long long)-balance[v]));
        }
    }
    assert(demand <= numeric_limits<long long>::max());
    if (flow.max_flow(super_source, super_sink, (long long)demand)
        != demand) {
        return nullopt;
    }

    long long base_value = flow.flow_on(auxiliary);
    for (auto handle : super_edges) flow.disable_edge(handle);
    flow.disable_edge(auxiliary);

    flow_i128 answer = base_value;
    if (maximize) {
        answer += flow.max_flow(source, sink);
    } else {
        answer -= flow.max_flow(sink, source, base_value);
    }
    assert(0 <= answer && answer <= numeric_limits<long long>::max());

    vector<long long> edge_flow(edges.size());
    for (int i = 0; i < (int)edges.size(); ++i) {
        edge_flow[i] = edges[i].lower + flow.flow_on(original_edges[i]);
    }
    return BoundedFlowResult{(long long)answer, move(edge_flow)};
}

optional<BoundedFlowResult> maximum_bounded_flow(
    int n, int source, int sink, const vector<BoundedEdge>& edges) {
    return bounded_st_flow(n, source, sink, edges, true);
}

optional<BoundedFlowResult> minimum_bounded_flow(
    int n, int source, int sink, const vector<BoundedEdge>& edges) {
    return bounded_st_flow(n, source, sink, edges, false);
}
```

注意：只判断可行时仍可直接使用上一节的 `feasible_circulation`。最大值和最小值必须分别从初始网络求解，不能在已经求过最大流的残量网络上继续求最小流。

## 其他常见建模

- 最大流值已知时，可以给最大流加上恰好该流量的限制，再求最小费用，从而得到最小费用最大流。
- 点权路径或点容量限制使用拆点：`in(v) -> out(v)` 承载点的容量或费用。
- 不要凭图形猜最小割；固定源侧点集，逐类列出真正从源侧指向汇侧的边，通常更不容易漏项。
