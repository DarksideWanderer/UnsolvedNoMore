# 二维计算几何基础

计算几何最容易出错的地方不是公式，而是**谓词是否精确**。当输入坐标是整数时，方向、共线、跨立和点在多边形内等离散判断应优先使用整数叉积；只有交点坐标、距离和圆等必须产生实数的操作才使用浮点数。

下面约定整数坐标和差的绝对值不超过 $10^9$。叉积使用 `__int128_t`，因此不会发生 64 位乘法溢出。

## 整数点、点积和叉积

```cpp
#include <bits/stdc++.h>
#include <cassert>
using namespace std;

namespace geometry {

using i64 = long long;
using i128 = __int128_t;

struct IPoint {
    i64 x = 0;
    i64 y = 0;

    IPoint operator+(const IPoint& other) const {
        return {x + other.x, y + other.y};
    }
    IPoint operator-(const IPoint& other) const {
        return {x - other.x, y - other.y};
    }
    bool operator==(const IPoint& other) const {
        return x == other.x && y == other.y;
    }
    bool operator<(const IPoint& other) const {
        return tie(x, y) < tie(other.x, other.y);
    }
};

i128 dot(const IPoint& lhs, const IPoint& rhs) {
    return (i128)lhs.x * rhs.x + (i128)lhs.y * rhs.y;
}

i128 cross(const IPoint& lhs, const IPoint& rhs) {
    return (i128)lhs.x * rhs.y - (i128)lhs.y * rhs.x;
}

i128 cross(const IPoint& origin, const IPoint& lhs, const IPoint& rhs) {
    return cross(lhs - origin, rhs - origin);
}

i128 norm2(const IPoint& point) {
    return dot(point, point);
}

int sign(i128 value) {
    return (value > 0) - (value < 0);
}

} // namespace geometry
```

`cross(a, b, c)` 的符号表示从向量 $\overrightarrow{ab}$ 转到 $\overrightarrow{ac}$ 的方向：正数为逆时针，负数为顺时针，零为共线。

## 跨立实验与线段相交

线段 $ab$ 与直线 $cd$ 的跨立实验是比较 `cross(c, d, a)` 与 `cross(c, d, b)` 的符号。两条线段严格相交，当且仅当它们分别严格跨立对方所在直线。

只用严格跨立会漏掉端点接触和共线重叠，因此完整实现必须单独处理叉积为零的情形：

```cpp
namespace geometry {

bool on_segment(const IPoint& point, const IPoint& lhs, const IPoint& rhs) {
    return cross(lhs, rhs, point) == 0 &&
           min(lhs.x, rhs.x) <= point.x && point.x <= max(lhs.x, rhs.x) &&
           min(lhs.y, rhs.y) <= point.y && point.y <= max(lhs.y, rhs.y);
}

enum class SegmentRelation {
    disjoint,             // 没有公共点
    touch,                // 恰有一个公共点，但不是两线段内部严格相交
    proper_intersection,  // 两线段在各自内部严格相交
    overlap               // 共线，且交集是一段非零长度线段
};

SegmentRelation segment_relation(IPoint a, IPoint b, IPoint c, IPoint d) {
    int ab_c = sign(cross(a, b, c));
    int ab_d = sign(cross(a, b, d));
    int cd_a = sign(cross(c, d, a));
    int cd_b = sign(cross(c, d, b));

    if (ab_c == 0 && ab_d == 0) {
        if (b < a) swap(a, b);
        if (d < c) swap(c, d);
        IPoint left = max(a, c);
        IPoint right = min(b, d);
        if (right < left) return SegmentRelation::disjoint;
        if (left == right) return SegmentRelation::touch;
        return SegmentRelation::overlap;
    }

    if (ab_c * ab_d < 0 && cd_a * cd_b < 0) {
        return SegmentRelation::proper_intersection;
    }
    if ((ab_c == 0 && on_segment(c, a, b)) ||
        (ab_d == 0 && on_segment(d, a, b)) ||
        (cd_a == 0 && on_segment(a, c, d)) ||
        (cd_b == 0 && on_segment(b, c, d))) {
        return SegmentRelation::touch;
    }
    return SegmentRelation::disjoint;
}

} // namespace geometry
```

