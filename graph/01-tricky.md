# 图论易错点与建模提示

## 先考虑的等价变换

- 连边条件难描述时，检查反图、补图或把“不能同时选”改成冲突边。
- 动态删边可离线倒序变成加边；连通性通常交给并查集。
- 点权路径问题可拆点；边权限制有时可放到 Kruskal 重构树上转成 LCA。
- DAG 上的可达偏序问题常先做传递闭包，再转成二分图匹配。
- 更多补图 BFS、势能、MST 换边、函数图和欧拉图技巧见 `08-techniques.md`。
- Euler 序 RMQ 求 LCA 的完整代码见 `10-euler-tour-lca.md`；2-SAT 完整代码见 `12-two-sat.md`。

## DFS 边分类

无向图 DFS 必须用**边编号**跳过父边，否则重边会被误判。对一条非树边，它的两个端点在 DFS 树上具有祖先关系。

有向图可按访问状态分类：

- 指向未访问点的是树边；
- 指向当前递归栈中点的是返祖边；
- 指向已退出点时，再用进入/退出时间判断前向边或横叉边。

“看到已访问点就一定指向祖先”只对无向 DFS 的非树边成立，不能直接套到有向图。

## 传递闭包

顶点数中等时，`bitset` 版 Floyd 很实用。若 `reachable[i][k]` 为真，就把第 $k$ 行并入第 $i$ 行；复杂度约为 $O(n^3/w)$。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

template<size_t MaximumSize>
void transitive_closure(vector<bitset<MaximumSize>>& reachable) {
    int size = (int)reachable.size();
    assert(size <= (int)MaximumSize);
    for (int vertex = 0; vertex < size; ++vertex) {
        reachable[vertex].set(vertex);
    }
    for (int middle = 0; middle < size; ++middle) {
        for (int from = 0; from < size; ++from) {
            if (reachable[from][middle]) {
                reachable[from] |= reachable[middle];
            }
        }
    }
}
```

## 最短路

- Johnson 重标号先增加虚拟源并用 Bellman--Ford 求势能 $h$。新边权为 $w'(u,v)=w(u,v)+h(u)-h(v)\ge0$；Dijkstra 后要还原距离。
- 若只关心满足同余条件的最小可达值，可把余数当顶点做同余最短路。
- 最短路上的边满足 `distance[u] + weight == distance[v]`；筛出后通常得到最短路 DAG。

## 匹配与覆盖

- Berge 引理：匹配最大当且仅当不存在增广路。
- Hall 定理：二分图存在覆盖左部的匹配，当且仅当每个左部子集 $S$ 都满足 $|N(S)|\ge|S|$。
- 柯尼希定理：二分图最大匹配数等于最小点覆盖数；因此最大独立集大小为 $|V|-|M|$。
- DAG 的顶点不交最小路径覆盖等于 $|V|$ 减去拆点二分图的最大匹配数。
- 若允许路径重复经过顶点，应先用可达关系建边，而不是只使用原图边。

二分图最大匹配中可行边、必须边的一般判定，以及偏序集最大反链的实际构造见 `06-match.md`。非完美匹配还要处理从自由左点出发和走向自由右点的交错路，不能只照搬完美匹配的 SCC 判据。
