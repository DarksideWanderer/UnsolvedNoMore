# 概率与期望建模

本章以竞赛中的离散随机过程为主。先在实数或有理数意义下证明公式与期望存在，再考虑取模；概率大小、收敛性和独立性都不能用模数值判断。

## 看到什么结构，先想什么方法

| 题目结构 | 优先考虑 |
| --- | --- |
| 总收益、出现种类数、逆序对数 | 拆成指示变量，交换求和，用期望线性性 |
| 条件复杂，但固定第一步或某个变量后简单 | 条件概率、全期望、首次转移分析 |
| 问第一次成功或首次到达的时间 | 几何分布、尾和公式、吸收状态方程 |
| 重复抽样，限制只依赖每类出现次数 | `21-generating-functions.md` 的 EGF 与指数换元 |
| 所有目标都出现才结束 | 分阶段收集、尾概率容斥、Min--Max 容斥 |
| 有自环或转移成环 | 自环移项；线性方程或按 SCC 分块求解 |
| 要方差，已有期望 | 二阶矩方程、协方差、全方差 |
| 独立随机变量之和、随机项数之和 | 概率生成函数的乘法、复合 |
| 多个坏事件或随机算法失败概率 | Union bound；独立和的 Chernoff 界 |

## 条件概率、全概率与独立性

对于 $\Pr(B)>0$，$\Pr(A\mid B)=\Pr(A\cap B)/\Pr(B)$。若 $B_i$ 是样本空间的互斥划分，则

$$
\Pr(A)=\sum_i\Pr(B_i)\Pr(A\mid B_i),\qquad
\Pr(B_i\mid A)=\frac{\Pr(B_i)\Pr(A\mid B_i)}{\sum_j\Pr(B_j)\Pr(A\mid B_j)}.
$$

第二式要求 $\Pr(A)>0$。零概率条件项不必定义，可以从求和中略去。

互斥表示不能同时发生，独立表示 $\Pr(A\cap B)=\Pr(A)\Pr(B)$。两个正概率的互斥事件不独立；两两独立也不足以把任意多个事件的交概率写成乘积。每步独立抽样不代表固定步数下各类出现次数独立。

## 期望线性性：把答案拆成贡献

对于可积随机变量，有限和满足

$$
\mathbb E\left[\sum_i a_iX_i\right]=\sum_i a_i\mathbb E[X_i].
$$

**这里不要求独立。** 设 $I_A$ 为事件 $A$ 的指示变量，则 $\mathbb E[I_A]=\Pr(A)$。求数量的期望时，优先给每个可能被计入的对象一个指示变量。

例如独立抽样 $n$ 次，每次选中类别 $i$ 的概率为 $p_i$，出现种类数 $D$ 满足

$$
\mathbb E[D]=\sum_i\bigl(1-(1-p_i)^n\bigr).
$$

出现事件之间虽然相关，但不妨碍把期望相加。类似地，均匀随机排列的每一对位置构成逆序的概率为 $1/2$，故逆序对期望为 $n(n-1)/4$。

乘法则不同：独立时才可直接使用 $\mathbb E[XY]=\mathbb E[X]\mathbb E[Y]$，一般情况要算联合分布或条件期望。一般也没有 $\mathbb E[1/X]=1/\mathbb E[X]$ 或 $\mathbb E[X/Y]=\mathbb E[X]/\mathbb E[Y]$。

## 全期望与全方差

先按 $Y$ 分类，再求每一类的条件期望：

$$
\mathbb E[X]=\mathbb E[\mathbb E[X\mid Y]]
=\sum_y\Pr(Y=y)\mathbb E[X\mid Y=y].
$$

对二阶矩有限的变量，

$$
\operatorname{Var}(X)
=\mathbb E[\operatorname{Var}(X\mid Y)]
+\operatorname{Var}(\mathbb E[X\mid Y]).
$$

可以理解为：总波动包含每一类内部的波动，以及各类均值之间的波动。只平均条件方差会漏掉第二部分。

## 尾和公式：等待时间转成“还没结束”

