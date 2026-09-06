# 后缀自动机

固定小写字母表。状态 0 是初始状态；每次 `extend` 后的 `last` 表示整个当前字符串。不同子串数量为所有非初始状态的 `length-link.length` 之和。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class SuffixAutomaton {
public:
    struct State {
        array<int, 26> next{};
        int link = -1;
        int length = 0;
        long long occurrences = 0;
    };

private:
    vector<State> states;
    int last = 0;

public:
    SuffixAutomaton() {
        states.push_back(State{});
    }

    void extend(char character) {
        int letter = character - 'a';
        assert(0 <= letter && letter < 26);
        int current = (int)states.size();
        states.push_back(State{});
        states[current].length = states[last].length + 1;
        states[current].occurrences = 1;

        int prefix = last;
        while (prefix != -1 && states[prefix].next[letter] == 0) {
            states[prefix].next[letter] = current;
            prefix = states[prefix].link;
        }
        if (prefix == -1) {
            states[current].link = 0;
        } else {
            int target = states[prefix].next[letter];
            if (states[prefix].length + 1 == states[target].length) {
                states[current].link = target;
            } else {
                int clone = (int)states.size();
                states.push_back(states[target]);
                states[clone].length = states[prefix].length + 1;
                states[clone].occurrences = 0;
                while (prefix != -1 &&
                       states[prefix].next[letter] == target) {
                    states[prefix].next[letter] = clone;
                    prefix = states[prefix].link;
                }
                states[target].link = clone;
                states[current].link = clone;
            }
        }
        last = current;
    }

    long long distinct_substring_count() const {
        long long answer = 0;
        for (int state = 1; state < (int)states.size(); ++state) {
            answer += states[state].length -
                      states[states[state].link].length;
        }
        return answer;
    }

    vector<long long> occurrence_counts() const {
        vector<int> order(states.size());
        iota(order.begin(), order.end(), 0);
        sort(order.begin(), order.end(), [&](int lhs, int rhs) {
            return states[lhs].length > states[rhs].length;
        });
        vector<long long> count(states.size());
        for (int state = 0; state < (int)states.size(); ++state) {
            count[state] = states[state].occurrences;
        }
        for (int state : order) {
            if (states[state].link != -1) {
                count[states[state].link] += count[state];
            }
        }
        return count;
    }

    int transition(int state, char character) const {
        return states[state].next[character - 'a'];
    }

    int last_state() const {
        return last;
    }

    const vector<State>& data() const {
        return states;
    }
};
```

构造复杂度为 $O(n)$（上面的计数排序为简洁使用了比较排序，统计出现次数时为 $O(n\log n)$）。克隆状态的初始出现次数必须为 0。多个字符串的广义 SAM 不能简单地在每个字符串前把 `last` 设回根后直接套此模板；应先建 Trie，再按 BFS 扩展。

## 状态究竟表示什么

对一个子串 $t$，记 `endpos(t)` 为它在原串中所有出现位置的右端点集合。SAM 把 `endpos` 完全相同的子串放入同一个状态。对非根状态 $v$：

- `length[v]` 是该状态中最长子串的长度；
- 最短长度是 `length[link[v]] + 1`；
- 它恰好代表长度区间
  $$
  [\operatorname{length}(\operatorname{link}(v))+1,
    \operatorname{length}(v)]
  $$
  中的一段连续后缀，这些串的出现位置集合相同；
- 汇总后的 `occurrences[v]` 就是 `endpos` 大小，因此状态内所有子串出现次数相同；
- `endpos(v)\subseteq endpos(link[v])`。把后缀链接反向建边得到后缀链接树，祖先对应更短且出现位置更多的后缀类。

这解释了为什么每个状态贡献

```cpp
states[v].length - states[states[v].link].length
```

个不同子串，而不是只贡献一个。

## 常用结论

设 `count = automaton.occurrence_counts()`：

| 问题 | SAM 上的做法 |
|---|---|
| 模式是否为子串 | 从根沿字符转移；缺边即不存在 |
| 模式出现次数 | 走到状态 `v` 后答案为 `count[v]` |
| 不同子串数 | 对每个非根状态累加 `length[v] - length[link[v]]` |
| 新增一个字符产生多少新子串 | 本次新状态 `current` 贡献 `length[current] - length[link[current]]` |
| 至少出现 $k$ 次的最长子串 | 在 `count[v] >= k` 的状态中最大化 `length[v]` |
| 所有不同子串的长度和 | 对每个状态把最短到最长长度作等差数列求和 |
| 字典序第 $k$ 小不同子串 | 在转移 DAG 上统计每条出边后的路径数，再按字符贪心 |

所有不同子串长度之和可能达到 $\Theta(n^3)$，下面用 `__int128`：

```cpp
__int128 distinct_substring_length_sum(const SuffixAutomaton& automaton) {
    const auto& states = automaton.data();
    __int128 answer = 0;
    for (int state = 1; state < (int)states.size(); ++state) {
        long long low = states[states[state].link].length + 1;
        long long high = states[state].length;
        answer += (__int128)(low + high) * (high - low + 1) / 2;
    }
    return answer;
}

