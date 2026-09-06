# 计数公式、反演与生成函数速查

本节集中保存容易在推式子时用到的公式。默认越界组合数为 $0$，空和为 $0$，空积为 $1$。第一类 Stirling 数的正负号严格沿用 `18-stirling.md`：无符号第一类记 $\left[{n\atop k}\right]$，带符号第一类记

$$
s(n,k)=(-1)^{n-k}\left[{n\atop k}\right].
$$

## 组合数与二项式

### 基本变形

$$
\binom nk=\binom n{n-k},
\qquad
\binom nk=\binom{n-1}k+\binom{n-1}{k-1},
$$

$$
k\binom nk=n\binom{n-1}{k-1},
\qquad
(n-k)\binom nk=n\binom{n-1}k,
$$

$$
\binom ji\binom ik
=\binom jk\binom{j-k}{i-k}.
$$

最后一式可理解为：先从 $j$ 个元素中选 $i$ 个、再从中标记 $k$ 个，等价于先选出被标记的 $k$ 个，再从剩余 $j-k$ 个中补 $i-k$ 个。

### 二项式定理与广义二项式

$$
(a+b)^n=\sum_{k=0}^{n}\binom nka^{n-k}b^k.
$$

对任意形式参数 $\alpha$，定义

$$
\binom\alpha n
=\frac{\alpha(\alpha-1)\cdots(\alpha-n+1)}{n!},
$$

则形式幂级数意义下

$$
(1+x)^\alpha=\sum_{n\ge0}\binom\alpha n x^n.
$$

特别地，对正整数 $r$，

$$
\frac1{(1-x)^r}
=\sum_{n\ge0}\binom{n+r-1}{r-1}x^n.
$$

不要把最后一式的系数误写成 $\binom rn$。

### Hockey-stick 与 Vandermonde

$$
\sum_{k=r}^{n}\binom kr=\binom{n+1}{r+1},
$$

$$
\sum_{k=0}^{m}\binom{n+k}{n}=\binom{n+m+1}{n+1},
$$

$$
\sum_{k=0}^{m}\binom{n-k}{m-k}=\binom{n+1}{m},
$$

$$
\sum_k\binom ak\binom b{n-k}=\binom{a+b}n.
$$

多组形式为

$$
\sum_{b_1+\cdots+b_t=m}\prod_{i=1}^{t}\binom{a_i}{b_i}
=\binom{a_1+\cdots+a_t}{m}.
$$

负二项式对应的卷积为

$$
\sum_{b_1+\cdots+b_t=m}
\prod_{i=1}^{t}\binom{a_i+b_i}{b_i}
=\binom{a_1+\cdots+a_t+m+t-1}{m}.
$$

它们分别来自 $(1+x)^{\sum a_i}$ 与 $(1-x)^{-\sum(a_i+1)}$ 的系数比较。

### 高频求和

$$
\sum_{k=0}^{n}\binom nk=2^n,
\qquad
\sum_{k=0}^{n}(-1)^k\binom nk=[n=0],
$$

$$
\sum_{k=0}^{n}\binom nk^2=\binom{2n}n,
$$

$$
\sum_{k=0}^{n}k\binom nk=n2^{n-1},
$$

$$
\sum_{k=0}^{n}k(k-1)\binom nk=n(n-1)2^{n-2},
$$

$$
\sum_{k=0}^{n}k^2\binom nk=n(n+1)2^{n-2}.
$$

带 $k,k(k-1),\ldots$ 的式子可对 $(1+x)^n$ 求导若干次，再乘相应的 $x$ 并令 $x=1$。

## 插板、上下界与不相邻选择

- $x_1+\cdots+x_m=n$，$x_i\ge0$：方案数 $\binom{n+m-1}{m-1}$。
- $x_i\ge l_i$：先令 $y_i=x_i-l_i$，答案为

  $$
  \binom{n-\sum l_i+m-1}{m-1}.
  $$

