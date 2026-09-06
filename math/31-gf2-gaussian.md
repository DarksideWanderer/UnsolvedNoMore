# GF(2) 高斯消元

在 $GF(2)$ 上加减法都是异或，非零主元只能是 1，因此没有除法。每一行用 `bitset` 保存：下标 `0..variable_count-1` 是系数，下标 `variable_count` 是右端常数。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

struct XorGaussResult {
    bool consistent;
    int rank;
    vector<int> solution;
};

template<size_t maximum_variables>
XorGaussResult xor_gaussian(
    vector<bitset<maximum_variables + 1>> matrix,
    int variable_count) {
    assert(0 <= variable_count);
    assert(variable_count <= (int)maximum_variables);
    int equation_count = (int)matrix.size();
    vector<int> pivot_row(variable_count, -1);
    int rank = 0;

    for (int column = 0; column < variable_count; ++column) {
        int pivot = rank;
        while (pivot < equation_count && !matrix[pivot][column]) ++pivot;
        if (pivot == equation_count) continue;
        swap(matrix[rank], matrix[pivot]);
        pivot_row[column] = rank;

        for (int row = 0; row < equation_count; ++row) {
            if (row != rank && matrix[row][column]) {
                matrix[row] ^= matrix[rank];
            }
        }
        ++rank;
    }

    for (int row = 0; row < equation_count; ++row) {
        bool has_coefficient = false;
        for (int column = 0; column < variable_count; ++column) {
            has_coefficient |= matrix[row][column];
        }
        if (!has_coefficient && matrix[row][variable_count]) {
            return {false, rank, {}};
        }
    }

    // 令所有自由变量为 0，得到一组特解。
    vector<int> solution(variable_count);
    for (int column = 0; column < variable_count; ++column) {
        if (pivot_row[column] != -1) {
            solution[column] = matrix[pivot_row[column]][variable_count];
        }
    }
    return {true, rank, move(solution)};
}
```

- 无解：出现 $0=1$ 的行。
- 唯一解：`rank == variable_count`。
- 多解：自由变量数为 `variable_count - rank`，解的数量为 $2^{variable\_count-rank}$。
- 若只求一组解，代码把自由变量全设为 0；若要枚举解，分别指定自由变量，再由主元行回代即可。

复杂度为 $O(nm^2/w)$ 的位运算版本，其中 $n$ 是方程数、$m$ 是变量数、$w$ 是机器字长。`maximum_variables` 是编译期上限，例如 `xor_gaussian<2000>(matrix, variable_count)`。
