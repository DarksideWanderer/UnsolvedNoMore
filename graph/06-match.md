# 图匹配

## Hopcroft–Karp 二分图最大匹配

左右两侧分别使用 0-based 编号。只从左侧调用 `add_edge(left, right)`。复杂度为 $O(E\sqrt V)$。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class HopcroftKarp {
    int left_count;
    int right_count;
    vector<vector<int>> graph;
    vector<int> distance;

    bool bfs() {
        queue<int> que;
        fill(distance.begin(), distance.end(), -1);
        for (int left = 0; left < left_count; ++left) {
            if (match_left[left] == -1) {
                distance[left] = 0;
                que.push(left);
            }
        }
        bool found = false;
        while (!que.empty()) {
            int left = que.front();
            que.pop();
            for (int right : graph[left]) {
                int next_left = match_right[right];
                if (next_left == -1) {
                    found = true;
                } else if (distance[next_left] == -1) {
                    distance[next_left] = distance[left] + 1;
                    que.push(next_left);
                }
            }
        }
        return found;
    }

    bool dfs(int left) {
        for (int right : graph[left]) {
            int next_left = match_right[right];
            if (next_left == -1 ||
                (distance[next_left] == distance[left] + 1 && dfs(next_left))) {
                match_left[left] = right;
                match_right[right] = left;
                return true;
            }
        }
        distance[left] = -1;
        return false;
    }

public:
    vector<int> match_left;
    vector<int> match_right;

    HopcroftKarp(int left_size, int right_size)
        : left_count(left_size), right_count(right_size), graph(left_size),
          distance(left_size), match_left(left_size, -1),
          match_right(right_size, -1) {}

    void add_edge(int left, int right) {
        graph[left].push_back(right);
    }

    int max_matching() {
        int matching_size = 0;
        while (bfs()) {
            for (int left = 0; left < left_count; ++left) {
                if (match_left[left] == -1 && dfs(left)) ++matching_size;
            }
        }
        return matching_size;
    }
};
```

## 偏序集最大反链：拆点、匹配与构造

Dilworth 定理：有限偏序集的最大反链大小等于最小链划分大小。把每个元素 $i$ 拆成左点 $i_L$ 和右点 $i_R$；对每个严格偏序关系 $i<j$ 连边 $i_L\to j_R$。若最大匹配大小为 $m$，则最大反链大小为 $n-m$。

左右副本是二分图中互不相同的点，所以同一个元素的左右副本可以同时参与两条匹配边。例如匹配中同时出现 $1_L-2_R$ 和 $2_L-6_R$，表示把 $1<2<6$ 接成一条链。每条匹配边把两条链接起来，因此 $m$ 条匹配边得到 $n-m$ 条链。

拆点边必须包含**所有**严格偏序关系。若输入只给出“较小指向较大”的 DAG 边，这些边通常只是偏序的生成关系，所以应先求传递闭包：只要 $i$ 能到达 $j$，就连接 $i_L-j_R$。

### 怎样实际取出反链

求出任意一组最大匹配 $M$ 后，做一次交错 BFS：

1. 从所有未匹配的左点开始，并把它们标记为到达；
2. 当前在左点时，只沿**非匹配边**走到右点；
3. 当前在右点时，只沿它的**匹配边**走回左点；
4. 不能再扩展时停止，记到达的左右点集合分别为 $Z_L,Z_R$。

方向始终是

$$
\text{未匹配左点}\xrightarrow{\text{非匹配边}}R
\xrightarrow{\text{匹配边}}L
\xrightarrow{\text{非匹配边}}R\longrightarrow\cdots.
$$

不要从未匹配右点开始，也不要在左点走匹配边。按上述方向得到的

$$
C=(L\setminus Z_L)\cup Z_R
$$

是拆点二分图的一组最小点覆盖。现在保留那些“左右副本都没有进入点覆盖”的原元素：

$$
\begin{aligned}
A
&=\{i:i_L\notin C,\ i_R\notin C\}\\
&=\{i:i_L\in Z_L,\ i_R\notin Z_R\}.
\end{aligned}
$$

所以实现时只需判断 `reached_left[i] && !reached_right[i]`。

为什么这一定是最大反链：若 $i<j$ 且 $i,j$ 都被选中，二分图中存在边 $i_L-j_R$，但它的两个端点都不在点覆盖 $C$ 中，与 $C$ 覆盖所有边矛盾，所以 $A$ 是反链。又因为 $|C|=|M|$，至少有 $n-|C|$ 个元素的左右副本都不在 $C$ 中；而匹配给出的 $n-|M|$ 条链说明任意反链至多从每条链取一个点。上下界相同，故 $|A|=n-|M|$。

### 例子：整除偏序

取元素 $\{1,2,3,6\}$，规定 $x<y$ 当且仅当 $x$ 严格整除 $y$。拆点边为

$$
1_L\to2_R,\quad1_L\to3_R,\quad1_L\to6_R,
\quad2_L\to6_R,\quad3_L\to6_R.
$$

取最大匹配 $M=\{1_L-2_R,\ 2_L-6_R\}$。未匹配左点是 $3_L,6_L$：从 $3_L$ 沿非匹配边到 $6_R$，再沿匹配边到 $2_L$，之后无法继续。因此

$$
Z_L=\{2_L,3_L,6_L\},\qquad Z_R=\{6_R\}.
$$

逐个元素检查：

| 元素 $i$ | $i_L\in Z_L$ | $i_R\in Z_R$ | 是否进入反链 |
|---|---:|---:|---:|
| $1$ | 否 | 否 | 否 |
| $2$ | 是 | 否 | 是 |
| $3$ | 是 | 否 | 是 |
| $6$ | 是 | 是 | 否 |

最终得到最大反链 $\{2,3\}$，大小为 $4-|M|=2$。

```cpp
// 使用上面的 HopcroftKarp。
vector<int> maximum_antichain(const vector<vector<int>>& dag) {
    int n = (int)dag.size();
    vector<vector<char>> less(n, vector<char>(n, false));

    // 求严格可达关系；输入必须是 DAG。
    for (int source = 0; source < n; ++source) {
        vector<char> visited(n, false);
        queue<int> que;
        visited[source] = true;
        que.push(source);
        while (!que.empty()) {
            int node = que.front();
            que.pop();
            for (int next : dag[node]) {
                if (visited[next]) continue;
                visited[next] = true;
                less[source][next] = true;
                que.push(next);
            }
        }
    }

    HopcroftKarp matching(n, n);
    for (int left = 0; left < n; ++left) {
        for (int right = 0; right < n; ++right) {
            if (less[left][right]) matching.add_edge(left, right);
        }
    }
    matching.max_matching();

    vector<char> reached_left(n, false), reached_right(n, false);
    queue<pair<int, bool>> que; // second=false 表示左点，true 表示右点
    for (int left = 0; left < n; ++left) {
        if (matching.match_left[left] == -1) {
            reached_left[left] = true;
            que.push({left, false});
        }
    }
    while (!que.empty()) {
        auto [node, is_right] = que.front();
        que.pop();
        if (!is_right) {
            // 左点只走不属于匹配的边。
            for (int right = 0; right < n; ++right) {
                if (!less[node][right] ||
                    matching.match_left[node] == right ||
                    reached_right[right]) {
                    continue;
                }
                reached_right[right] = true;
                que.push({right, true});
            }
        } else {
            // 右点只沿匹配边走回左点。
            int left = matching.match_right[node];
            if (left != -1 && !reached_left[left]) {
                reached_left[left] = true;
                que.push({left, false});
            }
        }
    }

    vector<int> antichain;
    for (int element = 0; element < n; ++element) {
        if (reached_left[element] && !reached_right[element]) {
            antichain.push_back(element);
        }
    }
    return antichain;
}
```

### 方法二：原笔记的“链尾向链首跳”

上面的最大匹配还确定了一组最小链划分。若匹配边为 `u_L -> v_R`，就在原偏序中令 `u` 的后继为 `v`、`v` 的前驱为 `u`：

```text
successor[u] = matching.match_left[u];
predecessor[v] = matching.match_right[v];
```

满足 `match_right[head] == -1` 的点是链首，满足 `match_left[tail] == -1` 的点是链尾。你原来的构造可以严格写成：

1. 每条链先选择链尾，放入候选集合 $H$；
2. 若当前代表 `y` 的右副本 `y_R` 被交错搜索到，即 `reached_right[y] == true`，就把 `y` 换成它在同一条链里的前驱 `match_right[y]`；
3. 继续向链首移动，直到当前代表的右副本没有被搜索到；每条链最终留下一个代表。

其中 `reached_right[y]` 正是原笔记里“当前链尾与其他候选产生可比冲突，需要向链首跳”的统一标记。一次交错 BFS 会把连续产生的所有冲突同时传播出来，不必每次重新扫描 $H$ 中的点对。

在前面函数已经求出 `reached_right` 后，也可以把最后构造答案的循环替换成下面这段：

```text
vector<int> antichain;
for (int tail = 0; tail < n; ++tail) {
    if (matching.match_left[tail] != -1) continue; // 不是链尾
    int representative = tail;
    while (reached_right[representative]) {
        // 沿匹配边 representative_R -> predecessor_L 向链首跳一步。
        representative = matching.match_right[representative];
        assert(representative != -1);
    }
    antichain.push_back(representative);
}
```

它不会越过链首：如果某条链首 `head` 仍满足 `reached_right[head]`，就存在一条从未匹配左点到未匹配右点 `head_R` 的交错路，也就是增广路，这与当前匹配已经最大矛盾。

这个写法与方法一选出的是同一批点。链尾的左副本本来就是搜索起点；每向链首跳一步，走的正是匹配边 `current_R -> predecessor_L`，所以新代表的左副本仍被访问。停止时代表满足

```text
reached_left[representative] && !reached_right[representative]
```

这恰好就是方法一的选点条件。在整除偏序的例子中，两条匹配链为 $1<2<6$ 和 $3$：先取链尾 $\{6,3\}$，因为 `6_R` 被访问，所以把 $6$ 向链首移动到 $2$，得到 $\{2,3\}$。

传递闭包部分复杂度为 $O(n(n+m))$，闭包最多产生 $n^2$ 条边；匹配复杂度为 $O(n^2\sqrt n)$。若 $n$ 较大且可达集合适合位运算，可换成 `bitset` 传递闭包。

## 二分图最大匹配的可行边与必须边

这里把平行边也视为不同的边：

- **可行边**：至少属于一组最大匹配；
- **必须边**：属于每一组最大匹配；
- 其余边不属于任何最大匹配。

先任取一组最大匹配 $M$，仍把非匹配边定向为 $L\to R$、匹配边定向为 $R\to L$。记：

- `from_free_left`：从未匹配左点出发可达；
- `to_free_right`：能够到达某个未匹配右点，可在反图中从这些右点出发求出；
- `component`：上述有向图的强连通分量。

对非匹配边 $(l,r)$，它可行当且仅当以下至少一项成立：两端同属一个 SCC、`l` 可从自由左点到达、`r` 可以到达自由右点。对匹配边，它本来就可行；若满足这三项中的任意一项，就能沿交错环或偶长交错路换掉，因此不是必须边，否则是必须边。存在完美匹配时没有自由点，判定恰好退化成 SCC 判据。

```cpp
enum class MatchingEdgeType {
    impossible, // 不属于任何最大匹配
    feasible,   // 属于某些、但不属于所有最大匹配
    mandatory   // 属于每一组最大匹配
};

