# PAM：回文后缀、fail 树与回文划分

依赖 `string/03-Pam.md`、`00-range-query.md`、`04-parent-tree-tricks.md`。原串位置 0-based；`pre[p]` 记录原模板 `add(text[p])` 的返回值。PAM 每个非根状态唯一对应一个回文串，不像 SAM 的状态对应一段长度区间。查询右端点必须在原串内，回文状态编号至少为 2。

## fail 树 DP、端点加权

`cnt[v]=cnt[fail[v]]+1` 表示状态 `v` 的回文后缀数量。每个位置取 `cnt[pre[p]]` 就是以该位置结尾的回文串出现次数；再对位置求和得到全部回文出现次数（包含重叠）。将 `+1` 换成 `+length[v]` 就得到回文后缀长度和。

```cpp
struct PAMQuery {
    PalindromicTree a;
    vector<int> pre, cnt; // pre[r]：最长回文后缀状态；cnt[v]：其回文后缀数
    vector<long long> len_sum; // 状态 v 的所有非空回文后缀长度之和
    TreeOrder tr;
    BIT bit;

    explicit PAMQuery(string_view s) {
        for (char c : s) pre.push_back(a.add(c));
        const auto& t = a.data();
        int m = (int)t.size();
        vector<int> fa(m, -1);
        // 奇根 0 的自环改成 -1；偶根 1 仍以奇根为父亲
        for (int v = 1; v < m; ++v) fa[v] = t[v].fail;
        tr = TreeOrder(fa);
        cnt.resize(m); len_sum.resize(m);
        // fail 总指向先创建的节点；两个虚根贡献均为 0
        for (int v = 2; v < m; ++v) {
            cnt[v] = cnt[t[v].fail] + 1;
            len_sum[v] = len_sum[t[v].fail] + t[v].length;
        }
        bit = BIT(m);
    }
    int ending_count(int r) const { return cnt[pre[r]]; } // 以 r 结尾，包含重叠
    long long ending_length_sum(int r) const { return len_sum[pre[r]]; }
    void add_end_weight(int r, long long x) { bit.add(tr.tin[pre[r]], x); } // 增量
    // 状态 v 的回文出现权重和；在 fail 子树汇总结束位置
    long long palindrome_weight(int v) const {
        assert(v >= 2);
        return bit.sum(tr.tin[v], tr.tout[v]);
    }
    pair<vector<int>,vector<int>> occurrence_extrema() const {
        int m = (int)a.data().size();
        // 无直接结束位置时先填 min/max 的单位元，再汇总子树
        vector<int> lo(m, INT_MAX), hi(m, -1);
        for (int i = 0; i < (int)pre.size(); ++i) {
            lo[pre[i]] = min(lo[pre[i]], i);
            hi[pre[i]] = i;
        }
        lo = tr.subtree_fold(lo, [](int x, int y) { return min(x,y); });
        hi = tr.subtree_fold(hi, [](int x, int y) { return max(x,y); });
        return {lo, hi}; // 非根状态的最早/最晚右端点
    }
    // dp[i]：长度 i 的前缀最少分成几段非空回文，dp[0]=0；O(n log n)
    vector<int> minimum_partition_counts() const {
        const auto& t = a.data();
        int n = (int)pre.size(), m = (int)t.size();
        // dif 为相邻 fail 长度差；sl 跳过连续相同 dif 的整组
        vector<int> dif(m), sl(m), best(m, n + 1), dp(n + 1, n + 1);
        for (int v = 2; v < m; ++v) {
            int f = t[v].fail;
            dif[v] = t[v].length - t[f].length;
            sl[v] = dif[v] == dif[f] ? sl[f] : f;
        }
        dp[0] = 0;
        for (int i = 1; i <= n; ++i)
            for (int v = pre[i-1]; t[v].length > 0; v = sl[v]) {
                int f = t[v].fail;
                // 本组最短回文长度为 length[sl[v]]+dif[v]
                best[v] = dp[i - t[sl[v]].length - dif[v]];
                // 同差值时合并其余候选；best[f] 可能是上一位置留下的缓存
                if (dif[v] == dif[f]) best[v] = min(best[v], best[f]);
                dp[i] = min(dp[i], best[v] + 1);
            }
        return dp; // best 跨位置保留，不能每轮清零
    }
    const PalindromicTree& pam() const { return a; }
    const vector<int>& prefix_states() const { return pre; }
};
using PalindromicApplications = PAMQuery;
```

构造后 `ending_count/ending_length_sum` 为 $O(1)$，端点增量和状态权值查询为 $O(\log n)$，首次/末次端点汇总为 $O(n)$。静态出现次数仍调用 `pam().occurrence_counts()`；最大 `length[v]*count[v]` 直接枚举非根状态即可。两个虚根不应算作回文串。

## series link 加速最少回文划分

朴素转移是枚举当前位置的所有回文后缀 `v`，用 `dp[i-length[v]]+1` 更新 `dp[i]`。若逐个走 fail，全相同字符会退化到 $O(n^2)$。

`dif[v]=length[v]-length[fail[v]]`；沿 fail 链把连续相同 `dif` 的状态归为一组，`sl[v]`（series link）跳到该组之外。组内回文长度形成等差序列。代码先取这一组最短回文对应的 `dp`，再在 `dif` 相同时使用 `best[fail[v]]` 合并其余候选。

**`best` 必须跨位置保留**：`fail[v]` 不一定在当前轮被遍历到，读取的是由周期关系保证正确的历史缓存，不能每轮整体清零，也不能不加证明把它改成任意带额外约束的 DP。根的 `dif` 置 0，长度 1 的状态跳到偶根。

上述标准 series DP 为 $O(n\log n)$ 时间、$O(n)$ 额外空间；依据为 [Rubinchik 与 Shur 的 EERTREE 论文](https://arxiv.org/abs/1506.04862)。接口返回每个前缀的最少**段数**，非空串最少切割次数为 `dp[n]-1`，空串切割次数为 0。
