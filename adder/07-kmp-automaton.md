# KMP 自动机与 border 树 DP

依赖 `string/07-Kmp.md`。使用固定小写字母表，状态是已匹配的模式前缀长度 `0..m`，包含完整匹配状态 `m`。已有 KMP 搜索不重复实现。

## 预处理 O(1) 字符转移

```cpp
struct KMP {
    vector<array<int,26>> go; // go[i][c]：已匹配 i 个字符，再读 c 后的新长度
    explicit KMP(const string& s) : go(s.size() + 1) {
        int n = (int)s.size();
        auto pi = prefix_function(s);
        // 必须算到状态 n；完整匹配后的下一次转移仍要允许重叠
        for (int i = 0; i <= n; ++i)
            for (int c = 0; c < 26; ++c)
                if (i < n && s[i] == char('a' + c)) go[i][c] = i + 1;
                else if (i) go[i][c] = go[pi[i-1]][c]; // 复用已算好的失配状态
    }
    int transition(int v, char c) const { return go[v][c-'a']; }
    int pattern_length() const { return (int)go.size() - 1; }
};
using KmpAutomaton = KMP;
```

预处理时间/空间为 $O(26m)$，每次字符转移 $O(1)$。模式非空时，每次转移后若状态等于 `m` 就产生一次匹配；下一字符通过 `go[m]` 自动失配，因此保留重叠匹配。空模式只有状态 0，应把初始边界也计作一次匹配，合计文本长度加 1。

自动机 DP 状态常为 `(生成长度, matched)`：统计避开单个模式的串时，禁止转移到 `m`；统计恰好出现 `k` 次时增加计数维度，每次到 `m` 加一。多模式的同类完整计数代码见 `05-ac-applications.md`，不再复制一份 DP。

## Parent 树：前缀次数、最长公共 border、受限 border

下面另依赖 `04-parent-tree-tricks.md`；LCA 复用 `graph/10-euler-tour-lca.md`。根 0 表示空前缀，节点 `i` 表示长度为 `i` 的前缀。

```cpp
vector<int> kmp_parent_array(const string& s) {
    auto pi = prefix_function(s);
    vector<int> fa(s.size() + 1, -1);
    // 节点编号是前缀长度，父亲是其最长真 border 长度；根 0 的父亲为 -1
    for (int i = 1; i <= (int)s.size(); ++i) fa[i] = pi[i-1];
    return fa;
}

struct BorderQuery {
    TreeOrder tr;
    EulerTourLca lca;
    vector<long long> cnt;
    explicit BorderQuery(const string& s)
        : tr(kmp_parent_array(s)), lca(tr.children, {0}) {
        // 每个非空前缀挂一次结束位置；子树和就是该前缀的总出现次数
        vector<long long> a(s.size() + 1, 1);
        a[0] = 0;
        cnt = tr.subtree_fold(a, plus<long long>{});
        cnt[0] = (long long)s.size() + 1; // 空串按 n+1 个边界计数
    }
    long long prefix_occurrences(int len) const { return cnt[len]; }
    int longest_common_border(int x, int y, bool proper = false) const {
        int v = lca.lca(x,y);
        // LCA 默认允许前缀本身；若要求双方都是真 border，必要时再跳父亲
        if (proper && v && (v == x || v == y)) v = tr.parent[v];
        return v;
    }
};
using KmpBorderQueries = BorderQuery;

// ans[i]：长度 i 的前缀中，满足 2*border长度<=i 的非空 border 数
vector<int> nonoverlapping_border_counts(const string& s) {
    auto pi = prefix_function(s);
    int n = (int)s.size(), j = 0;
    vector<int> dep(n + 1), ans(n + 1); // dep[j]：j 到根链上的非空节点数
    for (int i = 1; i <= n; ++i) dep[i] = dep[pi[i-1]] + 1;
    for (int i = 1; i < n; ++i) {
        // j 跨位置维护，不要每次重新从 pi[i] 跳，否则可能退化到平方
        while (j && s[i] != s[j]) j = pi[j-1];
        if (s[i] == s[j]) ++j;
        while (j > (i + 1) / 2) j = pi[j-1]; // 首尾两份不能重叠
        ans[i+1] = dep[j];
    }
    return ans;
}
```

`KmpBorderQueries` 预处理 $O(n\log n)$ 时间/空间，次数与公共 border 查询 $O(1)$。若只要次数，使用代码中的 `subtree_fold` 即可做到 $O(n)$，无需建 LCA。真 border 查询若 LCA 等于某个输入，必须跳一次父亲；空前缀的真 border 不存在，这里仍返回 0 作为哨兵。

`nonoverlapping_border_counts` 为 $O(n)$ 时间/空间。维护的 `matched` 是当前前缀最长、且首尾两段不重叠的 border；答案是它在失配树上的深度。这里阈值随前缀长度单调变化，且每步匹配长度最多加一，沿 fail 回退总计线性。**不能对每个前缀重新从 `prefix[i]` 开始跳**，也不能把此摊还结论套到任意乱序长度上限查询。
