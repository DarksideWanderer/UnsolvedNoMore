# Stirling 数

本节固定采用以下符号：

- $\left[{n\atop k}\right]$ 是**无符号第一类 Stirling 数**，表示 $n$ 个元素的排列恰有 $k$ 个环的方案数；
- $\left\{{n\atop k}\right\}$ 是第二类 Stirling 数，表示把 $n$ 个不同元素划分成 $k$ 个非空无标号集合的方案数。

边界均为 $S(0,0)=1$，且 $n>0$ 时 $S(n,0)=0$。

Stirling 反演、幂和换基、Bell 数关系及配套计数公式见 `24-counting-formulas.md`。

## 递推、换基与生成函数

$$
\left[{n\atop k}\right]
=\left[{n-1\atop k-1}\right]
+(n-1)\left[{n-1\atop k}\right],
$$

$$
\left\{{n\atop k}\right\}
=\left\{{n-1\atop k-1}\right\}
+k\left\{{n-1\atop k}\right\}.
$$

无符号第一类对应**上升幂**，带符号第一类 $s(n,k)=(-1)^{n-k}\left[{n\atop k}\right]$ 才对应下降幂：

$$
x^{\overline n}=\sum_{k=0}^{n}\left[{n\atop k}\right]x^k,
\qquad
x^{\underline n}=\sum_{k=0}^{n}s(n,k)x^k,
$$

$$
x^n=\sum_{k=0}^{n}\left\{{n\atop k}\right\}x^{\underline k}.
$$

固定 $k$ 的指数生成函数为

$$
\sum_{n\ge k}\left[{n\atop k}\right]\frac{x^n}{n!}
=\frac{(-\ln(1-x))^k}{k!},
$$

$$
\sum_{n\ge k}\left\{{n\atop k}\right\}\frac{x^n}{n!}
=\frac{(e^x-1)^k}{k!}.
$$

## 模 998244353 快速计算

下面代码依赖 `16-polynomial.md` 的 `polynomial::multiply`、`power`、`mod_power`、`mod_inverse` 和 `mod`。

```cpp
namespace combinatorics {

using polynomial::mod;
using polynomial::mod_inverse;
using polynomial::mod_power;
using polynomial::multiply;
using polynomial::power;

struct Factorials {
    vector<int> factorial;
    vector<int> inverse_factorial;

    explicit Factorials(int maximum)
        : factorial(maximum + 1), inverse_factorial(maximum + 1) {
        assert(0 <= maximum && maximum < mod);
        factorial[0] = 1;
        for (int value = 1; value <= maximum; ++value) {
            factorial[value] =
                (int)((long long)factorial[value - 1] * value % mod);
        }
        inverse_factorial[maximum] = mod_inverse(factorial[maximum]);
        for (int value = maximum; value >= 1; --value) {
            inverse_factorial[value - 1] =
                (int)((long long)inverse_factorial[value] * value % mod);
        }
    }
};

vector<int> stirling_second_row(int n) {
    assert(n >= 0);
    Factorials values(n);
    vector<int> powers(n + 1);
    vector<int> alternating_inverse_factorial(n + 1);
    for (int index = 0; index <= n; ++index) {
        powers[index] = (int)((long long)mod_power(index, n) *
                              values.inverse_factorial[index] % mod);
        alternating_inverse_factorial[index] =
            index & 1 ? mod - values.inverse_factorial[index]
                      : values.inverse_factorial[index];
    }
    vector<int> result = multiply(powers, alternating_inverse_factorial);
    result.resize(n + 1);
    return result;
}

vector<int> rising_factorial(int left, int right) {
    if (left == right) return {1};
    if (left + 1 == right) return {left % mod, 1};
    int middle = left + (right - left) / 2;
    return multiply(rising_factorial(left, middle),
                    rising_factorial(middle, right));
}

vector<int> stirling_first_row(int n) {
    assert(n >= 0);
    return rising_factorial(0, n);
}

vector<int> stirling_second_column(int maximum_n, int k) {
    assert(0 <= k && k <= maximum_n && maximum_n < mod);
    Factorials values(maximum_n);
    vector<int> exponential_minus_one(maximum_n + 1);
    for (int degree = 1; degree <= maximum_n; ++degree) {
        exponential_minus_one[degree] = values.inverse_factorial[degree];
    }
    vector<int> generating_function =
        power(exponential_minus_one, k, maximum_n + 1);
    vector<int> result(maximum_n + 1);
    for (int n = 0; n <= maximum_n; ++n) {
        result[n] = (int)((long long)generating_function[n] *
                          values.factorial[n] % mod *
                          values.inverse_factorial[k] % mod);
    }
    return result;
}

vector<int> stirling_first_column(int maximum_n, int k) {
    assert(0 <= k && k <= maximum_n && maximum_n < mod);
    Factorials values(maximum_n);
    vector<int> negative_logarithm(maximum_n + 1);
    for (int degree = 1; degree <= maximum_n; ++degree) {
        negative_logarithm[degree] = mod_inverse(degree);
    }
    vector<int> generating_function =
        power(negative_logarithm, k, maximum_n + 1);
    vector<int> result(maximum_n + 1);
    for (int n = 0; n <= maximum_n; ++n) {
        result[n] = (int)((long long)generating_function[n] *
                          values.factorial[n] % mod *
                          values.inverse_factorial[k] % mod);
    }
    return result;
}

} // namespace combinatorics
```

复杂度：

- 第二类同一行使用显式公式
  $\left\{{n\atop k}\right\}=\sum_{i=0}^{k}(-1)^{k-i}i^n/(i!(k-i)!)$，只需一次卷积，为 $O(M(n))$；
- 第一类同一行计算 $x(x+1)\cdots(x+n-1)$，分治乘法为 $O(M(n)\log n)$；
- 固定一列使用 EGF 和 FPS 幂，为 $O(M(n))$ 量级。

当前 NTT 最长为 $2^{23}$，实际可计算规模还受卷积补零长度与内存限制。只求单个 $S(n,k)$ 且 $k$ 很小时，$O(nk)$ 递推通常更简单。

Bell 数满足 $B_n=\sum_k\left\{{n\atop k}\right\}$，EGF 为 $\exp(e^x-1)$。因此求一整段 Bell 数时，也可以先构造 `exponential_minus_one`，调用 `polynomial::exponential`，最后把第 $n$ 项乘以 $n!$。