// 使用 02-tarjan.md 的 StronglyConnectedComponents。
// match_left、match_right 必须描述一组最大匹配。
vector<MatchingEdgeType> classify_maximum_matching_edges(
    int left_count, int right_count,
    const vector<pair<int, int>>& edges,
    const vector<int>& match_left,
    const vector<int>& match_right) {
    assert((int)match_left.size() == left_count);
    assert((int)match_right.size() == right_count);
    int node_count = left_count + right_count;
    for (int right : match_left) {
        assert(-1 <= right && right < right_count);
    }
    for (int left : match_right) {
        assert(-1 <= left && left < left_count);
    }

    vector<int> matched_edge(left_count, -1);
    for (int edge_id = 0; edge_id < (int)edges.size(); ++edge_id) {
        auto [left, right] = edges[edge_id];
        assert(0 <= left && left < left_count);
        assert(0 <= right && right < right_count);
        if (match_left[left] == right && match_right[right] == left &&
            matched_edge[left] == -1) {
            matched_edge[left] = edge_id;
        }
    }
    for (int left = 0; left < left_count; ++left) {
        if (match_left[left] != -1) {
            assert(match_right[match_left[left]] == left);
            assert(matched_edge[left] != -1);
        }
    }

    StronglyConnectedComponents scc(node_count);
    vector<vector<int>> directed(node_count), reversed(node_count);
    auto add_directed_edge = [&](int from, int to) {
        directed[from].push_back(to);
        reversed[to].push_back(from);
        scc.add_edge(from, to);
    };

    for (int edge_id = 0; edge_id < (int)edges.size(); ++edge_id) {
        auto [left, right] = edges[edge_id];
        int right_node = left_count + right;
        if (matched_edge[left] == edge_id) {
            add_directed_edge(right_node, left);
        } else {
            add_directed_edge(left, right_node);
        }
    }
    scc.build();

    auto reachable = [&](const vector<vector<int>>& graph,
                         const vector<int>& starts) {
        vector<char> visited(node_count, false);
        queue<int> que;
        for (int start : starts) {
            visited[start] = true;
            que.push(start);
        }
        while (!que.empty()) {
            int node = que.front();
            que.pop();
            for (int next : graph[node]) {
                if (visited[next]) continue;
                visited[next] = true;
                que.push(next);
            }
        }
        return visited;
    };

    vector<int> free_left, free_right;
    for (int left = 0; left < left_count; ++left) {
        if (match_left[left] == -1) free_left.push_back(left);
    }
    for (int right = 0; right < right_count; ++right) {
        if (match_right[right] == -1) {
            free_right.push_back(left_count + right);
        }
    }
    vector<char> from_free_left = reachable(directed, free_left);
    vector<char> to_free_right = reachable(reversed, free_right);

    vector<MatchingEdgeType> result(
        edges.size(), MatchingEdgeType::impossible);
    for (int edge_id = 0; edge_id < (int)edges.size(); ++edge_id) {
        auto [left, right] = edges[edge_id];
        int right_node = left_count + right;
        bool can_exchange =
            scc.component_of[left] == scc.component_of[right_node] ||
            from_free_left[left] || to_free_right[right_node];
        if (matched_edge[left] == edge_id) {
            result[edge_id] = can_exchange
                ? MatchingEdgeType::feasible
                : MatchingEdgeType::mandatory;
        } else if (can_exchange) {
            result[edge_id] = MatchingEdgeType::feasible;
        }
    }
    return result;
}
```

最大匹配求出后，建有向图、两次可达性和 SCC 总复杂度为 $O(V+E)$。不能对非完美匹配只使用“同 SCC”这一条，否则会漏掉通过自由点移动未匹配位置的可行边。

## 二分图最大权完美匹配

下面的 Hungarian 实现寻找“每个左点恰好匹配一个不同右点”的最大权匹配，要求 `left_count <= right_count`，并把权值矩阵中的每个位置都视为存在的边。不存在的边不能简单填 0：应填足够小的负数，并在结束后检查是否选到了它。

```cpp
class MaximumWeightMatching {
    using i64 = long long;
    static constexpr i64 inf = numeric_limits<i64>::max() / 4;

