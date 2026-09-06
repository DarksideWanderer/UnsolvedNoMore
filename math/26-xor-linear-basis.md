# 异或线性基

把无符号 64 位整数看成 $\mathbb F_2^{64}$ 向量。`basis[bit]` 保存最高位为 `bit` 的基向量；插入时从高位向低位消元。

```cpp
#include <bits/stdc++.h>
using namespace std;

using u64 = unsigned long long;

class XorLinearBasis {
    array<u64, 64> basis{};
    int basis_rank = 0;

public:
    bool insert(u64 value) {
        for (int bit = 63; bit >= 0; --bit) {
            if ((value >> bit & 1ULL) == 0) continue;
            if (basis[bit] == 0) {
                basis[bit] = value;
                ++basis_rank;
                return true;
            }
            value ^= basis[bit];
        }
        return false;
    }

    bool contains(u64 value) const {
        for (int bit = 63; bit >= 0; --bit) {
            if ((value >> bit & 1ULL) == 0) continue;
            if (basis[bit] == 0) return false;
            value ^= basis[bit];
        }
        return true;
    }

    u64 maximum_xor(u64 seed = 0) const {
        u64 result = seed;
        for (int bit = 63; bit >= 0; --bit) {
            result = max(result, result ^ basis[bit]);
        }
        return result;
    }

    void merge(const XorLinearBasis& other) {
        for (u64 value : other.basis) {
            if (value != 0) insert(value);
        }
    }

    int rank() const { return basis_rank; }
    u64 distinct_xor_count() const {
        return basis_rank == 64 ? 0 : (1ULL << basis_rank);
    }
};
```

插入、判定和最大异或都是 $O(64)$。当秩为 64 时不同异或值有 $2^{64}$ 个，无法装入 `u64`，因此 `distinct_xor_count()` 用 0 表示溢出；若这个约定不合题意，应改用 `u128` 或单独返回秩。

## 哪些输入元素是必须基

这里的“基”指从给定的带编号元素中选出的极大线性无关子集；即使两个数值相同，它们也是两个不同元素。第 $i$ 个元素属于每一组基，当且仅当

$$
\operatorname{rank}(S\setminus\{i\})<\operatorname{rank}(S),
$$

等价地说，`value[i]` 不能被其余元素异或表示。这就是向量拟阵中的 coloop，也就是属于每一组基的元素。若只询问一个位置，建立“除它以外”的线性基，再调用 `contains(value[i])` 即可，复杂度为 $O(64n)$。

若要一次求出所有位置，可以先贪心得到一组基 $B$。未被选入 $B$ 的元素显然不必须；把每个非基元素表示成 $B$ 的异或组合，表示中出现的基元素都可以被它替换，也不必须。其余基元素才是必须基。下面同时维护基向量在当前基中的坐标，总复杂度为 $O(64n)$。

```cpp
vector<bool> mandatory_basis_elements(const vector<u64>& values) {
    int n = (int)values.size();
    array<u64, 64> pivot_value{};
    array<u64, 64> pivot_coordinate{};
    vector<int> selected_index;
    vector<char> selected(n, false);

    for (int index = 0; index < n; ++index) {
        u64 value = values[index];
        u64 coordinate = 0;
        for (int bit = 63; bit >= 0; --bit) {
            if (((value >> bit) & 1ULL) == 0) continue;
            if (pivot_value[bit] != 0) {
                value ^= pivot_value[bit];
                coordinate ^= pivot_coordinate[bit];
                continue;
            }
            int id = (int)selected_index.size();
            pivot_value[bit] = value;
            pivot_coordinate[bit] = coordinate ^ (1ULL << id);
            selected_index.push_back(index);
            selected[index] = true;
            break;
        }
    }

    vector<char> replaceable(selected_index.size(), false);
    for (int index = 0; index < n; ++index) {
        if (selected[index]) continue;
        u64 value = values[index];
        u64 coordinate = 0;
        for (int bit = 63; bit >= 0; --bit) {
            if (((value >> bit) & 1ULL) == 0) continue;
            assert(pivot_value[bit] != 0);
            value ^= pivot_value[bit];
            coordinate ^= pivot_coordinate[bit];
        }
        assert(value == 0);
        for (int id = 0; id < (int)selected_index.size(); ++id) {
            if ((coordinate >> id) & 1ULL) replaceable[id] = true;
        }
    }

    vector<bool> mandatory(n, false);
    for (int id = 0; id < (int)selected_index.size(); ++id) {
        if (!replaceable[id]) mandatory[selected_index[id]] = true;
    }
    return mandatory;
}
```

零向量永远不是必须基；若同一个非零数出现至少两次，这两个位置也都不是必须基。不要把“被某一种消元顺序选进了基”误认为“必须出现在所有基中”。
