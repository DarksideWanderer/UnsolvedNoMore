# 高斯消元：秩、线性方程组与逆矩阵

## 浮点版本

使用 Gauss--Jordan 消元。`where[column]` 记录该未知量的主元行；消元结束后先检查形如 $0=c\ne0$ 的矛盾行，再由自由变量是否存在区分唯一解与无穷多解。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

using ld = long double;

enum class LinearSystemStatus {
    no_solution,  // 方程组无解
    unique,       // 方程组有唯一解
    infinite      // 方程组有无穷多组解
};

struct LinearSystemResult {
    LinearSystemStatus status;
    int rank;
    vector<ld> solution;
};

LinearSystemResult solve_linear_system(vector<vector<ld>> matrix,
                                       vector<ld> right_hand_side,
                                       ld epsilon = 1e-12L) {
    int row_count = (int)matrix.size();
    int column_count = row_count == 0 ? 0 : (int)matrix[0].size();
    assert((int)right_hand_side.size() == row_count);
    for (const auto& row : matrix) assert((int)row.size() == column_count);

    vector<int> where(column_count, -1);
    int pivot_row = 0;
    for (int column = 0; column < column_count && pivot_row < row_count;
         ++column) {
        int selected = pivot_row;
        for (int row = pivot_row + 1; row < row_count; ++row) {
            if (fabsl(matrix[row][column]) > fabsl(matrix[selected][column])) {
                selected = row;
            }
        }
        if (fabsl(matrix[selected][column]) <= epsilon) continue;
        swap(matrix[selected], matrix[pivot_row]);
        swap(right_hand_side[selected], right_hand_side[pivot_row]);
        where[column] = pivot_row;

        ld divisor = matrix[pivot_row][column];
        for (int next = column; next < column_count; ++next) {
            matrix[pivot_row][next] /= divisor;
        }
        right_hand_side[pivot_row] /= divisor;

        for (int row = 0; row < row_count; ++row) {
            if (row == pivot_row) continue;
            ld factor = matrix[row][column];
            if (fabsl(factor) <= epsilon) continue;
            for (int next = column; next < column_count; ++next) {
                matrix[row][next] -= factor * matrix[pivot_row][next];
            }
            right_hand_side[row] -= factor * right_hand_side[pivot_row];
        }
        ++pivot_row;
    }

    for (int row = 0; row < row_count; ++row) {
        bool all_zero = true;
        for (ld value : matrix[row]) {
            if (fabsl(value) > epsilon) all_zero = false;
        }
        if (all_zero && fabsl(right_hand_side[row]) > epsilon) {
            return {LinearSystemStatus::no_solution, pivot_row, {}};
        }
    }

    vector<ld> solution(column_count);
    for (int column = 0; column < column_count; ++column) {
        if (where[column] != -1) {
            solution[column] = right_hand_side[where[column]];
        }
    }
    LinearSystemStatus status =
        pivot_row == column_count ? LinearSystemStatus::unique
                                  : LinearSystemStatus::infinite;
    return {status, pivot_row, solution};
}

int matrix_rank(vector<vector<ld>> matrix, ld epsilon = 1e-12L) {
    vector<ld> zero(matrix.size());
    return solve_linear_system(move(matrix), move(zero), epsilon).rank;
}

optional<vector<vector<ld>>> inverse_matrix(
    vector<vector<ld>> matrix, ld epsilon = 1e-12L) {
    int n = (int)matrix.size();
    for (const auto& row : matrix) assert((int)row.size() == n);
    vector<vector<ld>> augmented(n, vector<ld>(2 * n));
    for (int row = 0; row < n; ++row) {
        for (int column = 0; column < n; ++column) {
            augmented[row][column] = matrix[row][column];
        }
        augmented[row][n + row] = 1;
    }

    for (int column = 0; column < n; ++column) {
        int selected = column;
        for (int row = column + 1; row < n; ++row) {
            if (fabsl(augmented[row][column]) >
                fabsl(augmented[selected][column])) selected = row;
        }
        if (fabsl(augmented[selected][column]) <= epsilon) return nullopt;
        swap(augmented[selected], augmented[column]);
        ld divisor = augmented[column][column];
        for (ld& value : augmented[column]) value /= divisor;
        for (int row = 0; row < n; ++row) {
            if (row == column) continue;
            ld factor = augmented[row][column];
            for (int next = 0; next < 2 * n; ++next) {
                augmented[row][next] -= factor * augmented[column][next];
            }
        }
    }

    vector<vector<ld>> inverse(n, vector<ld>(n));
    for (int row = 0; row < n; ++row) {
        copy(augmented[row].begin() + n, augmented[row].end(),
             inverse[row].begin());
    }
    return inverse;
}
```

复杂度 $O(rc\min(r,c))$，方阵时为 $O(n^3)$。固定绝对误差不适合数量级差异极大的矩阵；应先缩放数据或使用相对误差。整数/模意义问题不要转成浮点。

## 模质数版本

模意义下没有误差，但每个非零主元必须可逆，因此这里要求模数为质数。返回的无穷多解中，自由变量统一取 $0$。

```cpp
struct ModularLinearSystemResult {
    LinearSystemStatus status;
    int rank;
    vector<int> solution;
};

