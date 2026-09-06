# 浮点几何、直线与圆

只有必须构造非整数坐标时才进入浮点层。不要直接用 `==` 比较 `long double`，并且不要把 `eps` 当作任意数量级下的万能容差；坐标极大时应按题目范围调整。

```cpp
#include <bits/stdc++.h>
using namespace std;

namespace geometry_float {

using ld = long double;
constexpr ld eps = 1e-12L;
const ld pi = acosl(-1.0L);

int sign(ld value) {
    return (value > eps) - (value < -eps);
}

struct Point {
    ld x = 0;
    ld y = 0;

    Point operator+(const Point& other) const {
        return {x + other.x, y + other.y};
    }
    Point operator-(const Point& other) const {
        return {x - other.x, y - other.y};
    }
    Point operator*(ld factor) const {
        return {x * factor, y * factor};
    }
    Point operator/(ld factor) const {
        return {x / factor, y / factor};
    }
};

ld dot(const Point& lhs, const Point& rhs) {
    return lhs.x * rhs.x + lhs.y * rhs.y;
}

ld cross(const Point& lhs, const Point& rhs) {
    return lhs.x * rhs.y - lhs.y * rhs.x;
}

ld norm2(const Point& point) {
    return dot(point, point);
}

ld length(const Point& point) {
    return sqrtl(norm2(point));
}

Point rotate90(const Point& point) {
    return {-point.y, point.x};
}

struct Line {
    Point point;
    Point direction;
};

optional<Point> line_intersection(const Line& lhs, const Line& rhs) {
    ld denominator = cross(lhs.direction, rhs.direction);
    if (sign(denominator) == 0) return nullopt;
    ld ratio = cross(rhs.point - lhs.point, rhs.direction) / denominator;
    return lhs.point + lhs.direction * ratio;
}

Point projection(const Point& point, const Line& line) {
    return line.point + line.direction *
           (dot(point - line.point, line.direction) / norm2(line.direction));
}

ld distance_to_line(const Point& point, const Line& line) {
    return fabsl(cross(line.direction, point - line.point)) /
           length(line.direction);
}

struct Circle {
    Point center;
    ld radius = 0;
};

vector<Point> circle_intersections(const Circle& lhs, const Circle& rhs) {
    Point difference = rhs.center - lhs.center;
    ld center_distance = length(difference);
    if (center_distance <= eps) return {};
    if (center_distance > lhs.radius + rhs.radius + eps) return {};
    if (center_distance < fabsl(lhs.radius - rhs.radius) - eps) return {};

    ld along = (lhs.radius * lhs.radius - rhs.radius * rhs.radius +
                center_distance * center_distance) / (2 * center_distance);
    ld height_squared = lhs.radius * lhs.radius - along * along;
    if (height_squared < -eps) return {};
    height_squared = max<ld>(0, height_squared);

    Point unit = difference / center_distance;
    Point base = lhs.center + unit * along;
    Point offset = rotate90(unit) * sqrtl(height_squared);
    if (height_squared <= eps) return {base};
    return {base + offset, base - offset};
}

vector<Point> line_circle_intersections(const Line& line, const Circle& circle) {
    Point foot = projection(circle.center, line);
    ld distance_squared = norm2(foot - circle.center);
    ld height_squared = circle.radius * circle.radius - distance_squared;
    if (height_squared < -eps) return {};
    height_squared = max<ld>(0, height_squared);
    if (height_squared <= eps) return {foot};
    Point offset = line.direction / length(line.direction) * sqrtl(height_squared);
    return {foot + offset, foot - offset};
}

} // namespace geometry_float
```

重合圆有无穷多个交点，上面的 `circle_intersections` 也返回空数组；若题目需要区分“无交点”和“重合”，应在调用前单独判断圆心距离与半径差。传给投影、点到直线距离和直线圆交点的方向向量必须非零。