复杂度为 $O(1)$。如果题目只问“是否有公共点”，返回值不是 `disjoint` 即可。

## 多边形面积与点包含

`point_in_polygon` 适用于任意简单多边形，顶点可顺时针或逆时针给出，返回 `outside / boundary / inside`。射线经过顶点时必须使用半开区间判断，否则同一个顶点可能被统计两次。

```cpp
namespace geometry {

i128 polygon_area_twice(const vector<IPoint>& polygon) {
    i128 area = 0;
    int size = (int)polygon.size();
    for (int i = 0; i < size; ++i) {
        area += cross(polygon[i], polygon[(i + 1) % size]);
    }
    return area;
}

enum class PointLocation {
    outside,   // 点在多边形外部
    boundary,  // 点在多边形边界上
    inside     // 点在多边形内部
};

PointLocation point_in_polygon(const vector<IPoint>& polygon, const IPoint& point) {
    bool inside = false;
    int size = (int)polygon.size();
    for (int i = 0; i < size; ++i) {
        IPoint lhs = polygon[i];
        IPoint rhs = polygon[(i + 1) % size];
        if (on_segment(point, lhs, rhs)) return PointLocation::boundary;

        bool crosses_height = (lhs.y > point.y) != (rhs.y > point.y);
        if (!crosses_height) continue;
        i128 direction = cross(lhs, rhs, point);
        if ((direction > 0) == (rhs.y > lhs.y)) inside = !inside;
    }
    return inside ? PointLocation::inside : PointLocation::outside;
}

} // namespace geometry
```

面积的实际值是 `abs(polygon_area_twice(polygon)) / 2`。点包含单次查询复杂度为 $O(n)$。

## Pick 定理与格点计数

对顶点都在整点上、没有自交且没有洞的简单多边形，设面积为 $A$、内部格点数为 $I$、边界格点数为 $B$，则

$$
A=I+\frac B2-1.
$$

使用二倍面积 $A_2=2A$ 时无需浮点数：

$$
I=\frac{A_2-B+2}{2}.
$$

整数线段两端坐标差为 $(dx,dy)$ 时，线段被分成 $\gcd(|dx|,|dy|)$ 段最短格点线段。沿多边形各边累加该 gcd，端点恰好各计一次，因此

$$
B=\sum_{i=0}^{n-1}gcd(|x_{i+1}-x_i|,|y_{i+1}-y_i|).
$$

```cpp
namespace geometry {

i128 boundary_lattice_points(const vector<IPoint>& polygon) {
    i128 boundary = 0;
    int size = (int)polygon.size();
    for (int i = 0; i < size; ++i) {
        const IPoint& lhs = polygon[i];
        const IPoint& rhs = polygon[(i + 1) % size];
        i64 dx = llabs(rhs.x - lhs.x);
        i64 dy = llabs(rhs.y - lhs.y);
        boundary += gcd(dx, dy);
    }
    return boundary;
}

i128 interior_lattice_points(const vector<IPoint>& polygon) {
    i128 area_twice = polygon_area_twice(polygon);
    if (area_twice < 0) area_twice = -area_twice;
    i128 boundary = boundary_lattice_points(polygon);
    i128 numerator = area_twice - boundary + 2;
    assert(polygon.size() >= 3 && area_twice > 0);
    assert(numerator >= 0 && numerator % 2 == 0);
    return numerator / 2;
}

} // namespace geometry
```

单条闭线段上的格点数是 `gcd(abs(dx), abs(dy)) + 1`，但按多边形边累加时不能再加 1，否则每个顶点会被重复计算。Pick 定理不能直接用于自交多边形；有 $h$ 个洞时应改为 $A=I+B/2-1+h$。
