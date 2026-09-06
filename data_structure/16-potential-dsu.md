# 带权并查集 / 势能并查集

势能并查集维护形如

$$
potential[y]-potential[x]=difference
$$

的约束。`weight[x]` 表示 `potential[x] - potential[parent[x]]`；路径压缩时把沿途差值相加。它适合维护相对坐标、区间和关系、判定差分约束是否矛盾。这里只封装合并、连通性和差值查询。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

struct PotentialDsu {
    using i64 = long long;

    vector<int> parent, size;
    vector<i64> weight;

    explicit PotentialDsu(int n) : parent(n), size(n, 1), weight(n) {
        iota(parent.begin(), parent.end(), 0);
    }

    pair<int, i64> find(int x) {
        if (parent[x] == x) return {x, 0};
        int old_parent = parent[x];
        auto [root, parent_weight] = find(old_parent);
        __int128_t total = (__int128_t)weight[x] + parent_weight;
        assert(total >= numeric_limits<i64>::min());
        assert(total <= numeric_limits<i64>::max());
        parent[x] = root;
        weight[x] = (i64)total;
        return {root, weight[x]};
    }

    // 加入 potential[y] - potential[x] = difference。
    // 已连通时返回该约束是否与旧约束相容。
    bool add_constraint(int x, int y, i64 difference) {
        auto [root_x, weight_x] = find(x);
        auto [root_y, weight_y] = find(y);
        if (root_x == root_y) {
            return (__int128_t)weight_y - weight_x == difference;
        }

        if (size[root_x] >= size[root_y]) {
            // potential[root_y] - potential[root_x]
            __int128_t value = (__int128_t)difference + weight_x - weight_y;
            assert(value >= numeric_limits<i64>::min());
            assert(value <= numeric_limits<i64>::max());
            parent[root_y] = root_x;
            weight[root_y] = (i64)value;
            size[root_x] += size[root_y];
        } else {
            // potential[root_x] - potential[root_y]
            __int128_t value = (__int128_t)weight_y - weight_x - difference;
            assert(value >= numeric_limits<i64>::min());
            assert(value <= numeric_limits<i64>::max());
            parent[root_x] = root_y;
            weight[root_x] = (i64)value;
            size[root_y] += size[root_x];
        }
        return true;
    }

    // 未连通返回 nullopt，否则返回 potential[y] - potential[x]。
    optional<i64> difference(int x, int y) {
        auto [root_x, weight_x] = find(x);
        auto [root_y, weight_y] = find(y);
        if (root_x != root_y) return nullopt;
        __int128_t value = (__int128_t)weight_y - weight_x;
        assert(value >= numeric_limits<i64>::min());
        assert(value <= numeric_limits<i64>::max());
        return (i64)value;
    }
};
```

合并公式最容易写反。若把 `root_y` 接到 `root_x`，由

$$
(weight_y+potential[root_y])-(weight_x+potential[root_x])=difference
$$

立刻得到新边权 `difference + weight_x - weight_y`。建议现场忘记时按这行重推，不要背符号。

若关系是在模 $k$ 意义下，只需令所有 `weight` 和 `difference` 都先规范到 $[0,k)$，把加减法结果再次取规范模；异或关系则把上述加减全部换成异或。普通整数版本不能直接拿来表达“只在模 $k$ 下相等”的关系。

复杂度与普通并查集相同，均摊 $O(\alpha(n))$。这里的断言只防止势能累计溢出；题目若允许差值超出 `long long`，需要把 `weight` 本身改成 `__int128`。