- 若还有上界 $x_i\le r_i$，令 $u_i=r_i-l_i+1$，容斥得到

  $$
  \sum_{S\subseteq[m]}(-1)^{|S|}
  \binom{n-\sum l_i-\sum_{i\in S}u_i+m-1}{m-1}.
  $$

- 从 $1,\ldots,n$ 中选 $k$ 个互不相邻的位置：答案 $\binom{n-k+1}{k}$。把第 $i$ 个所选位置 $p_i$ 映成 $p_i-(i-1)$ 即变成普通选择。

## 容斥原理

对事件集合 $A_1,\ldots,A_m$，

$$
\left|\bigcup_{i=1}^{m}A_i\right|
=\sum_{\emptyset\ne S\subseteq[m]}
(-1)^{|S|-1}\left|\bigcap_{i\in S}A_i\right|.
$$

若 $T_k$ 表示所有 $k$ 个事件交集大小的总和，则“恰好满足 $r$ 个事件”的对象数为

$$
E_r=\sum_{k=r}^{m}(-1)^{k-r}\binom kr T_k.
$$

这里的“交集大小总和”不是“恰好满足 $k$ 个事件”的对象数：一个实际满足 $r$ 个事件的对象，会在 $T_k$ 中被计入 $\binom rk$ 次，这正是需要反演的原因。

概率版本中，设 $X$ 为成功事件个数，则

$$
A_j=\sum_{|J|=j}\Pr\left(\bigcap_{i\in J}A_i\right)
=\mathbb E\binom Xj,\qquad
\Pr(X=r)=\sum_{j=r}^m(-1)^{j-r}\binom jr A_j.
$$

这些等式不要求事件独立。$A_j$ 称为二项式矩，是第 $j$ 阶下降阶乘矩除以 $j!$。推导、阈值版本以及如何先消去无限时间再反演，见 `34-probability-expectation.md` 的“联合成功概率、二项式矩与阈值等待时间”。

常用结果：

- 错排数

  $$
  D_n=n!\sum_{k=0}^{n}\frac{(-1)^k}{k!},
  \qquad
  D_n=(n-1)(D_{n-1}+D_{n-2});
  $$

- 从 $n$ 个元素到 $k$ 个有标号盒子的满射数

  $$
  \sum_{i=0}^{k}(-1)^i\binom ki(k-i)^n
  =k!\left\{{n\atop k}\right\};
  $$

- Min--Max 容斥

  $$
  \max(S)=\sum_{\emptyset\ne T\subseteq S}(-1)^{|T|-1}\min(T),
  $$

  $$
  \min(S)=\sum_{\emptyset\ne T\subseteq S}(-1)^{|T|-1}\max(T).
  $$

## Catalan、反射原理与 Ballot

Catalan 数的等价形式为

$$
C_0=1,
\qquad
C_n=\sum_{i=0}^{n-1}C_iC_{n-1-i},
$$

$$
C_n=\frac1{n+1}\binom{2n}n
=\binom{2n}n-\binom{2n}{n-1},
$$

$$
C_n=\frac{4n-2}{n+1}C_{n-1}.
$$

它统计合法括号序列、固定入栈顺序的出栈序列、$n$ 个结点的二叉树、凸 $(n+2)$ 边形三角剖分，以及从 $(0,0)$ 到 $(n,n)$ 不越过对角线的单调路径。

更一般地，从 $(0,0)$ 到 $(p,q)$，$p\ge q$，始终满足横坐标不少于纵坐标的路径数为

$$
\binom{p+q}{q}-\binom{p+q}{q-1}
=\frac{p-q+1}{p+1}\binom{p+q}{q}.
$$

第二项来自把第一段越过边界的非法前缀关于边界反射。

生成函数满足

$$
C(x)=1+xC(x)^2,
\qquad
C(x)=\frac{1-\sqrt{1-4x}}{2x}.
$$

