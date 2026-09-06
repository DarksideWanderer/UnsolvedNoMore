# 线性筛与因数卷积

## 线性筛

一次预处理得到每个数的最小质因子、Möbius 函数和 Euler 函数。每个合数只由“当前数乘它的最小质因子”筛到一次，复杂度 $O(n)$。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

struct LinearSieve {
    vector<int> primes;
    vector<int> least_prime;
    vector<int> mobius;
    vector<int> phi;

    explicit LinearSieve(int maximum)
        : least_prime(maximum + 1), mobius(maximum + 1),
          phi(maximum + 1) {
        assert(maximum >= 1);
        mobius[1] = 1;
        phi[1] = 1;
        for (int value = 2; value <= maximum; ++value) {
            if (least_prime[value] == 0) {
                least_prime[value] = value;
                primes.push_back(value);
                mobius[value] = -1;
                phi[value] = value - 1;
            }
            for (int prime : primes) {
                if (prime > maximum / value) break;
                int product = value * prime;
                least_prime[product] = prime;
                if (value % prime == 0) {
                    mobius[product] = 0;
                    phi[product] = phi[value] * prime;
                    break;
                }
                mobius[product] = -mobius[value];
                phi[product] = phi[value] * (prime - 1);
            }
        }
    }
};
```

恒等式

$$
\sum_{d\mid n}\mu(d)=[n=1],
\qquad
\sum_{d\mid n}\varphi(d)=n
$$

是检查实现和推导 Möbius 反演时最常用的两条式子。

## 约数/倍数 Zeta 与 Möbius 变换

数组下标从 1 开始，0 号位置不使用。以下写法是 $O(n\log n)$ 的调和级数实现，输入系数应位于 $[0,modulus)$。

```cpp
void divisor_transform(vector<int>& values, bool inverse,
                       int modulus) {
    int maximum = (int)values.size() - 1;
    if (inverse) {
        for (int divisor = 1; divisor <= maximum; ++divisor) {
            for (int multiple = divisor * 2;
                 multiple <= maximum; multiple += divisor) {
                values[multiple] -= values[divisor];
                if (values[multiple] < 0) values[multiple] += modulus;
            }
        }
    } else {
        vector<int> source = values;
        fill(values.begin() + 1, values.end(), 0);
        for (int divisor = 1; divisor <= maximum; ++divisor) {
            for (int multiple = divisor;
                 multiple <= maximum; multiple += divisor) {
                values[multiple] += source[divisor];
                if (values[multiple] >= modulus) values[multiple] -= modulus;
            }
        }
    }
}

void multiple_transform(vector<int>& values, bool inverse,
                        int modulus) {
    int maximum = (int)values.size() - 1;
    if (inverse) {
        for (int divisor = maximum; divisor >= 1; --divisor) {
            for (int multiple = divisor * 2;
                 multiple <= maximum; multiple += divisor) {
                values[divisor] -= values[multiple];
                if (values[divisor] < 0) values[divisor] += modulus;
            }
        }
    } else {
        vector<int> source = values;
        fill(values.begin() + 1, values.end(), 0);
        for (int divisor = 1; divisor <= maximum; ++divisor) {
            for (int multiple = divisor;
                 multiple <= maximum; multiple += divisor) {
                values[divisor] += source[multiple];
                if (values[divisor] >= modulus) values[divisor] -= modulus;
            }
        }
    }
}

vector<int> lcm_convolution(vector<int> lhs, vector<int> rhs,
                            int modulus) {
    assert(lhs.size() == rhs.size());
    divisor_transform(lhs, false, modulus);
    divisor_transform(rhs, false, modulus);
    for (int value = 1; value < (int)lhs.size(); ++value) {
        lhs[value] = (int)((long long)lhs[value] * rhs[value] % modulus);
    }
    divisor_transform(lhs, true, modulus);
    return lhs;
}

vector<int> gcd_convolution(vector<int> lhs, vector<int> rhs,
                            int modulus) {
    assert(lhs.size() == rhs.size());
    multiple_transform(lhs, false, modulus);
    multiple_transform(rhs, false, modulus);
    for (int value = 1; value < (int)lhs.size(); ++value) {
        lhs[value] = (int)((long long)lhs[value] * rhs[value] % modulus);
    }
    multiple_transform(lhs, true, modulus);
    return lhs;
}
```

方向不要记反：

- `lcm(i,j) | n` 当且仅当 `i | n` 且 `j | n`，所以 LCM 卷积使用**约数** Zeta；
- `n | gcd(i,j)` 当且仅当 `n | i` 且 `n | j`，所以 GCD 卷积使用**倍数** Zeta。

卷积结果只统计下标不超过数组上界的项。若真实 LCM 可能超过上界，那些项会被截掉；GCD 不存在这个越界问题。
