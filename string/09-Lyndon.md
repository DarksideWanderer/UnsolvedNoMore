# Lyndon 分解

Duval 算法把字符串唯一分解成字典序非增的 Lyndon 串序列，复杂度为 $O(n)$。

```cpp
#include <bits/stdc++.h>
using namespace std;

vector<string> lyndon_factorization(const string& text) {
    vector<string> factors;
    int size = (int)text.size();
    for (int begin = 0; begin < size; ) {
        int scan = begin + 1;
        int matched = begin;
        while (scan < size && text[matched] <= text[scan]) {
            matched = text[matched] < text[scan] ? begin : matched + 1;
            ++scan;
        }
        int factor_length = scan - matched;
        while (begin <= matched) {
            factors.push_back(text.substr(begin, factor_length));
            begin += factor_length;
        }
    }
    return factors;
}
```