非负整数随机变量 $T$ 满足逐点恒等式 $T=\sum_{n\ge0}I_{T>n}$，因此

$$
\mathbb E[T]=\sum_{n\ge0}\Pr(T>n)=\sum_{n\ge1}\Pr(T\ge n),
$$

$$
\mathbb E[T^2]=\sum_{n\ge0}(2n+1)\Pr(T>n).
$$

第二式来自 $t^2=\sum_{n=0}^{t-1}(2n+1)$。对非负变量交换无限和合法，结果也可能为 $+\infty$；要输出有限期望仍需证明收敛。非负连续变量有对应公式 $\mathbb E[T]=\int_0^\infty\Pr(T>t)\,dt$。

若 $r_n=\Pr(T=n+1)$，则应算 $\mathbb E[T]=\sum_{n\ge0}(n+1)r_n$；仅在 $\sum_nr_n=1$ 时可写成 $1+\sum_nnr_n$。不要把首次完成概率和尾概率混用。

## 高频分布与等待阶段

| 分布与约定 | 期望 | 方差 |
| --- | --- | --- |
| Bernoulli$(p)$：取 $0,1$ | $p$ | $p(1-p)$ |
| Binomial$(n,p)$：$n$ 次独立试验的成功数 | $np$ | $np(1-p)$ |
| Geometric$(p)$：含成功那次的试验数，取 $1,2,\ldots$ | $1/p$ | $(1-p)/p^2$ |
| Negative binomial$(r,p)$：直到第 $r$ 次成功的总试验数 | $r/p$ | $r(1-p)/p^2$ |
| Poisson$(\lambda)$：$\Pr(X=k)=e^{-\lambda}\lambda^k/k!$ | $\lambda$ | $\lambda$ |
| Hypergeometric$(N,K,n)$：从 $N$ 个中不放回取 $n$ 个，原有 $K$ 个成功项 | $nK/N$ | $n(K/N)(1-K/N)(N-n)/(N-1)$ |

几何与负二项要求 $p>0$，各次试验独立且成功率不变。超几何公式要求 $0\le K,n\le N$ 且 $N>1$；$N=1$ 时合法抽样的成功数确定，方差为零。

几何分布满足 $\Pr(T>n)=(1-p)^n$，由尾和直接得到 $1/p$；也满足无记忆性 $\Pr(T>a+b\mid T>a)=\Pr(T>b)$，条件事件须有正概率。若改为统计成功前的失败数，期望变为 $(1-p)/p$。

如果过程能按“取得一次新进展”划为阶段，且第 $i$ 阶段每步成功概率恒为 $q_i>0$，该阶段期望耗时为 $1/q_i$，总期望为 $\sum_i1/q_i$。相加本身不要求各阶段独立。若阶段成功率还依赖具体历史，则应保留状态并用条件期望，不能随意把随机成功率换成其平均值。

## 收集问题与 Min--Max 容斥

每次均匀抽取 $m$ 种物品之一，已有 $i$ 种时取得新种类的概率为 $(m-i)/m$，因此集齐全部的期望为

$$
m\sum_{j=1}^m\frac1j=mH_m.
$$

更一般地，每次独立抽样，必需类别的概率为 $p_1,\ldots,p_m>0$，允许其他无用类别。令 $p(A)=\sum_{i\in A}p_i$，容斥给出

$$
\Pr(T>n)=\sum_{\emptyset\ne A\subseteq[m]}(-1)^{|A|+1}(1-p(A))^n,
$$

$$
\mathbb E[T]=\sum_{\emptyset\ne A\subseteq[m]}\frac{(-1)^{|A|+1}}{p(A)}.
$$

解释：对于子集 $A$，“其中一种首次出现”的等待时间是参数为 $p(A)$ 的几何分布；用 Min--Max 容斥把“全部出现”的最大等待时间转成这些最小等待时间。各类别的首次出现时间无需独立。容斥恒等式见 `24-counting-formulas.md`。

