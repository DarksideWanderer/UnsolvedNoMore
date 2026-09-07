# 序列自动机：子序列判定与不同子序列计数

这里的“序列”指**子序列**，允许跳过原串字符；它不解决要求连续的子串问题。固定小写字母表，状态 `p=0..n` 表示下一次只能使用原串 `text[p..n)` 的字符。

`next[p][c]` 保存从 `p` 开始字符 `c` 的最早出现位置。转移后变成 `next[p][c]+1`，严格递增，所以转移图为 DAG。总取最早位置不会损失之后的可行选择。

```cpp
#include <bits/stdc++.h>
using namespace std;

struct SeqAM {
    vector<array<int,26>> nxt; // nxt[p][c]：位置 >=p 的最早 c，-1 表示不存在
    explicit SeqAM(const string& s) : nxt(s.size() + 1) {
        int n = (int)s.size();
        nxt[n].fill(-1); // 状态 n 已用完整串，不能再取字符
        for (int i = n - 1; i >= 0; --i) {
            nxt[i] = nxt[i+1];
            nxt[i][s[i]-'a'] = i;
        }
    }
    // p 是下一次可选位置，转移返回新的 p；失败 -1 不能用于继续转移
    int transition(int p, char c) const {
        int q = nxt[p][c-'a'];
        return q == -1 ? -1 : q + 1;
    }
    // 返回 0-based 匹配位置；空模式返回空数组，失败返回 nullopt
    optional<vector<int>> earliest_embedding(string_view s) const {
        vector<int> pos;
        int p = 0;
        for (char c : s) {
            p = transition(p, c);
            if (p == -1) return nullopt;
            pos.push_back(p - 1);
        }
        return pos;
    }
    bool contains(string_view s) const { // 只判子序列存在性，额外空间 O(1)
        int p = 0;
        for (char c : s) {
            p = transition(p, c);
            if (p == -1) return false;
        }
        return true;
    }
    int distinct_subsequence_count(int mod) const {
        assert(mod > 0);
        int n = (int)nxt.size() - 1;
        vector<int> dp(n + 1); // dp[i]：s[i..n) 的不同非空子序列内容数
        for (int i = n - 1; i >= 0; --i)
            for (int c = 0; c < 26; ++c) {
                int j = nxt[i][c];
                // 首字符 c 只选最早的 j；1 对应单字符串，dp[j+1] 对应继续接
                if (j != -1) dp[i] = (int)(((long long)dp[i] + 1 + dp[j+1]) % mod);
            }
        return dp[0]; // 不含空子序列
    }
};
using SubsequenceAutomaton = SeqAM;
```

构造时间/空间 $O(26n)$；单模式判定/构造为 $O(|pattern|)$，`contains` 额外空间 $O(1)$，返回匹配位置时结果数组占 $O(|pattern|)$；不同子序列计数为 $O(26n)$ 时间、$O(n)$ 额外空间。若要包含空子序列，答案再加 1 后取模。`aaa` 的不同非空子序列仅有 `a,aa,aaa` 三种，而下标选择有七种。

“每个字符只走向最早可用位置”使每种字符串内容只有唯一的自动机路径，故按首字符分组的 `1+dp[next]` 不重复计数。普通下标 DAG 若把每个相同字符位置都连边，会计算下标方案而非不同内容。

字母表很大时可改为每个值保存出现位置数组，每步二分找下一个位置：空间降为 $O(n)$，单模式查询变为 $O(|pattern|\log n)$。不要在没有题目需求时为大值域直接分配 `n*值域` 表。