## Fibonacci 恒等式

取 $F_0=0,F_1=1$：

$$
\sum_{i=0}^{n}F_i=F_{n+2}-1,
\qquad
\sum_{i=0}^{n}F_i^2=F_nF_{n+1},
$$

$$
F_{n+1}F_{n-1}-F_n^2=(-1)^n,
$$

$$
F_{n+k}=F_{k-1}F_n+F_kF_{n+1},
\qquad
\gcd(F_m,F_n)=F_{\gcd(m,n)}.
$$

其 OGF 为

$$
\sum_{n\ge0}F_nx^n=\frac{x}{1-x-x^2}.
$$

Fibonacci 是整除数列：$n\mid m\Rightarrow F_n\mid F_m$；反方向在含 $F_1=F_2=1$ 等退化情形时不能直接使用。

## Stirling 数与幂的换基

基本换基为

$$
x^n=\sum_{k=0}^{n}\left\{{n\atop k}\right\}x^{\underline k},
$$

$$
x^{\underline n}=\sum_{k=0}^{n}s(n,k)x^k,
\qquad
x^{\overline n}=\sum_{k=0}^{n}\left[{n\atop k}\right]x^k.
$$

因此两种 Stirling 矩阵互逆：

$$
\sum_{k=m}^{n}s(n,k)\left\{{k\atop m}\right\}
=\sum_{k=m}^{n}\left\{{n\atop k}\right\}s(k,m)
=\delta_{nm}.
$$

第二类的显式公式为

$$
\left\{{n\atop k}\right\}
=\frac1{k!}\sum_{i=0}^{k}(-1)^{k-i}\binom ki i^n.
$$

它立刻给出满射数，并能把普通幂换成下降幂。一个很实用的幂和公式是

$$
\sum_{i=0}^{N}i^p
=\sum_{k=0}^{p}\left\{{p\atop k}\right\}
k!\binom{N+1}{k+1},
$$

因为 $i^{\underline k}=k!\binom ik$，再使用 Hockey-stick。

行和为

$$
\sum_k\left[{n\atop k}\right]=n!,
\qquad
\sum_k\left\{{n\atop k}\right\}=B_n.
$$

Bell 数还满足

$$
B_{n+1}=\sum_{k=0}^{n}\binom nkB_k,
\qquad
\sum_{n\ge0}B_n\frac{x^n}{n!}=\exp(e^x-1).
$$

整行、固定列的快速算法见 `18-stirling.md`。

## 常见反演

### 二项式反演

$$
g_n=\sum_{k=0}^{n}\binom nkf_k
\iff
f_n=\sum_{k=0}^{n}(-1)^{n-k}\binom nkg_k.
$$

上三角形式为

$$
g_k=\sum_{i=k}^{n}\binom ikf_i
\iff
f_k=\sum_{i=k}^{n}(-1)^{i-k}\binom ikg_i.
$$

### Möbius 反演

$$
g(n)=\sum_{d\mid n}f(d)
\iff
f(n)=\sum_{d\mid n}\mu(d)g(n/d).
$$

判断互质时常插入

$$
[\gcd(a,b)=1]=\sum_{d\mid\gcd(a,b)}\mu(d),
$$

从而

$$
\#\{1\le a\le A,1\le b\le B:\gcd(a,b)=1\}
=\sum_{d=1}^{\min(A,B)}\mu(d)
\left\lfloor\frac Ad\right\rfloor
\left\lfloor\frac Bd\right\rfloor.
$$

### 子集 Zeta/Möbius

$$
G(S)=\sum_{T\subseteq S}F(T)
\iff
F(S)=\sum_{T\subseteq S}(-1)^{|S|-|T|}G(T).
$$

两边均可按位做蝶形，在 $O(d2^d)$ 内计算。超集版本把 $T\subseteq S$ 全部反向即可。

### 单位根过滤

