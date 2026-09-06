# PBDS 有序集合

GNU PBDS 的 `tree` 支持排名和第 $k$ 小，接口不是标准 C++，只能在提供 libstdc++ PBDS 的评测环境使用。

```cpp
#include <bits/stdc++.h>
#include <ext/pb_ds/assoc_container.hpp>
#include <ext/pb_ds/tree_policy.hpp>
using namespace std;
using namespace __gnu_pbds;

template<class Value>
using OrderedSet = tree<
    Value, null_type, less<Value>, rb_tree_tag,
    tree_order_statistics_node_update>;

template<class Value>
class OrderedMultiSet {
    using Key = pair<Value, int>;
    tree<Key, null_type, less<Key>, rb_tree_tag,
         tree_order_statistics_node_update> data;
    int next_id = 0;

public:
    void insert(const Value& value) {
        data.insert({value, next_id++});
    }

    bool erase_one(const Value& value) {
        auto iterator = data.lower_bound({value, numeric_limits<int>::min()});
        if (iterator == data.end() || iterator->first != value) return false;
        data.erase(iterator);
        return true;
    }

    int count_less(const Value& value) const {
        return (int)data.order_of_key(
            {value, numeric_limits<int>::min()});
    }

    int count_less_equal(const Value& value) const {
        return (int)data.order_of_key(
            {value, numeric_limits<int>::max()});
    }

    optional<Value> kth(int rank) const {
        if (rank < 0 || rank >= (int)data.size()) return nullopt;
        return data.find_by_order(rank)->first;
    }

    optional<Value> predecessor(const Value& value) const {
        int rank = count_less(value);
        return rank == 0 ? nullopt : kth(rank - 1);
    }

    optional<Value> successor(const Value& value) const {
        int rank = count_less_equal(value);
        return rank == (int)data.size() ? nullopt : kth(rank);
    }

    int size() const {
        return (int)data.size();
    }
};
```

对于 `OrderedSet<int> values`：

- `values.order_of_key(x)` 是严格小于 $x$ 的元素个数；
- `values.find_by_order(k)` 返回 0-based 第 $k$ 小的迭代器，越界时等于 `end()`。

多重集合通过唯一编号区分相同值。编号只递增不复用；若插入次数可能超过 `int`，把编号改为 `long long`。
