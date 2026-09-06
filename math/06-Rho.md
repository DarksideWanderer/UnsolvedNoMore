# Pollard–Rho 质因数分解

依赖 `02-miller rabin.md` 中的 `u64`、`multiply_mod` 和 `is_prime`。返回结果包含重数并按升序排列。

```cpp
namespace number_theory {

u64 pollard_rho(u64 value) {
    if (value % 2 == 0) return 2;
    if (value % 3 == 0) return 3;

    static mt19937_64 random_engine(
        chrono::steady_clock::now().time_since_epoch().count());
    auto next_value = [&](u64 current, u64 constant) {
        return (multiply_mod(current, current, value) + constant) % value;
    };

    while (true) {
        u64 current = random_engine() % (value - 2) + 2;
        u64 constant = random_engine() % (value - 1) + 1;
        u64 block_size = 128;
        u64 cycle_length = 1;
        u64 divisor = 1;
        u64 checkpoint = 0;
        u64 fallback = 0;

        while (divisor == 1) {
            checkpoint = current;
            for (u64 step = 0; step < cycle_length; ++step) {
                current = next_value(current, constant);
            }
            for (u64 begin = 0;
                 begin < cycle_length && divisor == 1;
                 begin += block_size) {
                fallback = current;
                u64 product = 1;
                u64 steps = min(block_size, cycle_length - begin);
                for (u64 step = 0; step < steps; ++step) {
                    current = next_value(current, constant);
                    u64 difference = checkpoint > current
                        ? checkpoint - current : current - checkpoint;
                    product = multiply_mod(product, difference, value);
                }
                divisor = gcd(product, value);
            }
            cycle_length <<= 1;
        }

        if (divisor == value) {
            do {
                fallback = next_value(fallback, constant);
                u64 difference = checkpoint > fallback
                    ? checkpoint - fallback : fallback - checkpoint;
                divisor = gcd(difference, value);
            } while (divisor == 1);
        }
        if (divisor != value) return divisor;
    }
}

void factor_recursively(u64 value, vector<u64>& factors) {
    if (value == 1) return;
    if (is_prime(value)) {
        factors.push_back(value);
        return;
    }
    u64 divisor = pollard_rho(value);
    factor_recursively(divisor, factors);
    factor_recursively(value / divisor, factors);
}

vector<u64> factorize(u64 value) {
    vector<u64> factors;
    factor_recursively(value, factors);
    sort(factors.begin(), factors.end());
    return factors;
}

} // namespace number_theory
```

`factorize(1)` 返回空数组。Pollard–Rho 的运行时间具有随机性；若某次多项式迭代退化，外层循环会自动换随机参数重试。
