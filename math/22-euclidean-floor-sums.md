# 结构化万能欧几里得

这里的“万能欧几里得”不是把几个求和式放进同一个递归，而是把直线对应的格路编码成 `U/R` 字符串，再用任意幺半群维护这个字符串。

设

$$
y_i=\left\lfloor\frac{ai+b}{c}\right\rfloor,
\qquad a,b,n\ge 0,\ c>0.
$$

从 $x=0$ 走到 $x=n$：每跨过一条水平网格线记 `U`，每跨过一条竖直网格线记 `R`；若同时经过整点，约定先 `U` 后 `R`。于是第 $i$ 个 `R` 之前恰有 $y_i$ 个 `U`。例如 $n=6,a=3,b=2,c=5$ 时

```text
y_1,...,y_6 = 1,1,2,2,3,4
word          = U R R U R R U R U R
```

算法只要求状态满足：

- `Info{}` 是空串；
- `lhs * rhs` 是两段路径按顺序拼接，必须满足结合律；
- `U`、`R` 分别是单个字符的状态。

不要求乘法交换。矩阵、哈希、自动机转移以及各种路径统计都可以作为 `Info`。

## 通用模板

`euclidean_word(n,a,b,c,up,right)` 返回区间 $(0,n]$ 生成的完整路径状态；当 $n>0$ 时，它包含初始高度 $\lfloor b/c\rfloor$ 个 `U`，并且最后一个字符是第 $n$ 个 `R`；当 $n=0$ 时返回空串。参数和中间乘法使用无符号 64 位与 `u128`，以免 `a*n` 溢出。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

using u64 = unsigned long long;
using u128 = __uint128_t;
using i64 = long long;
using i128 = __int128_t;

template<class Info>
Info monoid_power(Info base, u64 exponent) {
    Info result;
    while (exponent > 0) {
        if (exponent & 1ULL) result = result * base;
        base = base * base;
        exponent >>= 1;
    }
    return result;
}

