# 基础约定与常用结论

## 推荐的竞赛前导

只保留不会隐藏控制流的短别名。循环宏容易造成变量遮蔽、边界写反和调试困难，不建议放进公共模板。

```cpp
#include <bits/stdc++.h>
using namespace std;

using i64 = long long;
using u64 = unsigned long long;
using i128 = __int128_t;
using u128 = __uint128_t;

template<class Container>
int size_of(const Container& container) {
    return (int)container.size();
}

template<class T>
void clear_and_release(vector<T>& values) {
    vector<T>().swap(values);
}
```

`size_of` 的返回值是 `int`，仅适合竞赛中元素数量确定不超过 `INT_MAX` 的容器。通常 `clear()` 会保留容量，只有确实需要立即释放内存时才使用 `clear_and_release`。

本仓库代码以 C++20 为基准。Windows/MSYS2 下可使用：

```text
g++ solution.cpp -std=c++20 -O2 -Wall -Wextra -Wshadow -Wconversion -o solution.exe
```

本地调试时建议另编译一份 ASan + UBSan 版本：

```text
g++ solution.cpp -std=c++20 -O1 -g -Wall -Wextra -Wshadow -Wconversion -fsanitize=address,undefined -fno-omit-frame-pointer -D_GLIBCXX_ASSERTIONS -o solution_asan.exe
```

`AddressSanitizer` 主要检查越界、use-after-free、double-free 等内存错误，`UndefinedBehaviorSanitizer` 检查有符号溢出、非法移位等未定义行为；`-D_GLIBCXX_ASSERTIONS` 还能捕获一部分 STL 下标或迭代器前提错误。调试版会明显变慢并增大内存占用，最终提交应恢复 `-O2` 并去掉 sanitizer。若 Windows 使用的 GCC 发行版没有提供对应运行库，应在同一套 MSYS2/MinGW 环境中安装运行库，或改在 Linux/WSL 下运行，不要因为链接失败就认为程序已经通过检查。

若程序需要很大的栈，优先把大数组放到静态存储区或堆上，而不是依赖平台特有的链接参数。

## Markov 不等式

概率与期望的建模方法、常见分布、尾和、随机过程方程及 Chernoff 界统一见 `../math/34-probability-expectation.md`。本文件保留以下三个基础不等式供速查。

若随机变量 $X\ge 0$，则对任意 $a>0$，

$$
\Pr(X\ge a)\le \frac{\mathbb E[X]}{a}.
$$

## Chebyshev 不等式

若 $X$ 的期望和方差存在，则对任意 $a>0$，

$$
\Pr\bigl(|X-\mathbb E[X]|\ge a\bigr)
\le \frac{\operatorname{Var}(X)}{a^2}.
$$

令 $a=k\sigma$，其中 $\sigma^2=\operatorname{Var}(X)$，可得

$$
\Pr\bigl(|X-\mathbb E[X]|\ge k\sigma\bigr)\le \frac1{k^2}.
$$

## Union bound

事件不要求独立：

$$
\Pr\left(\bigcup_i A_i\right)\le\sum_i\Pr(A_i).
$$

在随机化算法中，常先估计每个坏事件的概率，再用 union bound 控制“至少一个坏事件发生”的概率。
