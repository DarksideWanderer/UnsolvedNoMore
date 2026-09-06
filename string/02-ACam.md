# AC 自动机

固定小写字母表。`insert` 返回模式串的终止状态；相同模式串会得到同一个终止状态。`count_occurrences` 返回每个状态代表的模式在文本中的出现次数，允许重叠。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class AhoCorasick {
    struct Node {
        array<int, 26> next{};
        int fail = 0;
    };

    vector<Node> nodes{Node{}};
    vector<int> bfs_order;
    bool built = false;

public:
    int insert(const string& pattern) {
        assert(!built);
        int node = 0;
        for (char character : pattern) {
            int letter = character - 'a';
            assert(0 <= letter && letter < 26);
            if (nodes[node].next[letter] == 0) {
                nodes[node].next[letter] = (int)nodes.size();
                nodes.push_back(Node{});
            }
            node = nodes[node].next[letter];
        }
        return node;
    }

    void build() {
        assert(!built);
        built = true;
        queue<int> que;
        for (int letter = 0; letter < 26; ++letter) {
            int child = nodes[0].next[letter];
            if (child != 0) que.push(child);
        }
        while (!que.empty()) {
            int node = que.front();
            que.pop();
            bfs_order.push_back(node);
            for (int letter = 0; letter < 26; ++letter) {
                int child = nodes[node].next[letter];
                if (child != 0) {
                    nodes[child].fail =
                        nodes[nodes[node].fail].next[letter];
                    que.push(child);
                } else {
                    nodes[node].next[letter] =
                        nodes[nodes[node].fail].next[letter];
                }
            }
        }
    }

    vector<long long> count_occurrences(const string& text) const {
        assert(built);
        vector<long long> count(nodes.size());
        int node = 0;
        for (char character : text) {
            int letter = character - 'a';
            assert(0 <= letter && letter < 26);
            node = nodes[node].next[letter];
            ++count[node];
        }
        for (auto iterator = bfs_order.rbegin();
             iterator != bfs_order.rend(); ++iterator) {
            int state = *iterator;
            count[nodes[state].fail] += count[state];
        }
        return count;
    }
};
```

构建和查询总复杂度为 $O(\sum |pattern|+|text|+26\times states)$。空模式串的终止状态是根，其出现次数定义需按题意单独处理。
