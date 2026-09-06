# 完整多项式与形式幂级数库

这是自包含的高级版本，固定模数为 $998244353$。若只需要卷积、逆、对数、指数和普通整数幂，使用 `16-polynomial.md` 更短；需要下表中的高级操作时使用本文件。

| 接口 | 含义 | 主要前提 |
| --- | --- | --- |
| `fps_inv` | 形式幂级数逆 | $f_0\ne0$ |
| `fps_ln` | 形式对数 | $f_0=1$ |
| `fps_exp` | 形式指数 | $f_0=0$ |
| `fps_pow` | 十进制大指数幂 | 指数非负 |
| `fps_sqrt` | 形式平方根 | 前导零次数为偶数且首项有平方根 |
| `divmod` | 多项式商和余数 | 除式非零 |
| `multipoint_eval` | 多点求值 | 无 |
| `fast_interpolate` | 多点插值 | 横坐标两两不同 |
| `bostan_mori` | $[x^k]P/Q$ | $Q(0)\ne0$ |
| `taylor_shift` | $f(x+c)$ | 次数小于模数 |
| `compose` | $f(g(x))$ | 返回模 $x^{\deg f+1}$ |
| `power_projection` | 同时求 $[x^k]f(x)^i$ | 给定目标次数与项数 |
| `compositional_inverse` | 复合逆 | $f(0)=0,f'(0)\ne0$ |

多项式均按升幂存储。代码中的二维 Bostan--Mori 使用 Kronecker 代换，复合、幂投影和复合逆不是朴素占位实现。

## 方法、推导与复杂度

下面统一记 $M(n)$ 为两个 $n$ 次以内多项式的卷积复杂度；在本模数下使用 NTT，故 $M(n)=O(n\log n)$。所有 FPS 接口的第二个参数 `n` 都表示只保留模 $x^n$ 的前 $n$ 项。

### NTT 与卷积

DFT 把卷积变成逐点乘法。模 $998244353$ 中存在最大阶为 $2^{23}$ 的单位根，因此可把复数单位根替换为有限域单位根：

$$
\widehat a_k=\sum_{j=0}^{N-1}a_j\omega_N^{jk},
\qquad
a_j=N^{-1}\sum_{k=0}^{N-1}\widehat a_k\omega_N^{-jk}.
$$

Cooley--Tukey 每层按下标奇偶拆分，代码用位逆序迭代实现，并缓存每种长度的旋转因子。卷积先补零到不小于 $|A|+|B|-1$ 的二次幂，正变换后逐点相乘再逆变换。复杂度 $O(M(n))$，长度不得超过 $2^{23}$。

### FPS Newton 迭代的一般形式

令 $h(x)$ 为已知 FPS、$f(x)$ 为待求 FPS。先把目标关系写成

$$
g(f)=F(f)-h=0,
$$

然后把 $h$ 当作常量，对未知量 $f$ 求导。对当前近似值加入修正量 $\Delta$：

$$
g(f+\Delta)
=g(f)+\frac{\partial g}{\partial f}\Delta+O(\Delta^2).
$$

令一次项抵消当前误差，得到

$$
\Delta=-\left(\frac{\partial g}{\partial f}\right)^{-1}g(f),
\qquad
f_{\mathrm{new}}=f+\Delta.
$$

下面的求逆、指数和平方根都从这一步代入对应的 $g(f)$，而不是直接背最终更新式。这里涉及的导数都是对未知 FPS $f$ 的形式导数；在交换的 FPS 环中，下列导数算子都是乘法算子，所以可以写成通常的分式形式。

### FPS 逆：牛顿迭代从哪里来

已知 $h$，要求 $f=h^{-1}\pmod{x^n}$。写成

$$
g(f)=f^{-1}-h=0,
\qquad
\frac{\partial g}{\partial f}=-f^{-2}.
$$

代入 Newton 公式：

$$
f_{\mathrm{new}}
=f-\frac{f^{-1}-h}{-f^{-2}}
=f(2-hf).
$$

也可直接看误差：若 $hf=1-e$ 且 $e\equiv0\pmod{x^m}$，则

$$
h\,f(2-hf)=(1-e)(1+e)=1-e^2
\equiv1\pmod{x^{2m}}.
$$

所以每轮正确长度由 $m$ 翻倍到 $2m$。初值为 $f_0=h_0^{-1}$，故要求 $h_0\ne0$；总复杂度 $O(M(n))$。

### 求导、积分与形式对数

求导、积分逐项进行。积分的第 $i$ 项要除以 $i$，所以截断次数必须小于模数。由

$$
(\ln f)'=\frac{f'}f
$$

得到

$$
\ln f=\int f' f^{-1}\,dx.
$$

实现约定积分常数为 $0$，因此标准接口要求 $f_0=1$。复杂度由一次求逆和卷积主导，为 $O(M(n))$。

### FPS 指数：对 $\ln f-h=0$ 做牛顿迭代

已知 $h$，要求 $f=\exp(h)$。写成

$$
g(f)=\ln f-h=0,
\qquad
\frac{\partial g}{\partial f}=f^{-1}.
$$

Newton 更新为

$$
f_{\mathrm{new}}
=f-\frac{\ln f-h}{f^{-1}}
=f(1+h-\ln f).
$$

若 $f$ 已在模 $x^m$ 下正确，新值就在模 $x^{2m}$ 下正确。形式指数的常数项固定为 $1$，故输入要求 $h_0=0$。复杂度 $O(M(n))$。

### FPS 幂

先找到最低非零项 $f_t x^t$，写成

$$
f(x)=x^t f_t h(x),\qquad h(0)=1.
$$

于是对非负整数 $k$，

$$
f(x)^k=x^{tk}f_t^k\exp(k\ln h(x)).
$$

这里必须把 $k$ 的三种用途分开处理，不能笼统地说“指数取模”。设模数为质数 $p=998244353$：

1. **位移 $x^{tk}$：使用原始整数 $k$。** 指数代表次数，不是有限域元素，不能对 $p$ 或 $p-1$ 取模。算法只需判断 $tk<n$；若 $tk\ge n$，模 $x^n$ 的答案全为零。
2. **非零常数 $f_t^k$：指数对 $p-1$ 取模。** 因为 $f_t\in\mathbb F_p^*$，由 Fermat 定理 $f_t^{p-1}=1$，所以这里只需 $k\bmod(p-1)$。
3. **单位 FPS 的 $\exp(k\ln h)$：标量 $k$ 对 $p$ 取模。** `ln h` 的每个系数都在 $\mathbb F_p$ 中，乘整数 $k$ 就是把 $k$ 映射到域内，因此只取 $k\bmod p$。

第三点也可直接用 Frobenius 解释。因为 $h(0)=1$，在特征 $p$ 的域中

$$
h(x)^p=h(x^p)=1+O(x^p).
$$

当只保留模 $x^n$ 且 $n\le p$ 的项时，$h(x)^p\equiv1\pmod{x^n}$，于是

$$
h(x)^{k+p}\equiv h(x)^k\pmod{x^n}.
$$

这就是单位部分的指数周期为 $p$ 的直接原因。例如在 $\mathbb F_7$ 中，模 $x^7$ 有

$$
(1+x)^8=(1+x)(1+x)^7\equiv1+x,
$$

与指数 $8\bmod7=1$ 一致；但若保留到 $x^7$ 项，即模 $x^8$，则 $(1+x)^7=1+x^7\not\equiv1$，此时便不能把指数只对 $7$ 取模。这也说明模板为什么要求截断长度 $n\le p$。

