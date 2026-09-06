# 双模字符串哈希

只保留最常用的功能：$O(n)$ 预处理，$O(1)$ 取得半开区间 `[left,right)` 的哈希。比较两个子串时直接比较 `get` 的返回值。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

struct StringHash {
    static constexpr int base = 911382323;
    static constexpr array<int, 2> mod{1000000007, 1000000009};

    array<vector<int>, 2> hash;
    array<vector<int>, 2> power;

    explicit StringHash(string_view text) {
        for (int k = 0; k < 2; ++k) {
            hash[k].resize(text.size() + 1);
            power[k].resize(text.size() + 1, 1);
            for (int i = 0; i < (int)text.size(); ++i) {
                int value = (unsigned char)text[i] + 1;
                hash[k][i + 1] = (int)(
                    ((long long)hash[k][i] * base + value) % mod[k]);
                power[k][i + 1] = (int)(
                    (long long)power[k][i] * base % mod[k]);
            }
        }
    }

    array<int, 2> get(int left, int right) const {
        assert(0 <= left && left <= right && right < (int)hash[0].size());
        array<int, 2> result{};
        for (int k = 0; k < 2; ++k) {
            long long value = hash[k][right] -
                (long long)hash[k][left] * power[k][right - left] % mod[k];
            if (value < 0) value += mod[k];
            result[k] = (int)value;
        }
        return result;
    }
};
```

同一组字符串必须使用相同的底数和模数。双模碰撞概率很低，但不是严格零；要求确定性时应使用后缀数组、Z/KMP 或自动机。字符按 `unsigned char` 编码，所以 UTF-8 中文按字节处理。

LCP 不需要写进结构体：对长度二分并比较两次 `get` 即可，复杂度 $O(\log n)$。拼接哈希的公式是 `left_hash * power[right_length] + right_hash`；只有题目确实需要拼接时再写两行，公共模板不为它增加接口。

本模板保留字符顺序。若题目需要集合切换、区间出现次数奇偶或图割中让内部边抵消，见 `13-xor-hash.md`；异或哈希不能替代这里的字符串哈希。
