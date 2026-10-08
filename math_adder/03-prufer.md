# Prüfer 序列：标号树编码与计数

适用于顶点编号为 $1,\ldots,n$ 的无向标号树。$n\ge2$ 时，树与长度为
$n-2$、每项属于 $[1,n]$ 的 Prüfer 序列一一对应。基础结论见
`math/24-counting-formulas.md`；这里补充构造、证明和可复制代码。

## 1. 编码：反复删除最小叶子

重复 $n-2$ 次：找到编号最小的叶子 $v$，记录它唯一的邻居 $u$，删除 $v$。
最后剩下两个顶点，它们之间的边不记录。

例如边集 $\{(1,4),(2,4),(3,4),(4,5)\}$：依次删除叶子 $1,2,3$，
每次记录 $4$，得到序列 $(4,4,4)$。

**为什么顶点 $v$ 出现 $\deg(v)-1$ 次？** 每记录一次 $v$，就是删除一个与它相邻的
叶子，使它的度数减一。当 $v$ 自己成为叶子并被删除，或作为最后两个顶点之一时，
它还保留一条边。因此最初的 $\deg(v)$ 条边中恰有 $\deg(v)-1$ 条通过记录 $v$ 消去。
特别地，原树的叶子恰好是序列中未出现的顶点。

## 2. 解码：剩余出现次数决定当前叶子

令 $c_v$ 为 $v$ 在整个序列中的出现次数，初始化 $d_v=c_v+1$。
从左到右读出序列元素 $u$，每次取当前 $d_v=1$ 的最小顶点 $v$，加入边 $(v,u)$，
删除 $v$ 并将 $d_u$ 减一。最后连接剩余的两个叶子。

当前序列元素 $u$ 在未处理后缀中至少出现一次，所以它此时不是叶子，不会选到 $v=u$。
每一步选出的最小叶子都与编码时相同，因此两种操作互为逆操作。
解码也保证得到一棵树：每条前缀边把一个即将删除的顶点连接到仍保留的顶点，
最后再连接剩余两点，不会形成环，且所有点最终连通。

$n=2$ 对应空序列和唯一边 $(1,2)$。$n=1$ 单独视为一棵树；
下面的编码接口返回空序列，解码接口用显式参数 $n$ 区分这两种情况。

## 3. 完整代码：最小堆实现

时间 $O(n\log n)$，空间 $O(n)$。编码输入必须是一棵合法树，
邻接表大小为 $n+1$，下标零不使用；解码要求序列长度为 $\max(0,n-2)$。

```cpp
#include <algorithm>
#include <cassert>
#include <functional>
#include <queue>
#include <utility>
#include <vector>
using namespace std;

vector<int> prufer_encode(const vector<vector<int>>& adj) {
    int n = (int)adj.size() - 1;
    assert(n >= 1);
    if (n <= 2) return {};
    vector<int> degree(n + 1);
    priority_queue<int, vector<int>, greater<int>> leaves;
    for (int v = 1; v <= n; ++v) {
        degree[v] = (int)adj[v].size();
        if (degree[v] == 1) leaves.push(v);
    }
    vector<int> code;
    code.reserve(n - 2);
    for (int step = 0; step < n - 2; ++step) {
        int v = leaves.top();
        leaves.pop();
        int u = 0;
        for (int w : adj[v]) {
            if (degree[w] > 0) { u = w; break; }
        }
        assert(u != 0);
        code.push_back(u);
        degree[v] = 0;
        if (--degree[u] == 1) leaves.push(u);
    }
    return code;
}

vector<pair<int, int>> prufer_decode(int n, const vector<int>& code) {
    assert(n >= 1 && (int)code.size() == max(0, n - 2));
    if (n == 1) return {};
    vector<int> degree(n + 1, 1);
    for (int u : code) {
        assert(1 <= u && u <= n);
        ++degree[u];
    }
    priority_queue<int, vector<int>, greater<int>> leaves;
    for (int v = 1; v <= n; ++v)
        if (degree[v] == 1) leaves.push(v);
    vector<pair<int, int>> edges;
    edges.reserve(n - 1);
    for (int u : code) {
        int v = leaves.top();
        leaves.pop();
        edges.emplace_back(v, u);
        degree[v] = 0;
        if (--degree[u] == 1) leaves.push(u);
    }
    int u = leaves.top(); leaves.pop();
    int v = leaves.top(); leaves.pop();
    edges.emplace_back(u, v);
    return edges;
}
```

