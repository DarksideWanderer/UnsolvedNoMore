# 可持久化线段树与动态主席树

## 静态版本：前缀版本主席树

值域离散化为 $[0,m)$。每次单点增量只复制根到叶子的一条链；`roots[version]` 保存该版本的根。两个前缀版本相减即可查询区间频率与第 $k$ 小。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

using i64 = long long;

class PersistentSegmentTree {
    struct Node {
        int left = 0;
        int right = 0;
        i64 sum = 0;
    };

    int coordinate_count;
    vector<Node> nodes{{}};
    vector<int> roots{0};

    int add(int previous, int left, int right, int position, i64 delta) {
        int current = (int)nodes.size();
        nodes.push_back(nodes[previous]);
        nodes[current].sum += delta;
        if (right - left == 1) return current;
        int middle = left + (right - left) / 2;
        if (position < middle) {
            nodes[current].left =
                add(nodes[previous].left, left, middle, position, delta);
        } else {
            nodes[current].right =
                add(nodes[previous].right, middle, right, position, delta);
        }
        return current;
    }

    i64 range_sum(int node, int left, int right,
                  int query_left, int query_right) const {
        if (query_right <= left || right <= query_left || node == 0) return 0;
        if (query_left <= left && right <= query_right) return nodes[node].sum;
        int middle = left + (right - left) / 2;
        return range_sum(nodes[node].left, left, middle,
                         query_left, query_right) +
               range_sum(nodes[node].right, middle, right,
                         query_left, query_right);
    }

public:
    explicit PersistentSegmentTree(int initial_coordinate_count)
        : coordinate_count(initial_coordinate_count) {
        assert(initial_coordinate_count > 0);
    }

    int add_version(int previous_version, int position, i64 delta = 1) {
        assert(0 <= previous_version && previous_version < (int)roots.size());
        assert(0 <= position && position < coordinate_count);
        roots.push_back(add(roots[previous_version], 0, coordinate_count,
                            position, delta));
        return (int)roots.size() - 1;
    }

    i64 query_sum(int version, int left, int right) const {
        assert(0 <= version && version < (int)roots.size());
        assert(0 <= left && left <= right && right <= coordinate_count);
        return range_sum(roots[version], 0, coordinate_count, left, right);
    }

    int kth_between(int left_version, int right_version, i64 k) const {
        assert(0 <= left_version && left_version < (int)roots.size());
        assert(0 <= right_version && right_version < (int)roots.size());
        int left_root = roots[left_version];
        int right_root = roots[right_version];
        i64 total = nodes[right_root].sum - nodes[left_root].sum;
        assert(1 <= k && k <= total);

        int segment_left = 0;
        int segment_right = coordinate_count;
        while (segment_right - segment_left > 1) {
            i64 left_count =
                nodes[nodes[right_root].left].sum -
                nodes[nodes[left_root].left].sum;
            int middle = segment_left + (segment_right - segment_left) / 2;
            if (k <= left_count) {
                left_root = nodes[left_root].left;
                right_root = nodes[right_root].left;
                segment_right = middle;
            } else {
                k -= left_count;
                left_root = nodes[left_root].right;
                right_root = nodes[right_root].right;
                segment_left = middle;
            }
        }
        return segment_left;
    }
};
```

一次更新和查询均为 $O(\log m)$，每个版本新增 $O(\log m)$ 个结点。用于区间第 $k$ 小时，第 $i$ 个前缀版本必须从第 $i-1$ 个版本继续插入，且频率差不能为负。

## 动态主席树：树状数组套权值线段树

下面支持原数组单点修改以及区间 $[l,r)$ 第 $k$ 小。所有初值和未来修改值必须提前放入 `possible_values` 完成离散化；查询返回真实值。

```cpp
class DynamicChairmanTree {
    struct Node {
        int left = 0;
        int right = 0;
        int count = 0;
    };

    int size;
    vector<int> coordinates;
    vector<int> current_value;
    vector<int> bit_roots;
    vector<Node> nodes{{}};

    int coordinate(int value) const {
        int index = (int)(lower_bound(coordinates.begin(), coordinates.end(),
                                     value) - coordinates.begin());
        assert(index < (int)coordinates.size() && coordinates[index] == value);
        return index;
    }

    int update_node(int root, int left, int right,
                    int position, int delta) {
        if (root == 0) {
            root = (int)nodes.size();
            nodes.push_back({});
        }
        nodes[root].count += delta;
        assert(nodes[root].count >= 0);
        if (right - left == 1) return root;
        int middle = left + (right - left) / 2;
        if (position < middle) {
            int child = update_node(nodes[root].left, left, middle,
                                    position, delta);
            nodes[root].left = child;
        } else {
            int child = update_node(nodes[root].right, middle, right,
                                    position, delta);
            nodes[root].right = child;
        }
        return root;
    }

    void add_position(int position, int value, int delta) {
        int value_index = coordinate(value);
        for (int index = position + 1; index <= size; index += index & -index) {
            bit_roots[index] = update_node(
                bit_roots[index], 0, (int)coordinates.size(), value_index, delta);
        }
    }

    vector<int> prefix_roots(int length) const {
        vector<int> result;
        for (int index = length; index > 0; index -= index & -index) {
            result.push_back(bit_roots[index]);
        }
        return result;
    }

public:
    DynamicChairmanTree(const vector<int>& initial,
                        vector<int> possible_values)
        : size((int)initial.size()), current_value(initial),
          bit_roots(size + 1) {
        possible_values.insert(possible_values.end(),
                               initial.begin(), initial.end());
        sort(possible_values.begin(), possible_values.end());
        possible_values.erase(unique(possible_values.begin(), possible_values.end()),
                              possible_values.end());
        assert(!possible_values.empty());
        coordinates = move(possible_values);
        for (int position = 0; position < size; ++position) {
            add_position(position, current_value[position], 1);
        }
    }

    void assign(int position, int new_value) {
        assert(0 <= position && position < size);
        add_position(position, current_value[position], -1);
        current_value[position] = new_value;
        add_position(position, current_value[position], 1);
    }

    int kth(int left, int right, int k) const {
        assert(0 <= left && left < right && right <= size);
        assert(1 <= k && k <= right - left);
        vector<int> positive = prefix_roots(right);
        vector<int> negative = prefix_roots(left);
        int segment_left = 0;
        int segment_right = (int)coordinates.size();

        while (segment_right - segment_left > 1) {
            int left_count = 0;
            for (int root : positive) left_count += nodes[nodes[root].left].count;
            for (int root : negative) left_count -= nodes[nodes[root].left].count;
            int middle = segment_left + (segment_right - segment_left) / 2;
            bool go_left = k <= left_count;
            if (!go_left) k -= left_count;
            for (int& root : positive) {
                root = go_left ? nodes[root].left : nodes[root].right;
            }
            for (int& root : negative) {
                root = go_left ? nodes[root].left : nodes[root].right;
            }
            if (go_left) segment_right = middle;
            else segment_left = middle;
        }
        return coordinates[segment_left];
    }
};
```

单点修改和区间第 $k$ 小均为 $O(\log n\log m)$。`update_node` 不保存 `vector` 元素的引用跨越 `push_back`，避免扩容后引用失效。
