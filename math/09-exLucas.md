# 扩展 Lucas：组合数模合数

计算 $\binom nk\bmod m$，其中 $m$ 不要求为质数。先把 $m$ 分解成若干互质的质数幂，对每个 $p^q$ 计算答案，再用 CRT 合并。

该实现需要为每个质数幂分配 $O(p^q)$ 空间，适合模数不大的竞赛题；若某个质数幂很大，应换分块乘积或题目特定算法。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

namespace composite_binomial {

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

class PrimePowerBinomial {
    i64 prime;
    i64 modulus;
    vector<i64> prefix_product;

    i64 prime_exponent_in_factorial(i64 value) const {
        i64 exponent = 0;
        while (value > 0) {
            value /= prime;
            exponent += value;
        }
        return exponent;
    }

    i64 factorial_without_prime(i64 value) const {
        if (value == 0) return 1;
        i64 complete_blocks =
            power_mod(prefix_product[modulus], value / modulus, modulus);
        i64 remainder = prefix_product[value % modulus];
        return multiply_mod(
            multiply_mod(complete_blocks, remainder, modulus),
            factorial_without_prime(value / prime), modulus);
    }

public:
    PrimePowerBinomial(i64 prime_factor, i64 prime_power)
        : prime(prime_factor), modulus(prime_power),
          prefix_product(prime_power + 1, 1) {
        for (i64 value = 1; value <= prime_power; ++value) {
            prefix_product[value] = prefix_product[value - 1];
            if (value % prime_factor != 0) {
                prefix_product[value] =
                    multiply_mod(prefix_product[value], value, prime_power);
            }
        }
    }

    i64 choose(i64 n, i64 k) const {
        if (k < 0 || k > n) return 0;
        i64 exponent = prime_exponent_in_factorial(n) -
                       prime_exponent_in_factorial(k) -
                       prime_exponent_in_factorial(n - k);
        i64 numerator = factorial_without_prime(n);
        i64 denominator = multiply_mod(
            factorial_without_prime(k),
            factorial_without_prime(n - k), modulus);
        i64 result = multiply_mod(
            numerator, modular_inverse(denominator, modulus), modulus);
        return multiply_mod(result, power_mod(prime, exponent, modulus),
                            modulus);
    }
};

i64 choose_mod_composite(i64 n, i64 k, i64 modulus) {
    assert(n >= 0 && modulus >= 1);
    if (modulus == 1) return 0;

    vector<pair<i64, i64>> congruences;
    i64 remaining = modulus;
    for (i64 prime = 2; prime <= remaining / prime; ++prime) {
        if (remaining % prime != 0) continue;
        i64 prime_power = 1;
        while (remaining % prime == 0) {
            remaining /= prime;
            prime_power *= prime;
        }
        PrimePowerBinomial calculator(prime, prime_power);
        congruences.push_back({calculator.choose(n, k), prime_power});
    }
    if (remaining > 1) {
        PrimePowerBinomial calculator(remaining, remaining);
        congruences.push_back({calculator.choose(n, k), remaining});
    }

    i64 result = 0;
    i64 current_modulus = 1;
    for (auto [remainder, next_modulus] : congruences) {
        i64 difference = (remainder - result) % next_modulus;
        if (difference < 0) difference += next_modulus;
        i64 multiplier = multiply_mod(
            difference,
            modular_inverse(current_modulus % next_modulus, next_modulus),
            next_modulus);
        result = (i64)((i128)current_modulus * multiplier + result);
        current_modulus *= next_modulus;
        result %= current_modulus;
    }
    return result;
}

} // namespace composite_binomial
```

单次预处理和空间复杂度为 $O(\sum p_i^{q_i})$，之后一次查询还需要 $O(\sum\log_{p_i}n)$ 次递归与快速幂。CRT 中间乘法使用 `__int128_t`，但最终模数仍要求能装入正的 `long long`。
