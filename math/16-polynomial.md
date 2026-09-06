# NTT 与形式幂级数基础版

本模板固定模数为 $998244353=119\times2^{23}+1$，原根为 3，因此单次 NTT 长度不能超过 $2^{23}$。所有多项式按低次到高次存储，即 `a[i]` 是 $x^i$ 的系数。

本文件是赛场轻量版，只包含卷积、求导、积分、逆、对数、指数和非负整数幂。需要 FPS 开方、除法、多点求值/插值、Bostan--Mori、Taylor shift、多项式复合、幂投影或复合逆时，使用 `23-polynomial-advanced.md` 的自包含完整模板。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

namespace polynomial {

using i64 = long long;
constexpr int mod = 998244353;
constexpr int primitive_root = 3;

int mod_power(i64 base, i64 exponent) {
    i64 result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % mod;
        base = base * base % mod;
        exponent >>= 1;
    }
    return (int)result;
}

int mod_inverse(int value) {
    assert(value != 0);
    return mod_power(value, mod - 2);
}

void ntt(vector<int>& values, bool inverse) {
    int size = (int)values.size();
    assert(size > 0 && (size & (size - 1)) == 0);
    assert(size <= (1 << 23));

    for (int i = 1, reversed = 0; i < size; ++i) {
        int bit = size >> 1;
        while (reversed & bit) {
            reversed ^= bit;
            bit >>= 1;
        }
        reversed ^= bit;
        if (i < reversed) swap(values[i], values[reversed]);
    }

    for (int length = 2; length <= size; length <<= 1) {
        int root = mod_power(primitive_root, (mod - 1) / length);
        if (inverse) root = mod_inverse(root);
        for (int begin = 0; begin < size; begin += length) {
            i64 current_root = 1;
            for (int offset = 0; offset < length / 2; ++offset) {
                int even = values[begin + offset];
                int odd = (int)(values[begin + offset + length / 2] *
                                current_root % mod);
                values[begin + offset] = even + odd;
                if (values[begin + offset] >= mod) values[begin + offset] -= mod;
                values[begin + offset + length / 2] = even - odd;
                if (values[begin + offset + length / 2] < 0) {
                    values[begin + offset + length / 2] += mod;
                }
                current_root = current_root * root % mod;
            }
        }
    }

    if (inverse) {
        int size_inverse = mod_inverse(size);
        for (int& value : values) {
            value = (int)((i64)value * size_inverse % mod);
        }
    }
}

vector<int> multiply(vector<int> lhs, vector<int> rhs) {
    if (lhs.empty() || rhs.empty()) return {};
    int result_size = (int)lhs.size() + (int)rhs.size() - 1;
    if (min(lhs.size(), rhs.size()) <= 32) {
        vector<int> result(result_size);
        for (int i = 0; i < (int)lhs.size(); ++i) {
            for (int j = 0; j < (int)rhs.size(); ++j) {
                result[i + j] = (int)(
                    (result[i + j] + (i64)lhs[i] * rhs[j]) % mod);
            }
        }
        return result;
    }

    int ntt_size = 1;
    while (ntt_size < result_size) ntt_size <<= 1;
    lhs.resize(ntt_size);
    rhs.resize(ntt_size);
    ntt(lhs, false);
    ntt(rhs, false);
    for (int i = 0; i < ntt_size; ++i) {
        lhs[i] = (int)((i64)lhs[i] * rhs[i] % mod);
    }
    ntt(lhs, true);
    lhs.resize(result_size);
    return lhs;
}

vector<int> derivative(const vector<int>& poly) {
    if (poly.size() <= 1) return {};
    vector<int> result(poly.size() - 1);
    for (int i = 1; i < (int)poly.size(); ++i) {
        result[i - 1] = (int)((i64)poly[i] * i % mod);
    }
    return result;
}

vector<int> integral(const vector<int>& poly) {
    vector<int> result(poly.size() + 1);
    for (int i = 0; i < (int)poly.size(); ++i) {
        result[i + 1] = (int)((i64)poly[i] * mod_inverse(i + 1) % mod);
    }
    return result;
}

