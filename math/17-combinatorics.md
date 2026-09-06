# 组合数学基础

本节默认模数是质数，且预处理上界严格小于模数。若上界达到或超过模数，阶乘会变成 0，不能再用阶乘逆元；应改用 Lucas、扩展 Lucas 或题目特定方法。

本文件保存可直接复制的基础代码；更完整的组合恒等式、插板与上下界、容斥、Catalan/反射、各类反演、整数分拆以及 Burnside--Pólya 见 `24-counting-formulas.md`。

## 阶乘、组合数与排列数

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

using i64 = long long;

class PrimeCombinations {
    int prime;
    vector<int> factorial;
    vector<int> inverse_factorial;

    int power_mod(i64 base, i64 exponent) const {
        i64 result = 1;
        while (exponent > 0) {
            if (exponent & 1) result = result * base % prime;
            base = base * base % prime;
            exponent >>= 1;
        }
        return (int)result;
    }

public:
    PrimeCombinations(int maximum, int prime_modulus)
        : prime(prime_modulus), factorial(maximum + 1),
          inverse_factorial(maximum + 1) {
        assert(0 <= maximum && maximum < prime_modulus);
        factorial[0] = 1;
        for (int value = 1; value <= maximum; ++value) {
            factorial[value] =
                (int)((i64)factorial[value - 1] * value % prime_modulus);
        }
        inverse_factorial[maximum] =
            power_mod(factorial[maximum], prime_modulus - 2);
        for (int value = maximum; value >= 1; --value) {
            inverse_factorial[value - 1] =
                (int)((i64)inverse_factorial[value] * value % prime_modulus);
        }
    }

    int choose(int n, int k) const {
        if (k < 0 || k > n) return 0;
        assert(n < (int)factorial.size());
        return (int)((i64)factorial[n] * inverse_factorial[k] % prime *
                     inverse_factorial[n - k] % prime);
    }

    int permutations(int n, int k) const {
        if (k < 0 || k > n) return 0;
        assert(n < (int)factorial.size());
        return (int)((i64)factorial[n] * inverse_factorial[n - k] % prime);
    }

    int multiset_choose(int types, int count) const {
        if (count < 0 || types < 0) return 0;
        if (types == 0) return count == 0;
        return choose(types + count - 1, count);
    }

    int catalan(int n) const {
        assert(2 * n < (int)factorial.size());
        int answer = choose(2 * n, n) - choose(2 * n, n - 1);
        if (answer < 0) answer += prime;
        return answer;
    }

    int fact(int n) const {
        return factorial[n];
    }

    int inv_fact(int n) const {
        return inverse_factorial[n];
    }
};

vector<int> derangements(int maximum, int modulus) {
    vector<int> result(maximum + 1);
    result[0] = 1 % modulus;
    if (maximum >= 1) result[1] = 0;
    for (int n = 2; n <= maximum; ++n) {
        result[n] = (int)((long long)(n - 1) *
                          (result[n - 1] + result[n - 2]) % modulus);
    }
    return result;
}
```

- `choose(n,k)` 计算 $\binom nk$；`permutations(n,k)` 计算下降阶乘 $n^{\underline{k}}$。
- `multiset_choose(m,n)=\binom{m+n-1}{n}` 是从 $m$ 类物品中可重复选 $n$ 个，也等价于把 $n$ 个相同物品放进 $m$ 个有标号盒子。
- `catalan(n)=\frac1{n+1}\binom{2n}{n}=\binom{2n}{n}-\binom{2n}{n-1}`。差值写法避免额外求逆，但仍要求预处理到 $2n$。
- 错排数满足 $D_0=1,D_1=0,D_n=(n-1)(D_{n-1}+D_{n-2})$。

Hockey-stick、Vandermonde、二项式反演等恒等式统一收录在 `24-counting-formulas.md`；本文件只保留可直接复制的组合数代码及其接口说明。
