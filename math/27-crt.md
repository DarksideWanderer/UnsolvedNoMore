# 线性同余方程组与 exCRT

目标是求任意方程组

$$
a_i x\equiv b_i\pmod{m_i},\qquad m_i>0.
$$

每条方程不能直接当成 $x\equiv b_i\pmod{m_i}$。必须先令 $g=\gcd(a_i,m_i)$：若 $g\nmid b_i$，则整组无解；否则约去 $g$，把它化为一个标准剩余类，再用 exCRT 逐项合并。

下面的接口返回最小非负解。所有需要长期保存的数据都是 `long long`，乘法、差值和合并过程使用 `__int128` 暂存。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

using i64 = long long;
using i128 = __int128_t;

enum class CRTStatus {
    NoSolution,  // 方程组无解
    Success,     // 最小非负解不超过调用者给定上界
    TooLarge     // 最小解超过上界，或合并后的模数无法用 i64 保存
};

struct Congruence {
    i64 a;
    i64 b;
    i64 m;
};

struct CRTResult {
    CRTStatus status;
    i64 r;
    i64 mod;
};

struct ExgcdResult {
    i64 gcd;
    i64 x;
    i64 y;
};

// 要求 a,b >= 0；返回 ax+by=gcd(a,b)。
ExgcdResult exgcd(i64 a, i64 b) {
    assert(a >= 0 && b >= 0 && (a != 0 || b != 0));
    i64 old_remainder = a;
    i64 remainder = b;
    i128 old_x = 1, x = 0;
    i128 old_y = 0, y = 1;

    while (remainder != 0) {
        i64 quotient = old_remainder / remainder;
        i64 next_remainder = old_remainder % remainder;
        i128 next_x = old_x - (i128)quotient * x;
        i128 next_y = old_y - (i128)quotient * y;
        old_remainder = remainder;
        remainder = next_remainder;
        old_x = x;
        x = next_x;
        old_y = y;
        y = next_y;
    }

    assert(numeric_limits<i64>::min() <= old_x &&
           old_x <= numeric_limits<i64>::max());
    assert(numeric_limits<i64>::min() <= old_y &&
           old_y <= numeric_limits<i64>::max());
    return {old_remainder, (i64)old_x, (i64)old_y};
}

// C++ 的负数 % 正数仍可能为负，统一规范到 [0,mod)。
i64 normalize_mod(i128 value, i64 mod) {
    assert(mod > 0);
    value %= mod;
    if (value < 0) value += mod;
    return (i64)value;
}

struct ResidueClass {
    i64 r;
    i64 mod;
};

// 把 ax=b (mod m) 化成 x=r (mod mod)。nullopt 表示无解。
optional<ResidueClass> reduce_linear_congruence(const Congruence& equation) {
    assert(equation.m > 0);
    i64 a = normalize_mod(equation.a, equation.m);
    i64 b = normalize_mod(equation.b, equation.m);
    i64 gcd = std::gcd(a, equation.m);
    if (b % gcd != 0) return nullopt;

    i64 reduced_modulus = equation.m / gcd;
    if (reduced_modulus == 1) return ResidueClass{0, 1};

    i64 reduced_a = a / gcd;
    i64 reduced_b = b / gcd;
    ExgcdResult inverse = exgcd(reduced_a, reduced_modulus);
    assert(inverse.gcd == 1);
    i64 remainder = normalize_mod(
        (i128)reduced_b * inverse.x, reduced_modulus);
    return ResidueClass{remainder, reduced_modulus};
}

