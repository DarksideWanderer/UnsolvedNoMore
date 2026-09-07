# 区间查询公共组件

本章的 SA、SAM、AC、PAM 补充接口共用下面的树状数组；SA 的所有 LCP 查询共用同一张静态 RMQ 表。两者均使用 0-based 下标和左闭右开区间，避免在各应用中重复实现。

```cpp
#include <bits/stdc++.h>
using namespace std;

struct BIT {
    int n;
    vector<long long> t; // 外部 0-based，内部 1-based；初始权重全为 0
    explicit BIT(int n_ = 0) : n(n_), t(n + 1) {}
    // 位置 p 增加 x，允许负数用于撤销；O(log n)
    void add(int p, long long x) {
        assert(0 <= p && p < n);
        for (++p; p <= n; p += p & -p) t[p] += x;
    }
    long long sum(int r) const { // [0,r)
        long long s = 0;
        for (; r; r -= r & -r) s += t[r];
        return s;
    }
    long long sum(int l, int r) const { return sum(r) - sum(l); } // [l,r)
};

struct RMQ {
    vector<int> lg; // lg[i]=floor(log2(i))
    vector<vector<int>> st; // st[k][i]：从 i 开始、长 2^k 的区间最小值
    RMQ() = default;
    explicit RMQ(const vector<int>& a) {
        int n = (int)a.size();
        lg.resize(n + 1);
        for (int i = 2; i <= n; ++i) lg[i] = lg[i / 2] + 1;
        if (!n) return;
        st.assign(lg[n] + 1, a);
        for (int k = 1; k <= lg[n]; ++k)
            for (int i = 0; i + (1 << k) <= n; ++i)
                st[k][i] = min(st[k-1][i], st[k-1][i + (1 << (k-1))]);
    }
    int query(int l, int r) const { // 非空 [l,r)
        assert(0 <= l && l < r && r <= (int)st[0].size());
        int k = lg[r - l];
        // 两个长 2^k 的区间覆盖 [l,r)，min 允许重叠；O(1)
        return min(st[k][l], st[k][r - (1 << k)]);
    }
};
```

`BIT` 要求 `0<=p<n`、`0<=l<=r<=n`；`sum(r)` 返回 `[0,r)`，`sum(l,r)` 返回 `[l,r)`。允许负增量，总权重须装入 `long long`。`RMQ::query(l,r)` 要求非空区间。树状数组操作为 $O(\log n)$；RMQ 预处理时间/空间 $O(n\log n)$，查询 $O(1)$。