int gaussian_power_mod(long long base, long long exponent, int prime) {
    long long result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % prime;
        base = base * base % prime;
        exponent >>= 1;
    }
    return (int)result;
}

ModularLinearSystemResult solve_linear_system_mod(
    vector<vector<int>> matrix, vector<int> right_hand_side, int prime) {
    int row_count = (int)matrix.size();
    int column_count = row_count == 0 ? 0 : (int)matrix[0].size();
    assert(prime >= 2 && (int)right_hand_side.size() == row_count);
    for (auto& row : matrix) {
        assert((int)row.size() == column_count);
        for (int& value : row) value = (value % prime + prime) % prime;
    }
    for (int& value : right_hand_side) value = (value % prime + prime) % prime;

    vector<int> where(column_count, -1);
    int pivot_row = 0;
    for (int column = 0; column < column_count && pivot_row < row_count;
         ++column) {
        int selected = pivot_row;
        while (selected < row_count && matrix[selected][column] == 0) ++selected;
        if (selected == row_count) continue;
        swap(matrix[selected], matrix[pivot_row]);
        swap(right_hand_side[selected], right_hand_side[pivot_row]);
        where[column] = pivot_row;

        int inverse = gaussian_power_mod(matrix[pivot_row][column], prime - 2,
                                         prime);
        for (int next = column; next < column_count; ++next) {
            matrix[pivot_row][next] = (int)(
                (long long)matrix[pivot_row][next] * inverse % prime);
        }
        right_hand_side[pivot_row] = (int)(
            (long long)right_hand_side[pivot_row] * inverse % prime);

        for (int row = 0; row < row_count; ++row) {
            if (row == pivot_row || matrix[row][column] == 0) continue;
            int factor = matrix[row][column];
            for (int next = column; next < column_count; ++next) {
                matrix[row][next] = (int)(
                    (matrix[row][next] -
                     (long long)factor * matrix[pivot_row][next]) % prime);
                if (matrix[row][next] < 0) matrix[row][next] += prime;
            }
            right_hand_side[row] = (int)(
                (right_hand_side[row] -
                 (long long)factor * right_hand_side[pivot_row]) % prime);
            if (right_hand_side[row] < 0) right_hand_side[row] += prime;
        }
        ++pivot_row;
    }

    for (int row = pivot_row; row < row_count; ++row) {
        bool all_zero = all_of(matrix[row].begin(), matrix[row].end(),
                               [](int value) { return value == 0; });
        if (all_zero && right_hand_side[row] != 0) {
            return {LinearSystemStatus::no_solution, pivot_row, {}};
        }
    }
    vector<int> solution(column_count);
    for (int column = 0; column < column_count; ++column) {
        if (where[column] != -1) solution[column] = right_hand_side[where[column]];
    }
    return {pivot_row == column_count ? LinearSystemStatus::unique
                                      : LinearSystemStatus::infinite,
            pivot_row, solution};
}

optional<vector<vector<int>>> inverse_matrix_mod(vector<vector<int>> matrix,
                                                  int prime) {
    int n = (int)matrix.size();
    for (const auto& row : matrix) assert((int)row.size() == n);
    assert(prime >= 2);
    vector<vector<int>> augmented(n, vector<int>(2 * n));
    for (int row = 0; row < n; ++row) {
        for (int column = 0; column < n; ++column) {
            augmented[row][column] =
                (matrix[row][column] % prime + prime) % prime;
        }
        augmented[row][n + row] = 1;
    }

    for (int column = 0; column < n; ++column) {
        int selected = column;
        while (selected < n && augmented[selected][column] == 0) ++selected;
        if (selected == n) return nullopt;
        swap(augmented[selected], augmented[column]);

        int inverse_pivot =
            gaussian_power_mod(augmented[column][column], prime - 2, prime);
        for (int next = 0; next < 2 * n; ++next) {
            augmented[column][next] = (int)(
                (long long)augmented[column][next] * inverse_pivot % prime);
        }
        for (int row = 0; row < n; ++row) {
            if (row == column || augmented[row][column] == 0) continue;
            int factor = augmented[row][column];
            for (int next = 0; next < 2 * n; ++next) {
                augmented[row][next] = (int)(
                    (augmented[row][next] -
                     (long long)factor * augmented[column][next]) % prime);
                if (augmented[row][next] < 0) augmented[row][next] += prime;
            }
        }
    }

    vector<vector<int>> inverse(n, vector<int>(n));
    for (int row = 0; row < n; ++row) {
        copy(augmented[row].begin() + n, augmented[row].end(),
             inverse[row].begin());
    }
    return inverse;
}
```

逆矩阵把单位矩阵直接拼在右侧，一次 Gauss--Jordan 消元即可完成，复杂度 $O(n^3)$。若模数不是质数，不能用费马小定理求逆；即使主元非零，也可能不是单位元，此模板不适用。
