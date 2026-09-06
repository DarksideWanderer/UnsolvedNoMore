# 64 位 Miller–Rabin 素性测试

这组底数对所有 `uint64_t` 都是确定性的，不是概率测试。模乘使用 `__uint128_t`，避免 64 位乘法溢出。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

namespace number_theory {

using u64 = uint64_t;
using u128 = __uint128_t;

u64 multiply_mod(u64 lhs, u64 rhs, u64 modulus) {
    return (u64)((u128)lhs * rhs % modulus);
}

u64 power_mod(u64 base, u64 exponent, u64 modulus) {
    u64 result = 1 % modulus;
    while (exponent > 0) {
        if (exponent & 1) result = multiply_mod(result, base, modulus);
        base = multiply_mod(base, base, modulus);
        exponent >>= 1;
    }
    return result;
}

bool is_prime(u64 value) {
    if (value < 2) return false;
    for (u64 prime : {2ULL, 3ULL, 5ULL, 7ULL, 11ULL, 13ULL, 17ULL,
                      19ULL, 23ULL, 29ULL, 31ULL, 37ULL}) {
        if (value % prime == 0) return value == prime;
    }

    u64 odd_part = value - 1;
    int power_of_two = 0;
    while ((odd_part & 1) == 0) {
        odd_part >>= 1;
        ++power_of_two;
    }

    for (u64 base : {2ULL, 325ULL, 9375ULL, 28178ULL, 450775ULL,
                     9780504ULL, 1795265022ULL}) {
        if (base % value == 0) continue;
        u64 current = power_mod(base % value, odd_part, value);
        if (current == 1 || current == value - 1) continue;
        bool composite = true;
        for (int round = 1; round < power_of_two; ++round) {
            current = multiply_mod(current, current, value);
            if (current == value - 1) {
                composite = false;
                break;
            }
        }
        if (composite) return false;
    }
    return true;
}

} // namespace number_theory
```

复杂度为 $O(\log n)$ 次 128 位模乘。不要把待测的有符号负数直接转换为 `uint64_t`；应先在调用处排除负数。