若域中存在可逆的 $m$ 次单位根 $\omega$，则

$$
[n\equiv r\pmod m]
=\frac1m\sum_{j=0}^{m-1}\omega^{j(n-r)}.
$$

所以可从 $A(x)$ 中抽取下标模 $m$ 等于 $r$ 的项：

$$
\sum_{n\equiv r\pmod m}a_nx^n
=\frac1m\sum_{j=0}^{m-1}\omega^{-jr}A(\omega^jx).
$$

## 卷积与变换该选哪一种

| 目标 | 变换方式 |
| --- | --- |
| $h_k=\sum_{i+j=k}f_i g_j$ | 普通卷积；NTT/FFT |
| $h_k=\sum_{i+j\equiv k\pmod N}f_i g_j$ | 长度 $N$ 的循环卷积 |
| $h_k=\sum_{i\oplus j=k}f_i g_j$ | XOR FWT |
| $h(S)=\sum_{A\cup B=S}f(A)g(B)$ | 子集卷积或 OR FWT，取决于是否要求不交 |
| $h_k=\sum_{\gcd(i,j)=k}f_i g_j$ | **倍数** Zeta，逐点乘，再做倍数 Möbius |
| $h_k=\sum_{\operatorname{lcm}(i,j)=k}f_i g_j$ | **约数** Zeta，逐点乘，再做约数 Möbius |

GCD/LCM 的方向最容易记反。原因是

$$
d\mid\gcd(i,j)\iff d\mid i\land d\mid j,
$$

所以 GCD 卷积应累计所有下标为 $d$ 的倍数；而

$$
\operatorname{lcm}(i,j)\mid n\iff i\mid n\land j\mid n,
$$

所以 LCM 卷积应累计 $n$ 的所有约数。对应实现见 `19-sieve-convolutions.md`，XOR/OR/AND FWT 见 `10-快速沃尔什变换.md`。

## 常见对象的直接计数

### 排列、多重集与圆排列

- $n$ 个不同元素的排列数：$n!$；从中选 $k$ 个并排列：$n^{\underline k}=n!/(n-k)!$。
- 含有 $c_1,\ldots,c_m$ 个相同元素的多重集排列数：

  $$
  \frac{(c_1+\cdots+c_m)!}{c_1!\cdots c_m!}.
  $$

- $n$ 个不同元素只把旋转视为相同的圆排列数：$(n-1)!$。若翻转也视为相同，还需检查反射是否存在不动排列，不能无条件再除以 $2$。
- 恰有 $k$ 个置换环：$\left[{n\atop k}\right]$；恰有 $k$ 个下降位置使用 Eulerian 数

  $$
  \left\langle{n\atop k}\right\rangle
  =(k+1)\left\langle{n-1\atop k}\right\rangle
  +(n-k)\left\langle{n-1\atop k-1}\right\rangle.
  $$

### 标号树与 Prüfer 序列

Cayley 公式：$n$ 个有标号顶点的无根树共有

$$
n^{n-2}
$$

棵；指定根后共有 $n^{n-1}$ 棵。Prüfer 序列长度为 $n-2$，顶点 $v$ 在序列中出现次数恰为 $\deg(v)-1$，所以给定度数 $d_1,\ldots,d_n$ 且 $\sum d_i=2n-2$ 时，树的数量为

$$
\frac{(n-2)!}{\prod_{i=1}^{n}(d_i-1)!}.
$$

如果题目限制边集而不是只限制度数，应改用 Matrix--Tree 定理，不能套 Cayley。

### 盒子模型速查

设球数为 $n$、盒子数为 $k$：

| 球 | 盒子 | 是否允许空盒 | 方案数 |
| --- | --- | --- | --- |
| 不同 | 不同 | 允许 | $k^n$ |
| 不同 | 不同 | 不允许 | $k!\left\{{n\atop k}\right\}$ |
| 相同 | 不同 | 允许 | $\binom{n+k-1}{k-1}$ |
| 相同 | 不同 | 不允许 | $\binom{n-1}{k-1}$ |
| 不同 | 相同 | 不允许 | $\left\{{n\atop k}\right\}$ |

