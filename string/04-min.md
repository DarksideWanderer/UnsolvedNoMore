# 字符串最小表示法

返回循环同构中字典序最小的旋转起点；若有多个相同答案，返回最小下标。复杂度为 $O(n)$。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

int minimum_rotation(const string& text) {
    int size = (int)text.size();
    if (size == 0) return 0;
    int lhs = 0;
    int rhs = 1;
    int matched = 0;
    while (lhs < size && rhs < size && matched < size) {
        char lhs_char = text[(lhs + matched) % size];
        char rhs_char = text[(rhs + matched) % size];
        if (lhs_char == rhs_char) {
            ++matched;
            continue;
        }
        if (lhs_char > rhs_char) {
            lhs += matched + 1;
            if (lhs == rhs) ++lhs;
        } else {
            rhs += matched + 1;
            if (lhs == rhs) ++rhs;
        }
        matched = 0;
    }
    return min(lhs, rhs);
}
```
