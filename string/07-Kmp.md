# KMP

`prefix[i]` 是 `text[0..i]` 的最长真前后缀长度。

```cpp
#include <bits/stdc++.h>
using namespace std;

vector<int> prefix_function(const string& text) {
    vector<int> prefix(text.size());
    for (int index = 1; index < (int)text.size(); ++index) {
        int matched = prefix[index - 1];
        while (matched > 0 && text[index] != text[matched]) {
            matched = prefix[matched - 1];
        }
        if (text[index] == text[matched]) ++matched;
        prefix[index] = matched;
    }
    return prefix;
}

vector<int> kmp_search(const string& text, const string& pattern) {
    vector<int> positions;
    if (pattern.empty()) {
        for (int index = 0; index <= (int)text.size(); ++index) {
            positions.push_back(index);
        }
        return positions;
    }
    vector<int> prefix = prefix_function(pattern);
    int matched = 0;
    for (int index = 0; index < (int)text.size(); ++index) {
        while (matched > 0 && text[index] != pattern[matched]) {
            matched = prefix[matched - 1];
        }
        if (text[index] == pattern[matched]) ++matched;
        if (matched == (int)pattern.size()) {
            positions.push_back(index - matched + 1);
            matched = prefix[matched - 1];
        }
    }
    return positions;
}
```

复杂度为 $O(n+m)$，返回的匹配位置允许重叠。

## border、周期与失配树

长度为 $b$ 的 `border` 是同时为字符串真前缀和后缀的串。设整串长度为 $n$：

- 最长 border 长度是 `prefix[n - 1]`；所有 border 可从它开始反复令 `b = prefix[b - 1]` 得到。
- $p\in[1,n]$ 是一个周期（位移）当且仅当长度 $n-p$ 是 border；因此所有周期是 `n - b`，再加平凡周期 `n`。
- 最小位移周期是 `n - prefix[n - 1]`。若题目要求整串由某个块完整重复，则还必须满足 `n % period == 0`；不满足时最短重复块长度是 `n`。
- 若长度为 $n$ 的串同时有周期 $p,q$，且 $n\ge p+q-\gcd(p,q)$，Fine-Wilf 定理保证 $\gcd(p,q)$ 也是周期。

失配树把前缀长度 `0..n` 当作节点，长度 `length > 0` 的父亲是 `prefix[length - 1]`：

- 一个前缀的所有 border 正是它到根路径上的祖先；
- 节点 `u` 的子树对应所有“以长度 `u` 前缀为后缀”的字符串前缀，因此子树大小就是该前缀在整串中的出现次数；
- 两个前缀节点在失配树上的 LCA，是它们最长的公共 border（这里允许某个前缀本身）。

不用显式建树也能统计每个前缀的出现次数：先对每个位置 `i` 执行 `++count[prefix[i]]`，再让 `length` 从 `n` 降到 1，执行 `count[prefix[length - 1]] += count[length]`，最后给 `count[1..n]` 各加 1，补上前缀自身那次出现。

若要对大量字符做 KMP 转移，可以预处理状态 `matched = 0..m` 遇到每个字符后的新状态，得到失配自动机；状态间跳转仍然完全由 `prefix` 链决定。模式串自匹配、统计每个前缀出现次数、在失配树上做树上查询，是这棵树最常见的三类用途。