编码过程中每个顶点至多被删除一次，扫描它原始邻接表的总长度为 $2n-2$；
因此邻居搜索总计 $O(n)$，主要开销来自堆操作。

## 4. Cayley 公式与指定度数

每个序列位置有 $n$ 种选择，所以 $n\ge2$ 时标号无根树总数为

$$
\boxed{n^{n-2}}.
$$

根固定为某个给定编号时仍为 $n^{n-2}$；允许任选一个顶点作为根时为 $n^{n-1}$。
$n=1$ 时这几种计数均单独取 $1$。

指定度数 $d_1,\ldots,d_n$ 时，要求每个 $d_i\ge1$ 且 $\sum_i d_i=2n-2$。
序列中编号 $i$ 必须出现 $d_i-1$ 次，因此

$$
\boxed{\#\text{树}=\frac{(n-2)!}{\prod_i(d_i-1)!}}.
$$

例如指定顶点 $v$ 的度数为 $d$，先选出它出现的 $d-1$ 个位置，
剩下的位置任取其他 $n-1$ 个编号，故

$$
\boxed{\#\{\deg(v)=d\}=\binom{n-2}{d-1}(n-1)^{n-1-d}},
\qquad 1\le d\le n-1.
$$

## 5. 指定叶子集合与恰有多少叶子

设指定集合 $L$ 的大小为 $\ell$。如果只要求 $L$ 中的点**都是叶子**，
序列不能出现这些编号，其他编号不受限制，所以计数为

$$
\boxed{(n-\ell)^{n-2}},\qquad n\ge2.
$$

这里允许额外叶子。若要求叶子集合**恰好是 $L$**，则余下的 $m=n-\ell$ 个编号
都必须在序列中出现，变成长度 $n-2$ 的满射计数：

$$
\boxed{m!\left\{{n-2\atop m}\right\}
=\sum_{j=0}^{m}(-1)^j\binom mj(m-j)^{n-2}}.
$$

因此恰有 $\ell$ 个叶子的树共有

$$
\boxed{\binom n\ell(n-\ell)!\left\{{n-2\atop n-\ell}\right\}}.
$$

使用 $S(0,0)=1$、空序列计数 $0^0=1$，上述公式也覆盖 $n=2$、两点均为叶子的情形。
$n=1$ 的叶子定义另行约定，不套这些式子。

## 6. 带权 Cayley 与连接已有连通块

给顶点 $i$ 权值 $w_i$。一个序列贡献各位置权值之积，由出现次数等于度数减一，
对所有序列求和立即得到

$$
\boxed{\sum_T\prod_i w_i^{\deg_T(i)-1}
=\left(\sum_iw_i\right)^{n-2}},\qquad n\ge2.
$$

两边乘 $\prod_iw_i$ 得到无负指数的形式：

$$
\sum_T\prod_iw_i^{\deg_T(i)}
=\left(\prod_iw_i\right)\left(\sum_iw_i\right)^{n-2}.
$$

常用应用：已有一个森林，含 $k$ 个连通块，大小分别为 $s_1,\ldots,s_k$，
总顶点数为 $N$。从完全图中补 $k-1$ 条边使它成为树。
先将各块缩成点；块 $i,j$ 之间每条边有 $s_is_j$ 种端点选择。
对于一棵缩点树，选择数是 $\prod_i s_i^{\deg(i)}$，故 $k\ge2$ 时总数为

$$
\boxed{N^{k-2}\prod_{i=1}^{k}s_i}.
$$

$k=1$ 时无需加边，计数为 $1$。公式要求每对不同块间的所有端点组合均可选，
且块内结构已经固定；一般限制边集的生成树计数应使用 Matrix--Tree 定理。
