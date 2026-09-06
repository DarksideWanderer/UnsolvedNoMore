# 线性递推

若

$$
a_n=c_1a_{n-1}+c_2a_{n-2}+\cdots+c_ka_{n-k},
$$

则特征多项式给出 $x^k\equiv c_1x^{k-1}+\cdots+c_k$。对 $x^n$ 快速幂并始终模该多项式，可在 $O(k^2\log n)$ 内求第 $n$ 项。

## 已知递推求第 n 项

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

using i64 = long long;
using u64 = unsigned long long;

vector<int> combine_recurrence(const vector<int>& lhs,
                               const vector<int>& rhs,
                               const vector<int>& recurrence,
                               int modulus) {
    int order = (int)recurrence.size();
    vector<int> product(2 * order - 1);
    for (int i = 0; i < order; ++i) {
        for (int j = 0; j < order; ++j) {
            product[i + j] = (int)(
                (product[i + j] + (i64)lhs[i] * rhs[j]) % modulus);
        }
    }
    for (int degree = 2 * order - 2; degree >= order; --degree) {
        for (int step = 1; step <= order; ++step) {
            product[degree - step] = (int)(
                (product[degree - step] +
                 (i64)product[degree] * recurrence[step - 1]) % modulus);
        }
    }
    product.resize(order);
    return product;
}

int linear_recurrence_nth(const vector<int>& initial,
                          const vector<int>& recurrence,
                          u64 index, int modulus) {
    int order = (int)recurrence.size();
    assert(order > 0 && (int)initial.size() >= order);
    if (index < initial.size()) return initial[(size_t)index];

    vector<int> result(order);
    vector<int> base(order);
    result[0] = 1;
    if (order == 1) base[0] = recurrence[0];
    else base[1] = 1;
    while (index > 0) {
        if (index & 1) {
            result = combine_recurrence(result, base, recurrence, modulus);
        }
        base = combine_recurrence(base, base, recurrence, modulus);
        index >>= 1;
    }

    i64 answer = 0;
    for (int position = 0; position < order; ++position) {
        answer = (answer + (i64)result[position] * initial[position]) % modulus;
    }
    return (int)answer;
}
```

`initial[i]=a_i`，`recurrence[j]=c_{j+1}`。输入系数必须正规化到 $[0,modulus)$。若 $k$ 很大且模数支持 NTT，可进一步用多项式取模或 Bostan–Mori 降低复杂度。

## Berlekamp--Massey

给出模质数域上的若干前缀项，BM 返回能够生成该前缀的最短线性递推。一般需要至少约两倍真实阶数的可靠项；短前缀上得到的递推可能不能预测后续。

```cpp
int recurrence_power_mod(i64 base, i64 exponent, int prime) {
    i64 result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % prime;
        base = base * base % prime;
        exponent >>= 1;
    }
    return (int)result;
}

vector<int> berlekamp_massey(const vector<int>& sequence, int prime) {
    vector<int> connection{1};
    vector<int> previous{1};
    int order = 0;
    int shift = 1;
    int previous_discrepancy = 1;

    for (int index = 0; index < (int)sequence.size(); ++index) {
        i64 discrepancy = sequence[index];
        for (int i = 1; i <= order; ++i) {
            discrepancy += (i64)connection[i] * sequence[index - i];
            discrepancy %= prime;
        }
        if (discrepancy == 0) {
            ++shift;
            continue;
        }

        vector<int> old_connection = connection;
        int scale = (int)(discrepancy *
            recurrence_power_mod(previous_discrepancy, prime - 2, prime) %
            prime);
        if (connection.size() < previous.size() + (size_t)shift) {
            connection.resize(previous.size() + shift);
        }
        for (int i = 0; i < (int)previous.size(); ++i) {
            connection[i + shift] = (int)(
                (connection[i + shift] - (i64)scale * previous[i]) % prime);
            if (connection[i + shift] < 0) connection[i + shift] += prime;
        }

        if (2 * order <= index) {
            order = index + 1 - order;
            previous = move(old_connection);
            previous_discrepancy = (int)discrepancy;
            shift = 1;
        } else {
            ++shift;
        }
    }

    connection.resize(order + 1);
    connection.erase(connection.begin());
    for (int& coefficient : connection) {
        if (coefficient != 0) coefficient = prime - coefficient;
    }
    return connection;
}
```

全零序列会得到空递推；调用 `linear_recurrence_nth` 前应单独返回 0。BM 使用逆元，因此要求模数为质数（更一般地，所有非零差异都必须可逆）。
