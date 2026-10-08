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
    // 精确内容键：(长度,匹配区间左端点)，O(log n)；空串统一为 (0,0)
    pair<int,int> key(SuffixArraySubstring a) const {
        if (!a.length) return {0,0};
        return {a.length, matching_interval(a).first};
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

## 用 map 统计插入子串的精确次数（step2）

要统计的是“之前插入的子串中，有多少个与查询串内容和长度完全相同”，用上面的 `key`。同长度的相同子串拥有相同 SA 区间；反过来，同长度且左端点相同，它们就是那个后缀的同长度前缀。因此 `(length,L)` 是确定性内容键。不同位置的相同内容会合并；键只在**同一份固定原串的 SA** 内有效，不能跨两份 SA 比较。

```cpp
struct SubstrCount {
    const SAQuery& sa; // sa 必须比计数器活得久，使用期间不能重建/移动
    map<pair<int,int>, long long> cnt;
    explicit SubstrCount(const SAQuery& a) : sa(a) {}

    // 插入一个指定起点、长度的子串；x=-1 可删除一次，允许一般权重
    void add(SuffixArraySubstring a, long long x = 1) {
        auto k = sa.key(a);
        auto& v = cnt[k];
        v += x;
        if (!v) cnt.erase(k);
    }
    // 只查完全相同的插入项；不存在时返回 0，不创建新的 map 项
    long long get(SuffixArraySubstring a) const {
        auto it = cnt.find(sa.key(a));
        return it == cnt.end() ? 0 : it->second;
    }
};
```

`SubstrCount cnt(saq)` 在 `step2` 循环外建一次；查询为 `cnt.get({pos[i].back(),d})`，插入为 `cnt.add({pos[i][d-1],d})`。这里 `d` 必须是插入/查询子串各自的真实长度，不能只传起点。同一轮应先查询再插入，避免把当前项统计为之前的项。清空时用 `cnt.cnt.clear()`。

若直接写 `map`，就是 `map<pair<int,int>,long long> cnt`，插入 `++cnt[saq.key({p,len})]`、查询 `cnt[saq.key({q,len})]`；注意 `operator[]` 的查询会把不存在的键也插入，封装中的 `get` 用 `find` 避免这一点。已算好的键可以缓存，之后单次 map 操作仅为 $O(\log(M+1))$。

不缓存键时，单次增量/查询为 $O(\log(n+1)+\log(M+1))$，map 额外空间为 $O(M)$，`M` 是当前非零权重的不同内容数。空串计数在这里仅来自显式插入空串，不自动等于原串的 `n+1` 个边界。键的默认顺序先比较长度，不是子串字典序；需要字典序时仍用 `SAQuery::compare`。

**不能用 LCP 恰好等于 len 替代插入长度等于 len。** 例如原串 `aba#abb`，插入 `{4,3}` 即 `abb`，查询 `{0,2}` 即 `ab`：完整后缀的 LCP 恰好为 2，但精确计数必须返回 0。即使“LCP 至少 len 减去 LCP 大于 len”能正确统计 LCP 等于 len，也没有记录插入项长度。

三种计数必须区分：`static_occurrence_count` 是原串中的全部出现次数；`matching_weight` 是已加权起点的后缀前缀匹配；`SubstrCount::get` 才是插入子串多重集的精确次数。BIT 从未记录插入长度，不能在查询时推回它。
