# Parent 树 DP：汇总方向与 DFS 区间

本篇是 `05`～`07` 的公共依赖。所有节点 0-based，根的父亲约定为 `-1`，输入必须是一棵非空有根树。复用时不要把自动机转移图当成 Parent 树：

| 结构 | 本篇所说的 parent | 祖先的含义 | 每个原串位置挂在哪 |
|---|---|---|---|
| SAM | suffix link | 更短后缀的 endpos 类 | 扩展后的 `last` |
| AC | fail | 当前已读文本的后缀，同时为 Trie 前缀 | 扫描文本后的状态 |
| PAM | fail | 更短的回文后缀 | `add` 返回的最长回文后缀 |
| KMP | `prefix[length-1]` | 当前前缀的 border | 前缀长度 `i+1` |

SAM 的转移是 DAG；AC 的 Trie 父边表示删去最后一个字符；PAM 的建树父边表示删去首尾两个字符。它们均不同于上述 suffix/fail 父边。PAM 的偶根指向奇根，奇根的自环要改成 `-1` 才能交给树代码。

两个常见方向：

- 儿子向父亲：先把结束位置的次数、权重、最早/最晚端点放到其状态，逆序合并。状态的子树结果就是其出现位置的聚合信息。
- 父亲向儿子：在终止状态放标记或权重，正序继承。当前状态根路径上的和就是此刻结束的全部模式的权值；OR 标记则表示是否命中任意禁串。

```cpp
#include <bits/stdc++.h>
using namespace std;

struct TreeOrder {
    vector<int> parent, order, tin, tout; // parent[root]=-1，order 为 DFS 前序
    vector<vector<int>> children; // 只存从父到子的边
    TreeOrder() = default;
    // fa 必须描述一棵非空有根树；O(V) 预处理，子树为 [tin,tout)
    explicit TreeOrder(vector<int> fa) : parent(std::move(fa)) {
        int n = (int)parent.size(), root = -1;
        children.resize(n); tin.resize(n); tout.resize(n);
        for (int v = 0; v < n; ++v) {
            if (parent[v] == -1) root = v;
            else children[parent[v]].push_back(v);
        }
        assert(root != -1);
        vector<int> st{root};
        // 栈式 DFS 保证子树连续；这里不是 BFS
        while (!st.empty()) {
            int v = st.back(); st.pop_back();
            tin[v] = (int)order.size();
            order.push_back(v);
            for (int u : children[v]) st.push_back(u);
        }
        assert((int)order.size() == n);
        // 子树处理完再更新父亲，右端点取子树中最大 tin 加一
        for (int i = n - 1; i >= 0; --i) {
            int v = order[i], p = parent[v];
            tout[v] = max(tout[v], tin[v] + 1);
            if (p != -1) tout[p] = max(tout[p], tout[v]);
        }
    }
    bool is_ancestor(int u, int v) const { // 包含 u==v
        return tin[u] <= tin[v] && tin[v] < tout[u];
    }
    // 儿子向父亲汇总；op 为可交换、可结合操作，如 sum/min/max/OR。
    // a 长度等于节点数，初值为自身贡献；无贡献处填相应单位元。
    template<class T, class F>
    vector<T> subtree_fold(vector<T> a, F op) const {
        for (int i = (int)order.size() - 1; i > 0; --i) {
            int v = order[i], p = parent[v];
            a[p] = op(a[p], a[v]);
        }
        return a;
    }
    // 父亲向儿子继承，返回含自身的根路径聚合；顺序为父在前、子在后
    template<class T, class F>
    vector<T> root_path_fold(vector<T> a, F op) const {
        for (int v : order)
            if (parent[v] != -1) a[v] = op(a[parent[v]], a[v]);
        return a;
    }
};
using ParentTreeIndex = TreeOrder;
```

预处理与一次 DP 均为 $O(V)$，空间 $O(V)$，使用迭代 DFS。不能对 SAM 按状态编号倒序汇总，克隆的编号可能大于儿子；应按长度降序或用这里的树序。AC 可用逆 BFS，PAM 的 fail 总指向更早创建的节点，KMP 的父长度更小。

动态场景复用 `00-range-query.md` 的 `BIT`，有两种互为对偶的写法，见 AC/PAM 完整封装：

- **结束位置动态加权**：`add(tin[state], delta)`，查询模式状态子树 `[tin[v],tout[v])`。
- **模式动态加权**：在模式子树做差分区间加 `add(tin[v],delta)`、`add(tout[v],-delta)`，文本状态查询 `sum(tin[state]+1)`。差分树状数组要开 `V+1`，容纳 `tout==V`。

限制结束位置在 `[l,r]`：把查询拆成截止 `r` 的贡献减去截止 `l-1` 的贡献，按端点扫描，每个位置只激活一次，用第一种写法查询。若要求长度为 `len` 的子串**完整落在**原串 `[a,b]`，结束位置范围应是 `[a+len-1,b]`，不是 `[a,b]`。离线复杂度 $O((n+q)\log V)$。

首次/末次出现用子树 min/max（无贡献节点初始化为 `INT_MAX/-1`）；多个串的归属集合可改成 bitset OR，但注意 bitset 合并时间与字符串数量有关。LCA 直接复用 `graph/10-euler-tour-lca.md`，不要再写一份树剖。
