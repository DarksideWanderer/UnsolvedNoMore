# 广义后缀自动机

广义后缀自动机维护多个字符串的全部子串。这里先把所有字符串插入 Trie，再按 BFS 顺序把 Trie 边加入 SAM；这样不会产生跨越两个字符串边界的子串，也能正确处理重复字符串和公共前缀。

固定小写字母表，状态 0 是初始状态。必须先完成所有 `insert`，再调用一次 `build`。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class GeneralizedSuffixAutomaton {
public:
    struct State {
        array<int, 26> next{};
        int link = -1;
        int length = 0;
    };

private:
    struct TrieNode {
        array<int, 26> next{};
    };

    vector<TrieNode> trie{TrieNode{}};
    vector<State> states;
    bool built = false;

    int extend_from(int last, int letter) {
        int existing = states[last].next[letter];
        if (existing != 0) {
            if (states[last].length + 1 == states[existing].length) {
                return existing;
            }
            int clone = (int)states.size();
            states.push_back(states[existing]);
            states[clone].length = states[last].length + 1;
            int prefix = last;
            while (prefix != -1 &&
                   states[prefix].next[letter] == existing) {
                states[prefix].next[letter] = clone;
                prefix = states[prefix].link;
            }
            states[existing].link = clone;
            return clone;
        }

        int current = (int)states.size();
        states.push_back(State{});
        states[current].length = states[last].length + 1;
        int prefix = last;
        while (prefix != -1 && states[prefix].next[letter] == 0) {
            states[prefix].next[letter] = current;
            prefix = states[prefix].link;
        }
        if (prefix == -1) {
            states[current].link = 0;
            return current;
        }

        int target = states[prefix].next[letter];
        if (states[prefix].length + 1 == states[target].length) {
            states[current].link = target;
            return current;
        }

        int clone = (int)states.size();
        states.push_back(states[target]);
        states[clone].length = states[prefix].length + 1;
        while (prefix != -1 && states[prefix].next[letter] == target) {
            states[prefix].next[letter] = clone;
            prefix = states[prefix].link;
        }
        states[target].link = clone;
        states[current].link = clone;
        return current;
    }

public:
    void insert(const string& text) {
        assert(!built);
        int node = 0;
        for (char character : text) {
            int letter = character - 'a';
            assert(0 <= letter && letter < 26);
            if (trie[node].next[letter] == 0) {
                trie[node].next[letter] = (int)trie.size();
                trie.push_back(TrieNode{});
            }
            node = trie[node].next[letter];
        }
    }

    void build() {
        assert(!built);
        built = true;
        states = {State{}};
        vector<int> trie_state(trie.size());
        queue<int> que;
        que.push(0);
        while (!que.empty()) {
            int node = que.front();
            que.pop();
            for (int letter = 0; letter < 26; ++letter) {
                int child = trie[node].next[letter];
                if (child == 0) continue;
                trie_state[child] = extend_from(trie_state[node], letter);
                que.push(child);
            }
        }
    }

    bool contains(const string& pattern) const {
        assert(built);
        int state = 0;
        for (char character : pattern) {
            int letter = character - 'a';
            assert(0 <= letter && letter < 26);
            state = states[state].next[letter];
            if (state == 0) return false;
        }
        return true;
    }

    long long distinct_substring_count() const {
        assert(built);
        long long answer = 0;
        for (int state = 1; state < (int)states.size(); ++state) {
            answer += states[state].length -
                      states[states[state].link].length;
        }
        return answer;
    }

    vector<long long> occurrence_counts(
        const vector<string>& source_strings) const {
        assert(built);
        vector<long long> count(states.size());
        for (const string& text : source_strings) {
            int state = 0;
            for (char character : text) {
                int letter = character - 'a';
                assert(0 <= letter && letter < 26);
                state = states[state].next[letter];
                assert(state != 0);
                ++count[state];
            }
        }

        vector<int> order(states.size());
        iota(order.begin(), order.end(), 0);
        sort(order.begin(), order.end(), [&](int lhs, int rhs) {
            return states[lhs].length > states[rhs].length;
        });
        for (int state : order) {
            if (states[state].link != -1) {
                count[states[state].link] += count[state];
            }
        }
        return count;
    }

    long long occurrences_of(const string& pattern,
                             const vector<long long>& count) const {
        assert(built && count.size() == states.size());
        int state = 0;
        for (char character : pattern) {
            int letter = character - 'a';
            assert(0 <= letter && letter < 26);
            state = states[state].next[letter];
            if (state == 0) return 0;
        }
        return count[state];
    }

    const vector<State>& data() const {
        assert(built);
        return states;
    }
};
```

Trie 与 SAM 的状态数都是所有字符串总长度的 $O(\sum |s_i|)$ 量级，构造为线性复杂度（这里为固定 26 字母转移）。`distinct_substring_count` 统计所有字符串的非空子串并集。

出现次数必须在自动机构造完成后，把原字符串逐个从根重新扫描，再沿后缀链接按 `length` 降序累加；不能把 Trie 结点数或 SAM 克隆次数直接当成出现次数。`source_strings` 应与建 Trie 时的字符串集合一致，重复字符串会重复贡献出现次数。当前实现为简洁使用比较排序，因此出现次数统计为 $O(L\log L+\sum|s_i|)$。