template<class Info>
Info euclidean_word(u64 n, u64 a, u64 b, u64 c,
                    const Info& up, const Info& right) {
    assert(c > 0);
    if (n == 0) return Info{};

    if (b >= c) {
        return monoid_power(up, b / c) *
               euclidean_word(n, a, b % c, c, up, right);
    }
    if (a >= c) {
        Info new_right = monoid_power(up, a / c) * right;
        return euclidean_word(n, a % c, b, c, up, new_right);
    }

    // 此时 0 <= a,b < c。
    u64 up_count = (u64)(((u128)a * n + b) / c);
    if (up_count == 0) return monoid_power(right, n);

    // 转置坐标轴。头尾两段必须保留，不能只交换 a 与 c。
    u64 first_rights = (c - b - 1) / a;
    u64 last_up_position =
        (u64)(((u128)c * up_count - b - 1) / a);
    assert(last_up_position <= n);

    return monoid_power(right, first_rights) * up *
           euclidean_word(up_count - 1, c, (c - b - 1) % a, a,
                          right, up) *
           monoid_power(right, n - last_up_position);
}
```

递归深度与 Euclid 算法相同。若一次状态合并代价为 $T$，复杂度为 $O(T\log\max(a,c,n))$；额外的 $\log n$ 来自幺半群快速幂。很多状态可为纯段构造闭式幂，但通用模板保留快速幂最稳妥。

## 为什么递归成立

以下顺序很重要，因为 `operator*` 不一定交换。

1. 若 $b\ge c$，整条线先整体升高 $\lfloor b/c\rfloor$，答案前缀是 `U^(b/c)`。
2. 若 $a\ge c$，每次向右前固定多走 $\lfloor a/c\rfloor$ 次 `U`，故把原子 `R` 替换为 `U^(a/c) R`。
3. 若 $0<a<c$，令 $m=\lfloor(an+b)/c\rfloor$。交换坐标轴后，第 $i$ 个 `U` 前的 `R` 数为

   $$
   \left\lfloor\frac{ci-b-1}{a}\right\rfloor.
   $$

   `-1` 正是“整点先 `U` 后 `R`”的边界修正。提出第一个 `U` 之前与最后一个 `U` 之后的 `R`，中间部分就是交换 `U/R` 后的同类子问题：

   $$
   R^{\lfloor(c-b-1)/a\rfloor}U\;
   F(m-1,c,(c-b-1)\bmod a,a,R,U)\;
   R^{n-\lfloor(cm-b-1)/a\rfloor}.
   $$

若 $m=0$，路径只有 `R^n`。这四种情况就是完整的结构化算法。

## 示例：怎样从目标式设计结构体

假设最终要求

$$
\sum_{i=0}^{n}y_i,\qquad
\sum_{i=0}^{n}y_i^2,\qquad
\sum_{i=0}^{n}iy_i.
$$

重点不是记住下面的代码，而是学会从目标式推出一个对“字符串拼接”封闭的结构体。

### 第一步：规定每个字段的局部含义

任取一段 `U/R` 串 $S$，都从局部原点 $(0,0)$ 开始执行。每遇到一次 `U` 令 $y\gets y+1$；每遇到一次 `R`，先令 $x\gets x+1$，再记录此时的 $(x,y)$。

结构体维护：

| 字段 | 含义 |
| --- | --- |
| $x$ | 串中 `R` 的数量，即终点横坐标 |
| $y$ | 串中 `U` 的数量，即终点纵坐标 |
| $s_x$ | 每个 `R` 处的横坐标之和 $\sum x$ |
| $s_y$ | 每个 `R` 处的纵坐标之和 $\sum y$ |
| $s_{y^2}$ | $\sum y^2$ |
| $s_{xy}$ | $\sum xy$ |

为什么还要维护看似不是答案的 $x,y,s_x$？因为把右段接到左段后，右段的每个局部坐标 $(x',y')$ 都会变成

$$
(x_L+x',\ y_L+y').
$$

展开目标中的 $xy$ 会出现 $x_Ly'$、$y_Lx'$ 和 $x_Ly_L$，所以必须同时知道右段的 $s_x,s_y$ 以及两段的 `R/U` 数量。设计结构体的一般方法正是：先放入答案，再反复展开拼接式，把缺失的辅助统计量补到不再产生新量为止。

### 第二步：推导左右段的合并式

设整串是 $L+R$。左段里的坐标不变；右段的坐标整体平移 $(x_L,y_L)$。于是

$$
\begin{aligned}
x&=x_L+x_R,\\
y&=y_L+y_R,\\
s_x&=s_{x,L}+s_{x,R}+x_Lx_R,\\
s_y&=s_{y,L}+s_{y,R}+y_Lx_R,\\
s_{y^2}&=s_{y^2,L}+s_{y^2,R}
             +2y_Ls_{y,R}+y_L^2x_R,\\
s_{xy}&=s_{xy,L}+s_{xy,R}
          +x_Ls_{y,R}+y_Ls_{x,R}+x_Ly_Lx_R.
\end{aligned}
$$

最后一行直接来自

$$
(x_L+x')(y_L+y')=x'y'+x_Ly'+y_Lx'+x_Ly_L.
$$

这一步也说明拼接通常不交换：`L * R` 和 `R * L` 的平移量不同。

### 第三步：写空串与两个原子

- 空串：六个字段全为 $0$，它就是乘法单位元。
- 单个 `U`：终点为 $(0,1)$，还没有遇到 `R`，所以只有 $y=1$。
- 单个 `R`：执行后记录点 $(1,0)$，所以 $x=1,s_x=1$，其余为 $0$。

例如把 `URR` 与 `UR` 拼接：

$$
L=(2,1,3,2,2,3),\qquad
R=(1,1,1,1,1,1),
$$

字段顺序为 $(x,y,s_x,s_y,s_{y^2},s_{xy})$。代入合并式得到

$$
L+R=(3,2,6,4,6,9),
$$

与直接扫描 `URRUR` 时三个 `R` 上的坐标 $(1,1),(2,1),(3,2)$ 完全一致。先用这种短串手算，是检查合并式最有效的方法。

### 第四步：把推导翻译成结构体

下面的代码只是上述六条公式的逐项翻译，所有量对 $998244353$ 取模；Euclid 模板本身完全不知道这些字段的含义。

```cpp
struct FloorPathInfo {
    static constexpr i64 mod = 998244353;