通过子集最低位递推预处理 $p(A)$，时间与空间均为 $O(2^m)$；不是大 $m$ 的通用解。某个必需类别概率为零时不可能集齐。注意离散抽样中“任一类命中”的概率是互斥类别概率之和，不能换成独立事件的并概率。

## 联合成功概率、二项式矩与阈值等待时间

### 容斥的另一层：从“指定若干个成功”恢复“总共成功几个”

设 $I_1,\ldots,I_C$ 是任意事件的指示变量，$X=\sum_iI_i$ 为成功个数。定义

$$
A_j=\sum_{\substack{J\subseteq[C]\\|J|=j}}
\Pr(I_i=1\text{ 对所有 }i\in J),\qquad A_0=1.
$$

一个样本若实际成功了 $r$ 个事件，它恰好出现在 $\binom rj$ 个大小为 $j$ 的成功子集中。因此

$$
A_j=\mathbb E\binom Xj
=\sum_{r=j}^C\binom rj\Pr(X=r).
$$

**$A_j$ 统计“选出 $j$ 个成功事件的方式数”的期望，并不是恰好成功 $j$ 个的概率。** 它称为二项式矩；$j!A_j=\mathbb E[X(X-1)\cdots(X-j+1)]$ 才是通常不除以阶乘的阶乘矩。

写成生成函数，令 $G_X(u)=\mathbb E[u^X]$，则

$$
\sum_{j=0}^CA_jv^j=\mathbb E[(1+v)^X]=G_X(1+v).
$$

把 $v$ 换成 $u-1$ 再取 $[u^r]$，直接得到二项式反演：

$$
\Pr(X=r)=\sum_{j=r}^C(-1)^{j-r}\binom jr A_j.
$$

这里没有用到独立性。对于 $1\le p\le C$，把 $r=p,\ldots,C$ 的概率相加，并使用交错二项式和，可直接得到阈值版本

$$
\Pr(X\ge p)=\sum_{j=p}^C(-1)^{j-p}\binom{j-1}{p-1}A_j.
$$

其中系数来自 $\sum_{r=p}^j(-1)^{j-r}\binom jr=(-1)^{j-p}\binom{j-1}{p-1}$。取 $p=1$ 就退化为普通的并事件容斥。

### 两层容斥如何在重复抽样中配合

每步独立均匀抽取长度为 $S$ 的列表中的一个位置。共有 $C$ 个任务，每个任务至少需要一类课程，任务 $i$ 的各类出现次数为正整数 $a_{i,r}$。假设所有这些课程类别对应的列表位置两两不交，故 $\sum_{i,r}a_{i,r}\le S$；剩余位置可以是无用课程。

第一层对“缺失的课程类别”容斥。令

$$
P_i(x)=\prod_r(1-x^{a_{i,r}}),\qquad
\mathcal L_t(x^k)=(1-k/S)^t.
$$

则 $\mathcal L_t(P_i)$ 是任务 $i$ 在 $t$ 步后完成的概率。这里 $x$ 是形式标记，指数是被禁用的位置总数；线性映射的完整解释见 `21-generating-functions.md`。

第二层对“完成的任务个数”反演。先计算

$$
\prod_{i=1}^C(1+uP_i(x))=\sum_{j=0}^Cf_j(x)u^j,
\qquad
f_j(x)=\sum_{|J|=j}\prod_{i\in J}P_i(x).
$$

任务的课程类别不交，保证 $\mathcal L_t(\prod_{i\in J}P_i)$ 编码这些任务的联合完成概率。令 $X_t$ 为 $t$ 步后完成任务数，便有

$$
\mathcal L_t(f_j)=A_j(t)=\mathbb E\binom{X_t}{j}.
$$

这里是**先在多项式层面相乘，再映射成联合概率**，并未假设任务完成事件独立。一般 $\mathcal L_t(P_iP_h)\ne\mathcal L_t(P_i)\mathcal L_t(P_h)$。