综上，代码分别计算：用于位移判断的有界原始 $k$、`k_mod = k mod p`、`k_phi = k mod (p-1)`。三者不能互换。复杂度 $O(M(n))$。

### FPS 平方根

先删除前导零。最低非零次数必须为偶数，否则不可能是平方；首项还必须在模意义下有平方根，代码用 Tonelli--Shanks 求它。

记去掉前导项后的已知 FPS 为 $h$，待求平方根为 $f$。从

$$
g(f)=f^2-h=0,
\qquad
\frac{\partial g}{\partial f}=2f
$$

开始，Newton 更新为

$$
f_{\mathrm{new}}
=f-\frac{f^2-h}{2f}
=\frac12\left(f+\frac hf\right).
$$

每轮同样把正确精度翻倍，复杂度 $O(M(n))$。平方根通常有正负两支，接口返回 Tonelli--Shanks 选出的其中一支；无解返回空数组。

### 多项式除法

若 $A=BQ+R$ 且 $\deg R<\deg B$，设商长为 $k=\deg A-\deg B+1$。把系数反转后，高次项变成低次项，而余数落到不影响前 $k$ 项的位置：

$$
\operatorname{rev}(Q)
\equiv\operatorname{rev}(A)\,
       \operatorname{rev}(B)^{-1}\pmod{x^k}.
$$

求出商后再算 $R=A-BQ$。复杂度 $O(M(n))$，除式必须非零。

### 多点求值

对点 $x_i$ 建乘积树：叶子是 $M_i(x)=x-x_i$，结点维护

$$
M_{[l,r)}(x)=\prod_{i=l}^{r-1}(x-x_i).
$$

根处先求 $f\bmod M$，再向下分别对两个儿子的 $M$ 取模；叶子的常数余数就是 $f(x_i)$。模板把乘积树存成反转形式，使每层取模归约为卷积，复杂度 $O(M(n)\log n)$。

### 快速插值

令 $M(x)=\prod_i(x-x_i)$。Lagrange 公式写成

