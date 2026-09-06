# 凸多边形 Minkowski 和

两个点集的 Minkowski 和定义为

$$
A+B=\{a+b:a\in A,b\in B\}.
$$

对严格凸多边形，其边向量分别按极角有序；合并两组边向量即可在线性时间得到和多边形。代码依赖 `01-geometry.md` 的整数点与 `02-convex-hull.md`。

```cpp
namespace geometry {

vector<IPoint> rotate_convex_start(vector<IPoint> polygon) {
    if (polygon.empty()) return polygon;
    int start = 0;
    for (int index = 1; index < (int)polygon.size(); ++index) {
        if (tie(polygon[index].y, polygon[index].x) <
            tie(polygon[start].y, polygon[start].x)) start = index;
    }
    rotate(polygon.begin(), polygon.begin() + start, polygon.end());
    return polygon;
}

vector<IPoint> minkowski_sum(vector<IPoint> left,
                             vector<IPoint> right) {
    if (left.empty() || right.empty()) return {};

    // 输入应是 convex_hull(..., false) 的输出；退化到点或线段时直接做常数次枚举。
    if (left.size() <= 2 || right.size() <= 2) {
        vector<IPoint> sums;
        for (const IPoint& lhs : left) {
            for (const IPoint& rhs : right) sums.push_back(lhs + rhs);
        }
        return convex_hull(move(sums));
    }

    left = rotate_convex_start(move(left));
    right = rotate_convex_start(move(right));
    vector<IPoint> left_edges(left.size());
    vector<IPoint> right_edges(right.size());
    for (int index = 0; index < (int)left.size(); ++index) {
        left_edges[index] = left[(index + 1) % left.size()] - left[index];
    }
    for (int index = 0; index < (int)right.size(); ++index) {
        right_edges[index] = right[(index + 1) % right.size()] - right[index];
    }

    vector<IPoint> result;
    IPoint current = left[0] + right[0];
    result.push_back(current);
    int left_index = 0;
    int right_index = 0;
    while (left_index < (int)left_edges.size() ||
           right_index < (int)right_edges.size()) {
        IPoint step;
        if (right_index == (int)right_edges.size()) {
            step = left_edges[left_index++];
        } else if (left_index == (int)left_edges.size()) {
            step = right_edges[right_index++];
        } else {
            i128 direction = cross(left_edges[left_index],
                                   right_edges[right_index]);
            if (direction > 0) {
                step = left_edges[left_index++];
            } else if (direction < 0) {
                step = right_edges[right_index++];
            } else {
                step = left_edges[left_index++] + right_edges[right_index++];
            }
        }
        current = current + step;
        result.push_back(current);
    }
    assert(result.front() == result.back());
    result.pop_back();
    return result;
}

} // namespace geometry
```

前提是两个输入均为 `convex_hull(points, false)` 产生的严格凸包：不重复首点、逆时针、无共线中间点。主体复杂度 $O(|A|+|B|)$；点和线段的退化分支只枚举至多四个点。

若原始输入还不是凸包，先分别求凸包，总复杂度由排序变成 $O(n\log n+m\log m)$。叉积与点加法的范围也必须满足 `i128/i64` 的约束；Minkowski 和坐标是两边坐标之和。
