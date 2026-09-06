# 半平面交

每条有向直线保留其左侧半平面。下面实现要求最终交集**有界**；常见做法是额外加入一个足够大的逆时针矩形。空数组既可能表示空集，也可能表示无界区域。

依赖 `03-floating-geometry.md` 中的 `Point`、`Line`、`cross`、`dot`、`length`、`sign`、`eps` 和 `line_intersection`。

```cpp
namespace geometry_float {

bool outside(const Line& line, const Point& point) {
    return cross(line.direction, point - line.point) < -eps;
}

vector<Point> half_plane_intersection(vector<Line> lines) {
    auto angle = [](const Line& line) {
        return atan2l(line.direction.y, line.direction.x);
    };
    sort(lines.begin(), lines.end(), [&](const Line& lhs, const Line& rhs) {
        ld lhs_angle = angle(lhs);
        ld rhs_angle = angle(rhs);
        if (lhs_angle != rhs_angle) return lhs_angle < rhs_angle;
        return cross(lhs.direction, rhs.point - lhs.point) > 0;
    });

    vector<Line> unique_lines;
    for (const Line& line : lines) {
        if (length(line.direction) <= eps) continue;
        if (!unique_lines.empty() &&
            sign(cross(unique_lines.back().direction, line.direction)) == 0 &&
            dot(unique_lines.back().direction, line.direction) > 0) {
            if (cross(unique_lines.back().direction,
                      line.point - unique_lines.back().point) > eps) {
                unique_lines.back() = line;
            }
        } else {
            unique_lines.push_back(line);
        }
    }

    deque<Line> active;
    deque<Point> intersections;
    for (const Line& line : unique_lines) {
        while (!intersections.empty() && outside(line, intersections.back())) {
            intersections.pop_back();
            active.pop_back();
        }
        while (!intersections.empty() && outside(line, intersections.front())) {
            intersections.pop_front();
            active.pop_front();
        }
        if (!active.empty()) {
            optional<Point> point = line_intersection(active.back(), line);
            if (!point.has_value()) return {};
            intersections.push_back(*point);
        }
        active.push_back(line);
    }

    while (!intersections.empty() && outside(active.front(), intersections.back())) {
        intersections.pop_back();
        active.pop_back();
    }
    while (!intersections.empty() && outside(active.back(), intersections.front())) {
        intersections.pop_front();
        active.pop_front();
    }
    if (active.size() < 3) return {};

    optional<Point> closing = line_intersection(active.back(), active.front());
    if (!closing.has_value()) return {};
    intersections.push_back(*closing);
    return {intersections.begin(), intersections.end()};
}

} // namespace geometry_float
```

排序复杂度为 $O(n\log n)$，双端队列扫描为 $O(n)$。平行线去重时保留更靠左、约束更强的那一条。