vector<int> inverse(const vector<int>& poly, int result_size) {
    assert(result_size >= 1);
    assert(!poly.empty() && poly[0] != 0);
    vector<int> result{mod_inverse(poly[0])};
    for (int length = 2; length < 2 * result_size; length <<= 1) {
        int current_size = min(length, result_size);
        vector<int> prefix(min((int)poly.size(), current_size));
        copy(poly.begin(), poly.begin() + prefix.size(), prefix.begin());
        vector<int> product = multiply(prefix, result);
        product.resize(current_size);
        for (int& value : product) {
            if (value != 0) value = mod - value;
        }
        product[0] = (product[0] + 2) % mod;
        result = multiply(result, product);
        result.resize(current_size);
    }
    result.resize(result_size);
    return result;
}

vector<int> logarithm(const vector<int>& poly, int result_size) {
    assert(result_size >= 1);
    assert(!poly.empty() && poly[0] == 1);
    vector<int> result = multiply(derivative(poly), inverse(poly, result_size));
    if ((int)result.size() >= result_size) result.resize(result_size - 1);
    result = integral(result);
    result.resize(result_size);
    return result;
}

vector<int> exponential(const vector<int>& poly, int result_size) {
    assert(result_size >= 1);
    assert(poly.empty() || poly[0] == 0);
    vector<int> result{1};
    for (int length = 2; length < 2 * result_size; length <<= 1) {
        int current_size = min(length, result_size);
        vector<int> difference(current_size);
        copy(poly.begin(), poly.begin() + min((int)poly.size(), current_size),
             difference.begin());
        vector<int> result_log = logarithm(result, current_size);
        for (int i = 0; i < current_size; ++i) {
            difference[i] -= result_log[i];
            if (difference[i] < 0) difference[i] += mod;
        }
        difference[0] = (difference[0] + 1) % mod;
        result = multiply(result, difference);
        result.resize(current_size);
    }
    result.resize(result_size);
    return result;
}

vector<int> power(const vector<int>& poly, i64 exponent, int result_size) {
    assert(exponent >= 0);
    vector<int> result(result_size);
    if (result_size == 0) return result;
    if (exponent == 0) {
        result[0] = 1;
        return result;
    }

    int first_nonzero = 0;
    while (first_nonzero < (int)poly.size() && poly[first_nonzero] == 0) {
        ++first_nonzero;
    }
    if (first_nonzero == (int)poly.size() ||
        first_nonzero > (result_size - 1) / exponent) {
        return result;
    }

    int shift = (int)(first_nonzero * exponent);
    int remaining_size = result_size - shift;
    int leading = poly[first_nonzero];
    int leading_inverse = mod_inverse(leading);
    vector<int> normalized(min((int)poly.size() - first_nonzero, remaining_size));
    for (int i = 0; i < (int)normalized.size(); ++i) {
        normalized[i] =
            (int)((i64)poly[first_nonzero + i] * leading_inverse % mod);
    }

    vector<int> normalized_log = logarithm(normalized, remaining_size);
    int reduced_exponent = (int)(exponent % mod);
    for (int& value : normalized_log) {
        value = (int)((i64)value * reduced_exponent % mod);
    }
    vector<int> powered = exponential(normalized_log, remaining_size);
    int leading_power = mod_power(leading, exponent);
    for (int i = 0; i < remaining_size; ++i) {
        result[i + shift] = (int)((i64)powered[i] * leading_power % mod);
    }
    return result;
}

} // namespace polynomial
```

## 前置条件与复杂度

- `inverse(a, n)` 要求 $a_0\ne0$，返回 $a^{-1}\bmod x^n$。
- `logarithm(a, n)` 要求 $a_0=1$。
- `exponential(a, n)` 要求 $a_0=0$。
- `power(a, k, n)` 支持 $k\ge0$，包括前导零多项式。
- 乘法复杂度为 $O(n\log n)$；逆、对数、指数和幂均为 $O(n\log n)$，常数不同。

比赛中不要把普通整数负数直接存入系数数组；先执行 `(value % mod + mod) % mod`。积分要求次数小于模数，否则分母可能在模意义下不可逆。