// 合并 x=A (mod M) 与 x=B (mod N)。输入必须已经规范化。
CRTResult merge_residue_classes(const ResidueClass& current,
                                const ResidueClass& added) {
    assert(current.mod > 0 && added.mod > 0);
    assert(0 <= current.r && current.r < current.mod);
    assert(0 <= added.r && added.r < added.mod);

    i64 gcd = std::gcd(current.mod, added.mod);
    i128 difference = (i128)added.r - current.r;
    if (difference % gcd != 0) {
        return {CRTStatus::NoSolution, 0, 0};
    }

    // 令 x=A+M*k，需要解 (M/g)k=(B-A)/g (mod N/g)。
    i64 reduced_added_modulus = added.mod / gcd;
    i64 multiplier = 0;
    if (reduced_added_modulus != 1) {
        i64 reduced_current_modulus = current.mod / gcd;
        ExgcdResult inverse =
            exgcd(reduced_current_modulus, reduced_added_modulus);
        assert(inverse.gcd == 1);
        multiplier = normalize_mod(
            (difference / gcd) * inverse.x, reduced_added_modulus);
    }

    i128 merged_modulus =
        (i128)(current.mod / gcd) * added.mod;
    i128 merged_remainder =
        (i128)current.r + (i128)current.mod * multiplier;
    assert(0 <= merged_remainder && merged_remainder < merged_modulus);

    if (merged_modulus > numeric_limits<i64>::max()) {
        return {CRTStatus::TooLarge, 0, 0};
    }
    return {CRTStatus::Success, (i64)merged_remainder,
            (i64)merged_modulus};
}

CRTResult solve_congruences(const vector<Congruence>& equations, i64 lim) {
    assert(lim >= 0);
    ResidueClass answer{0, 1};

    for (const Congruence& equation : equations) {
        optional<ResidueClass> reduced =
            reduce_linear_congruence(equation);
        if (!reduced.has_value()) {
            return {CRTStatus::NoSolution, 0, 0};
        }

        CRTResult merged = merge_residue_classes(answer, *reduced);
        if (merged.status != CRTStatus::Success) return merged;
        answer = {merged.r, merged.mod};
    }

    if (answer.r > lim) return {CRTStatus::TooLarge, answer.r, answer.mod};
    return {CRTStatus::Success, answer.r, answer.mod};
}
```

## 为什么这样化简

若 $g=\gcd(a,m)$，线性同余 $ax\equiv b\pmod m$ 有解当且仅当 $g\mid b$。有解时除以 $g$ 得

$$
\frac agx\equiv\frac bg\pmod{m/g}.
$$

此时 $a/g$ 与 $m/g$ 互质，可以用 `exgcd` 求逆元，最终得到

$$
x\equiv \frac bg\left(\frac ag\right)^{-1}\pmod{m/g}.
$$

`a`、`b` 先按原模数规范到非负数不会改变方程，也避免了负数除法和 `%` 的符号干扰。特别地，约化后模数为 1 表示该方程对 $x$ 没有任何限制，不应再求逆元。

## 合并与边界

合并 $x\equiv A\pmod M$ 和 $x\equiv B\pmod N$ 时，令 $x=A+Mk$，得到

$$
\frac Mgk\equiv\frac{B-A}{g}\pmod{N/g},
\qquad g=\gcd(M,N).
$$

所以必须先检查 $g\mid(B-A)$。`difference` 使用 `i128`，负数再交给 `normalize_mod`；规范化后的 $k\in[0,N/g)$ 保证构造出的新余数天然满足 $0\le A'<\operatorname{lcm}(M,N)$。

需要区分两种“过大”：

- 新模数仍能保存时，即使 `mod > lim` 也必须继续；最终判断的是最小非负解 `r`，例如 $x\equiv1\pmod{10^{18}}$ 在 `lim=1` 时应当成功。
- 若合并后的 LCM 已超过 `long long`，按照本模板的接口约定立即返回 `TooLarge`，不再保存或继续合并真实的大整数。

只要模数仍在 `long long` 内，不能在中途因为 `r > lim` 提前返回：后面还可能出现矛盾约束，最终状态应是 `NoSolution`。空方程组返回 $x\equiv0\pmod1$。总复杂度为 $O(k\log V)$，其中 $V$ 是参与合并的模数规模。
