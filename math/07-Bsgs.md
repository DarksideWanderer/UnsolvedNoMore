# BSGS 与扩展 BSGS

求最小非负整数 $x$ 使 $a^x\equiv b\pmod m$。扩展版本允许 $\gcd(a,m)\ne1$，无解返回 -1。下面实现约定 $1\le m\le 2^{63}-1$。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

namespace discrete_logarithm {

using i64 = long long;
using i128 = __int128_t;

i64 multiply_mod(i64 lhs, i64 rhs, i64 modulus) {
    return (i64)((i128)lhs * rhs % modulus);
}

i64 power_mod(i64 base, i64 exponent, i64 modulus) {
    i64 result = 1 % modulus;
    while (exponent > 0) {
        if (exponent & 1) result = multiply_mod(result, base, modulus);
        base = multiply_mod(base, base, modulus);
        exponent >>= 1;
    }
    return result;
}

i64 extended_gcd(i64 lhs, i64 rhs, i64& lhs_coefficient,
                 i64& rhs_coefficient) {
    if (rhs == 0) {
        lhs_coefficient = 1;
        rhs_coefficient = 0;
        return lhs;
    }
    i64 next_lhs = 0;
    i64 next_rhs = 0;
    i64 divisor = extended_gcd(rhs, lhs % rhs, next_lhs, next_rhs);
    lhs_coefficient = next_rhs;
    rhs_coefficient = next_lhs - lhs / rhs * next_rhs;
    return divisor;
}

i64 modular_inverse(i64 value, i64 modulus) {
    i64 coefficient = 0;
    i64 ignored = 0;
    i64 divisor = extended_gcd(value, modulus, coefficient, ignored);
    assert(divisor == 1);
    coefficient %= modulus;
    if (coefficient < 0) coefficient += modulus;
    return coefficient;
}

i64 bsgs_coprime(i64 base, i64 target, i64 modulus) {
    i64 block = (i64)ceill(sqrtl((long double)modulus));
    unordered_map<i64, i64> baby_step;
    baby_step.reserve((size_t)block * 2 + 1);
    i64 current = 1 % modulus;
    for (i64 exponent = 0; exponent < block; ++exponent) {
        baby_step.emplace(current, exponent);
        current = multiply_mod(current, base, modulus);
    }

    i64 inverse_block =
        modular_inverse(power_mod(base, block, modulus), modulus);
    current = target;
    for (i64 block_id = 0; block_id <= block; ++block_id) {
        auto found = baby_step.find(current);
        if (found != baby_step.end()) {
            return block_id * block + found->second;
        }
        current = multiply_mod(current, inverse_block, modulus);
    }
    return -1;
}

i64 extended_bsgs(i64 base, i64 target, i64 modulus) {
    assert(modulus >= 1);
    base %= modulus;
    target %= modulus;
    if (modulus == 1 || target == 1 % modulus) return 0;

    i64 removed_steps = 0;
    i64 accumulated = 1 % modulus;
    while (true) {
        i64 divisor = gcd(base, modulus);
        if (divisor == 1) break;
        if (target == accumulated) return removed_steps;
        if (target % divisor != 0) return -1;
        target /= divisor;
        modulus /= divisor;
        accumulated = multiply_mod(accumulated, base / divisor, modulus);
        ++removed_steps;
    }

    target = multiply_mod(target, modular_inverse(accumulated, modulus),
                          modulus);
    i64 remaining = bsgs_coprime(base % modulus, target, modulus);
    return remaining == -1 ? -1 : removed_steps + remaining;
}

} // namespace discrete_logarithm
```

时间和空间复杂度均为 $O(\sqrt m)$。哈希表可能被构造数据攻击；需要更稳定常数时可把 baby step 存入数组后排序，用二分查找代替 `unordered_map`。
