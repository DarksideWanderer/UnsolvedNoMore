# SAM：后缀链接树上的动态 endpos

这是 `string/01-Sam.md` 中 `SuffixAutomaton` 的应用层，依赖 `00` 的 BIT，不重复 `extend` 和克隆状态构造。`pre[p]` 即每个位置扩展后的 `prefix_state[p]`。字符为小写字母，子串定位/判等只接受正长度。树和倍增预处理完成后，不能继续 `extend`。

```cpp
using SamSubstringKey = pair<int,int>; // (状态,长度)

struct SAMQuery {
    SuffixAutomaton a;
    vector<int> pre, tin, tout; // pre[p]：扩展第 p 个字符后的 last
    vector<vector<int>> up; // up[k][v]：沿 suffix link 跳 2^k 次，根跳到根
    BIT bit; // 在 tin[pre[p]] 存结束位置 p 的权重，初始全 0

    explicit SAMQuery(string_view s) {
        for (char c : s) {
            a.extend(c);
            pre.push_back(a.last_state());
        }
        const auto& t = a.data();
        int m = (int)t.size(), lg = 1;
        while ((1LL << lg) <= m) ++lg;
        vector<vector<int>> g(m);
        up.assign(lg, vector<int>(m));
        // 反向 suffix link 建树；不是 SAM 的字符转移图
        for (int v = 1; v < m; ++v) {
            up[0][v] = t[v].link;
            g[t[v].link].push_back(v);
        }
        for (int k = 1; k < lg; ++k)
            for (int v = 0; v < m; ++v)
                up[k][v] = up[k-1][up[k-1][v]];
        tin.resize(m); tout.resize(m);
        vector<int> st{0}, order;
        // 迭代 DFS 前序：整棵子树占连续区间，避免长链递归爆栈
        while (!st.empty()) {
            int v = st.back(); st.pop_back();
            tin[v] = (int)order.size();
            order.push_back(v);
            for (int u : g[v]) st.push_back(u);
        }
        // 逆 DFS 序汇总子树右端点，子树为 [tin[v],tout[v])
        for (int i = m - 1; i >= 0; --i) {
            int v = order[i];
            tout[v] = max(tout[v], tin[v] + 1);
            if (v) tout[t[v].link] = max(tout[t[v].link], tout[v]);
        }
        bit = BIT(m);
    }
    // 子串用 0-based 右端点 r、正长度 len 表示；O(log n)
    int substring_state(int r, int len) const {
        assert(0 <= r && r < (int)pre.size() && 1 <= len && len <= r + 1);
        int v = pre[r];
        // 尽量向上跳，停在 length[link[v]] < len <= length[v]
        for (int k = (int)up.size() - 1; k >= 0; --k)
            if (a.data()[up[k][v]].length >= len) v = up[k][v];
        return v;
    }
    // 同状态可以有多个长度，精确键必须保留 len
    SamSubstringKey substring_key(int r, int len) const {
        return {substring_state(r, len), len};
    }
    bool equal(int r1, int len1, int r2, int len2) const {
        return len1 == len2 && substring_key(r1, len1) == substring_key(r2, len2);
    }
    void add_end_weight(int p, long long x) { bit.add(tin[pre[p]], x); } // 增量
    // 一个结束位置属于 endpos(v)，当且仅当它的前缀状态在 v 的子树内
    long long state_endpos_weight(int v) const { return bit.sum(tin[v], tout[v]); }
    long long substring_endpos_weight(int r, int len) const {
        return state_endpos_weight(substring_state(r, len));
    }
    const vector<int>& prefix_states() const { return pre; }
    const SuffixAutomaton& sam() const { return a; }
};
using SuffixAutomatonApplications = SAMQuery; // 保留旧调用名
```

suffix link 树上，状态 `v` 的 DFS 子树恰好覆盖 `endpos(v)` 对应的所有前缀状态。因此给结束位置 `p` 加权时修改 `tin[pre[p]]`，查询状态 `v` 时求 `[tin[v], tout[v])`。根状态查询返回全部已加权的结束位置之和，不定义空串的 `n+1` 次出现。

预处理时间/空间 $O(n\log n)$，定位状态、两次定位后的判等、动态修改/查询均为 $O(\log n)$；已取得 `(状态,长度)` 键后的比较为 $O(1)$。只有倍增表把根的祖先设为根，不改变原 SAM 的 `link[0]=-1`。

状态只确定一个 `endpos` 等价类；同一状态可能代表多个长度不同、内容也不同的子串。故子串的确定性键必须是 `(state, length)`。
