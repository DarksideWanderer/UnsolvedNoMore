# Z 函数

`z[i]` 是字符串与后缀 `text[i..]` 的最长公共前缀长度，约定 `z[0]=n`。

```cpp
#include <bits/stdc++.h>
using namespace std;

vector<int> z_function(const string& text) {
    int size = (int)text.size();
    vector<int> z(size);
    if (size == 0) return z;
    z[0] = size;
    for (int index = 1, left = 0, right = 0; index < size; ++index) {
        if (index <= right) {
            z[index] = min(right - index + 1, z[index - left]);
        }
        while (index + z[index] < size &&
               text[z[index]] == text[index + z[index]]) {
            ++z[index];
        }
        if (index + z[index] - 1 > right) {
            left = index;
            right = index + z[index] - 1;
        }
    }
    return z;
}
```

匹配模式串时可计算 `pattern + separator + text` 的 Z 函数；分隔符必须不出现在两串中。复杂度为 $O(n)$。

## 常见推论

设字符串长度为 $n$：

- 长度 $b$ 是 border，当且仅当 `z[n - b] >= b`；由于该后缀只有 $b$ 个字符，这里实际上必有等号。
- $p$ 是周期，当且仅当 `z[p] >= n - p`。从小到大找第一个满足者即可得到最小位移周期。
- 长度为 $length$ 的前缀在位置 `i` 出现，当且仅当 `z[i] >= length`；把所有 Z 值排序、做桶计数或离线查询，就能同时回答很多前缀出现次数。
- `i + z[i] == n` 的位置恰好对应一个 border，其长度为 `z[i]`。

KMP 更方便沿 border 链跳转并建立失配树；Z 函数更方便判断某个指定位置与整串前缀能匹配多长。周期问题中两者等价，选择能让后续统计更直接的一种即可。