“相同球放进相同盒子且允许空盒”是至多 $k$ 部分的整数分拆，没有单个组合数闭式。

## 生成函数操作字典

重复抽样中如何用 EGF 自动统计顺序、指数换元与标记变量的解释见 `21-generating-functions.md`；概率生成函数与求矩见 `34-probability-expectation.md`。

若 $A(x)=\sum_{n\ge0}a_nx^n$，则：

| 操作 | 系数意义 |
| --- | --- |
| $x^kA(x)$ | 下标整体右移 $k$ |
| $A(x)/(1-x)$ | 前缀和 $\sum_{i=0}^{n}a_i$ |
| $(1-x)A(x)$ | 一阶差分 $a_n-a_{n-1}$ |
| $xA'(x)$ | 第 $n$ 项乘 $n$ |
| $A'(x)$ | $(n+1)a_{n+1}$ |
| $A(x)B(x)$ | 普通卷积 $\sum_{k=0}^{n}a_kb_{n-k}$ |
| $(A(x)+A(-x))/2$ | 只保留偶数下标 |
| $(A(x)-A(-x))/2$ | 只保留奇数下标 |

高频 OGF/EGF：

| 对象 | 生成函数 |
| --- | --- |
| 常数序列 $1$ | $1/(1-x)$ |
| $\binom{n+r-1}{r-1}$ | $(1-x)^{-r}$ |
| Fibonacci | $x/(1-x-x^2)$ |
| Catalan | $(1-\sqrt{1-4x})/(2x)$ |
| 错排 EGF | $e^{-x}/(1-x)$ |
| 第二类 Stirling 固定 $k$ 的 EGF | $(e^x-1)^k/k!$ |
| 无符号第一类固定 $k$ 的 EGF | $(-\ln(1-x))^k/k!$ |
| Bell EGF | $\exp(e^x-1)$ |
| 分拆数 | $\prod_{j\ge1}(1-x^j)^{-1}$ |
| 互异部分拆 | $\prod_{j\ge1}(1+x^j)$ |

标号组合类的常用构造规则：

- 有序序列 `SEQ(A)`：$1/(1-A(x))$；
- 无序标号集合 `SET(A)`：$\exp(A(x))$；
- 标号环 `CYC(A)`：$-\ln(1-A(x))$；
- $k$ 个无序非空标号块：$(e^x-1)^k/k!$；
- 任意个无序非空标号块：$\exp(e^x-1)$。

使用这些规则前必须先确认对象是否有标号、子结构是否有序、空结构是否允许。

## 对数导数、Euler 变换与 Newton 恒等式

设 $F(x)=\sum_{n\ge0}f_nx^n$ 且 $f_0=1$。若

