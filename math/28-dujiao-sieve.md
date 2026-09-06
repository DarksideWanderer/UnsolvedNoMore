# 杜教筛

杜教筛适合求积性函数的前缀和，前提是能快速计算它与另一个函数 Dirichlet 卷积后的前缀和。最常用的是

$$
\varphi * 1=\operatorname{id},
\qquad
\mu * 1=\varepsilon.
$$

令 $S_f(n)=\sum_{i\le n}f(i)$，把卷积按 $\lfloor n/i\rfloor$ 相同的整除块分组，可递归计算 $S_\varphi,S_\mu$。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

using i64 = long long;
using i128 = __int128_t;

class DujiaoSieve {
    int limit;
    vector<int> primes;
    vector<int> least_prime;
    vector<i64> phi;
    vector<int> mobius;
    vector<i128> prefix_phi;
    vector<i64> prefix_mobius;
    unordered_map<i64, i128> phi_cache;
    unordered_map<i64, i64> mobius_cache;

public:
    explicit DujiaoSieve(int sieve_limit)
        : limit(sieve_limit), least_prime(sieve_limit + 1),
          phi(sieve_limit + 1), mobius(sieve_limit + 1),
          prefix_phi(sieve_limit + 1), prefix_mobius(sieve_limit + 1) {
        assert(sieve_limit >= 1);
        phi[1] = 1;
        mobius[1] = 1;
        for (int value = 2; value <= limit; ++value) {
            if (least_prime[value] == 0) {
                least_prime[value] = value;
                primes.push_back(value);
                phi[value] = value - 1;
                mobius[value] = -1;
            }
            for (int prime : primes) {
                if (prime > limit / value) break;
                int product = value * prime;
                least_prime[product] = prime;
                if (value % prime == 0) {
                    phi[product] = phi[value] * prime;
                    mobius[product] = 0;
                    break;
                }
                phi[product] = phi[value] * (prime - 1);
                mobius[product] = -mobius[value];
            }
        }
        for (int value = 1; value <= limit; ++value) {
            prefix_phi[value] = prefix_phi[value - 1] + phi[value];
            prefix_mobius[value] = prefix_mobius[value - 1] + mobius[value];
        }
    }

    i128 sum_phi(i64 n) {
        if (n <= limit) return prefix_phi[(int)n];
        if (auto iterator = phi_cache.find(n); iterator != phi_cache.end()) {
            return iterator->second;
        }
        i128 result = (i128)n * (n + 1) / 2;
        for (i64 left = 2, right; left <= n; left = right + 1) {
            i64 quotient = n / left;
            right = n / quotient;
            result -= (i128)(right - left + 1) * sum_phi(quotient);
        }
        phi_cache[n] = result;
        return result;
    }

    i64 sum_mobius(i64 n) {
        if (n <= limit) return prefix_mobius[(int)n];
        if (auto iterator = mobius_cache.find(n);
            iterator != mobius_cache.end()) return iterator->second;
        i128 result = 1;
        for (i64 left = 2, right; left <= n; left = right + 1) {
            i64 quotient = n / left;
            right = n / quotient;
            result -= (i128)(right - left + 1) * sum_mobius(quotient);
        }
        assert(result >= numeric_limits<i64>::min() &&
               result <= numeric_limits<i64>::max());
        mobius_cache[n] = (i64)result;
        return (i64)result;
    }
};
```

取预处理阈值约 $n^{2/3}$ 时，经典复杂度约为 $O(n^{2/3})$，实际也常按内存与询问次数调整。`sum_phi` 使用 `i128`，因为结果量级为 $n^2$；`sum_mobius` 返回 `i64`，递推中的“块长乘前缀和”仍用 `i128` 暂存。
