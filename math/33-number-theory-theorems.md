# 数论常用定理速查

本页只收录容易在推式子时临时忘记、但不值得单独写模板的结论。线性同余与 CRT 见 `27-crt.md`，原根见 `05-原根.md`，素性测试和分解见 Miller--Rabin / Pollard--Rho。

## Bézout、Euler、Fermat 与 Wilson

- Bézout：整数 $a,b$ 的所有线性组合 $ax+by$ 构成 $\gcd(a,b)$ 的倍数集合；所以 $ax\equiv c\pmod m$ 有解当且仅当 $\gcd(a,m)\mid c$。
- Euler：$\gcd(a,m)=1$ 时 $a^{\varphi(m)}\equiv1\pmod m$。素数模下化为 Fermat 小定理 $a^{p-1}\equiv1\pmod p$。
- 指数真正的周期是乘法阶 `ord_m(a)`，它整除 $\varphi(m)$；直接把指数对 $\varphi(m)$ 取模之前必须先确认底数与模数互质。
- Wilson：$p>1$ 为素数当且仅当 $(p-1)!\equiv-1\pmod p$。它适合证明和小范围公式，不适合代替素性测试。

Carmichael 函数给出对所有可逆剩余都成立的更小公倍周期。互素分解时

$$
\lambda\!\left(\prod p_i^{e_i}\right)
=\operatorname{lcm}_i\lambda(p_i^{e_i}),
$$

奇素数幂以及 $2,4$ 上有 $\lambda(p^e)=\varphi(p^e)$；$e\ge3$ 时 $\lambda(2^e)=2^{e-2}$。

## 阶乘和组合数中的素因子

Legendre 公式：

$$
v_p(n!)=\sum_{k\ge1}\left\lfloor\frac{n}{p^k}\right\rfloor
=\frac{n-s_p(n)}{p-1},
$$

其中 $s_p(n)$ 是 $n$ 的 $p$ 进制数位和。因此

$$
v_p\binom nk=v_p(n!)-v_p(k!)-v_p((n-k)!).
$$

Kummer 定理给出等价的组合解释：$v_p\binom nk$ 等于用 $p$ 进制计算 $k+(n-k)$ 时产生的进位次数。判断组合数是否被某个素数幂整除时，通常比真的计算组合数更方便。

## LTE（指数提升）

记 $v_p(x)$ 为 $x$ 中素因子 $p$ 的指数。设 $p$ 为奇素数、$p\mid x-y$ 且 $p\nmid xy$，则

$$
v_p(x^n-y^n)=v_p(x-y)+v_p(n).
$$

若 $p\mid x+y$ 且 $n$ 为奇数，则

$$
v_p(x^n+y^n)=v_p(x+y)+v_p(n).
$$

对奇数 $x,y$，二进制版本是

$$
v_2(x^n-y^n)=
\begin{cases}
v_2(x-y),&n\text{ 为奇数},\\
v_2(x-y)+v_2(x+y)+v_2(n)-1,&n\text{ 为偶数}.
\end{cases}
$$

LTE 的整除前提不可省略；不满足时应先因式分解或按乘法阶分析。

## 二次剩余与二次互反

对奇素数 $p$ 且 $p\nmid a$，Euler 判别给出

$$
a^{(p-1)/2}\equiv\left(\frac ap\right)\pmod p,
$$

右侧 Legendre 符号为 $1$ 或 $-1$，可先判定模平方根是否存在。不同奇素数 $p,q$ 满足二次互反律

$$
\left(\frac pq\right)\left(\frac qp\right)
=(-1)^{(p-1)(q-1)/4},
$$

并有补充公式

$$
\left(\frac{-1}{p}\right)=(-1)^{(p-1)/2},\qquad
\left(\frac2p\right)=(-1)^{(p^2-1)/8}.
$$

实际求平方根使用 Tonelli--Shanks；`23-polynomial-advanced.md` 中已有实现。合数模下即使 Jacobi 符号为 1 也不保证是二次剩余。