int longest_substring_appearing_at_least(
    const SuffixAutomaton& automaton,
    const vector<long long>& count, long long minimum_occurrences) {
    const auto& states = automaton.data();
    assert(count.size() == states.size());
    int answer = 0;
    for (int state = 1; state < (int)states.size(); ++state) {
        if (count[state] >= minimum_occurrences) {
            answer = max(answer, states[state].length);
        }
    }
    return answer;
}
```

## 与另一个串的最长公共子串

在 SAM 上扫描另一个串，维护当前状态和当前连续匹配长度。缺少转移时沿后缀链接缩短；这不是把状态直接重置为根，因为较短后缀仍可能继续匹配。

```cpp
string longest_common_substring(
    const SuffixAutomaton& automaton, string_view other) {
    const auto& states = automaton.data();
    int state = 0;
    int matched = 0;
    int best_length = 0;
    int best_end = -1;

    for (int index = 0; index < (int)other.size(); ++index) {
        int letter = other[index] - 'a';
        assert(0 <= letter && letter < 26);
        while (state != 0 && states[state].next[letter] == 0) {
            state = states[state].link;
            matched = states[state].length;
        }
        if (states[state].next[letter] != 0) {
            state = states[state].next[letter];
            ++matched;
        } else {
            matched = 0;
        }
        if (matched > best_length) {
            best_length = matched;
            best_end = index;
        }
    }
    return best_end == -1 ? string() :
        string(other.substr(best_end - best_length + 1, best_length));
}
```

多个串的最长公共子串：用第一个串建 SAM。对每个其余串按上面方法扫描，记录它在每个状态能匹配到的最大长度；再按 `length` 降序令

```cpp
best[link[v]] = max(best[link[v]], min(best[v], length[link[v]]));
```

最后对每个状态取所有字符串 `best` 的最小值，再在所有状态中取最大值。传播时必须截断到父状态的 `length`。

## 字典序第 k 小不同子串

从根出发的每条非空路径唯一对应一个不同子串。令 `paths[v]` 为从状态 `v` 出发能形成的非空字符串数，则

$$
\operatorname{paths}(v)=\sum_{v\xrightarrow{c}u}
\bigl(1+\operatorname{paths}(u)\bigr).
$$

转移一定走向 `length` 更大的状态，因此按 `length` 降序 DP。下面 `k` 从 1 开始，并把计数饱和在 `ULLONG_MAX`，避免只为比较大小而溢出。

```cpp
optional<string> kth_distinct_substring(
    const SuffixAutomaton& automaton, unsigned long long k) {
    using u64 = unsigned long long;
    if (k == 0) return nullopt;
    const auto& states = automaton.data();

    vector<int> order(states.size());
    iota(order.begin(), order.end(), 0);
    sort(order.begin(), order.end(), [&](int lhs, int rhs) {
        return states[lhs].length > states[rhs].length;
    });

    auto capped_add = [](u64 lhs, u64 rhs) {
        u64 maximum = numeric_limits<u64>::max();
        return maximum - lhs < rhs ? maximum : lhs + rhs;
    };
    vector<u64> paths(states.size());
    for (int state : order) {
        for (int next : states[state].next) {
            if (next == 0) continue;
            paths[state] = capped_add(
                paths[state], capped_add(1, paths[next]));
        }
    }
    if (k > paths[0]) return nullopt;

    string answer;
    int state = 0;
    while (true) {
        bool moved = false;
        for (int letter = 0; letter < 26; ++letter) {
            int next = states[state].next[letter];
            if (next == 0) continue;
            u64 block = capped_add(1, paths[next]);
            if (k > block) {
                k -= block;
                continue;
            }
            answer.push_back(char('a' + letter));
            if (k == 1) return answer;
            --k; // 跳过恰好等于当前 answer 的子串
            state = next;
            moved = true;
            break;
        }
        assert(moved);
    }
}
```

若按出现次数重复计算子串，则每条转移 `v -> u` 的当前字符串权重应从 `1` 改成 `count[u]`，并相应修改第 $k$ 小过程；不要把“不同子串”和“按出现次数计数”混用。

## 后缀链接树与出现位置

建串时每次 `extend` 后记录 `last_state()`，第 $i$ 个前缀状态代表结束位置 $i$。把这些位置挂到对应状态，再在后缀链接树上做子树汇总，就得到每个状态的全部 `endpos`：

- 只求出现次数：子树求和，也就是模板中的降序累加；
- 求某个子串第一次、最后一次出现：子树维护端点最小值、最大值；
- 限制右端点区间内的出现次数：对后缀链接树做 DFS 序，再离线使用树状数组，或为每个状态合并端点集合；
- 大量“子串在区间内是否出现”查询：常把端点放入可持久化线段树或合并线段树。

模式串走到状态 `v` 后，只有当模式长度位于该状态的合法长度区间内时，才能直接使用该状态的 `endpos` 信息；从根逐字符走完整模式时这个条件自然满足。
