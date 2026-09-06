# 凸包与旋转卡壳

以下函数依赖 `01-geometry.md` 中的 `IPoint`、`cross`、`norm2` 和 `i128`。输入点允许重复。默认删除凸包边上的中间共线点；`keep_collinear=true` 时保留边界上的共线点。

## Andrew 凸包

```cpp
namespace geometry {

vector<IPoint> convex_hull(vector<IPoint> points, bool keep_collinear = false) {
    sort(points.begin(), points.end());
    points.erase(unique(points.begin(), points.end()), points.end());
    if (points.size() <= 1) return points;

    if (keep_collinear) {
        bool all_collinear = true;
        for (int i = 2; i < (int)points.size(); ++i) {
            if (cross(points[0], points[1], points[i]) != 0) {
                all_collinear = false;
                break;
            }
        }
        if (all_collinear) return points;
    }

    vector<IPoint> hull;
    auto should_pop = [&](const IPoint& next) {
        i128 turn = cross(hull[hull.size() - 2], hull.back(), next);
        return keep_collinear ? turn < 0 : turn <= 0;
    };

    for (const IPoint& point : points) {
        while (hull.size() >= 2 && should_pop(point)) hull.pop_back();
        hull.push_back(point);
    }
    int lower_size = (int)hull.size();
    for (int i = (int)points.size() - 2; i >= 0; --i) {
        while ((int)hull.size() > lower_size && should_pop(points[i])) {
            hull.pop_back();
        }
        hull.push_back(points[i]);
    }
    hull.pop_back();
    return hull;
}

} // namespace geometry
```

输出不重复首点，并按逆时针排列，从字典序最小点开始。复杂度由排序主导，为 $O(n\log n)$。

## 凸包直径

凸包直径是最远点对距离。输入必须是 `keep_collinear=false` 得到的逆时针凸包。

```cpp
namespace geometry {

i128 convex_diameter_squared(const vector<IPoint>& hull) {
    int size = (int)hull.size();
    if (size <= 1) return 0;
    if (size == 2) return norm2(hull[1] - hull[0]);

    i128 answer = 0;
    int opposite = 1;
    for (int i = 0; i < size; ++i) {
        int next_i = (i + 1) % size;
        while (true) {
            int next_opposite = (opposite + 1) % size;
            i128 current_area = cross(hull[next_i] - hull[i],
                                      hull[opposite] - hull[i]);
            i128 next_area = cross(hull[next_i] - hull[i],
                                   hull[next_opposite] - hull[i]);
            if (next_area <= current_area) break;
            opposite = next_opposite;
        }
        answer = max(answer, norm2(hull[i] - hull[opposite]));
        answer = max(answer, norm2(hull[next_i] - hull[opposite]));
    }
    return answer;
}

} // namespace geometry
```

复杂度为 $O(h)$，其中 $h$ 是凸包点数。返回距离平方，避免不必要的开方和浮点误差。
