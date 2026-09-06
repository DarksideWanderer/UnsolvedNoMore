# 回文自动机（PAM）

状态 0 表示长度为 $-1$ 的奇根，状态 1 表示长度为 0 的偶根。每加入一个字符，最多新建一个本质不同回文串状态。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class PalindromicTree {
public:
    struct Node {
        array<int, 26> next{};
        int fail = 0;
        int length = 0;
        long long occurrences = 0;
    };

private:
    vector<Node> nodes;
    string text;
    int last = 1;

    int suffix_link_candidate(int node, int position) const {
        while (position - nodes[node].length - 1 < 0 ||
               text[position - nodes[node].length - 1] != text[position]) {
            node = nodes[node].fail;
        }
        return node;
    }

public:
    PalindromicTree() : nodes(2) {
        nodes[0].length = -1;
        nodes[0].fail = 0;
        nodes[1].length = 0;
        nodes[1].fail = 0;
    }

    int add(char character) {
        int letter = character - 'a';
        assert(0 <= letter && letter < 26);
        text.push_back(character);
        int position = (int)text.size() - 1;
        int parent = suffix_link_candidate(last, position);
        if (nodes[parent].next[letter] == 0) {
            int created = (int)nodes.size();
            nodes.push_back(Node{});
            nodes[created].length = nodes[parent].length + 2;
            if (nodes[created].length == 1) {
                nodes[created].fail = 1;
            } else {
                int candidate =
                    suffix_link_candidate(nodes[parent].fail, position);
                nodes[created].fail = nodes[candidate].next[letter];
            }
            nodes[parent].next[letter] = created;
        }
        last = nodes[parent].next[letter];
        ++nodes[last].occurrences;
        return last;
    }

    vector<long long> occurrence_counts() const {
        vector<long long> count(nodes.size());
        for (int node = 0; node < (int)nodes.size(); ++node) {
            count[node] = nodes[node].occurrences;
        }
        for (int node = (int)nodes.size() - 1; node >= 2; --node) {
            count[nodes[node].fail] += count[node];
        }
        return count;
    }

    int distinct_palindrome_count() const {
        return (int)nodes.size() - 2;
    }

    const vector<Node>& data() const {
        return nodes;
    }
};
```

构造复杂度和空间复杂度均为 $O(n\lvert\Sigma\rvert)$ 的定长转移存储形式（小写字母下常数为 26）。统计总出现次数时必须按回文长度从长到短向 fail 汇总；状态创建顺序恰好满足这一点。