$$
f(x)=\sum_i\frac{y_i}{M'(x_i)}\frac{M(x)}{x-x_i}.
$$

先用多点求值算出全部 $M'(x_i)$，叶子权值为 $w_i=y_i/M'(x_i)$。乘积树上合并两个区间时使用

$$
F_{L\cup R}=F_LM_R+F_RM_L.
$$

根结点即插值多项式。批量逆元只做一次快速幂；横坐标必须两两不同。复杂度 $O(M(n)\log n)$。

### Bostan--Mori

要求 $[x^k]P(x)/Q(x)$。构造 $Q(-x)$ 后，

$$
Q(x)Q(-x)
$$

只含偶次项。若 $k$ 为偶数，$P(x)Q(-x)$ 只保留偶次项；若 $k$ 为奇数则只保留奇次项。随后令 $x^2\gets x$、$k\gets\lfloor k/2\rfloor$，目标下标每轮减半。复杂度 $O(M(d)\log k)$，其中 $d$ 是分母次数，并要求 $Q(0)\ne0$。

### Taylor shift

由二项式定理，

$$
[x^j]f(x+c)
=\frac1{j!}\sum_{i\ge j}(f_i i!)\frac{c^{i-j}}{(i-j)!}.
$$

把序列 $f_i i!$ 反转后，右侧就是一次普通卷积，故可在 $O(M(n))$ 内求出全部系数。

### 多项式复合

目标是 $f(g(x))\bmod x^{n+1}$。当 $g(0)\ne0$ 时，先做 Taylor shift：把常数项吸收到 $f(x+g_0)$，再令 $g_0=0$。

对 $g(0)=0$，使用二元恒等式

$$
\sum_{i\ge0}g(x)^iy^i=\frac1{1-yg(x)}.
$$

于是复合可转化为关于 $x,y$ 的二维 Bostan--Mori。每轮用 $V(-x,y)$ 消掉分母的奇数次 $x$，再令 $x^2\gets x$。实现先保存每轮分母核，再反向应用转置乘法；二维卷积通过 Kronecker 代换

$$
x^iy^j\longmapsto z^{i\cdot\text{stride}+j}
$$

压成一次 NTT。每轮 $x$ 次数约减半、$y$ 次数约翻倍，打包后的一维有效长度保持在线性量级；总复杂度为 $O(M(n)\log n)$。这个实现面向大规模复合，不是朴素 $O(n^2)$ 版本。

### 转置原理：乘法、除法和复合的转置

在有限维系数空间中取标准内积

$$
\langle a,b\rangle=\sum_i a_i b_i.
$$

若线性映射 $L$ 满足

$$
\langle L(a),b\rangle=\langle a,L^{\mathsf T}(b)\rangle,
$$

则 $L^{\mathsf T}$ 称为 $L$ 的转置。转置原理说：一段只包含加法、常数乘法和复制的直线程序，倒序执行并把“取值”改成“累加贡献”，就能以同阶复杂度计算转置映射。这里的转置是线性代数意义，不是简单 `reverse`；反转系数只是实现卷积转置时出现的工具。

#### 乘法的转置：middle product

固定 $f$，考虑截断乘法

$$
h_k=[x^k]f(x)g(x)=\sum_i f_i g_{k-i}.
$$

若输出端给定权值 $w_k$，则

$$
\sum_k w_kh_k
=\sum_j g_j\left(\sum_i f_iw_{i+j}\right).
$$

所以转置后第 $j$ 项是 $\sum_i f_iw_{i+j}$。它等价于把 $f$ 或 $w$ 反转后做一次卷积，再截取中间连续的一段，因此通常称为 `middle product`。完整代码中的 `multiply_transpose` 正是在二维 Kronecker 编码下做这个操作。

#### 固定除式时，除法的转置

FPS 除法在除式 $q$ 固定时是关于被除式 $p$ 的线性映射：

$$
D_q(p)=p\,q^{-1}\pmod{x^n}.
$$

因此

$$
D_q^{\mathsf T}=M_{q^{-1}}^{\mathsf T},
$$

即先求一次 $q^{-1}$，再使用上面的 middle product。若讨论普通多项式长除法的“取商”映射，则正向过程为

$$
p\xrightarrow{\text{反转、截取}}
\operatorname{rev}(p)
\xrightarrow{\times\operatorname{rev}(q)^{-1}}
\operatorname{rev}(\operatorname{quotient}),
$$

转置时必须把这三步反向执行：先把输出权值放回对应截取区间，再做乘法的转置，最后反转回来。不能只写成“再除一次 $q$”。

例如在模 $x^4$ 下固定

$$
q^{-1}(x)=r_0+r_1x+r_2x^2+r_3x^3.
$$

正向输出 $h_k=\sum_{i=0}^{k}p_i r_{k-i}$。给定输出权值 $w_0,\ldots,w_3$，转置输出为

$$
p_j\text{ 的权值}
=\sum_{k=j}^{3}w_k r_{k-j},
$$

这正是一段相关运算，也就是反转卷积后的中间段。

#### 复合的转置就是幂投影

固定内层多项式 $g$，映射

$$
C_g:f\longmapsto f(g(x))\pmod{x^n}
$$

对 $f$ 的系数是线性的，因为

$$
f(g(x))=\sum_i f_i g(x)^i.
$$

设输出端权值多项式为 $w$，则

$$
\begin{aligned}
\langle C_g(f),w\rangle
&=\sum_j w_j[x^j]\sum_i f_i g(x)^i\\
&=\sum_i f_i\left(\sum_jw_j[x^j]g(x)^i\right).
\end{aligned}
$$

故

$$
\bigl(C_g^{\mathsf T}(w)\bigr)_i
=\sum_jw_j[x^j]g(x)^i.
$$

若 $w=x^k$，转置输出恰为

$$
\bigl([x^k]g(x)^0,[x^k]g(x)^1,\ldots\bigr),
$$

这就是幂投影。换句话说，`power_projection(g,k,m)` 是“复合映射的转置作用在第 $k$ 个坐标基向量上”，而不是另一个无关技巧。

例如 $g=x+x^2$，取 $k=2$，则

$$
[x^2]g^0=0,
\quad [x^2]g^1=1,
\quad [x^2]g^2=1,
\quad [x^2]g^i=0\ (i\ge3).
$$

因此前四项幂投影是 $(0,1,1,0)$。它与任意 $f=f_0+f_1x+f_2x^2+f_3x^3$ 做内积，得到 $f_1+f_2$，也正是 $[x^2]f(x+x^2)$。

需要注意：$C_g$ 只在固定 $g$、变化 $f$ 时是线性的；把 $f$ 固定而改变 $g$ 并不是线性映射，不能直接套转置原理。

### 幂投影：复合转置的专用实现

要求同时得到

$$
c_i=[x^k]f(x)^i,\qquad 0\le i<m.
$$

仍由

$$
\sum_{i\ge0}f(x)^iy^i=\frac1{1-yf(x)}
$$

可知答案是该二元有理式在 $x^k$ 处、关于 $y$ 的前 $m$ 项。直接执行二维 Bostan--Mori，每轮按当前 $k$ 的奇偶抽取分子、只抽取分母偶次项即可。

打包卷积部分复杂度为 $O(M(k)\log k)$，最后还需一次长度 $m$ 的 FPS 逆，合计 $O(M(k)\log k+M(m))$。

### 复合逆

要求 $G(F(x))=x\pmod{x^n}$，前提是 $F(0)=0,F'(0)\ne0$。先除以线性项，把 $A'(0)$ 归一为 $1$。设 $H=A^{\langle-1\rangle}$，固定 $N=n-1$；Lagrange 反演把 $H$ 的系数转化为 $[x^N]A(x)^k$，这些值可由一次幂投影同时得到。构造

$$
S(x)=\sum_{k=1}^{N}\frac Nk[x^N]A(x)^k\,x^{N-k}
=\left(\frac{x}{H(x)}\right)^N,
$$

便有

$$
H(x)=xS(x)^{-1/N}.
$$

最后缩放变量恢复原来的线性系数。代码用 `ln/exp` 计算 $S^{-1/N}$。

它由一次规模 $n$ 的幂投影和常数次 FPS 操作组成，复杂度为 $O(M(n)\log n)$。

## 完整实现

```cpp
#include<vector>
#include<array>
#include<iostream>
#include<algorithm>
#include<limits>
#include<cassert>
#include<optional>
#include<string>
#include<random>
using namespace std;

// ============================================================
// 1. NTT
// ============================================================

template <int modulus_, int root_, int inverse_root_>
struct NTT {
    static constexpr int mod = modulus_;
    static constexpr int root = root_;
    static constexpr int iroot = inverse_root_;

    static int qpow(int a, long long e) {
        int r = 1;
        while (e) {
            if (e & 1) r = (int)(1LL * r * a % mod);
            a = (int)(1LL * a * a % mod);
            e >>= 1;
        }
        return r;
    }

    static int add(int a, int b) {
        a += b;
        return a >= mod ? a - mod : a;
    }

    static int sub(int a, int b) {
        a -= b;
        return a < 0 ? a + mod : a;
    }

private:
    inline static vector<vector<int>> rev_cache;
    inline static vector<vector<int>> roots, iroots;
    inline static int built_level = 0;

    static const vector<int>& get_rev(int level) {
        if ((int)rev_cache.size() <= level)
            rev_cache.resize(level + 1);

        auto& rev = rev_cache[level];
        if (!rev.empty()) return rev;

        int n = 1 << level;
        rev.resize(n);
        for (int i = 1; i < n; ++i)
            rev[i] = (rev[i >> 1] >> 1) | ((i & 1) << (level - 1));
        return rev;
    }

    static void ensure_roots(int level) {
        if (level <= built_level) return;

        roots.resize(level + 1);
        iroots.resize(level + 1);

        for (int t = built_level + 1; t <= level; ++t) {
            int half = 1 << (t - 1);
            roots[t].resize(half);
            iroots[t].resize(half);

            int w = qpow(root, (mod - 1) >> t);
            int iw = qpow(iroot, (mod - 1) >> t);
            roots[t][0] = iroots[t][0] = 1;

            for (int i = 1; i < half; ++i) {
                roots[t][i] = (int)(1LL * roots[t][i - 1] * w % mod);
                iroots[t][i] = (int)(1LL * iroots[t][i - 1] * iw % mod);
            }
        }
        built_level = level;
    }

public:
    // a.size() 必须是 2 的幂；正逆变换均为自然顺序输入、自然顺序输出。
    static void transform(vector<int>& a, bool inverse = false) {
        int n = (int)a.size();
        assert(n > 0 && (n & (n - 1)) == 0);
        assert((mod - 1) % n == 0); // 防止 NTT 长度超过模数支持范围

        int level = __builtin_ctz((unsigned)n);
        ensure_roots(level);
        const auto& rev = get_rev(level);

        // 同一 NTT 长度的位逆序表只构造一次。
        for (int i = 0; i < n; ++i)
            if (i < rev[i]) swap(a[i], a[rev[i]]);

        const auto& table = inverse ? iroots : roots;
        for (int half = 1, t = 1; half < n; half <<= 1, ++t) {
            int block = half << 1;
            const auto& w = table[t];
            for (int l = 0; l < n; l += block) {
                for (int j = 0; j < half; ++j) {
                    int u = a[l + j];
                    int v = (int)(1LL * a[l + j + half] * w[j] % mod);
                    a[l + j] = add(u, v);
                    a[l + j + half] = sub(u, v);
                }
            }
        }

        if (!inverse) return;
        int inv_n = qpow(n, mod - 2);
        for (int& x : a) x = (int)(1LL * x * inv_n % mod);
    }
};

// ============================================================
// 2. 多项式基础设施
// ============================================================

namespace polyops {

using poly = vector<int>;
using Ntt = NTT<998244353, 3, 332748118>;
static constexpr int mod = Ntt::mod;

// 取前 n 项，不足补 0。
poly prefix(const poly& f, int n) {
    assert(n >= 0);
    poly r(f.begin(), f.begin() + min(n, (int)f.size()));
    r.resize(n);
    return r;
}

// 删除高位 0；零多项式统一保留为 {0}。
void normalize(poly& f) {
    while (f.size() > 1 && f.back() == 0) f.pop_back();
    if (f.empty()) f.push_back(0);
}

// 多项式乘法。
// 参数按值传递：调用方若不再需要原对象，可显式 std::move 以避免复制。
poly mul(poly a, poly b) {
    if (a.empty() || b.empty()) return {};

    int na = (int)a.size();
    int nb = (int)b.size();

    if (min(na, nb) <= 32) {
        poly c(na + nb - 1);
        for (int i = 0; i < na; ++i) {
            long long ai = a[i];
            for (int j = 0; j < nb; ++j)
                c[i + j] = (int)((c[i + j] + ai * b[j]) % mod);
        }
        return c;
    }

    int need = na + nb - 1;
    int ntt_len = 1;
    while (ntt_len < need) ntt_len <<= 1;

    a.resize(ntt_len);
    b.resize(ntt_len);
    Ntt::transform(a);
    Ntt::transform(b);

    for (int i = 0; i < ntt_len; ++i)
        a[i] = (int)(1LL * a[i] * b[i] % mod);

    Ntt::transform(a, true);
    a.resize(need);
    return a;
}

// ============================================================
// 3. FPS：逆 / 导数 / 积分 / ln / exp
// ============================================================

// f^{-1} mod x^n，要求 f[0] != 0。
//
// 设当前 g 已满足 f*g = 1 (mod x^m)，误差 e = 1-f*g 含有因子 x^m。
// 令 g_new = g*(2-f*g) = g*(1+e)，则
//     1-f*g_new = 1-(1-e)(1+e) = e^2 = 0 (mod x^{2m})。
// 因而每轮把正确项数翻倍，这就是下面牛顿迭代的来源。
poly fps_inv(const poly& f, int n) {
    assert(n >= 0);
    if (n == 0) return {};
    assert(!f.empty() && f[0] != 0);

    poly g{Ntt::qpow(f[0], mod - 2)};
    if (n == 1) return g;

    for (int len = 2;; len <<= 1) {
        int cur = min(len, n);
        poly f_cut = prefix(f, cur);

        // 在频域一次完成 g * (2 - f*g)，比写两次 convolution 常数更小。
        int ntt_len = 1;
        while (ntt_len < cur * 2) ntt_len <<= 1;

        g.resize(ntt_len);
        f_cut.resize(ntt_len);
        Ntt::transform(g);
        Ntt::transform(f_cut);

        for (int i = 0; i < ntt_len; ++i) {
            int fg = (int)(1LL * f_cut[i] * g[i] % mod);
            g[i] = (int)(1LL * g[i] * ((2 - fg + mod) % mod) % mod);
        }

        Ntt::transform(g, true);
        g.resize(cur);
        if (cur == n) break;
    }
    return g;
}

poly derivative(const poly& f) {
    if (f.size() <= 1) return {};
    poly g(f.size() - 1);
    for (int i = 1; i < (int)f.size(); ++i)
        g[i - 1] = (int)(1LL * f[i] * i % mod);
    return g;
}

namespace fps_detail {

// 积分会频繁用到 1/i，线性预处理比每项快速幂更清楚也更快。
inline vector<int> inv_int{0, 1};

void ensure_inv_int(int n) {
    assert(n < mod);
    if ((int)inv_int.size() > n) return;

    int old = (int)inv_int.size();
    inv_int.resize(n + 1);
    for (int i = max(2, old); i <= n; ++i)
        inv_int[i] =
            (int)(mod - 1LL * (mod / i) * inv_int[mod % i] % mod);
}

} // namespace fps_detail

poly integral(const poly& f) {
    fps_detail::ensure_inv_int((int)f.size());
    poly g(f.size() + 1);
    for (int i = 0; i < (int)f.size(); ++i)
        g[i + 1] =
            (int)(1LL * f[i] * fps_detail::inv_int[i + 1] % mod);
    return g;
}

// ln(f) mod x^n = integral(f' / f)，要求 f[0] != 0。
// 这是形式幂级数恒等式 (ln f)' = f'/f；积分常数约定为 0。
poly fps_ln(const poly& f, int n) {
    assert(n >= 0);
    if (n == 0) return {};
    assert(!f.empty() && f[0] != 0);

    poly df = derivative(f);
    poly inv_f = fps_inv(f, n);
    poly g = mul(df, inv_f);
    g.resize(max(0, n - 1));
    g = integral(g);
    g.resize(n);
    return g;
}

// exp(f) mod x^n，要求 f[0] = 0。
//
// 把目标写成方程 Phi(g)=ln(g)-f=0。由于 Phi'(g)=1/g，牛顿迭代为
//     g_new = g - (ln g-f)/(1/g) = g*(1+f-ln g)。
// 若 g 在模 x^m 下正确，新值就在模 x^{2m} 下正确。
poly fps_exp(const poly& f, int n) {
    assert(n >= 0);
    if (n == 0) return {};
    assert(f.empty() || f[0] == 0);

    poly g{1};
    for (int len = 2;; len <<= 1) {
        int cur = min(len, n);

        poly delta = prefix(f, cur);
        poly log_g = fps_ln(g, cur);
        for (int i = 0; i < cur; ++i)
            delta[i] = (delta[i] - log_g[i] + mod) % mod;
        delta[0] = (delta[0] + 1) % mod;

        g = mul(g, delta);
        g.resize(cur);
        if (cur == n) break;
    }
    return g;
}

// ============================================================
// 4. FPS 幂
// ============================================================

namespace power_detail {

long long decimal_mod(const string& s, long long m) {
    long long r = 0;
    for (char ch : s) r = (r * 10 + ch - '0') % m;
    return r;
}

bool is_zero(const string& s) {
    for (char ch : s)
        if (ch != '0') return false;
    return true;
}

// 若十进制整数 <= limit，返回其值；否则返回 nullopt。
optional<long long> parse_bounded(const string& s, long long limit) {
    long long x = 0;
    for (char ch : s) {
        int d = ch - '0';
        if (x > limit / 10 || (x == limit / 10 && d > limit % 10))
            return nullopt;
        x = x * 10 + d;
    }
    return x;
}

} // namespace power_detail

// f^k mod x^n，k 用十进制字符串表示，可非常大。
poly fps_pow(const poly& f, const string& k_str, int n) {
    assert(n >= 0);
    assert(n <= mod);
    if (n == 0) return {};

    if (power_detail::is_zero(k_str)) {
        poly ans(n);
        ans[0] = 1;
        return ans;
    }

    int valuation = 0;
    while (valuation < (int)f.size() && f[valuation] == 0) ++valuation;
    if (valuation == (int)f.size()) return poly(n, 0);

    // x^{valuation * k} 若已经达到 x^n，答案直接为 0。
    long long shift = 0;
    if (valuation > 0) {
        long long max_k = (n - 1) / valuation;
        auto k_small = power_detail::parse_bounded(k_str, max_k);
        if (!k_small) return poly(n, 0);
        shift = 1LL * valuation * *k_small;
    }

    long long k_mod = power_detail::decimal_mod(k_str, mod);
    long long k_phi = power_detail::decimal_mod(k_str, mod - 1);

    int lead = f[valuation];
    int inv_lead = Ntt::qpow(lead, mod - 2);
    int need = n - (int)shift;

    // 分解 f = x^valuation * lead * unit，其中 unit[0] = 1，于是
    // f^k = x^{valuation*k} * lead^k * exp(k*ln(unit))。
    // unit[0]=1 且 need<=mod，所以 unit^mod=1 (mod x^need)：
    // 单位部分的标量 k 取模 mod；非零常数 lead 的指数取模 mod-1；
    // 位移 valuation*k 已在上面用原始整数单独判断，三者不能混用。
    poly unit(f.begin() + valuation, f.end());
    unit.resize(need);
    for (int& x : unit) x = (int)(1LL * x * inv_lead % mod);

    poly log_unit = fps_ln(unit, need);
    for (int& x : log_unit) x = (int)(1LL * x * k_mod % mod);
    poly unit_pow = fps_exp(log_unit, need);

    int lead_pow = Ntt::qpow(lead, k_phi);
    poly ans(n);
    for (int i = 0; i < need; ++i)
        ans[i + shift] = (int)(1LL * unit_pow[i] * lead_pow % mod);
    return ans;
}

// ============================================================
// 5. FPS 开方
// ============================================================

namespace sqrt_detail {

// Tonelli-Shanks：求模 mod 的平方根；无解返回 -1。
int mod_sqrt(int x) {
    if (x == 0) return 0;
    if (Ntt::qpow(x, (mod - 1) / 2) != 1) return -1;

    int q = mod - 1, s = 0;
    while ((q & 1) == 0) q >>= 1, ++s;

    int z = 2;
    while (Ntt::qpow(z, (mod - 1) / 2) != mod - 1) ++z;

    int c = Ntt::qpow(z, q);
    int t = Ntt::qpow(x, q);
    int r = Ntt::qpow(x, (q + 1) / 2);
    int m = s;

    while (t != 1) {
        int i = 0;
        int tt = t;
        while (tt != 1) {
            tt = (int)(1LL * tt * tt % mod);
            ++i;
        }

        int b = Ntt::qpow(c, 1LL << (m - i - 1));
        int bb = (int)(1LL * b * b % mod);
        r = (int)(1LL * r * b % mod);
        t = (int)(1LL * t * bb % mod);
        c = bb;
        m = i;
    }
    return r;
}

} // namespace sqrt_detail

// sqrt(f) mod x^n；不存在时返回空 vector。
// 去掉偶数阶前导零后，对 g^2=f 使用牛顿迭代：
//     g_new = (g + f/g) / 2。
// 与求逆相同，每轮把正确精度从 x^m 提升到 x^{2m}。
poly fps_sqrt(const poly& f, int n) {
    assert(n >= 0);
    if (n == 0) return {};

    int valuation = 0;
    while (valuation < (int)f.size() && f[valuation] == 0) ++valuation;
    if (valuation == (int)f.size()) return poly(n, 0);
    if (valuation & 1) return {};

    int shift = valuation / 2;
    if (shift >= n) return poly(n, 0);

    int root = sqrt_detail::mod_sqrt(f[valuation]);
    if (root == -1) return {};

    int need = n - shift;
    poly unit(f.begin() + valuation, f.end());
    unit.resize(need);

    static const int inv2 = (mod + 1) / 2;
    poly g{root};

    for (int len = 2;; len <<= 1) {
        int cur = min(len, need);
        poly inv_g = fps_inv(g, cur);
        poly q = mul(prefix(unit, cur), inv_g);
        q.resize(cur);
        g.resize(cur);

        for (int i = 0; i < cur; ++i)
            g[i] = (int)(1LL * (g[i] + q[i]) * inv2 % mod);

        if (cur == need) break;
    }

    poly ans(n);
    for (int i = 0; i < need; ++i) ans[i + shift] = g[i];
    return ans;
}

// ============================================================
// 6. 多项式除法
// ============================================================

// 返回 {商, 余数}。输入按普通多项式解释，会自动去掉高位 0。
//
// 若 A=BQ+R 且 deg R<deg B，把系数反转后，R 会落在不影响前 q_len 项的
// 高次位置，因此有 rev(Q)=rev(A)/rev(B) (mod x^q_len)。求出商后再用
// R=A-BQ 恢复余数。这样多项式除法就归约成一次 FPS 求逆和两次乘法。
pair<poly, poly> divmod(poly a, poly b) {
    normalize(a);
    normalize(b);
    assert(!(b.size() == 1 && b[0] == 0));

    int n = (int)a.size();
    int m = (int)b.size();
    if (n < m) return {{0}, a};

    int q_len = n - m + 1;
    poly ra = a, rb = b;
    reverse(ra.begin(), ra.end());
    reverse(rb.begin(), rb.end());
    ra.resize(q_len);
    rb.resize(q_len);

    poly q = mul(ra, fps_inv(rb, q_len));
    q.resize(q_len);
    reverse(q.begin(), q.end());

    poly prod = mul(q, b);
    poly r(max(0, m - 1));
    for (int i = 0; i < m - 1; ++i) {
        int pi = i < (int)prod.size() ? prod[i] : 0;
        r[i] = (a[i] - pi + mod) % mod;
    }

    normalize(q);
    if (r.empty()) r = {0};
    else normalize(r);
    return {q, r};
}

// ============================================================
// 7. 多点求值
// ============================================================

namespace multipoint_detail {

struct Evaluator {
    vector<int> points;
    // 对区间 [l,r)，令 M_p(x)=prod_{i=l}^{r-1}(x-x_i)。
    // tree[p] 存的是固定长度 r-l+1 的 rev(M_p)，即 prod(1-x_i*x)。
    // 翻转表示既适合下面的快速取模，也能被插值的自底向上合并直接复用。
    vector<poly> tree;
    vector<int> answer;

    void build(int p, int l, int r) {
        if (r - l == 1) {
            tree[p] = {1, points[l] ? mod - points[l] : 0};
            return;
        }

        int mid = (l + r) >> 1;
        build(p << 1, l, mid);
        build(p << 1 | 1, mid, r);
        tree[p] = mul(tree[p << 1], tree[p << 1 | 1]);
    }

    // q 是当前区间余数的翻转表示。
    //
    // 从父亲向左儿子取模，相当于在翻转域中乘上右儿子的 rev(M_R)，
    // 再截取中间连续的 left_len 项；向右同理。这个写法把每层的多项式
    // 除法变成两次卷积，不必在每个结点各做一次 FPS 求逆，常数明显更小。
    void descend(int p, int l, int r, const poly& q) {
        if (r - l == 1) {
            answer[l] = q[0];
            return;
        }

        int mid = (l + r) >> 1;
        int left_len = mid - l;
        int right_len = r - mid;

        poly to_left = mul(q, tree[p << 1 | 1]);
        poly left_q(left_len);
        for (int i = 0; i < left_len; ++i)
            left_q[i] = to_left[i + right_len];
        descend(p << 1, l, mid, left_q);

        poly to_right = mul(q, tree[p << 1]);
        poly right_q(right_len);
        for (int i = 0; i < right_len; ++i)
            right_q[i] = to_right[i + left_len];
        descend(p << 1 | 1, mid, r, right_q);
    }

    void init(const vector<int>& xs) {
        assert(!xs.empty());
        points.resize(xs.size());
        for (int i = 0; i < (int)xs.size(); ++i) {
            int x = xs[i] % mod;
            points[i] = x < 0 ? x + mod : x;
        }
        int m = (int)points.size();
        tree.assign(m << 2, {});
        answer.assign(m, 0);
        build(1, 0, m);
    }

    vector<int> evaluate(const poly& f) {
        int m = (int)points.size();
        assert(m > 0);

        // 根结点是 rev(M)。rev(f) / rev(M) 的低位给出商；这里把除法与
        // 余数树合并整理后，只需根结点的一次逆，再由 descend 逐层下传。
        int work_len = max(m, (int)f.size());
        poly inv_root = fps_inv(tree[1], work_len);

        poly rev_f = f;
        rev_f.resize(work_len);
        reverse(rev_f.begin(), rev_f.end());
        poly q = mul(rev_f, inv_root);

        poly root_q(m);
        for (int i = 0; i < m; ++i)
            root_q[i] = q[work_len - m + i];

        descend(1, 0, m, root_q);
        return answer;
    }

    vector<int> solve(const poly& f, const vector<int>& xs) {
        if (xs.empty()) return {};
        init(xs);
        return evaluate(f);
    }

};

} // namespace multipoint_detail

vector<int> multipoint_eval(const poly& f, const vector<int>& xs) {
    return multipoint_detail::Evaluator{}.solve(f, xs);
}

// ============================================================
// 8. 多项式快速插值
// ============================================================

namespace interpolation_detail {

// 批量求非零元素的逆：前缀积 + 一次快速幂 + 反向扫描。
// 与逐个 qpow 相比，把 n 次 O(log mod) 求逆降为一次，插值时常数更小。
vector<int> batch_inverse_nonzero(const vector<int>& a) {
    int n = (int)a.size();
    vector<int> pref(n + 1, 1), inv(n);
    for (int i = 0; i < n; ++i) {
        assert(a[i] != 0);
        pref[i + 1] = (int)(1LL * pref[i] * a[i] % mod);
    }

    int suffix_inv = Ntt::qpow(pref[n], mod - 2);
    for (int i = n - 1; i >= 0; --i) {
        inv[i] = (int)(1LL * pref[i] * suffix_inv % mod);
        suffix_inv = (int)(1LL * suffix_inv * a[i] % mod);
    }
    return inv;
}

// 已知叶子值 weight_i，自底向上构造
//     F_p = F_L*M_R + F_R*M_L。
// 若 F_L、F_R 也使用固定长度翻转表示，则翻转乘积仍是普通卷积，
// 所以可以直接与 product_tree 中的 rev(M_L)、rev(M_R) 相乘，无需来回 reverse。
poly interpolate_up(
    int p,
    int l,
    int r,
    const vector<int>& weight,
    const vector<poly>& product_tree
) {
    if (r - l == 1) return {weight[l]};

    int mid = (l + r) >> 1;
    poly left = interpolate_up(p << 1, l, mid, weight, product_tree);
    poly right = interpolate_up(p << 1 | 1, mid, r, weight, product_tree);

    poly a = mul(std::move(left), product_tree[p << 1 | 1]);
    poly b = mul(std::move(right), product_tree[p << 1]);
    int len = r - l;
    a.resize(len);
    b.resize(len);
    for (int i = 0; i < len; ++i) a[i] = Ntt::add(a[i], b[i]);
    return a;
}

// 给定两两不同的点 (xs[i], ys[i])，返回唯一的次数 < n 的插值多项式。
// 空点集返回零多项式 {0}；重复横坐标会触发 assert。
//
// 令 M(x)=prod_i(x-x_i)。拉格朗日公式可写成
//     f(x) = sum_i y_i / M'(x_i) * M(x)/(x-x_i)。
// 先用同一棵乘积树求出所有 M'(x_i)，得到叶子权值
//     w_i = y_i / M'(x_i)。
// 对区间分治合并：
//     F_[l,r) = F_L*M_R + F_R*M_L，
// 展开后恰好是该区间所有 w_i*M_[l,r)/(x-x_i) 的和。根结点即答案。
//
// 复杂度 O(M(n) log n)，额外只有一次模逆；乘积树同时服务于求值和合并。
poly solve(const vector<int>& xs, const vector<int>& ys) {
    assert(xs.size() == ys.size());
    int n = (int)xs.size();
    if (n == 0) return {0};
    assert(n < mod);

    multipoint_detail::Evaluator evaluator;
    evaluator.init(xs);

    // tree[1]=rev(M)，先翻转回普通系数顺序再求导。
    poly product = evaluator.tree[1];
    reverse(product.begin(), product.end());
    poly derivative_values_poly = derivative(product);
    vector<int> derivative_values = evaluator.evaluate(derivative_values_poly);
    vector<int> inv_derivative = batch_inverse_nonzero(derivative_values);

    vector<int> weight(n);
    for (int i = 0; i < n; ++i) {
        int y = ys[i] % mod;
        if (y < 0) y += mod;
        weight[i] = (int)(1LL * y * inv_derivative[i] % mod);
    }

    // interpolate_up 返回固定长度 n 的翻转系数，最后翻转回升幂顺序。
    poly result = interpolate_up(1, 0, n, weight, evaluator.tree);
    reverse(result.begin(), result.end());
    normalize(result);
    return result;
}

} // namespace interpolation_detail

// 给定两两不同的点 (xs[i], ys[i])，返回唯一的次数 < n 的插值多项式。
poly fast_interpolate(const vector<int>& xs, const vector<int>& ys) {
    return interpolation_detail::solve(xs, ys);
}

// ============================================================
// 9. Bostan-Mori
// ============================================================

// 求 [x^k] P(x)/Q(x)，要求 Q(0) != 0。
//
// 乘 Q(-x) 后，Q(x)Q(-x) 只含偶次项。若 k 为偶数，分子只保留偶次项；
// 若 k 为奇数，只保留奇次项。随后令 x^2->x、k=floor(k/2)，问题规模减半。
// 重复 O(log k) 轮后只需求 P(0)/Q(0)。
int bostan_mori(poly p, poly q, long long k) {
    assert(!q.empty() && q[0] != 0);
    if (p.empty()) return 0;

    while (k > 0) {
        poly q_neg = q;
        for (int i = 1; i < (int)q_neg.size(); i += 2)
            if (q_neg[i]) q_neg[i] = mod - q_neg[i];

        poly pq = mul(p, q_neg);
        poly qq = mul(q, q_neg);

        poly next_p, next_q;
        next_p.reserve((pq.size() + 1) / 2);
        next_q.reserve((qq.size() + 1) / 2);

        for (int i = (int)(k & 1); i < (int)pq.size(); i += 2)
            next_p.push_back(pq[i]);
        for (int i = 0; i < (int)qq.size(); i += 2)
            next_q.push_back(qq[i]);

        p.swap(next_p);
        q.swap(next_q);
        k >>= 1;
    }

    int p0 = p.empty() ? 0 : p[0];
    return (int)(1LL * p0 * Ntt::qpow(q[0], mod - 2) % mod);
}

// ============================================================
// 10. 多项式复合
// ============================================================

namespace composition_detail {

// 复合的核心恒等式：
//     f(g(x)) = [y^n] f_rev(y) / (1-y*g(x))，
// 其中 f_rev(y)=sum_{i=0}^n f_i*y^{n-i}（实现通过转置过程隐式放入 f_i）。
// 因而复合可以转化为一个关于 x、y 的二维 Bostan-Mori 问题：每轮把分母
// V(x,y) 乘 V(-x,y)，消掉 x 的奇次项，再令 x^2->x，使 x 次数减半。
//
// 直接正向维护分子仍然偏慢。这里先只跑分母并保存每轮 kernel，最后从
// 目标线性泛函反向应用每步的转置（transposed multiplication）。这样总复杂度
// 由二维卷积主导；二维卷积再通过 Kronecker 代换压成一次普通 NTT。

// 二元多项式：dx / dy 永远表示“最高次数”，不是 size。
// P(i,j) = [x^i y^j] P(x,y)。
struct BiPoly {
    int dx = -1, dy = -1;
    // 按 x 主序连续存储：(i,j) 位于 coef[i*(dy+1)+j]。
    // 相比 vector<vector<int>>，这会把 O(dx) 次小块堆分配降为一次，
    // 也让 Kronecker 打包和奇偶抽取保持顺序访存。
    vector<int> coef;

    BiPoly(int _dx = -1, int _dy = -1)
        : dx(_dx), dy(_dy), coef((_dx + 1) * (_dy + 1)) {}

    int& operator()(int i, int j) { return coef[i * (dy + 1) + j]; }
    const int& operator()(int i, int j) const { return coef[i * (dy + 1) + j]; }

    poly row(int i) const {
        auto first = coef.begin() + i * (dy + 1);
        return poly(first, first + dy + 1);
    }

    void swap(BiPoly& other) noexcept {
        std::swap(dx, other.dx);
        std::swap(dy, other.dy);
        coef.swap(other.coef);
    }
};

// Kronecker 代换：x^i y^j -> z^(i * stride + j)。
// stride 取结果 y 次数上界 dy+1，保证不同的 (i,j) 不会映射到同一 z 次数。
BiPoly multiply(const BiPoly& left, const BiPoly& right) {
    int dx = left.dx + right.dx;
    int dy = left.dy + right.dy;
    int stride = dy + 1;

    poly a(left.dx * stride + left.dy + 1);
    poly b(right.dx * stride + right.dy + 1);

    for (int i = 0; i <= left.dx; ++i)
        for (int j = 0; j <= left.dy; ++j)
            a[i * stride + j] = left(i, j);

    for (int i = 0; i <= right.dx; ++i)
        for (int j = 0; j <= right.dy; ++j)
            b[i * stride + j] = right(i, j);

    // a、b 到这里都是最后一次使用，转移给 mul。
    poly c = mul(std::move(a), std::move(b));

    // c 的长度恰为 (dx+1)*(dy+1)，且 Kronecker 的 stride 就是 dy+1，
    // 所以它已经是 BiPoly 所需的连续行主序，无需再分配并逐项复制。
    BiPoly result;
    result.dx = dx;
    result.dy = dy;
    result.coef = std::move(c);
    return result;
}

BiPoly negate_x(BiPoly value) {
    for (int i = 1; i <= value.dx; i += 2)
        for (int j = 0; j <= value.dy; ++j)
            if (value(i, j)) value(i, j) = mod - value(i, j);
    return value;
}

// 正向 parity_s：取 x^{2i+s} 并把指数除 2。
// 转置就是把系数重新塞回 2i+s 位置。
BiPoly inject_parity(const BiPoly& value, int old_dx, int parity) {
    BiPoly result(old_dx, value.dy);
    for (int i = 0; i <= value.dx; ++i) {
        int p = 2 * i + parity;
        if (p > old_dx) break;
        for (int j = 0; j <= value.dy; ++j)
            result(p, j) = value(i, j);
    }
    return result;
}

// “乘固定 W”的转置：与 reverse(W) 卷积，再取中间块。
// 直接把 reverse(W) 打包进一维数组，并从卷积结果提取所需区间，避免真的
// 构造 reverse(W) 和完整 BiPoly 卷积结果；公式仍与朴素转置完全一致。
BiPoly multiply_transpose(
    const BiPoly& value,
    const BiPoly& kernel,
    int old_dx,
    int old_dy
) {
    int result_dy = value.dy + kernel.dy;
    int stride = result_dy + 1;
    poly a(value.dx * stride + value.dy + 1);
    poly b(kernel.dx * stride + kernel.dy + 1);

    for (int i = 0; i <= value.dx; ++i)
        for (int j = 0; j <= value.dy; ++j)
            a[i * stride + j] = value(i, j);

    for (int i = 0; i <= kernel.dx; ++i)
        for (int j = 0; j <= kernel.dy; ++j)
            b[(kernel.dx - i) * stride + kernel.dy - j] = kernel(i, j);

    poly c = mul(std::move(a), std::move(b));
    BiPoly result(old_dx, old_dy);

    for (int i = 0; i <= old_dx; ++i)
        for (int j = 0; j <= old_dy; ++j)
            result(i, j) =
                c[(i + kernel.dx) * stride + j + kernel.dy];
    return result;
}

struct Stage {
    int x_deg;       // 本轮 BM 前的 x 次数
    int old_y_deg;   // 本轮分子变换前的 y 次数
    BiPoly kernel;   // W = V(-x,y)
};

struct Plan {
    vector<Stage> stages;
    int final_y_deg = 0;
};

// 只正向跑“分母 BM”，保存每轮分子转置需要的 kernel。
Plan build_stages(const poly& g, int n) {
    BiPoly denominator(n, 1);       // V_0 = 1 - y g(x)
    denominator(0, 0) = 1;
    for (int i = 0; i <= n; ++i)
        if (g[i]) denominator(i, 1) = mod - g[i];

    Plan plan;
    int x_deg = n;
    int u_y_deg = 0;

    while (x_deg > 0) {
        BiPoly kernel = negate_x(denominator); // W = V(-x,y)
        int next_x_deg = x_deg >> 1;
        int next_u_y_deg = min(n, u_y_deg + kernel.dy);

        // V_next = Even_x( V * V(-x,y) )。
        BiPoly product = multiply(denominator, kernel);
        int next_v_y_deg = min(n, denominator.dy + kernel.dy);
        BiPoly next_denominator(next_x_deg, next_v_y_deg);

        for (int i = 0; i <= next_x_deg; ++i)
            for (int j = 0; j <= next_v_y_deg; ++j)
                next_denominator(i, j) = product(2 * i, j);

        // W 到这里已经最后一次使用，可以安全转移到 stage。
        plan.stages.push_back({x_deg, u_y_deg, std::move(kernel)});
        denominator.swap(next_denominator);
        x_deg = next_x_deg;
        u_y_deg = next_u_y_deg;
    }

    plan.final_y_deg = u_y_deg;
    return plan;
}

poly compose_zero_constant(const poly& f, const poly& g) {
    assert(!g.empty() && g[0] == 0);
    int n = (int)f.size() - 1;
    if (n == 0) return {f[0]};

    Plan plan = build_stages(g, n);

    // 转置的起点：最终 U(0,y) 的各个 y 系数对应 f_i。
    BiPoly adjoint(0, plan.final_y_deg);
    for (int i = 0; i <= n; ++i) adjoint(0, i) = f[i];

    // 正向：U_next = parity(U * W)
    // 反向：U_bar  = Mul_W^T( parity^T(U_next_bar) )
    for (int t = (int)plan.stages.size() - 1; t >= 0; --t) {
        const Stage& st = plan.stages[t];
        adjoint = inject_parity(adjoint, st.x_deg, st.x_deg & 1);
        adjoint = multiply_transpose(
            adjoint, st.kernel, st.x_deg, st.old_y_deg);
    }

    // 初始分子是 b_0 x^n + b_1 x^{n-1} + ... + b_n，因此最后反转 x 下标。
    poly ans(n + 1);
    for (int i = 0; i <= n; ++i) ans[i] = adjoint(n - i, 0);
    return ans;
}

} // namespace composition_detail

// Taylor shift：f(x) -> f(x+c)。
// 由二项式定理
//   [x^j]f(x+c) = 1/j! * sum_{i>=j}(f_i*i!) * c^{i-j}/(i-j)!，
// 反转 i 这一维后，右侧正好是一段卷积。
poly taylor_shift(const poly& f, int c) {
    if (f.empty()) return {};
    int n = (int)f.size() - 1;

    poly fac(n + 1), ifac(n + 1);
    fac[0] = 1;
    for (int i = 1; i <= n; ++i)
        fac[i] = (int)(1LL * fac[i - 1] * i % mod);

    ifac[n] = Ntt::qpow(fac[n], mod - 2);
    for (int i = n; i >= 1; --i)
        ifac[i - 1] = (int)(1LL * ifac[i] * i % mod);

    // h_j = 1/j! * sum_{i>=j} (f_i i!) * c^{i-j}/(i-j)!。
    // 反转第一列后就是普通卷积。
    poly weighted_coefficients(n + 1), shift_powers(n + 1);
    for (int i = 0; i <= n; ++i)
        weighted_coefficients[n - i] =
            (int)(1LL * f[i] * fac[i] % mod);

    long long pw = 1;
    for (int i = 0; i <= n; ++i) {
        shift_powers[i] = (int)(pw * ifac[i] % mod);
        pw = pw * c % mod;
    }

    poly convolution = mul(std::move(weighted_coefficients),
                           std::move(shift_powers));
    poly h(n + 1);
    for (int j = 0; j <= n; ++j)
        h[j] = (int)(1LL * convolution[n - j] * ifac[j] % mod);
    return h;
}

// f(g(x)) mod x^{deg(f)+1}。
// g 可以比 f 长或短：只保留需要的前 deg(f)+1 项。
poly compose(poly f, poly g) {
    if (f.empty()) return {};
    int n = (int)f.size() - 1;
    if (n == 0) return {f[0]};

    g.resize(n + 1);
    if (g[0] != 0) {
        int c = g[0];
        f = taylor_shift(f, c);
        g[0] = 0;
    }
    return composition_detail::compose_zero_constant(f, g);
}

// ============================================================
// 11. 幂投影：[x^k] f(x)^i
// ============================================================

namespace power_projection_detail {

using composition_detail::BiPoly;

// 从 P(x,y) 中抽取 x 次数与 parity 同奇偶的项，并执行 x^2 -> x。
// x 次数只保留到下一轮目标 next_x_deg，y 次数只保留前 y_limit+1 项。
BiPoly parity_reduce(
    const BiPoly& value,
    int next_x_deg,
    int parity,
    int y_limit
) {
    BiPoly result(next_x_deg, min(y_limit, value.dy));
    for (int i = 0; i <= result.dx; ++i) {
        int source_x = 2 * i + parity;
        if (source_x > value.dx) break;
        for (int j = 0; j <= result.dy; ++j)
            result(i, j) = value(source_x, j);
    }
    return result;
}

// 返回 c_i=[x^target]f(x)^i (0<=i<count)。
//
// 关于幂次数 i 再引入变量 y：
//     sum_{i>=0} f(x)^i y^i = 1/(1-y*f(x)) = U(x,y)/V(x,y)。
// 因此答案就是 [x^target]U/V 作为 y 的形式幂级数的前 count 项。
//
// 二维 Bostan-Mori 的一轮为
//     W(x,y) = V(-x,y),
//     U <- parity_target(U*W),
//     V <- even(V*W),
//     target <- floor(target/2)。
// 因为 V(x,y)V(-x,y) 的 x 奇次项全部抵消，所以可令 x^2->x。
// 每轮 x 上界减半、y 上界至多翻倍，二维有效面积始终为 O(target*count)；
// BiPoly::multiply 再用 Kronecker 代换把二维卷积压成一次普通 NTT。
poly solve(poly f, int target, int count) {
    assert(target >= 0 && count >= 0);
    if (count == 0) return {};

    f.resize(target + 1);

    BiPoly numerator(0, 0);
    numerator(0, 0) = 1;

    BiPoly denominator(target, min(1, count - 1));
    denominator(0, 0) = 1;
    if (count > 1) {
        for (int i = 0; i <= target; ++i)
            if (f[i]) denominator(i, 1) = mod - f[i];
    }

    int current_target = target;
    while (current_target > 0) {
        BiPoly kernel = composition_detail::negate_x(denominator);
        BiPoly numerator_product =
            composition_detail::multiply(numerator, kernel);
        BiPoly denominator_product =
            composition_detail::multiply(denominator, kernel);

        int parity = current_target & 1;
        int next_target = current_target >> 1;
        numerator = parity_reduce(
            numerator_product, next_target, parity, count - 1);
        denominator = parity_reduce(
            denominator_product, next_target, 0, count - 1);
        current_target = next_target;
    }

    // x 已经被完全消去，此时所求 y 级数就是 U(0,y)/V(0,y)。
    poly numerator_row = numerator.row(0);
    poly denominator_row = denominator.row(0);
    poly result = mul(std::move(numerator_row),
                      fps_inv(denominator_row, count));
    result.resize(count);
    return result;
}

} // namespace power_projection_detail

// 返回 [x^target]f(x)^i (0<=i<count)。
poly power_projection(const poly& f, int target, int count) {
    return power_projection_detail::solve(f, target, count);
}

// ============================================================
// 12. 多项式复合逆
// ============================================================

namespace compositional_inverse_detail {

// 求 G(F(x))=x (mod x^n)。要求 F(0)=0 且 F'(0)!=0。
//
// 先令 v=F'(0)，A=F/v，则 A'(0)=1。设 H 是 A 的复合逆。
// 固定 N=n-1，对 A 做幂投影 c_k=[x^N]A(x)^k。交换拉格朗日反演中的
// 原函数与逆函数可得
//     c_k = k/N * [x^{N-k}](x/H(x))^N。
// 因而令
//     S(x)=sum_{k=1}^N N/k*c_k*x^{N-k}，
// 就有 S=(x/H)^N (mod x^N)，常数项为 1，故
//     H(x)=x*S(x)^(-1/N)。
// 最后 F(G)=x 等价于 A(G)=x/v，所以 G(x)=H(x/v)。
poly solve(const poly& f, int n) {
    assert(n >= 2);
    assert((int)f.size() >= n);
    assert(f[0] == 0 && f[1] != 0);
    assert(n < mod);

    int degree = n - 1;
    int linear = f[1];
    int inv_linear = Ntt::qpow(linear, mod - 2);

    poly normalized = prefix(f, n);
    for (int& coefficient : normalized)
        coefficient = (int)(1LL * coefficient * inv_linear % mod);

    poly projected = power_projection_detail::solve(
        std::move(normalized), degree, degree + 1
    );

    fps_detail::ensure_inv_int(degree);
    poly lagrange_series(degree);
    for (int k = 1; k <= degree; ++k) {
        int index = degree - k;
        lagrange_series[index] = (int)(
            1LL * degree * fps_detail::inv_int[k] % mod * projected[k] % mod);
    }
    assert(lagrange_series[0] == 1);

    // S 的常数项为 1，因此任意模意义指数都可定义为 exp(alpha*ln S)。
    int exponent = mod - fps_detail::inv_int[degree]; // -1/degree
    poly log_series = fps_ln(lagrange_series, degree);
    for (int& coefficient : log_series)
        coefficient = (int)(1LL * coefficient * exponent % mod);
    poly root = fps_exp(log_series, degree);

    poly inverse(n);
    long long scale = inv_linear;
    for (int i = 1; i < n; ++i) {
        inverse[i] = (int)(root[i - 1] * scale % mod);
        scale = scale * inv_linear % mod;
    }
    return inverse;
}

} // namespace compositional_inverse_detail

poly compositional_inverse(const poly& f, int n) {
    return compositional_inverse_detail::solve(f, n);
}

// ============================================================
// 13. 兼容旧模板命名（可删除）
// ============================================================

poly poly_mul(poly a, poly b) { return mul(std::move(a), std::move(b)); }
poly poly_inv(const poly& f, int n) { return fps_inv(f, n); }
poly poly_derivative(const poly& f) { return derivative(f); }
poly poly_integral(const poly& f) { return integral(f); }
poly poly_ln(const poly& f, int n) { return fps_ln(f, n); }
poly poly_exp(const poly& f, int n) { return fps_exp(f, n); }
poly poly_pow(const poly& f, const string& k, int n) { return fps_pow(f, k, n); }
poly poly_sqrt(const poly& f, int n) { return fps_sqrt(f, n); }
pair<poly, poly> poly_divmod(poly a, poly b) { return divmod(std::move(a), std::move(b)); }
poly poly_interpolate(const vector<int>& xs, const vector<int>& ys) {
    return fast_interpolate(xs, ys);
}
poly poly_power_projection(const poly& f, int target, int count) {
    return power_projection(f, target, count);
}
poly poly_compositional_inverse(const poly& f, int n) {
    return compositional_inverse(f, n);
}

} // namespace polyops
```