    int left_count;
    int right_count;
    vector<vector<i64>> weight;

public:
    MaximumWeightMatching(int left_size, int right_size)
        : left_count(left_size), right_count(right_size),
          weight(left_size, vector<i64>(right_size)) {
        assert(left_size <= right_size);
    }

    void set_weight(int left, int right, i64 value) {
        weight[left][right] = value;
    }

    pair<i64, vector<int>> solve() const {
        vector<i64> left_potential(left_count + 1);
        vector<i64> right_potential(right_count + 1);
        vector<int> matched_left(right_count + 1);
        vector<int> previous_right(right_count + 1);

        for (int left = 1; left <= left_count; ++left) {
            matched_left[0] = left;
            int right = 0;
            vector<i64> minimum(right_count + 1, inf);
            vector<bool> used(right_count + 1, false);
            do {
                used[right] = true;
                int current_left = matched_left[right];
                i64 delta = inf;
                int next_right = 0;
                for (int candidate = 1; candidate <= right_count; ++candidate) {
                    if (used[candidate]) continue;
                    i64 reduced_cost =
                        -weight[current_left - 1][candidate - 1] -
                        left_potential[current_left] - right_potential[candidate];
                    if (reduced_cost < minimum[candidate]) {
                        minimum[candidate] = reduced_cost;
                        previous_right[candidate] = right;
                    }
                    if (minimum[candidate] < delta) {
                        delta = minimum[candidate];
                        next_right = candidate;
                    }
                }
                for (int candidate = 0; candidate <= right_count; ++candidate) {
                    if (used[candidate]) {
                        left_potential[matched_left[candidate]] += delta;
                        right_potential[candidate] -= delta;
                    } else {
                        minimum[candidate] -= delta;
                    }
                }
                right = next_right;
            } while (matched_left[right] != 0);

            do {
                int previous = previous_right[right];
                matched_left[right] = matched_left[previous];
                right = previous;
            } while (right != 0);
        }

        vector<int> assignment(left_count, -1);
        for (int right = 1; right <= right_count; ++right) {
            if (matched_left[right] != 0) {
                assignment[matched_left[right] - 1] = right - 1;
            }
        }
        i64 total_weight = 0;
        for (int left = 0; left < left_count; ++left) {
            total_weight += weight[left][assignment[left]];
        }
        return {total_weight, assignment};
    }
};
```

复杂度为 $O(n^2m)$，方阵时为 $O(n^3)$。权值取负以及势能运算必须能装入 `long long`。

## 一般图最大匹配（Edmonds Blossom）

支持奇环，点编号为 0-based。复杂度为 $O(V^3)$。

```cpp
class GeneralMatching {
    int node_count;
    vector<vector<int>> graph;
    vector<int> parent;
    vector<int> base;
    vector<int> que;
    vector<bool> used;
    vector<bool> blossom;

