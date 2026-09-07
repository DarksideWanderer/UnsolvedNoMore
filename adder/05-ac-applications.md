# AC 自动机：fail 树、动态模式集与禁串 DP

依赖 `string/02-ACam.md`、`00-range-query.md`、`04-parent-tree-tricks.md`。仓库原 AC 文件保持不变；复制到题目中使用时，把下面这段只读接口放入 `AhoCorasick` 的 `public:` 区域。原类的数据为 private，应用层必须通过这些接口访问；插入与构造算法不变。验证脚本也仅在内存中的源码副本接入这段接口。

```cpp-member
    // 放进原类 public:；调用前必须 build()，c 为小写字母
    int state_count() const { return (int)nodes.size(); }
    int transition(int v, char c) const { return nodes[v].next[c-'a']; }
    int failure(int v) const { return nodes[v].fail; }
    const vector<int>& breadth_first_order() const { return bfs_order; } // 不含根
```

扫描到状态 `v` 时，一个模式此刻结束，当且仅当其终止节点在 `v` 的 fail 祖先链上。故只检查 `v` 自身是否为终止点会漏掉后缀模式，如模式 `a,ba` 扫到 `ba` 时两个都命中。静态全文出现次数直接调用已有 `count_occurrences`，其逆 BFS 已是 fail 树 DP，不再重复实现。

## 动态开关模式，流式查询

```cpp
struct ACQuery {
    AhoCorasick ac;
    vector<int> id; // id[i]：第 i 个模式的终止状态，重复模式可能相同
    TreeOrder tr;
    BIT bit; // fail 子树区间加、文本状态单点查，存的是差分
    int cur = 0; // 已读文本后缀对应的 AC 状态
    explicit ACQuery(const vector<string>& s) {
        for (const auto& p : s) {
            assert(!p.empty());
            id.push_back(ac.insert(p));
        }
        ac.build();
        int n = ac.state_count();
        vector<int> fa(n, -1);
        for (int v = 1; v < n; ++v) fa[v] = ac.failure(v);
        tr = TreeOrder(fa);
        bit = BIT(n + 1); // tout 可以等于 n
    }
    // 第 i 个模式权重增加 x；初始全为 0，+1 激活、-1 撤销
    void add_pattern_weight(int i, long long x) {
        int v = id[i];
        // v 是哪些状态的 fail 祖先，就影响哪些状态的匹配答案
        bit.add(tr.tin[v], x);
        bit.add(tr.tout[v], -x);
    }
    // 返回以这个新字符为右端点的匹配权重和，允许重叠；O(log V)
    long long feed(char c) {
        cur = ac.transition(cur, c);
        return bit.sum(tr.tin[cur] + 1);
    }
    void reset_text() { cur = 0; } // 新文本从根开始，模式权重保留
};
using DynamicAhoPatterns = ACQuery;
```

加权与读入一个字符均为 $O(\log V)$；构造 $O(26V+\sum|pattern|)$，空间 $O(26V)$。权重总和须装入 `long long`。在文本读到一半时激活一个模式，仅影响之后的查询，不追溯修改已经返回的答案；继续匹配会保留激活前已读的文本后缀。每份独立文本开始前调用 `reset_text()`。

## 长度为 n、避开所有禁串的字符串数量

把模式终止标记沿 fail 从父到子传播，再在 `(已生成长度, AC状态)` 上 DP。接受状态应是“沿 fail 链存在终止点”，不能只标记 Trie 叶子。

```cpp
// 生成长度 len 的字符串，字母表为前 sigma 个小写字母，答案模 mod
int count_avoiding_patterns(const vector<string>& s, int len, int sigma, int mod) {
    assert(len >= 0 && 1 <= sigma && sigma <= 26 && mod > 0);
    AhoCorasick ac;
    vector<int> id;
    for (const auto& p : s) id.push_back(ac.insert(p));
    ac.build();
    int n = ac.state_count();
    vector<char> bad(n); // 当前状态或任一 fail 祖先为禁串终点
    for (int v : id) bad[v] = true;
    // 正 BFS：父亲的标记先算完，否则漏掉较短的后缀模式
    for (int v : ac.breadth_first_order()) bad[v] |= bad[ac.failure(v)];
    if (bad[0]) return 0; // 空禁串
    vector<int> dp(n), ndp(n); // dp[v]：当前长度、停在 v 的合法串数
    dp[0] = 1 % mod;
    for (int i = 0; i < len; ++i) {
        fill(ndp.begin(), ndp.end(), 0);
        for (int v = 0; v < n; ++v)
            for (int c = 0; c < sigma; ++c) {
                int u = ac.transition(v, char('a' + c));
                // 已命中禁串的路径直接丢弃，不再参与后续转移
                if (!bad[u]) ndp[u] = (int)(((long long)ndp[u] + dp[v]) % mod);
            }
        dp.swap(ndp);
    }
    long long ans = 0;
    for (int x : dp) ans = (ans + x) % mod;
    return (int)ans;
}
```

生成字母表是前 `alphabet_size` 个小写字母，模式仍允许使用任意小写字母。DP 为 $O(nV|\Sigma|)$，滚动空间 $O(V)$，另加 AC 构造。长度很大且状态少时可对合法状态转移矩阵快速幂；要求出现全部模式时可把终止标记改成 fail 继承的模式 bitmask，再扩展 DP 的 mask 维度，复杂度会多出 $2^k$。

“匹配了多少次”与“多少种模式至少出现过一次”不同：后者静态扫描后检查已有 `count_occurrences()[terminal[id]]>0` 即可；重复模式按 ID 还是按内容去重要先定口径。不要在每个文本位置无条件遍历整条 fail 链，`a,aa,...` 会使时间退化到文本长度乘模式最大长度。
