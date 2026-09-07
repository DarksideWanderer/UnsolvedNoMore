# Trie 上的广义 PAM

输入已经建好的 Trie：根为 0，`tr[u][c]` 为儿子，0 表示无边；字符 `c` 为 `0..25`，每个非根节点只有一个父亲。不展开根到每个终点的字符串。

`t[0]` 为奇根，`t[1]` 为偶根；`last[u]` 是根到 Trie 节点 `u` 的字符串的最长回文后缀状态。全局每种非空回文串只有一个状态。

```cpp
#include <bits/stdc++.h>
using namespace std;

struct TriePAM {
    struct Node {
        array<int,26> ch{}, direct{}; // ch[c]：在回文首尾加 c 后的状态
        int len = 0, fail = 0; // fail：最长真回文后缀
    };
    vector<Node> t = vector<Node>(2); // 0 奇根(len=-1)，1 偶根(len=0)
    vector<int> last; // last[u]：Trie 根到 u 的最长回文后缀状态

    // s[0]=-1 是哨兵，s.back() 是新字符；p 是追加前的最长回文后缀。
    // direct[v][c] 是 v 内部前驱字符为 c 的最长真回文后缀，无解为奇根。
    int extend(int p, int c, const vector<int>& s) {
        int i = (int)s.size() - 1;
        // 先检查 p 外侧字符；失败后一次 direct 跳转就找到可扩展后缀
        if (s[i - t[p].len - 1] != c) p = t[p].direct[c];
        if (!t[p].ch[c]) {
            int v = (int)t.size();
            t.emplace_back();
            t[v].len = t[p].len + 2;
            // 单字符的 fail 为偶根；其余是 c + 更短可扩展后缀 + c
            t[v].fail = p == 0 ? 1 : t[t[p].direct[c]].ch[c];
            int f = t[v].fail;
            // 除了紧邻 f 的前驱字符，其余 direct 项都继承 f 的表
            t[v].direct = t[f].direct;
            t[v].direct[s[i - t[f].len]] = f; // i-len[f] 是后缀 f 前一位
            t[p].ch[c] = v;
        }
        return t[p].ch[c];
    }

    explicit TriePAM(const vector<array<int,26>>& tr) : last(tr.size(), 1) {
        assert(!tr.empty());
        t[0].len = -1;
        vector<int> s{-1};
        vector<pair<int,int>> st{{0,0}}; // (Trie 节点,下一条待扫描字符边)
        while (!st.empty()) {
            int u = st.back().first, c = st.back().second;
            if (c == 26) {
                st.pop_back();
                if (u) s.pop_back(); // 只恢复路径；全局 PAM 状态和转移保留
                continue;
            }
            ++st.back().second;
            int v = tr[u][c];
            if (!v) continue;
            s.push_back(c);
            // 从 Trie 父节点的 last 扩展，不能沿用上一个兄弟分支的 last
            last[v] = extend(last[u], c, s);
            st.push_back({v,0});
        }
    }

    int size() const { return (int)t.size() - 2; } // 全局不同非空回文串数

    // w[u] 是 Trie 结束节点权重；返回每个回文状态的出现权重和。
    // w[u]=1 时共享前缀只计一次；根权重 w[0] 忽略。
    vector<long long> count(const vector<long long>& w) const {
        assert(w.size() == last.size());
        vector<long long> cnt(t.size());
        for (int u = 1; u < (int)last.size(); ++u) cnt[last[u]] += w[u];
        // fail 总在当前状态之前创建，逆编号即可把贡献传给全部回文后缀
        for (int v = (int)t.size() - 1; v >= 2; --v) cnt[t[v].fail] += cnt[v];
        return cnt; // 两个根的值不作字符串答案
    }
};
```

构造时间/空间为 $O(26V)$，`size()` 为 $O(1)$，一次 `count` 为 $O(V)$，其中 $V$ 是 Trie 节点数。每条 Trie 边最多新建一个回文状态；DFS 只恢复当前路径，已建 PAM 状态不回滚。

`direct[v][c]`：回文串 `v` 内部，前一个字符为 `c` 的最长真回文后缀；不存在时指向奇根 0。新状态的 direct 表从 fail 状态复制，再修改一项。根的 direct 表均初始化为 0。这样每次扩展只检查常数次字符与跳转，不需要沿 fail 逐个尝试。

普通 PAM 的 `while(fail)` 直接搬到 Trie 上会退化：一条长 `a` 链，每个节点挂一个 `b` 儿子，每个分支可能重新跳整条链。这里的 direct link 消除了该问题。

**计数口径：** 非根 `w[u]=1` 时按 Trie 上不同结束节点计数，共享前缀只计一次；若按字典中每个字符串的每次出现计数，先给终点加字符串重数，再在 Trie 子树求和作为 `w[u]`。不要把这两种次数混用。动态端点权重可复用 `04` 的 fail 树 DFS 序和 `00` 的 BIT。

技术依据：[EERTREE 的 direct link 与多版本构造](https://arxiv.org/pdf/1506.04862)，固定字母表下直接复制 26 项即可。