$$
\frac{xF'(x)}{F(x)}=\sum_{n\ge1}c_nx^n,
$$

把等式改写成 $xF'=F\sum c_nx^n$ 并比较 $x^n$ 系数，得到

$$
nf_n=\sum_{k=1}^{n}c_kf_{n-k}.
$$

这就是从乘积型生成函数推系数递推的常用入口。特别地，Euler 变换

$$
F(x)=\prod_{d\ge1}(1-x^d)^{-a_d}
$$

满足

$$
c_n=\sum_{d\mid n}d\,a_d,\qquad
nf_n=\sum_{k=1}^{n}c_kf_{n-k}.
$$

例如 $a_d=1$ 时 $F$ 是分拆生成函数，$c_n=\sigma(n)$。先按倍数循环求所有 $c_n$ 需 $O(N\log N)$，再用递推求 $f_n$ 需 $O(N^2)$。

Newton 恒等式是同一技巧的有限变量版本。令 $p_k=\sum_i x_i^k$，$e_k$ 为第 $k$ 个基本对称多项式，$h_k$ 为第 $k$ 个完全齐次对称多项式，则

$$
ke_k=\sum_{i=1}^{k}(-1)^{i-1}e_{k-i}p_i,\qquad
kh_k=\sum_{i=1}^{k}h_{k-i}p_i,
$$

其中 $e_0=h_0=1$。第一式可由幂和恢复多项式 $\prod_i(t-x_i)$ 的系数；第二式常用于多重集选择。

这些递推都有“除以 $n$”或“除以 $k$”。在模意义下只有分母与模数互质时才能直接乘逆元。整数答案中“分子必然整除”不代表只知道分子模 $M$ 后还能除；模数为合数或分母等于模数的倍数时，必须改用无除法递推、保存更高精度的整数，或在足够大的模数上保留额外信息。

## 没有 NTT 友好模数时

先判断是否真的需要通用卷积：

1. 分母次数为 $k$ 的有理生成函数可直接比较系数，按递推做到 $O(Nk)$；只求很远的一项可用 Kitamasa，做到 $O(k^2\log n)$。
2. 乘积因子或非零项很稀疏时，按背包或稀疏递推更新；分拆数的五边形递推就是典型例子，只用加减法。
3. $N$ 不大时直接做 $O(N^2)$ 卷积，适用于任意正模数，也不要求存在逆元。
4. 只有确实需要大规模稠密卷积时，才考虑 FFT 拆系数或多个 NTT 素数加 CRT。多模 NTT 若要先还原整数卷积再对目标模数取模，辅助素数乘积必须大于真实系数的上界；不能只取两三个素数便默认正确。
5. 多项式求逆、对数、指数等除了卷积外还有常数项可逆、`1..N` 可逆等前提；“把 NTT 换成朴素乘法”不会自动消除这些代数条件。

所以赛场上遇到非 NTT 模数时，优先寻找低阶递推、稀疏乘积和专用恒等式，而不是立刻实现任意模卷积。

## 整数分拆与五边形数

分拆数 $p(n)$ 的 OGF 是

$$
P(x)=\prod_{k\ge1}\frac1{1-x^k}.
$$

Euler 五边形数定理给出

$$
\prod_{k\ge1}(1-x^k)
=\sum_{t\in\mathbb Z}(-1)^t x^{t(3t-1)/2}.
$$

因此 $p(0)=1$，并有递推

$$
p(n)=\sum_{t=1}^{\infty}(-1)^{t-1}
\left(
p\!\left(n-\frac{t(3t-1)}2\right)
+p\!\left(n-\frac{t(3t+1)}2\right)
\right),
$$

负下标项视为 $0$。只求前 $N$ 项时该递推复杂度为 $O(N\sqrt N)$。

下面的代码只做加减法，适用于任意正模数，包括合数；`result[n]` 是 $p(n)\bmod modulus$。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

vector<int> partition_numbers(int maximum, int modulus) {
    assert(maximum >= 0 && modulus > 0);
    vector<int> result(maximum + 1);
    result[0] = 1 % modulus;
    for (int n = 1; n <= maximum; ++n) {
        long long value = 0;
        for (long long k = 1; ; ++k) {
            long long first = k * (3 * k - 1) / 2;
            if (first > n) break;
            long long second = k * (3 * k + 1) / 2;
            int sign = (k & 1) ? 1 : -1;

            value += sign * result[n - (int)first];
            if (value < 0) value += modulus;
            if (value >= modulus) value -= modulus;
            if (second <= n) {
                value += sign * result[n - (int)second];
                if (value < 0) value += modulus;
                if (value >= modulus) value -= modulus;
            }
        }
        result[n] = (int)value;
    }
    return result;
}
```

有限 $q$-二项式定理（这里的 $q$ 是形式变量，不是模数）也常用于分拆限制：

$$
\prod_{i=0}^{n-1}(1+yq^i)
=\sum_{k=0}^{n}q^{k(k-1)/2}{n\brack k}_q y^k,
$$

并有

$$
{n\brack k}_q={n-1\brack k}_q+q^{n-k}{n-1\brack k-1}_q.
$$

Gaussian 二项式 ${n\brack k}_q$ 的 $q^s$ 系数，等于恰好装在 $k\times(n-k)$ 矩形内、大小为 $s$ 的分拆数。题目同时限制部分个数和每部分大小时，这个解释往往比硬推多项式更直接。

分拆中还常用三条双射/生成函数结论：

- 共轭 Ferrers 图说明“至多 $k$ 个部分”和“每部分至多 $k$”等势；
- 把每部分都减 1，说明“恰好 $k$ 个正部分的 $n$ 的分拆数”等于“至多 $k$ 个部分的 $n-k$ 的分拆数”；
- Euler 分拆定理说明“部分互不相同”的分拆数等于“所有部分均为奇数”的分拆数，因为

  $$
  \prod_{j\ge1}(1+x^j)
  =\prod_{j\ge1}\frac1{1-x^{2j-1}}.
  $$

## Burnside 与 Pólya

群 $G$ 作用在方案集合 $X$ 上时，本质不同方案数为

$$
|X/G|=\frac1{|G|}\sum_{g\in G}|\operatorname{Fix}(g)|.
$$

若一个位置置换 $g$ 有 $c(g)$ 个循环，用 $q$ 种颜色任意染色，则被 $g$ 固定的染色数为 $q^{c(g)}$，所以

$$
\#\text{本质不同染色}
=\frac1{|G|}\sum_{g\in G}q^{c(g)}.
$$

长度为 $n$、只视旋转相同的 $q$ 色项链数为

$$
\frac1n\sum_{r=0}^{n-1}q^{\gcd(n,r)}
=\frac1n\sum_{d\mid n}\varphi(d)q^{n/d}.
$$

若还把翻转视为相同，则要把二面体群中的反射也加入 Burnside 求和；$n$ 的奇偶会导致反射循环结构不同，不能直接把旋转答案除以 $2$。

Pólya 的循环指标为

$$
Z_G(s_1,s_2,\ldots)
=\frac1{|G|}\sum_{g\in G}\prod_{j\ge1}s_j^{c_j(g)},
$$

其中 $c_j(g)$ 是 $g$ 中长度为 $j$ 的循环数。若颜色还带权，把 $s_j$ 替换为所有颜色权值的 $j$ 次幂和，即可同时记录各颜色使用次数。

## 推式子的常用检查方法

1. **双计数**：从两种顺序选择同一个带标记结构，常得到 Vandermonde 或组合数乘积恒等式。
2. **差分**：证明 $F(n)=G(n)$ 时，比较两边的一阶差分并核对初值；Hockey-stick 尤其适合这样处理。
3. **生成函数比较系数**：卷积、前缀和、递推与换基通常可直接转成乘法或除法。
4. **反射/双射**：格路边界、括号序列和 Catalan 问题优先寻找第一次越界点。
5. **容斥后交换求和**：先固定违反条件的集合，再按每个对象被统计的次数合并。
6. **小值验符号**：第一类 Stirling、Möbius、五边形数和二项式反演都很容易差一个 $(-1)$；至少检查 $n=0,1,2,3$。

## 参考

- [OI Wiki：排列组合](https://oi-wiki.org/math/combinatorics/combination/)
- [OI Wiki：Catalan 数](https://oi-wiki.org/math/combinatorics/catalan/)
- [OI Wiki：分拆数与五边形数定理](https://oi-wiki.org/math/combinatorics/partition/)
- [OI Wiki：Pólya 计数](https://oi-wiki.org/math/combinatorics/polya/)
- [OI Wiki：普通生成函数](https://oi-wiki.org/math/poly/ogf/)