    int lowest_common_ancestor(int lhs, int rhs) {
        vector<bool> visited(node_count, false);
        while (true) {
            lhs = base[lhs];
            visited[lhs] = true;
            if (match[lhs] == -1) break;
            lhs = parent[match[lhs]];
        }
        while (true) {
            rhs = base[rhs];
            if (visited[rhs]) return rhs;
            rhs = parent[match[rhs]];
        }
    }

    void mark_path(int node, int ancestor, int child) {
        while (base[node] != ancestor) {
            blossom[base[node]] = true;
            blossom[base[match[node]]] = true;
            parent[node] = child;
            child = match[node];
            node = parent[match[node]];
        }
    }

    bool find_augmenting_path(int root) {
        fill(used.begin(), used.end(), false);
        fill(parent.begin(), parent.end(), -1);
        iota(base.begin(), base.end(), 0);
        int que_begin = 0;
        int que_end = 0;
        que[que_end++] = root;
        used[root] = true;

        while (que_begin < que_end) {
            int node = que[que_begin++];
            for (int next : graph[node]) {
                if (base[node] == base[next] || match[node] == next) continue;
                if (next == root ||
                    (match[next] != -1 && parent[match[next]] != -1)) {
                    int ancestor = lowest_common_ancestor(node, next);
                    fill(blossom.begin(), blossom.end(), false);
                    mark_path(node, ancestor, next);
                    mark_path(next, ancestor, node);
                    for (int vertex = 0; vertex < node_count; ++vertex) {
                        if (!blossom[base[vertex]]) continue;
                        base[vertex] = ancestor;
                        if (!used[vertex]) {
                            used[vertex] = true;
                            que[que_end++] = vertex;
                        }
                    }
                } else if (parent[next] == -1) {
                    parent[next] = node;
                    if (match[next] == -1) {
                        int current = next;
                        while (current != -1) {
                            int previous = parent[current];
                            int following = previous == -1 ? -1 : match[previous];
                            match[current] = previous;
                            if (previous != -1) match[previous] = current;
                            current = following;
                        }
                        return true;
                    }
                    next = match[next];
                    used[next] = true;
                    que[que_end++] = next;
                }
            }
        }
        return false;
    }

public:
    vector<int> match;

    explicit GeneralMatching(int initial_node_count)
        : node_count(initial_node_count), graph(initial_node_count),
          parent(initial_node_count), base(initial_node_count),
          que(initial_node_count), used(initial_node_count),
          blossom(initial_node_count), match(initial_node_count, -1) {}

    void add_edge(int lhs, int rhs) {
        assert(lhs != rhs);
        graph[lhs].push_back(rhs);
        graph[rhs].push_back(lhs);
    }

    int max_matching() {
        int matching_size = 0;
        for (int node = 0; node < node_count; ++node) {
            if (match[node] == -1 && find_augmenting_path(node)) {
                ++matching_size;
            }
        }
        return matching_size;
    }
};
```

一般图匹配实现较长，比赛中尤其要测试三角形、五元环、两个奇环通过路径相连，以及含重边的情况。自环应在加入图前删除。
