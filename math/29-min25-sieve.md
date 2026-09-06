# Min_25 筛：Euler φ 前缀和实例

Min_25 筛分两层：先对所有不同的 $\lfloor n/i\rfloor$ 求素数处的前缀和，再按最小质因子递归枚举质数幂，从素数扩展到整个积性函数。

通用 Min_25 需要题目给出 $f(p)$ 的低次多项式表示以及 $f(p^e)$。下面选择 $f=\varphi$ 给出完整实例：

$$
\varphi(p)=p-1,
\qquad
\varphi(p^e)=p^{e-1}(p-1).
$$

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

using i64 = long long;
using i128 = __int128_t;

class Min25PhiSummatory {
    i64 maximum;
    vector<int> primes;
    vector<i64> quotient_values;
    unordered_map<i64, int> quotient_index;
    vector<i64> prime_count_sieve;
    vector<i128> prime_sum_sieve;
    vector<i128> prefix_prime_phi;

    i128 prime_phi_sum(i64 value) const {
        auto iterator = quotient_index.find(value);
        assert(iterator != quotient_index.end());
        int index = iterator->second;
        return prime_sum_sieve[index] - prime_count_sieve[index];
    }

    i128 enumerate(i64 value, int first_prime) const {
        if (value < 2) return 0;

        i128 result = prime_phi_sum(value) - prefix_prime_phi[first_prime];
        if (first_prime >= (int)primes.size() ||
            primes[first_prime] > value) return result;
        for (int index = first_prime; index < (int)primes.size(); ++index) {
            i64 prime = primes[index];
            if (prime > value / prime) break;
            i64 power = prime;
            i128 phi_power = prime - 1;
            while (power <= value / prime) {
                i64 next_power = power * prime;
                i128 next_phi_power = phi_power * prime;
                result += phi_power * enumerate(value / power, index + 1) +
                          next_phi_power;
                power = next_power;
                phi_power = next_phi_power;
            }
        }
        return result;
    }

public:
    explicit Min25PhiSummatory(i64 upper_bound) : maximum(upper_bound) {
        assert(upper_bound >= 1);
        int square_root = (int)sqrtl((long double)upper_bound);
        while ((i64)(square_root + 1) <= upper_bound / (square_root + 1)) {
            ++square_root;
        }
        while ((i64)square_root > upper_bound / square_root) --square_root;

        vector<bool> composite(square_root + 1);
        for (int value = 2; value <= square_root; ++value) {
            if (!composite[value]) primes.push_back(value);
            for (int prime : primes) {
                if (prime > square_root / value) break;
                composite[value * prime] = true;
                if (value % prime == 0) break;
            }
        }

        prefix_prime_phi.assign(primes.size() + 1, 0);
        for (int index = 0; index < (int)primes.size(); ++index) {
            prefix_prime_phi[index + 1] =
                prefix_prime_phi[index] + primes[index] - 1;
        }

        for (i64 left = 1, right; left <= maximum; left = right + 1) {
            i64 value = maximum / left;
            right = maximum / value;
            quotient_index[value] = (int)quotient_values.size();
            quotient_values.push_back(value);
            prime_count_sieve.push_back(value - 1);
            prime_sum_sieve.push_back((i128)value * (value + 1) / 2 - 1);
        }

        i128 previous_prime_sum = 0;
        for (int prime_index = 0;
             prime_index < (int)primes.size(); ++prime_index) {
            i64 prime = primes[prime_index];
            i64 square = prime * prime;
            for (int index = 0;
                 index < (int)quotient_values.size() &&
                 quotient_values[index] >= square; ++index) {
                i64 value = quotient_values[index];
                int reduced = quotient_index.at(value / prime);
                prime_count_sieve[index] -=
                    prime_count_sieve[reduced] - prime_index;
                prime_sum_sieve[index] -=
                    (i128)prime *
                    (prime_sum_sieve[reduced] - previous_prime_sum);
            }
            previous_prime_sum += prime;
        }
    }

    i128 sum_phi() const {
        return 1 + enumerate(maximum, 0);
    }
};
```

`prime_count_sieve` 与 `prime_sum_sieve` 必须分开筛，最后才能相减得到 $\sum_{p\le x}(p-1)$；直接把 $p-1$ 当成完全积性函数做一张筛是错误的。

该实例的典型复杂度约为 $O(n^{3/4}/\log n)$，空间 $O(\sqrt n)$。只求 $\sum\varphi$ 时杜教筛通常更短；Min_25 的优势是处理那些素数处容易求和、但没有方便 Dirichlet 卷积递推的积性函数。

## 怎样改成其他积性函数

没有必要为了“通用”再包一层难以调试的回调类。迁移这份代码只需要替换三处数学量：

1. `prime_phi_sum(x)`：改成 $\sum_{p\le x}f(p)$。若 $f(p)$ 是 $p$ 的低次多项式，就像当前代码同时筛 $\sum1$ 和 $\sum p$ 一样，分别维护所需的 $\sum p^j$ 后线性组合。
2. `prefix_prime_phi[i]`：改成前 $i$ 个素数的 $f(p)$ 前缀和，递归时用它排除小于 `first_prime` 的素数。
3. `phi_power` 和 `next_phi_power`：分别改成 $f(p^e)$、$f(p^{e+1})$。递归式的结构不变。

常见替换如下：

| $f(n)$ | $f(p)$ | $f(p^e)$ | 素数前缀和需要什么 |
|---|---:|---:|---|
| $\mu(n)$ | $-1$ | $e=1$ 时 $-1$，否则 $0$ | $-\pi(x)$ |
| $d(n)$ | $2$ | $e+1$ | $2\pi(x)$ |
| $\sigma_k(n)$ | $1+p^k$ | $1+p^k+\cdots+p^{ek}$ | $\pi(x)+\sum_{p\le x}p^k$ |
| Jordan $J_k(n)$ | $p^k-1$ | $p^{k(e-1)}(p^k-1)$ | $\sum_{p\le x}p^k-\pi(x)$ |

最容易漏掉的是递归中的单独一项 `next_phi_power`：它表示只选择当前素数幂 $p^{e+1}$、后面不再乘其他素数的数。只保留递归乘积项会漏掉所有纯素数幂。若答案取模，筛表、素数前缀和和 `f(p^e)` 必须从头到尾使用同一个模数；若不取模，则先估计 $f(p^e)$ 和答案是否会超过 `i128`。