$f_j$ 是初等对称多项式，也可当作“恰好选 $j$ 个任务”的 01 背包：初始 $f_0=1$，其他为零；加入任务 $P_i$ 时，倒序更新 $f_j\gets f_j+P_if_{j-1}$。较大规模用分治乘积和二元卷积，见 `21-generating-functions.md` 的 Kronecker 代换；倒序背包只说明代数关系，不保证达到分治复杂度。

### 先减去极限，才能对时间求和

所需课程概率均为正，所以所有任务最终都完成，$A_j(t)\to\binom Cj$。因此 $j\ge1$ 时直接计算 $\sum_tA_j(t)$ 会发散。应先定义趋于零的差值

$$
D_j(t)=\binom Cj-A_j(t),\qquad h_j=\sum_{t\ge0}D_j(t).
$$

每个 $P_i$ 常数项为 $1$，所以 $f_j(0)=\binom Cj$。若 $f_j(x)=\sum_{k=0}^S c_{j,k}x^k$，便有

$$
D_j(t)=-\sum_{k=1}^Sc_{j,k}(1-k/S)^t,
$$

$$
h_j=-\sum_{k=1}^Sc_{j,k}\frac Sk
=S\int_0^1\frac{\binom Cj-f_j(x)}x\,dx.
$$

这同时解释了实现中的三个细节：只枚举 $k\ge1$ 是因为已经减去常数项；乘 $S/k$ 是几何级数求和；整体负号来自“极限减当前值”。$h_0=0$。

### 直接还原第 $p$ 个任务完成的期望

完成状态随时间单调，令 $T_p=\min\{t:X_t\ge p\}$。对 $1\le p\le C$，尾和公式给出 $\mathbb E[T_p]=\sum_{t\ge0}\Pr(X_t<p)$。

在阈值反演式中把 $X$ 取为恒等于 $C$ 的变量，得到

$$
1=\sum_{j=p}^C(-1)^{j-p}\binom{j-1}{p-1}\binom Cj.
$$

因此可以先相减、再对时间求和，直接得到

$$
\Pr(X_t<p)=\sum_{j=p}^C(-1)^{j-p}\binom{j-1}{p-1}D_j(t),
$$

$$
\boxed{\mathbb E[T_p]=\sum_{j=p}^C(-1)^{j-p}\binom{j-1}{p-1}h_j.}
$$

无需逐个时间恢复完整概率分布。给定全部 $h_j$，用双重循环可在 $O(C^2)$ 时间内算出全部阈值的期望。

例如 $C=2$ 时，$A_1=\Pr(X_t=1)+2\Pr(X_t=2)$，$A_2=\Pr(X_t=2)$，所以 $\mathbb E[T_1]=h_1-h_2$，$\mathbb E[T_2]=h_2$。若两个任务分别只需一种课程，概率为 $a/S,b/S$，则

$$
h_1=\frac Sa+\frac Sb,\qquad
h_2=\frac Sa+\frac Sb-\frac S{a+b},
$$

故 $\mathbb E[T_1]=S/(a+b)$，正好是首次抽中任一种所需课程的几何等待时间。

$p>C$ 时不能达到阈值；$p=0$ 时等待时间为零。若有必需类别概率为零的任务，应先去掉这些永远不能完成的任务，再确定 $C$。模质数 $M$ 计算仍须检查 $S$ 与实际使用的 $k$ 可逆，$S<M$ 是足够条件。

## 首次转移分析：自环、环与二阶矩

状态必须包含决定后续转移分布的全部信息。对有限状态过程，设 $E_i$ 为从状态 $i$ 到目标的期望总代价，目标状态取 $E_i=0$；从 $i$ 转移到 $j$ 的概率为 $P_{ij}$，支付确定的边代价 $c_{ij}$，则

$$
E_i=\sum_jP_{ij}(c_{ij}+E_j).
$$

每步代价为 $1$ 时，非目标状态满足 $E_i=1+\sum_jP_{ij}E_j$。存在自环可以移项：

$$
E_i=\frac{1+\sum_{j\ne i}P_{ij}E_j}{1-P_{ii}}.
$$

