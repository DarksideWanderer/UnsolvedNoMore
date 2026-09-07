# SA：LCP、子串比较与匹配区间

这是 `string/08-Sa.md` 中 `suffix_array_and_lcp` 的应用层，不重复后缀数组和 LCP 的构造。子串统一表示为 `(start, length)`，其中 `start` 是原串中的 0-based 起点。

依赖 `00` 的 `BIT/RMQ`。要求 `0<=start<=n`、`0<=length<=n-start`；空串可用于判等和比较，匹配区间/计数必须传非空子串。`suffix_lcp` 的两个起点均须小于 `n`，相同起点直接返回后缀长度。

```cpp
struct SuffixArraySubstring { int start, length; }; // 原串 0-based 起点、长度

struct SAQuery {
    int n;
    vector<int> sa_, rk; // sa_[排名]=起点，rk[起点]=排名
    RMQ rmq; // 建在 h 上，h[i]=LCP(sa_[i-1],sa_[i])
    BIT bit; // 起点权重存到对应的 SA 排名上

    explicit SAQuery(const string& s) : n((int)s.size()), bit(n) {
        auto [sa, h] = suffix_array_and_lcp(s);
        sa_ = std::move(sa);
        rk.resize(n);
        for (int i = 0; i < n; ++i) rk[sa_[i]] = i;
        rmq = RMQ(h);
    }
    // 两个完整后缀的 LCP，O(1)；x,y 均须在 [0,n)
    int suffix_lcp(int x, int y) const {
        if (x == y) return n - x;
        int l = rk[x], r = rk[y];
        if (l > r) swap(l, r);
        return rmq.query(l + 1, r + 1); // h 的闭区间 [l+1,r]
    }
    // 内容精确判等，允许空串；O(1)
    bool equal(SuffixArraySubstring a, SuffixArraySubstring b) const {
        return a.length == b.length &&
            (!a.length || suffix_lcp(a.start, b.start) >= a.length);
    }
    // 返回 -1/0/1；一串是另一串前缀时比较长度，否则比较后缀排名
    int compare(SuffixArraySubstring a, SuffixArraySubstring b) const {
        int len = min(a.length, b.length);
        if (!len || suffix_lcp(a.start, b.start) >= len)
            return (a.length > b.length) - (a.length < b.length);
        return rk[a.start] < rk[b.start] ? -1 : 1;
    }
    // 所有匹配起点在 SA 上连续；返回排名闭区间，O(log n)
    pair<int,int> matching_interval(SuffixArraySubstring a) const {
        assert(a.length > 0); // 原串中的非空子串
        int p = rk[a.start], l = 0, r = p;
        // 左侧 LCP>=长度 的判定从假变真，找第一个真
        while (l < r) {
            int m = (l + r) / 2;
            if (suffix_lcp(sa_[m], a.start) >= a.length) r = m;
            else l = m + 1;
        }
        int L = l;
        l = p; r = n - 1;
        // 右侧判定从真变假，找最后一个真
        while (l < r) {
            int m = (l + r + 1) / 2;
            if (suffix_lcp(a.start, sa_[m]) >= a.length) l = m;
            else r = m - 1;
        }
        return {L, l}; // SA 闭区间
    }
    // 静态次数不依赖 BIT；允许重叠出现
    int static_occurrence_count(SuffixArraySubstring a) const {
        auto [l,r] = matching_interval(a);
        return r - l + 1;
    }
    void add_start_weight(int p, long long x) { bit.add(rk[p], x); } // x 为增量
    // 仅统计已加权起点；初始为 0，闭区间转 BIT 的半开区间
    long long matching_weight(SuffixArraySubstring a) const {
        auto [l,r] = matching_interval(a);
        return bit.sum(l, r + 1);
    }
    const vector<int>& sa() const { return sa_; }
    const vector<int>& rank() const { return rk; }
};
using SuffixArrayApplications = SAQuery; // 保留旧调用名
```

预处理时间/空间 $O(n\log n)$，后缀 LCP、子串判等和比较为 $O(1)$。`matching_interval` 的二分判定只调用 $O(1)$ 的 LCP RMQ，所以总复杂度为 $O(\log n)$。静态出现次数为 `R-L+1`；动态权值查询在起点的 `rk[start]` 上单点修改，再对 `[L,R]` 求和，单次修改或查询为 $O(\log n)$。
