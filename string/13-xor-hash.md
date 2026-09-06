# 异或哈希与可交换哈希

多项式字符串哈希保留顺序，而异或哈希故意忽略顺序。给每个对象 $x$ 分配一个随机 64 位标签 $h(x)$，集合签名定义为

$$
H(S)=\bigoplus_{x\in S}h(x).
$$

插入、删除或切换一个对象都只需再异或一次它的标签。这就是 Zobrist hashing 的基本形式。

```cpp
#include <bits/stdc++.h>
using namespace std;

using u64 = unsigned long long;

u64 splitmix64(u64 value) {
    value += 0x9e3779b97f4a7c15ULL;
    value = (value ^ (value >> 30)) * 0xbf58476d1ce4e5b9ULL;
    value = (value ^ (value >> 27)) * 0x94d049bb133111ebULL;
    return value ^ (value >> 31);
}

u64 random_tag(u64 value) {
    static const u64 seed = (u64)
        chrono::steady_clock::now().time_since_epoch().count();
    return splitmix64(value + seed);
}
```

同一次程序中必须让相同对象调用得到相同标签，因此 `seed` 只能初始化一次。运行时随机种子可以避免输入方提前针对固定哈希构造数据；它仍是概率算法，不用于密码学。

## 最重要的边界：XOR 只保留奇偶

因为

$$
h(x)\oplus h(x)=0,
$$

直接异或一串元素得到的不是多重集哈希，而是“出现奇数次的元素集合”的哈希：

- 判断两个集合是否相同：可以异或，但必须保证每个元素在集合中最多保留一次；
- 动态 `toggle(x)`：非常适合，执行 `signature ^= random_tag(x)`；
- 判断区间中是否每个值都出现偶数次：适合使用前缀异或哈希；
- 判断两个多重集或两个字符串是否互为排列：不能只用 XOR，偶数次重复会被消掉。

多重集需要使用可逆的可交换运算，例如对随机标签按模 $2^{64}$ 求和：

```cpp
u64 multiset_hash = 0;
multiset_hash += random_tag(value); // 插入一次
multiset_hash -= random_tag(value); // 删除一次
```

无符号整数溢出就是模 $2^{64}$，定义良好。需要更低碰撞概率时使用两个独立种子得到一对 64 位签名。

## 前缀 XOR：区间奇偶集合

```cpp
vector<u64> prefix(values.size() + 1);
for (int i = 0; i < (int)values.size(); ++i) {
    prefix[i + 1] = prefix[i] ^ random_tag(values[i]);
}

// [left, right) 中所有出现奇数次的值的随机签名。
u64 range_hash = prefix[right] ^ prefix[left];
```

典型结论：

- `range_hash == 0` 表示区间内每个值都出现偶数次，结论是概率正确；
- 两个区间哈希相同，表示它们“奇数次元素集合”相同，不表示完整频率相同；
- 两个集合签名异或后，得到它们对称差的签名。

绝不能直接异或原值。原值之间可能满足人为构造的线性关系，例如 $a\oplus b\oplus c=0$；先经过带随机种子的 `random_tag` 才能把这种结构打散。

## 图的割边集合签名

给每条无向边分配随机标签，并把它异或进两个端点：

```cpp
vector<u64> vertex_hash(node_count);
for (int edge_id = 0; edge_id < (int)edges.size(); ++edge_id) {
    auto [u, v] = edges[edge_id];
    u64 tag = random_tag(edge_id);
    vertex_hash[u] ^= tag;
    vertex_hash[v] ^= tag;
}
```

对任意点集 $S$ 异或其中所有 `vertex_hash`：内部边出现两次而抵消，只剩下割 $\delta(S)$ 中跨出点集的边标签异或和。常见用途是树上子树割、随机检测某个割是否为空，以及“割中恰有一条边”时借助 `tag -> edge_id` 映射找出候选边；取出候选后仍应检查它是否真的跨越该割。

## 无序树和多重子结构不能裸 XOR

无序根树的儿子是一个**多重集**。若直接写

```cpp
subtree_hash ^= random_tag(child_hash);
```

两个相同儿子会完全抵消，得到明显错误的结构信息。应使用求和等保留重数的可交换组合，例如

```cpp
subtree_hash += random_tag(child_hash);
```

再把儿子数量、当前结点颜色或一个额外随机盐混入结果。不同类型的对象也应先编码成不同 key；例如点 `7`、颜色 `7`、边 `7` 不应无意中使用同一个标签。

## 什么时候不要用

- 普通字符串或序列相等需要保留顺序，使用多项式哈希、后缀数组、KMP/Z 或自动机；
- 题目要求绝对确定性时不能用随机哈希；
- 对手能看到固定种子并自适应构造数据时，单个 64 位签名不够可靠；
- 哈希相等只能当作候选判定，能以较低代价复核时应始终复核。

异或哈希的价值不是“比普通哈希更强”，而是它支持 $O(1)$ 撤销，并能让出现两次的对象自动抵消；只有题目恰好需要这两个代数性质时才使用。