这是“失败后回到原状态”的通用公式，不能在有自环时直接递归计算。DAG 可逆拓扑 DP；一般图先按正概率边分 SCC，再从后继 SCC 向前求解。一个大小为 $b$ 的 SCC 可用 $O(b^3)$ 高斯消元，见 `25-gaussian-elimination.md`。

对全部可达非目标状态构造子转移矩阵 $R$，令 $b_i=\sum_jP_{ij}c_{ij}$，则 $(I-R)E=b$。**先判断是否会吸收**：有限状态下，若从起点能以正概率到达不含目标的封闭 SCC，则存在永不结束的概率，单位步长下期望无限；若所有可达状态都能到达目标，则最终吸收概率为 $1$，且期望有限。

命中概率也可列 $h_i=\sum_jP_{ij}h_j$，目标边界为 $1$，无法到达目标的状态为 $0$。先固定这些边界再解方程，避免把封闭非目标类留在齐次系统中造成不唯一。

要方差时，设 $V_i$ 是剩余步数的二阶矩，目标取 $V_i=0$，则

$$
V_i=1+2\sum_jP_{ij}E_j+\sum_jP_{ij}V_j,
\qquad \operatorname{Var}(T_i)=V_i-E_i^2.
$$

先解 $E$，再用同一个系数矩阵解 $V$。有确定边代价时，右侧改为 $\sum_jP_{ij}(c_{ij}^2+2c_{ij}E_j+V_j)$。

## 协方差与二阶矩

$$
\operatorname{Var}(X)=\mathbb E[X^2]-\mathbb E[X]^2,\qquad
\operatorname{Cov}(X,Y)=\mathbb E[XY]-\mathbb E[X]\mathbb E[Y],
$$

$$
\operatorname{Var}\left(\sum_iX_i\right)
=\sum_i\operatorname{Var}(X_i)+2\sum_{i<j}\operatorname{Cov}(X_i,X_j).
$$

两两独立足以使上式协方差项为零；不独立时不能只加方差。对指示变量 $I_i$，有 $I_i^2=I_i$，并且 $\mathbb E[I_iI_j]=\Pr(A_i\cap A_j)$，所以计数变量的方差通常只需单事件概率和两事件交概率。

## 概率生成函数与随机和

非负整数变量 $X$ 的概率生成函数（PGF）是

$$
G_X(s)=\mathbb E[s^X]=\sum_{k\ge0}\Pr(X=k)s^k.
$$

这是概率序列的 OGF，系数本身就是概率，**不含 $1/k!$**。相关矩有限时，

$$
G_X(1)=1,\quad G'_X(1)=\mathbb E[X],\quad
G''_X(1)=\mathbb E[X(X-1)],
$$

$$
\operatorname{Var}(X)=G''_X(1)+G'_X(1)-G'_X(1)^2.
$$

独立的 $X,Y$ 满足 $G_{X+Y}=G_XG_Y$。若 $N$ 是非负整数变量，$X_i$ 独立同分布且整个序列与 $N$ 独立，令 $Z=\sum_{i=1}^NX_i$，则

$$
G_Z(s)=G_N(G_X(s)),\qquad
\mathbb E[Z]=\mathbb E[N]\mathbb E[X],
$$

$$
\operatorname{Var}(Z)=\mathbb E[N]\operatorname{Var}(X)+\operatorname{Var}(N)\mathbb E[X]^2.
$$

复合来自先固定 $N=n$ 得到 $G_X(s)^n$，再对 $N$ 求平均。矩公式要求对应矩有限。对于依赖已观察结果的停止时刻，不能直接使用上述 PGF 复合与方差式。

一个常用扩展是 Wald 等式：若 $X_i$ 独立同分布且可积，$N$ 是相对于它们自然历史的停止时刻，且 $\mathbb E[N]<\infty$，则 $\mathbb E[\sum_{i=1}^NX_i]=\mathbb E[N]\mathbb E[X_1]$。这里 $N$ 不必与序列独立，但“是否继续第 $i$ 次”只能依赖此前的信息；只知道 $N$ 有限或事后挑选终点不够。

