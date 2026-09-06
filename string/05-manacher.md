# Manacher

`odd_radius[i]` 表示以 $i$ 为中心的最长奇回文半径（包含中心），`even_radius[i]` 表示中心位于 $i-1,i$ 之间的最长偶回文半径。

```cpp
#include <bits/stdc++.h>
using namespace std;

pair<vector<int>, vector<int>> manacher(const string& text) {
    int size = (int)text.size();
    vector<int> odd_radius(size);
    for (int center = 0, left = 0, right = -1; center < size; ++center) {
        int radius = center > right
            ? 1 : min(odd_radius[left + right - center], right - center + 1);
        while (center - radius >= 0 && center + radius < size &&
               text[center - radius] == text[center + radius]) {
            ++radius;
        }
        odd_radius[center] = radius;
        if (center + radius - 1 > right) {
            left = center - radius + 1;
            right = center + radius - 1;
        }
    }

    vector<int> even_radius(size);
    for (int center = 0, left = 0, right = -1; center < size; ++center) {
        int radius = center > right
            ? 0 : min(even_radius[left + right - center + 1],
                      right - center + 1);
        while (center - radius - 1 >= 0 && center + radius < size &&
               text[center - radius - 1] == text[center + radius]) {
            ++radius;
        }
        even_radius[center] = radius;
        if (center + radius - 1 > right) {
            left = center - radius;
            right = center + radius - 1;
        }
    }
    return {odd_radius, even_radius};
}
```

最长回文长度是 `max(2*odd_radius[i]-1, 2*even_radius[i])`。复杂度为 $O(n)$。
