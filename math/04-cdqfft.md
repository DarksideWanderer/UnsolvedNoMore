# CDQ 分治卷积

求形式递推

$$
f_i=base_i+\sum_{0\le j<i}f_jg_{i-j}.
$$

下面代码依赖 `16-polynomial.md` 的 `polynomial::multiply` 与 `mod`。CDQ 保证计算右半部分前，左半部分已经完整。

```cpp
namespace polynomial {

void cdq_convolution(vector<int>& values, const vector<int>& kernel,
                     int left, int right) {
    if (left == right) return;
    int middle = left + (right - left) / 2;
    cdq_convolution(values, kernel, left, middle);

    vector<int> lhs(values.begin() + left, values.begin() + middle + 1);
    int kernel_size = min((int)kernel.size(), right - left + 1);
    vector<int> rhs(kernel.begin(), kernel.begin() + kernel_size);
    vector<int> product = multiply(lhs, rhs);
    for (int index = middle + 1; index <= right; ++index) {
        int product_index = index - left;
        if (product_index < (int)product.size()) {
            values[index] += product[product_index];
            if (values[index] >= mod) values[index] -= mod;
        }
    }
    cdq_convolution(values, kernel, middle + 1, right);
}

vector<int> solve_convolution_recurrence(vector<int> base,
                                         const vector<int>& kernel) {
    if (!base.empty()) {
        assert(!kernel.empty());
        assert(kernel[0] == 0);
        cdq_convolution(base, kernel, 0, (int)base.size() - 1);
    }
    return base;
}

} // namespace polynomial
```

`kernel[0]` 必须为 0，因为递推只允许 $j<i$。当前写法每层分别做 NTT，总复杂度为 $O(n\log^2 n)$；使用带撤销或更精细的在线卷积可以进一步优化常数或复杂度。
