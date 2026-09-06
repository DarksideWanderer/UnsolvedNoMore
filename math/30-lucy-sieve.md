# 洲阁筛（Lucy DP）

洲阁筛直接计算所有质数不超过 $n$ 的数量与和。它只保留 $\lfloor n/i\rfloor$ 的不同取值，把 Eratosthenes 筛中的状态压缩到 $O(\sqrt n)$ 个。

初始时把 $2,3,\ldots,x$ 都视为候选：数量为 $x-1$、总和为 $x(x+1)/2-1$。处理质数 $p$ 时，删除由 $p$ 乘上“不小于 $p$ 的剩余候选”产生的合数。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

using i64 = long long;
using i128 = __int128_t;

class LucyPrimeSums {
    i64 maximum;
    vector<i64> values;
    unordered_map<i64, int> index_of;
    vector<i64> count_values;
    vector<i128> sum_values;

public:
    explicit LucyPrimeSums(i64 upper_bound) : maximum(upper_bound) {
        assert(upper_bound >= 1);
        for (i64 left = 1, right; left <= upper_bound; left = right + 1) {
            i64 value = upper_bound / left;
            right = upper_bound / value;
            index_of[value] = (int)values.size();
            values.push_back(value);
            count_values.push_back(value - 1);
            sum_values.push_back((i128)value * (value + 1) / 2 - 1);
        }

        for (i64 prime = 2; prime <= maximum / prime; ++prime) {
            if (prime_count_at(prime) == prime_count_at(prime - 1)) continue;
            i64 count_before = prime_count_at(prime - 1);
            i128 sum_before = prime_sum_at(prime - 1);
            i64 square = prime * prime;
            for (int index = 0;
                 index < (int)values.size() && values[index] >= square;
                 ++index) {
                i64 value = values[index];
                count_values[index] -=
                    prime_count_at(value / prime) - count_before;
                sum_values[index] -=
                    (i128)prime * (prime_sum_at(value / prime) - sum_before);
            }
        }
    }

    i64 prime_count_at(i64 value) const {
        if (value < 2) return 0;
        auto iterator = index_of.find(value);
        assert(iterator != index_of.end());
        return count_values[iterator->second];
    }

    i128 prime_sum_at(i64 value) const {
        if (value < 2) return 0;
        auto iterator = index_of.find(value);
        assert(iterator != index_of.end());
        return sum_values[iterator->second];
    }

    i64 prime_count() const { return prime_count_at(maximum); }
    i128 prime_sum() const { return prime_sum_at(maximum); }
};
```

`prime_count_at(x)` 和 `prime_sum_at(x)` 只允许查询构造过程中出现的 $x=\lfloor n/i\rfloor$（以及 $x<2$）；若只关心最终 $n$，调用无参数接口即可。

复杂度通常写作约 $O(n^{3/4}/\log n)$，空间 $O(\sqrt n)$。洲阁筛只得到**素数上的和**；Min_25 在它的结果上继续枚举质数幂，才得到一般积性函数的前缀和。