## 泊松化与 EGF 的联系

固定抽样次数 $n$ 时，各类别次数服从多项分布，通常相关。若先独立取 $N\sim\operatorname{Poisson}(t)$，再进行 $N$ 次独立类别抽样，概率为 $p_i$、总和为 $1$，则联合概率为

$$
\Pr(N_i=k_i\text{ 对所有 }i)
=e^{-t}\prod_i\frac{(tp_i)^{k_i}}{k_i!}
=\prod_i\left(e^{-tp_i}\frac{(tp_i)^{k_i}}{k_i!}\right).
$$

因此 $N_i$ 变为相互独立的 Poisson$(tp_i)$ 变量。例如全部必需类别都出现的概率变为 $\prod_i(1-e^{-tp_i})$。这是精确恒等式，并非大样本近似。

如果固定 $n$ 步的事件概率为 $a_n$，EGF 为 $A(z)=\sum_na_nz^n/n!$，泊松化后概率就是 $e^{-t}A(t)$。这解释了 EGF 中为什么自然出现指数，但固定 $n$ 的问题仍要提取系数或另做严格转换，不能直接把 $t=n$ 当作精确答案。

也可把每次抽样之间插入独立的 Exp$(1)$ 等待时间。若停止抽样次数 $T$ 只由类别序列决定且期望有限，连续完成时间 $\tau$ 满足 $\mathbb E[\tau\mid T]=T$，故 $\mathbb E[\tau]=\mathbb E[T]$；两者分布和方差一般不同。这个构造与泊松过程的分裂性质相联系，参见 [Harchol-Balter 教材第 12 章](https://www.cs.cmu.edu/~harchol/Probability/book.html)。

## 概率界与概率法

Markov、Chebyshev 和 Union bound 见 `../other/01-basic.md`，都不要求变量或事件相互独立；Markov 要求非负，Chebyshev 要求方差有限。

若 $X=\sum_iX_i$，其中 $X_i$ 为相互独立的 Bernoulli 变量，$\mu=\mathbb E[X]>0$，常用 Chernoff 界为

$$
\Pr(X\ge(1+\delta)\mu)\le
\left(\frac{e^\delta}{(1+\delta)^{1+\delta}}\right)^\mu
\le \exp\left(-\frac{\mu\delta^2}{2+\delta}\right),\qquad\delta>0,
$$

$$
\Pr(X\le(1-\delta)\mu)\le e^{-\mu\delta^2/2},\qquad 0<\delta<1.
$$

推导入口是对 $e^{tX}$ 使用 Markov，再用独立性拆开指数矩；所以不能仅凭知道期望就套用这组界。参见 [MIT Chernoff 讲义](https://ocw.mit.edu/courses/18-200-principles-of-discrete-applied-mathematics-spring-2024/mit18_200_s24_lec_chernoff.pdf)。

概率法的两个常见入口：有限样本空间中，总有一个方案的收益不小于平均收益；若坏事件数 $B$ 满足 $\mathbb E[B]<1$，由 $\Pr(B\ge1)\le\mathbb E[B]<1$ 知存在没有坏事件的方案。若能高效计算条件期望，可逐次固定一个选择，使条件期望不下降，从存在性证明构造出至少达到初始期望的方案。

## 模意义下的概率与期望

有理数 $a/b$ 映射为 $a\,b^{-1}\bmod M$，需要约分后的分母与 $M$ 互质。每一步直接做模除法，还要求当时的分母可逆；中间不可逆不等价于最终约分后的答案必然没有模意义。

常见问题包括：实数中成功概率大于零但模 $M$ 后为零；实数吸收过程的 $I-R$ 可逆，但模 $M$ 后奇异；实数期望本来无限却仍机械解出一个模数值。应先证明过程会终止且期望有限，再检查具体代数分母。

模意义下无限几何级数并不解析收敛。使用 $1/(1-r)$ 等公式，是先在 $|r|<1$ 的实数模型中求和、化为有理数恒等式，再将可逆分母映射到模数域。
