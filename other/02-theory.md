## 简介

Lindström–Gessel–Viennot lemma，即 LGV 引理，可以用来处理有向无环图上不相交路径计数等问题。

前置知识：[图论相关概念](./concept.md) 中的基础部分、[矩阵](../math/linear-algebra/matrix.md)、[高斯消元求行列式](../math/numerical/gauss.md)。

LGV 引理仅适用于 **有向无环图**。

## 定义

$\omega(P)$ 表示 $P$ 这条路径上所有边的边权之积。（路径计数时，可以将边权都设为 $1$）（事实上，边权可以为生成函数）

$e(u, v)$ 表示 $u$ 到 $v$ 的 **每一条** 路径 $P$ 的 $\omega(P)$ 之和，即 $e(u, v)=\sum\limits_{P:u\rightarrow v}\omega(P)$。

起点集合 $A$，是有向无环图点集的一个子集，大小为 $n$。

终点集合 $B$，也是有向无环图点集的一个子集，大小也为 $n$。

一组 $A\rightarrow B$ 的不相交路径 $S$：$S_i$ 是一条从 $A_i$ 到 $B_{\sigma(S)_i}$ 的路径（$\sigma(S)$ 是一个排列），对于任何 $i\ne j$，$S_i$ 和 $S_j$ 没有公共顶点。

$t(\sigma)$ 表示排列 $\sigma$ 的逆序对个数。

## 引理

$$
M = \begin{bmatrix}e(A_1,B_1)&e(A_1,B_2)&\cdots&e(A_1,B_n)\\
e(A_2,B_1)&e(A_2,B_2)&\cdots&e(A_2,B_n)\\
\vdots&\vdots&\ddots&\vdots\\
e(A_n,B_1)&e(A_n,B_2)&\cdots&e(A_n,B_n)\end{bmatrix}
$$

$$
\det(M)=\sum\limits_{S:A\rightarrow B}(-1)^{t(\sigma(S))}\prod\limits_{i=1}^n \omega(S_i)
$$

其中 $\sum\limits_{S:A\rightarrow B}$ 表示满足上文要求的 $A\rightarrow B$ 的每一组不相交路径 $S$。

矩阵树定理解决了一张图的生成树个数计数问题。

## 本篇记号声明

本篇中的图，无论无向还是有向，都允许重边，但是默认没有自环。

??? note "有自环的情形"
    自环并不影响生成树的个数，也不影响下文中 Laplace 矩阵的计算，故而矩阵树定理对有自环的情形依然成立。计算时不必删去自环。如果删去自环，会影响根据 BEST 定理应用矩阵树定理统计有向图的欧拉回路个数。

### 无向图情况

设 $G$ 是一个有 $n$ 个顶点的无向图。定义度数矩阵 $D(G)$ 为

$$
D_{ii}(G) = \mathrm{deg}(i),\ D_{ij} = 0,\ i\neq j.
$$

设 $\#e(i,j)$ 为点 $i$ 与点 $j$ 相连的边数，并定义邻接矩阵 $A$ 为

$$
A_{ij}(G)=A_{ji}(G)=\#e(i,j),\ i\neq j.
$$

定义 Laplace 矩阵（亦称 Kirchhoff 矩阵）$L$ 为

$$
L(G) = D(G) - A(G).
$$

记图 $G$ 的所有生成树个数为 $t(G)$。

### 有向图情况

设 $G$ 是一个有 $n$ 个顶点的有向图。定义出度矩阵 $D^{out}(G)$ 为

$$
D^\mathrm{out}_{ii}(G) = \mathrm{deg}^\mathrm{out}(i),\ D^\mathrm{out}_{ij} = 0,\ i\neq j.
$$

类似地定义入度矩阵 $D^\mathrm{in}(G)$。

设 $\#e(i,j)$ 为点 $i$ 指向点 $j$ 的有向边数，并定义邻接矩阵 $A$ 为

$$
A_{ij}(G)=\#e(i,j),\ i\neq j.
$$

定义出度 Laplace 矩阵 $L^\mathrm{out}$ 为

$$
L^\mathrm{out}(G) = D^\mathrm{out}(G) - A(G).
$$

定义入度 Laplace 矩阵 $L^\mathrm{in}$ 为

$$
L^\mathrm{in}(G) = D^\mathrm{in}(G) - A(G).
$$

