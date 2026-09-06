# 树分块（王室联邦）

给定一棵树和块大小下界 $B$，可以在 $O(n)$ 时间内把点划分成若干块。除整棵树不足 $B$ 个点的情形外，每块大小均在 $[B,3B)$ 内，块数不超过 $\lfloor n/B\rfloor$。每块还有一个核心点；核心不一定属于该块，但块内任意点走向核心时，核心之前的点仍在该块内。

DFS 时用栈保存尚未分块的点。进入点 `node` 时记录栈底；每处理完一个儿子，若这个儿子新留下的点连同此前未分块的兄弟子树已经达到 $B$ 个，就全部弹出组成一块，并令 `node` 为核心。处理新儿子前栈中这部分少于 $B$ 个，而一个儿子返回时至多新留下 $B$ 个，所以新块小于 $2B$；DFS 结束后至多 $B$ 个残余点并入最后一块，因此最后一块小于 $3B$。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

struct TreeBlocks {
    vector<int> block_id; // 每个点所属的块，编号从 0 开始
    vector<int> core;     // 每块的核心；核心不一定属于该块
};

TreeBlocks divide_tree_into_blocks(
    const vector<vector<int>>& tree, int block_size, int root = 0) {
    int n = (int)tree.size();
    assert(block_size > 0);
    if (n == 0) return {};
    assert(0 <= root && root < n);

    TreeBlocks result{vector<int>(n, -1), {}};
    vector<int> pending;

    auto dfs = [&](auto&& self, int node, int parent) -> void {
        int bottom = (int)pending.size();
        for (int next : tree[node]) {
            if (next == parent) continue;
            self(self, next, node);
            if ((int)pending.size() - bottom >= block_size) {
                int id = (int)result.core.size();
                result.core.push_back(node);
                while ((int)pending.size() > bottom) {
                    result.block_id[pending.back()] = id;
                    pending.pop_back();
                }
            }
        }
        pending.push_back(node);
    };

    dfs(dfs, root, -1);
    if (result.core.empty()) result.core.push_back(root);
    int last_id = (int)result.core.size() - 1;
    while (!pending.empty()) {
        result.block_id[pending.back()] = last_id;
        pending.pop_back();
    }
    return result;
}
```

取 $B\approx\sqrt n$ 后，块数和每块大小都是 $O(\sqrt n)$。典型用法是把整块信息预处理，只对路径两端所在块或零散点暴力；这是一种按点划分的静态技巧，不等同于重链剖分，也不自动支持在线修改。

注意：输入必须是连通树。代码使用递归 DFS，链很长且栈空间较小时需改成手写栈或增大程序栈。
