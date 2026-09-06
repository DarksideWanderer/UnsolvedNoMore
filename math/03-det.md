# 模质数意义下的行列式

模数必须是质数。矩阵元素会先正规化到 $[0,p)$；使用高斯消元，复杂度为 $O(n^3)$。

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

long long power_mod(long long base, long long exponent, int modulus) {
    long long result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

int determinant_mod_prime(vector<vector<int>> matrix, int prime) {
    int size = (int)matrix.size();
    for (const auto& row : matrix) assert((int)row.size() == size);
    for (auto& row : matrix) {
        for (int& value : row) {
            value %= prime;
            if (value < 0) value += prime;
        }
    }

    long long determinant = 1;
    for (int column = 0; column < size; ++column) {
        int pivot = column;
        while (pivot < size && matrix[pivot][column] == 0) ++pivot;
        if (pivot == size) return 0;
        if (pivot != column) {
            swap(matrix[pivot], matrix[column]);
            determinant = prime - determinant;
        }
        int pivot_value = matrix[column][column];
        determinant = determinant * pivot_value % prime;
        long long pivot_inverse = power_mod(pivot_value, prime - 2, prime);
        for (int row = column + 1; row < size; ++row) {
            long long factor = matrix[row][column] * pivot_inverse % prime;
            for (int next_column = column; next_column < size; ++next_column) {
                matrix[row][next_column] = (int)(
                    (matrix[row][next_column] -
                     factor * matrix[column][next_column]) % prime);
                if (matrix[row][next_column] < 0) {
                    matrix[row][next_column] += prime;
                }
            }
        }
    }
    return (int)determinant;
}
```

不要在合数模数下使用 Fermat 逆元。合数模数可用不除法的欧几里得消元，或分别模质数幂计算后 CRT 合并。