记图 $G$ 的以 $k$ 为根的所有根向树形图个数为 $t^\mathrm{root}(G,k)$。所谓根向树形图，是说这张图的基图是一棵树，所有的边全部指向父亲。

记图 $G$ 的以 $k$ 为根的所有叶向树形图个数为 $t^\mathrm{leaf}(G,k)$。所谓叶向树形图，是说这张图的基图是一棵树，所有的边全部指向儿子。

## 定理叙述

矩阵树定理具有多种形式。

定义 $[n]=\{1,2,\cdots,n\}$，矩阵 $A$ 的子矩阵 $A_{S,T}$ 为选取 $A_{i,j}\pod{i\in S,j\in T}$ 的元素得到的子矩阵。

"定理 1（矩阵树定理，无向图，行列式形式）"

对于无向图 $G$ 和任意的 $k$，都有

$$
t(G) = \det L(G)_{[n]\setminus\{k\},[n]\setminus\{k\}}.
$$

也就是说，无向图的 Laplace 矩阵所有 $n-1$ 阶主子式都相等，且都等于图的生成树的个数。

"推论 1（矩阵树定理，无向图，特征值形式）"
 
设 $\lambda_1\ge\lambda_2\ge\cdots\ge\lambda_{n-1}\ge\lambda_n=0$ 为 $L(G)$ 的 $n$ 个特征值，那么有

$$
t(G) = \frac{1}{n}\lambda_1\lambda_2\cdots\lambda_{n-1}.
$$

"定理 2（矩阵树定理，有向图根向树，行列式形式）"

对于有向图 $G$ 和任意的 $k$，都有

$$
t^\mathrm{root}(G,k) = \det L^\mathrm{out}(G)_{[n]\setminus\{k\},[n]\setminus\{k\}}.
$$

也就是说，有向图的出度 Laplace 矩阵删去第 $k$ 行第 $k$ 列得到的主子式等于以 $k$ 为根的根向树形图的个数。

因此如果要统计一张图所有的根向树形图，只要枚举所有的根 $k$ 并对 $t^\mathrm{root}(G,k)$ 求和即可。

"定理 3（矩阵树定理，有向图叶向树，行列式形式）"

对于有向图 $G$ 和任意的 $k$，都有

$$
t^\mathrm{leaf}(G,k) = \det L^\mathrm{in}(G)_{[n]\setminus\{k\},[n]\setminus\{k\}}.
$$
    
也就是说，有向图的入度 Laplace 矩阵删去第 $k$ 行第 $k$ 列得到的主子式等于以 $k$ 为根的叶向树形图的个数。

因此如果要统计一张图所有的叶向树形图，只要枚举所有的根 $k$ 并对 $t^\mathrm{leaf}(G,k)$ 求和即可。

根向树形图也被称为内向树形图，但因为计算内向树形图用的是出度，为了不引起 $\mathrm{in}$ 和 $\mathrm{out}$ 的混淆，所以采用了根向这一说法。


### BEST 定理

前置知识：[欧拉图](./euler.md)

这一定理将有向欧拉图中欧拉回路的数目和该图的根向树形图的数目联系起来，从而解决了有向图中的欧拉回路的计数问题。注意，任意无向图中的欧拉回路的计数问题是 NP 完全的。

在实现该算法时，应当首先判定给定图是否是欧拉图，移除所有零度顶点，然后建图计算根向树形图的个数，并由 BEST 定理得到欧拉回路的计数。注意，如果所求欧拉回路个数要求以给定点作为起点，需要将答案再乘上该点出度，相当于枚举回路中首条边。

在证明 BEST 定理之前，需要知道如下结论。

一个有向图具有欧拉回路，当且仅当非零度顶点是强连通的，且所有顶点的出度和入度相等。

对于欧拉图，因为出度和入度相等，可以将它们略去上标，记作 $\mathrm{deg}(v)$。BEST 定理可以叙述如下。

设 $G$ 是有向欧拉图，$k$ 为任意顶点，那么 $G$ 的不同欧拉回路总数 $\mathrm{ec}(G)$ 是

$$
\mathrm{ec}(G) = t^\mathrm{root}(G,k)\prod_{v\in V}(\deg (v) - 1)!.
$$

这也说明，对欧拉图 $G$ 的任意两个节点 $k, k'$，都有 $t^\mathrm{root}(G,k)=t^\mathrm{root}(G,k')$。