    i64 x = 0;
    i64 y = 0;
    i64 sum_x = 0;
    i64 sum_y = 0;
    i64 sum_y_squared = 0;
    i64 sum_xy = 0;

    friend FloorPathInfo operator*(const FloorPathInfo& left,
                                   const FloorPathInfo& right) {
        auto norm = [](i128 value) -> i64 {
            value %= mod;
            if (value < 0) value += mod;
            return (i64)value;
        };

        FloorPathInfo result;
        result.x = (left.x + right.x) % mod;
        result.y = (left.y + right.y) % mod;
        result.sum_x = norm((i128)left.sum_x + right.sum_x +
                            (i128)left.x * right.x);
        result.sum_y = norm((i128)left.sum_y + right.sum_y +
                            (i128)left.y * right.x);
        result.sum_y_squared = norm(
            (i128)left.sum_y_squared + right.sum_y_squared +
            (i128)right.x * left.y % mod * left.y +
            (i128)2 * left.y * right.sum_y);
        result.sum_xy = norm(
            (i128)left.sum_xy + right.sum_xy +
            (i128)right.x * left.x % mod * left.y +
            (i128)left.x * right.sum_y +
            (i128)left.y * right.sum_x);
        return result;
    }

    static FloorPathInfo up() {
        FloorPathInfo result;
        result.y = 1;
        return result;
    }

    static FloorPathInfo right() {
        FloorPathInfo result;
        result.x = 1;
        result.sum_x = 1;
        return result;
    }
};

struct FloorMoments {
    i64 floor_sum = 0;
    i64 square_sum = 0;
    i64 index_times_floor = 0;
};

FloorMoments floor_moments(u64 n, u64 a, u64 b, u64 c) {
    assert(c > 0);
    FloorPathInfo path = euclidean_word(
        n, a, b, c, FloorPathInfo::up(), FloorPathInfo::right());

    constexpr i64 mod = FloorPathInfo::mod;
    i64 initial_height = (i64)((b / c) % (u64)mod);
    return {
        (path.sum_y + initial_height) % mod,
        (path.sum_y_squared +
         (i64)((i128)initial_height * initial_height % mod)) % mod,
        path.sum_xy
    };
}
```

`floor_moments(n,a,b,c)` 计算闭区间 $0\le i\le n$ 上的

$$
\sum y_i,\qquad \sum y_i^2,\qquad \sum iy_i.
$$

之所以额外补一次初始高度，是因为路径中的每个 `R` 记录 $i=1,\ldots,n$，而 $i=0$ 没有对应的 `R`。

例如 `floor_moments(5,3,2,5)` 对应

$$
(y_0,\ldots,y_5)=(0,1,1,2,2,3),
$$

结果为 `floor_sum=9`、`square_sum=19`、`index_times_floor=32`。

## 如何迁移到别的题

先完全忘掉 Euclid 递归，只按题意设计一个能表示任意 `U/R` 串的结构：

1. 写出单个 `U` 与单个 `R` 的状态；
2. 推导 `left + right` 的拼接公式，特别检查顺序；
3. 确认空状态是单位元、拼接满足结合律；
4. 把三个对象直接传给 `euclidean_word`。

常见应用包括 $\sum i^p y_i^q$、$\sum A^iB^{y_i}$、路径哈希以及在格路上复合转移。所谓“万能”，指的是 Euclid 部分无需随统计量重推；真正变化的只有幺半群状态。
