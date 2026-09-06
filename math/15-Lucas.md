# Lucas 定理

模数必须是质数。预处理 $0,1,\ldots,p-1$ 的阶乘和逆阶乘后，可以在 $O(\log_p n)$ 内计算 $\binom nk\bmod p$。当 $p$ 太大、无法分配 $O(p)$ 空间时不应使用此版本。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

class LucasBinomial {
    using i64 = long long;

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

    int small_choose(int n, int k) const {
        if (k < 0 || k > n) return 0;
        return (int)((i64)factorial[n] * inverse_factorial[k] % prime *
                     inverse_factorial[n - k] % prime);
    }

public:
    explicit LucasBinomial(int prime_modulus)
        : prime(prime_modulus), factorial(prime_modulus),
          inverse_factorial(prime_modulus) {
        assert(prime_modulus >= 2);
        factorial[0] = 1;
        for (int value = 1; value < prime_modulus; ++value) {
            factorial[value] =
                (int)((i64)factorial[value - 1] * value % prime_modulus);
        }
        inverse_factorial[prime_modulus - 1] =
            power_mod(factorial[prime_modulus - 1], prime_modulus - 2);
        for (int value = prime_modulus - 1; value > 0; --value) {
            inverse_factorial[value - 1] =
                (int)((i64)inverse_factorial[value] * value % prime_modulus);
        }
    }

    int choose(i64 n, i64 k) const {
        if (k < 0 || k > n) return 0;
        i64 result = 1;
        while (n > 0 || k > 0) {
            result = result *
                     small_choose((int)(n % prime), (int)(k % prime)) %
                     prime;
            if (result == 0) return 0;
            n /= prime;
            k /= prime;
        }
        return (int)result;
    }
};
```

构造类之前必须确认 `prime` 确为质数；否则 Fermat 逆元和 Lucas 分解都不成立。
