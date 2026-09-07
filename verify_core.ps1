param(
    [switch]$KeepExecutables,
    [switch]$Sanitize,
    [string]$Cxx = "g++",
    [string]$Only = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$markdownFiles = Get-ChildItem -LiteralPath $repoRoot -Recurse -File -Filter *.md |
    Where-Object { $_.FullName -notlike "$repoRoot\pdf_output\*" }
$badLatexSpacing = Select-String -LiteralPath $markdownFiles.FullName `
    -Pattern '(?<!\\)\b(?:qquad|quad)\b'
if ($badLatexSpacing) {
    $locations = $badLatexSpacing | ForEach-Object {
        "$($_.Path):$($_.LineNumber): $($_.Line.Trim())"
    }
    throw "LaTeX spacing command is missing a backslash:`n$($locations -join "`n")"
}

function Get-CppBlocks {
    param([string[]]$Paths)
    $fence = [string]::new([char]96, 3)
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($relativePath in $Paths) {
        $inside = $false
        $path = (Resolve-Path (Join-Path $repoRoot $relativePath)).Path
        foreach ($line in Get-Content -Encoding UTF8 -LiteralPath $path) {
            if (-not $inside -and
                ($line.Trim().ToLowerInvariant() -eq ($fence + "cpp") -or
                 $line.Trim().ToLowerInvariant() -eq ($fence + "c++"))) {
                $inside = $true
                continue
            }
            if ($inside -and $line.StartsWith($fence)) {
                $inside = $false
                continue
            }
            if ($inside) {
                $lines.Add($line)
            }
        }
        if ($inside) {
            throw "Unclosed code block: $relativePath"
        }
    }
    return $lines -join [Environment]::NewLine
}

function Invoke-CppTest {
    param([string]$Name, [string[]]$Paths, [string]$TestCode)
    if ($Only -and $Name -ne $Only) {
        return
    }
    $executable = Join-Path ([IO.Path]::GetTempPath()) (
        "template-" + $Name + "-" + $PID + ".exe"
    )
    try {
        $source = "#include <cassert>" + [Environment]::NewLine +
                  (Get-CppBlocks $Paths) + [Environment]::NewLine + $TestCode
        $compilerArguments = @(
            "-x", "c++", "-std=c++20", "-Wall", "-Wextra", "-Wshadow",
            "-Wconversion", "-pedantic"
        )
        if ($Sanitize) {
            $compilerArguments += @(
                "-O1", "-g", "-fsanitize=address,undefined",
                "-fno-omit-frame-pointer", "-D_GLIBCXX_ASSERTIONS"
            )
        } else {
            $compilerArguments += "-O2"
        }
        $compilerArguments += @("-o", $executable, "-")
        $source | & $Cxx @compilerArguments
        if ($LASTEXITCODE -ne 0) {
            throw "$Name failed to compile"
        }
        & $executable
        if ($LASTEXITCODE -ne 0) {
            throw "$Name tests failed"
        }
        Write-Host "[PASS] $Name"
    }
    finally {
        if (-not $KeepExecutables -and (Test-Path -LiteralPath $executable)) {
            Remove-Item -LiteralPath $executable
        }
    }
}

$geometryTest = @'
int main() {
    using namespace geometry;
    using Relation = SegmentRelation;
    assert(segment_relation({0, 0}, {4, 4}, {0, 4}, {4, 0}) ==
           Relation::proper_intersection);
    assert(segment_relation({0, 0}, {2, 0}, {2, 0}, {3, 1}) ==
           Relation::touch);
    assert(segment_relation({0, 0}, {4, 0}, {2, 0}, {6, 0}) ==
           Relation::overlap);
    assert(segment_relation({0, 0}, {1, 0}, {2, 0}, {3, 0}) ==
           Relation::disjoint);

    vector<IPoint> square{{0, 0}, {4, 0}, {4, 4}, {0, 4}};
    assert(point_in_polygon(square, {2, 2}) == PointLocation::inside);
    assert(point_in_polygon(square, {4, 2}) == PointLocation::boundary);
    assert(point_in_polygon(square, {5, 2}) == PointLocation::outside);

    mt19937 random_engine(712367);
    for (int test = 0; test < 1000; ++test) {
        int size = 1 + (int)(random_engine() % 25);
        vector<IPoint> points(size);
        for (IPoint& point : points) {
            point.x = (int)(random_engine() % 41) - 20;
            point.y = (int)(random_engine() % 41) - 20;
        }
        vector<IPoint> hull = convex_hull(points);
        i128 expected = 0;
        for (const IPoint& lhs : points) {
            for (const IPoint& rhs : points) {
                expected = max(expected, norm2(lhs - rhs));
            }
        }
        assert(convex_diameter_squared(hull) == expected);
    }

    namespace gf = geometry_float;
    auto intersection = gf::line_intersection(
        {{0, 0}, {1, 1}}, {{0, 1}, {1, -1}});
    assert(intersection.has_value());
    assert(fabsl(intersection->x - 0.5L) < 1e-12L);
    assert(fabsl(intersection->y - 0.5L) < 1e-12L);
    vector<gf::Point> tangent = gf::circle_intersections(
        {{0, 0}, 1}, {{2, 0}, 1});
    assert(tangent.size() == 1);
    vector<gf::Line> half_planes{
        {{0, 0}, {1, 0}},
        {{1, 0}, {0, 1}},
        {{1, 1}, {-1, 0}},
        {{0, 1}, {0, -1}}
    };
    vector<gf::Point> polygon = gf::half_plane_intersection(half_planes);
    assert(polygon.size() == 4);
    long double area_twice = 0;
    for (int i = 0; i < (int)polygon.size(); ++i) {
        area_twice += gf::cross(polygon[i], polygon[(i + 1) % polygon.size()]);
    }
    assert(fabsl(fabsl(area_twice) - 2.0L) < 1e-9L);

    for (int test = 0; test < 2000; ++test) {
        vector<IPoint> source_points(30);
        for (IPoint& point : source_points) {
            point.x = (int)(random_engine() % 201) - 100;
            point.y = (int)(random_engine() % 201) - 100;
        }
        vector<IPoint> integer_hull = convex_hull(source_points);
        if (integer_hull.size() < 3) continue;
        vector<gf::Line> constraints;
        long double expected_area_twice = 0;
        for (int i = 0; i < (int)integer_hull.size(); ++i) {
            const IPoint& lhs = integer_hull[i];
            const IPoint& rhs = integer_hull[(i + 1) % integer_hull.size()];
            gf::Point point{(long double)lhs.x, (long double)lhs.y};
            gf::Point direction{(long double)(rhs.x - lhs.x),
                                (long double)(rhs.y - lhs.y)};
            constraints.push_back({point, direction});
            expected_area_twice +=
                (long double)lhs.x * rhs.y - (long double)lhs.y * rhs.x;
        }
        shuffle(constraints.begin(), constraints.end(), random_engine);
        vector<gf::Point> result = gf::half_plane_intersection(constraints);
        assert(result.size() == integer_hull.size());
        long double result_area_twice = 0;
        for (int i = 0; i < (int)result.size(); ++i) {
            result_area_twice +=
                gf::cross(result[i], result[(i + 1) % result.size()]);
            for (const gf::Line& constraint : constraints) {
                assert(!gf::outside(constraint, result[i]));
            }
        }
        assert(fabsl(fabsl(result_area_twice) -
                     fabsl(expected_area_twice)) < 1e-7L);
    }
}
'@

$polynomialTest = @'
using namespace polynomial;

vector<int> naive_multiply(const vector<int>& lhs, const vector<int>& rhs,
                           int limit = INT_MAX) {
    if (lhs.empty() || rhs.empty()) return {};
    int size = min(limit, (int)lhs.size() + (int)rhs.size() - 1);
    vector<int> result(size);
    for (int i = 0; i < (int)lhs.size(); ++i) {
        for (int j = 0; j < (int)rhs.size() && i + j < size; ++j) {
            result[i + j] = (int)(
                (result[i + j] + (long long)lhs[i] * rhs[j]) % mod);
        }
    }
    return result;
}

int main() {
    mt19937 random_engine(998244353);
    for (int test = 0; test < 300; ++test) {
        int lhs_size = 1 + (int)(random_engine() % 80);
        int rhs_size = 1 + (int)(random_engine() % 80);
        vector<int> lhs(lhs_size);
        vector<int> rhs(rhs_size);
        for (int& value : lhs) value = (int)(random_engine() % mod);
        for (int& value : rhs) value = (int)(random_engine() % mod);
        assert(multiply(lhs, rhs) == naive_multiply(lhs, rhs));
    }

    for (int test = 0; test < 200; ++test) {
        constexpr int size = 64;
        vector<int> poly(size);
        poly[0] = 1 + (int)(random_engine() % (mod - 1));
        for (int i = 1; i < size; ++i) {
            poly[i] = (int)(random_engine() % mod);
        }
        vector<int> product = multiply(poly, inverse(poly, size));
        product.resize(size);
        assert(product[0] == 1);
        for (int i = 1; i < size; ++i) assert(product[i] == 0);

        poly[0] = 1;
        assert(exponential(logarithm(poly, size), size) == poly);
    }

    for (int exponent = 0; exponent <= 6; ++exponent) {
        vector<int> poly{0, 2, 3, 4};
        vector<int> expected{1};
        for (int step = 0; step < exponent; ++step) {
            expected = naive_multiply(expected, poly, 20);
        }
        expected.resize(20);
        assert(power(poly, exponent, 20) == expected);
    }

    vector<int> fibonacci(201);
    fibonacci[1] = 1;
    for (int i = 2; i <= 200; ++i) {
        fibonacci[i] = fibonacci[i - 1] + fibonacci[i - 2];
        if (fibonacci[i] >= mod) fibonacci[i] -= mod;
    }
    for (int i = 0; i <= 200; ++i) {
        assert(bostan_mori({0, 1}, {1, mod - 1, mod - 1}, i) ==
               fibonacci[i]);
    }
}
'@

$numberTheoryTest = @'
int main() {
    using namespace number_theory;
    vector<u64> primes{2, 3, 5, 97, 1000000007ULL, 18446744073709551557ULL};
    for (u64 value : primes) assert(is_prime(value));
    vector<u64> composites{0, 1, 4, 341, 561, 3215031751ULL,
                           3825123056546413051ULL};
    for (u64 value : composites) assert(!is_prime(value));

    vector<u64> values{2, 12, 600851475143ULL,
                       1000000007ULL * 1000000009ULL};
    for (u64 value : values) {
        vector<u64> factors = factorize(value);
        u128 product = 1;
        for (u64 factor : factors) {
            assert(is_prime(factor));
            product *= factor;
        }
        assert(product == value);
        assert(is_sorted(factors.begin(), factors.end()));
    }
}
'@

$discreteLogTest = @'
long long brute_log(long long base, long long target, long long modulus) {
    vector<bool> visited(modulus);
    long long current = 1 % modulus;
    for (long long exponent = 0; !visited[current]; ++exponent) {
        if (current == target) return exponent;
        visited[current] = true;
        current = (long long)((__int128_t)current * base % modulus);
    }
    return -1;
}

int main() {
    using discrete_logarithm::extended_bsgs;
    for (int modulus = 1; modulus <= 200; ++modulus) {
        for (int base = 0; base < modulus; ++base) {
            for (int target = 0; target < modulus; ++target) {
                assert(extended_bsgs(base, target, modulus) ==
                       brute_log(base, target, modulus));
            }
        }
    }
}
'@

$tarjanTest = @'
int component_count_without(
    const vector<vector<pair<int, int>>>& graph,
    int removed_vertex, int removed_edge) {
    int size = (int)graph.size();
    vector<bool> visited(size);
    int count = 0;
    for (int start = 0; start < size; ++start) {
        if (start == removed_vertex || visited[start]) continue;
        ++count;
        queue<int> que;
        que.push(start);
        visited[start] = true;
        while (!que.empty()) {
            int node = que.front();
            que.pop();
            for (auto [next, edge_id] : graph[node]) {
                if (next == removed_vertex || edge_id == removed_edge ||
                    visited[next]) {
                    continue;
                }
                visited[next] = true;
                que.push(next);
            }
        }
    }
    return count;
}

int main() {
    mt19937 random_engine(20240901);
    for (int test = 0; test < 500; ++test) {
        int size = 1 + (int)(random_engine() % 9);
        StronglyConnectedComponents scc(size);
        vector<vector<bool>> reachable(size, vector<bool>(size));
        for (int node = 0; node < size; ++node) reachable[node][node] = true;
        for (int from = 0; from < size; ++from) {
            for (int to = 0; to < size; ++to) {
                if (random_engine() % 4 == 0) {
                    scc.add_edge(from, to);
                    reachable[from][to] = true;
                }
            }
        }
        scc.build();
        for (int middle = 0; middle < size; ++middle) {
            for (int from = 0; from < size; ++from) {
                for (int to = 0; to < size; ++to) {
                    reachable[from][to] =
                        reachable[from][to] ||
                        (reachable[from][middle] && reachable[middle][to]);
                }
            }
        }
        for (int lhs = 0; lhs < size; ++lhs) {
            for (int rhs = 0; rhs < size; ++rhs) {
                assert((scc.component_of[lhs] == scc.component_of[rhs]) ==
                       (reachable[lhs][rhs] && reachable[rhs][lhs]));
            }
        }
    }

    for (int test = 0; test < 1000; ++test) {
        int size = 1 + (int)(random_engine() % 9);
        EdgeBiconnectedComponents edge_bcc(size);
        VertexBiconnectedComponents vertex_bcc(size);
        vector<vector<pair<int, int>>> graph(size);
        vector<pair<int, int>> edges;
        int edge_count = (int)(random_engine() % 18);
        for (int edge_id = 0; edge_id < edge_count; ++edge_id) {
            int lhs = random_engine() % size;
            int rhs = random_engine() % size;
            if (lhs == rhs) {
                --edge_id;
                --edge_count;
                continue;
            }
            int actual_id = edge_bcc.add_edge(lhs, rhs);
            assert(actual_id == (int)edges.size());
            vertex_bcc.add_edge(lhs, rhs);
            edges.push_back({lhs, rhs});
            graph[lhs].push_back({rhs, actual_id});
            graph[rhs].push_back({lhs, actual_id});
        }
        edge_bcc.build();
        int original_components = component_count_without(graph, -1, -1);
        for (int edge_id = 0; edge_id < (int)edges.size(); ++edge_id) {
            bool expected =
                component_count_without(graph, -1, edge_id) >
                original_components;
            assert(edge_bcc.is_bridge[edge_id] == expected);
        }

        vertex_bcc.build();
        for (int node = 0; node < size; ++node) {
            bool expected =
                component_count_without(graph, node, -1) >
                original_components;
            assert(vertex_bcc.is_cut_vertex[node] == expected);
        }
    }
}
'@

$flowTest = @'
long long edmonds_karp(vector<vector<long long>> capacity,
                       int source, int sink) {
    int size = (int)capacity.size();
    long long answer = 0;
    while (true) {
        vector<int> parent(size, -1);
        queue<int> que;
        parent[source] = source;
        que.push(source);
        while (!que.empty() && parent[sink] == -1) {
            int node = que.front();
            que.pop();
            for (int next = 0; next < size; ++next) {
                if (parent[next] == -1 && capacity[node][next] > 0) {
                    parent[next] = node;
                    que.push(next);
                }
            }
        }
        if (parent[sink] == -1) return answer;
        long long pushed = LLONG_MAX;
        for (int node = sink; node != source; node = parent[node]) {
            pushed = min(pushed, capacity[parent[node]][node]);
        }
        for (int node = sink; node != source; node = parent[node]) {
            capacity[parent[node]][node] -= pushed;
            capacity[node][parent[node]] += pushed;
        }
        answer += pushed;
    }
}

int main() {
    mt19937 random_engine(19260817);
    for (int test = 0; test < 1000; ++test) {
        int size = 2 + (int)(random_engine() % 8);
        Dinic dinic(size);
        vector<vector<long long>> capacity(size, vector<long long>(size));
        for (int from = 0; from < size; ++from) {
            for (int to = 0; to < size; ++to) {
                if (from == to || random_engine() % 4 != 0) continue;
                long long value = random_engine() % 8;
                dinic.add_edge(from, to, value);
                capacity[from][to] += value;
            }
        }
        assert(dinic.max_flow(0, size - 1) ==
               edmonds_karp(capacity, 0, size - 1));
    }
}
'@

$minCostFlowTest = @'
class ReferenceMinCostFlow {
    struct Edge {
        int to;
        int reverse_id;
        long long capacity;
        long long cost;
    };
    vector<vector<Edge>> graph;

public:
    explicit ReferenceMinCostFlow(int size) : graph(size) {}

    void add_edge(int from, int to, long long capacity, long long cost) {
        int from_id = (int)graph[from].size();
        int to_id = (int)graph[to].size();
        graph[from].push_back({to, to_id, capacity, cost});
        graph[to].push_back({from, from_id, 0, -cost});
    }

    pair<long long, long long> solve(int source, int sink, long long limit) {
        int size = (int)graph.size();
        long long total_flow = 0;
        long long total_cost = 0;
        while (total_flow < limit) {
            vector<long long> distance(size, LLONG_MAX / 4);
            vector<int> previous_node(size, -1);
            vector<int> previous_edge(size, -1);
            distance[source] = 0;
            for (int round = 1; round < size; ++round) {
                bool changed = false;
                for (int node = 0; node < size; ++node) {
                    if (distance[node] == LLONG_MAX / 4) continue;
                    for (int edge_id = 0;
                         edge_id < (int)graph[node].size(); ++edge_id) {
                        const Edge& edge = graph[node][edge_id];
                        if (edge.capacity > 0 &&
                            distance[edge.to] > distance[node] + edge.cost) {
                            distance[edge.to] = distance[node] + edge.cost;
                            previous_node[edge.to] = node;
                            previous_edge[edge.to] = edge_id;
                            changed = true;
                        }
                    }
                }
                if (!changed) break;
            }
            if (previous_node[sink] == -1) break;
            long long pushed = limit - total_flow;
            for (int node = sink; node != source; node = previous_node[node]) {
                pushed = min(
                    pushed,
                    graph[previous_node[node]][previous_edge[node]].capacity);
            }
            for (int node = sink; node != source; node = previous_node[node]) {
                Edge& edge =
                    graph[previous_node[node]][previous_edge[node]];
                edge.capacity -= pushed;
                graph[node][edge.reverse_id].capacity += pushed;
            }
            total_flow += pushed;
            total_cost += pushed * distance[sink];
        }
        return {total_flow, total_cost};
    }
};

int main() {
    mt19937 random_engine(31415926);
    for (int test = 0; test < 1000; ++test) {
        int size = 2 + (int)(random_engine() % 7);
        long long limit = random_engine() % 8;
        MinCostMaxFlow tested(size);
        ReferenceMinCostFlow reference(size);
        for (int from = 0; from < size; ++from) {
            for (int to = from + 1; to < size; ++to) {
                if (random_engine() % 3 != 0) continue;
                long long capacity = random_engine() % 4;
                long long cost = (int)(random_engine() % 15) - 7;
                tested.add_edge(from, to, capacity, cost);
                reference.add_edge(from, to, capacity, cost);
            }
        }
        assert(tested.min_cost_max_flow(0, size - 1, limit) ==
               reference.solve(0, size - 1, limit));
    }
}
'@

$matchingTest = @'
// Enumerate all matchings by left vertex and count each edge in optimal ones.
// Parallel edges have distinct IDs in this independent brute-force oracle.
void check_bipartite(int left_size, int right_size,
                     const vector<pair<int, int>>& edges) {
    HopcroftKarp matching(left_size, right_size);
    vector<vector<int>> incident(left_size);
    for (int id = 0; id < (int)edges.size(); ++id) {
        auto [left, right] = edges[id];
        matching.add_edge(left, right);
        incident[left].push_back(id);
    }
    int best = -1;
    long long ways = 0;
    vector<long long> edge_ways(edges.size());
    vector<int> chosen;
    auto enumerate = [&](auto&& self, int left, int used_right) -> void {
        if (left == left_size) {
            int size = (int)chosen.size();
            if (size < best) return;
            if (size > best) {
                best = size;
                ways = 0;
                fill(edge_ways.begin(), edge_ways.end(), 0);
            }
            ++ways;
            for (int id : chosen) ++edge_ways[id];
            return;
        }
        self(self, left + 1, used_right);
        for (int id : incident[left]) {
            int right = edges[id].second;
            if (used_right >> right & 1) continue;
            chosen.push_back(id);
            self(self, left + 1, used_right | (1 << right));
            chosen.pop_back();
        }
    };
    enumerate(enumerate, 0, 0);
    assert(matching.max_matching() == best);
    int actual_size = 0;
    for (int left = 0; left < left_size; ++left) {
        int right = matching.match_left[left];
        if (right == -1) continue;
        assert(0 <= right && right < right_size);
        assert(matching.match_right[right] == left);
        assert(find(edges.begin(), edges.end(), make_pair(left, right)) !=
               edges.end());
        ++actual_size;
    }
    assert(actual_size == best);
    for (int right = 0; right < right_size; ++right) {
        int left = matching.match_right[right];
        if (left != -1) assert(matching.match_left[left] == right);
    }
    auto types = classify_maximum_matching_edges(
        left_size, right_size, edges, matching.match_left, matching.match_right);
    for (int id = 0; id < (int)edges.size(); ++id) {
        MatchingEdgeType expected = edge_ways[id] == 0
            ? MatchingEdgeType::impossible
            : edge_ways[id] == ways ? MatchingEdgeType::mandatory
                                    : MatchingEdgeType::feasible;
        assert(types[id] == expected);
    }
}

void check_antichain(const vector<vector<int>>& dag) {
    int size = (int)dag.size();
    vector<vector<bool>> reachable(size, vector<bool>(size));
    for (int from = 0; from < size; ++from) {
        for (int to : dag[from]) reachable[from][to] = true;
    }
    for (int middle = 0; middle < size; ++middle) {
        for (int from = 0; from < size; ++from) {
            for (int to = 0; to < size; ++to) {
                reachable[from][to] = reachable[from][to] ||
                    (reachable[from][middle] && reachable[middle][to]);
            }
        }
    }
    auto independent = [&](int mask) {
        for (int lhs = 0; lhs < size; ++lhs) {
            for (int rhs = lhs + 1; rhs < size; ++rhs) {
                if ((mask >> lhs & 1) && (mask >> rhs & 1) &&
                    (reachable[lhs][rhs] || reachable[rhs][lhs])) return false;
            }
        }
        return true;
    };
    int best = 0;
    for (int mask = 0; mask < (1 << size); ++mask) {
        if (independent(mask)) best = max(best, popcount((unsigned)mask));
    }
    auto answer = maximum_antichain(dag);
    int mask = 0;
    for (int vertex : answer) {
        assert(0 <= vertex && vertex < size);
        assert(!(mask >> vertex & 1));
        mask |= 1 << vertex;
    }
    assert(independent(mask));
    assert((int)answer.size() == best);
}

int brute_matching(const vector<vector<bool>>& graph, int used,
                   vector<int>& memo) {
    int size = (int)graph.size();
    if (memo[used] != -1) return memo[used];
    int first = 0;
    while (first < size && (used >> first & 1)) ++first;
    if (first == size) return memo[used] = 0;
    int answer = brute_matching(graph, used | (1 << first), memo);
    for (int next = first + 1; next < size; ++next) {
        if (!(used >> next & 1) && graph[first][next]) {
            answer = max(answer, 1 + brute_matching(
                graph, used | (1 << first) | (1 << next), memo));
        }
    }
    return memo[used] = answer;
}

int main() {
    mt19937 random_engine(114514);
    // All simple bipartite graphs with up to 3 vertices on each side.
    for (int left_size = 0; left_size <= 3; ++left_size) {
        for (int right_size = 0; right_size <= 3; ++right_size) {
            for (int mask = 0; mask < (1 << (left_size * right_size)); ++mask) {
                vector<pair<int, int>> edges;
                for (int left = 0; left < left_size; ++left) {
                    for (int right = 0; right < right_size; ++right) {
                        if (mask >> (left * right_size + right) & 1) {
                            edges.push_back({left, right});
                        }
                    }
                }
                check_bipartite(left_size, right_size, edges);
            }
        }
    }
    for (int test = 0; test < 1000; ++test) {
        int left_size = 1 + (int)(random_engine() % 5);
        int right_size = 1 + (int)(random_engine() % 5);
        vector<pair<int, int>> edges;
        int edge_count = (int)(random_engine() % 20);
        for (int id = 0; id < edge_count; ++id) {
            edges.push_back({(int)(random_engine() % (unsigned)left_size),
                             (int)(random_engine() % (unsigned)right_size)});
        }
        check_bipartite(left_size, right_size, edges);
    }
    // All DAGs with a fixed topological order and up to 5 vertices.
    for (int size = 0; size <= 5; ++size) {
        vector<pair<int, int>> possible;
        for (int lhs = 0; lhs < size; ++lhs) {
            for (int rhs = lhs + 1; rhs < size; ++rhs) {
                possible.push_back({lhs, rhs});
            }
        }
        for (int mask = 0; mask < (1 << (int)possible.size()); ++mask) {
            vector<vector<int>> dag(size);
            for (int id = 0; id < (int)possible.size(); ++id) {
                if (mask >> id & 1) {
                    auto [lhs, rhs] = possible[id];
                    dag[lhs].push_back(rhs);
                }
            }
            check_antichain(dag);
        }
    }
    for (int test = 0; test < 500; ++test) {
        int size = (int)(random_engine() % 11);
        vector<int> order(size);
        iota(order.begin(), order.end(), 0);
        shuffle(order.begin(), order.end(), random_engine);
        vector<vector<int>> dag(size);
        for (int lhs = 0; lhs < size; ++lhs) {
            for (int rhs = lhs + 1; rhs < size; ++rhs) {
                if (random_engine() % 3 == 0) {
                    dag[order[lhs]].push_back(order[rhs]);
                }
            }
        }
        check_antichain(dag);
    }
    assert(GeneralMatching(0).max_matching() == 0);
    for (int test = 0; test < 1000; ++test) {
        int size = 1 + (int)(random_engine() % 10);
        vector<vector<bool>> graph(size, vector<bool>(size));
        GeneralMatching matching(size);
        for (int lhs = 0; lhs < size; ++lhs) {
            for (int rhs = lhs + 1; rhs < size; ++rhs) {
                if (random_engine() % 3 == 0) {
                    graph[lhs][rhs] = graph[rhs][lhs] = true;
                    matching.add_edge(lhs, rhs);
                    if (random_engine() % 3 == 0) matching.add_edge(lhs, rhs);
                }
            }
        }
        vector<int> memo(1 << size, -1);
        int actual = matching.max_matching();
        assert(actual == brute_matching(graph, 0, memo));
        int matched_vertices = 0;
        for (int vertex = 0; vertex < size; ++vertex) {
            int partner = matching.match[vertex];
            if (partner == -1) continue;
            assert(0 <= partner && partner < size && partner != vertex);
            assert(graph[vertex][partner]);
            assert(matching.match[partner] == vertex);
            ++matched_vertices;
        }
        assert(matched_vertices == 2 * actual);
    }

    for (int test = 0; test < 300; ++test) {
        int left_size = (int)(random_engine() % 8);
        int right_size = left_size + (int)(random_engine() % 3);
        vector<vector<long long>> weight(
            left_size, vector<long long>(right_size));
        MaximumWeightMatching matching(left_size, right_size);
        for (int left = 0; left < left_size; ++left) {
            for (int right = 0; right < right_size; ++right) {
                weight[left][right] = (int)(random_engine() % 31) - 15;
                matching.set_weight(left, right, weight[left][right]);
            }
        }
        vector<int> columns(right_size);
        iota(columns.begin(), columns.end(), 0);
        long long expected = LLONG_MIN;
        do {
            long long current = 0;
            for (int left = 0; left < left_size; ++left) {
                current += weight[left][columns[left]];
            }
            expected = max(expected, current);
        } while (next_permutation(columns.begin(), columns.end()));
        auto [actual_weight, assignment] = matching.solve();
        assert(actual_weight == expected);
        assert((int)assignment.size() == left_size);
        vector<bool> used(right_size);
        long long assignment_weight = 0;
        for (int left = 0; left < left_size; ++left) {
            int right = assignment[left];
            assert(0 <= right && right < right_size && !used[right]);
            used[right] = true;
            assignment_weight += weight[left][right];
        }
        assert(assignment_weight == actual_weight);
    }
}
'@

$dynamicTreeTest = @'
bool naive_connected(const vector<set<int>>& graph, int source, int sink) {
    vector<bool> visited(graph.size());
    queue<int> que;
    visited[source] = true;
    que.push(source);
    while (!que.empty()) {
        int node = que.front();
        que.pop();
        if (node == sink) return true;
        for (int next : graph[node]) {
            if (!visited[next]) {
                visited[next] = true;
                que.push(next);
            }
        }
    }
    return false;
}

optional<int> naive_path_xor(const vector<set<int>>& graph,
                             const vector<int>& value,
                             int source, int sink) {
    vector<int> parent(graph.size(), -1);
    queue<int> que;
    parent[source] = source;
    que.push(source);
    while (!que.empty()) {
        int node = que.front();
        que.pop();
        for (int next : graph[node]) {
            if (parent[next] == -1) {
                parent[next] = node;
                que.push(next);
            }
        }
    }
    if (parent[sink] == -1) return nullopt;
    int result = 0;
    for (int node = sink; ; node = parent[node]) {
        result ^= value[node];
        if (node == source) break;
    }
    return result;
}

int main() {
    constexpr int size = 20;
    LinkCutTree tree(size);
    vector<set<int>> graph(size + 1);
    vector<int> value(size + 1);
    mt19937 random_engine(20240608);
    for (int node = 1; node <= size; ++node) {
        value[node] = (int)random_engine();
        tree.set_value(node, value[node]);
    }
    for (int step = 0; step < 20000; ++step) {
        int lhs = 1 + (int)(random_engine() % size);
        int rhs = 1 + (int)(random_engine() % size);
        if (lhs == rhs) continue;
        int operation = random_engine() % 4;
        if (operation == 0) {
            bool expected = !naive_connected(graph, lhs, rhs);
            assert(tree.link(lhs, rhs) == expected);
            if (expected) {
                graph[lhs].insert(rhs);
                graph[rhs].insert(lhs);
            }
        } else if (operation == 1) {
            bool expected = graph[lhs].contains(rhs);
            assert(tree.cut(lhs, rhs) == expected);
            if (expected) {
                graph[lhs].erase(rhs);
                graph[rhs].erase(lhs);
            }
        } else if (operation == 2) {
            value[lhs] = (int)random_engine();
            tree.set_value(lhs, value[lhs]);
        } else {
            assert(tree.query_path_xor(lhs, rhs) ==
                   naive_path_xor(graph, value, lhs, rhs));
        }
    }
}
'@

$liChaoTest = @'
struct BruteLine {
    long double slope;
    long double intercept;
    int left;
    int right;
    int id;
};

int main() {
    constexpr int left_bound = -30;
    constexpr int right_bound = 30;
    LiChaoSegmentTree tree(left_bound, right_bound);
    vector<BruteLine> lines;
    mt19937 random_engine(1919810);
    for (int step = 0; step < 3000; ++step) {
        if (lines.empty() || random_engine() % 3 != 0) {
            int left = left_bound + (int)(random_engine() %
                                          (right_bound - left_bound + 1));
            int right = left_bound + (int)(random_engine() %
                                           (right_bound - left_bound + 1));
            if (left > right) swap(left, right);
            long double slope = (int)(random_engine() % 101) - 50;
            long double intercept = (int)(random_engine() % 101) - 50;
            int id = tree.add_segment(slope, intercept, left, right);
            lines.push_back({slope, intercept, left, right, id});
        } else {
            int x = left_bound + (int)(random_engine() %
                                       (right_bound - left_bound + 1));
            optional<pair<long double, int>> actual = tree.query(x);
            optional<pair<long double, int>> expected;
            for (const BruteLine& line : lines) {
                if (x < line.left || x > line.right) continue;
                long double current = line.slope * x + line.intercept;
                if (!expected.has_value() ||
                    current > expected->first + 1e-12L ||
                    (fabsl(current - expected->first) <= 1e-12L &&
                     line.id < expected->second)) {
                    expected = pair<long double, int>{current, line.id};
                }
            }
            if (actual.has_value() != expected.has_value()) {
                cerr << "presence mismatch at step " << step << " x=" << x << "\n";
                return 1;
            }
            if (actual.has_value()) {
                if (fabsl(actual->first - expected->first) > 1e-9L ||
                    actual->second != expected->second) {
                    cerr << "value mismatch at step " << step << " x=" << x
                         << " actual=(" << (double)actual->first << ","
                         << actual->second << ") expected=("
                         << (double)expected->first << "," << expected->second
                         << ")\n";
                    return 1;
                }
            }
        }
    }
}
'@

$stringTest = @'
int main() {
    mt19937 random_engine(1234567);
    for (int test = 0; test < 2000; ++test) {
        int size = random_engine() % 30;
        string text(size, 'a');
        for (char& character : text) {
            character = char('a' + random_engine() % 4);
        }

        int expected_rotation = 0;
        for (int begin = 1; begin < size; ++begin) {
            string candidate = text.substr(begin) + text.substr(0, begin);
            string expected = text.substr(expected_rotation) +
                              text.substr(0, expected_rotation);
            if (candidate < expected) expected_rotation = begin;
        }
        assert(minimum_rotation(text) == expected_rotation);

        vector<int> z = z_function(text);
        for (int index = 0; index < size; ++index) {
            int expected = 0;
            while (index + expected < size &&
                   text[expected] == text[index + expected]) {
                ++expected;
            }
            assert(z[index] == expected);
        }

        auto [odd, even] = manacher(text);
        for (int center = 0; center < size; ++center) {
            int odd_expected = 1;
            while (center - odd_expected >= 0 &&
                   center + odd_expected < size &&
                   text[center - odd_expected] ==
                   text[center + odd_expected]) {
                ++odd_expected;
            }
            int even_expected = 0;
            while (center - even_expected - 1 >= 0 &&
                   center + even_expected < size &&
                   text[center - even_expected - 1] ==
                   text[center + even_expected]) {
                ++even_expected;
            }
            assert(odd[center] == odd_expected);
            assert(even[center] == even_expected);
        }

        auto [suffix_array, lcp] = suffix_array_and_lcp(text);
        vector<int> expected_suffixes(size);
        iota(expected_suffixes.begin(), expected_suffixes.end(), 0);
        sort(expected_suffixes.begin(), expected_suffixes.end(),
             [&](int lhs, int rhs) {
                 return text.substr(lhs) < text.substr(rhs);
             });
        assert(suffix_array == expected_suffixes);
        for (int position = 1; position < size; ++position) {
            int expected = 0;
            int lhs = suffix_array[position - 1];
            int rhs = suffix_array[position];
            while (lhs + expected < size && rhs + expected < size &&
                   text[lhs + expected] == text[rhs + expected]) {
                ++expected;
            }
            assert(lcp[position] == expected);
        }

        vector<string> factors = lyndon_factorization(text);
        string rebuilt;
        for (const string& factor : factors) rebuilt += factor;
        assert(rebuilt == text);
        for (int i = 1; i < (int)factors.size(); ++i) {
            assert(factors[i - 1] >= factors[i]);
        }
    }

    assert(kmp_search("aaaa", "aa") == vector<int>({0, 1, 2}));
    assert(kmp_search("abc", "") == vector<int>({0, 1, 2, 3}));
}
'@

$binomialTest = @'
unsigned long long exact_choose(int n, int k) {
    k = min(k, n - k);
    __uint128_t result = 1;
    for (int value = 1; value <= k; ++value) {
        result = result * (n - k + value) / value;
    }
    return (unsigned long long)result;
}

int main() {
    for (int n = 0; n <= 60; ++n) {
        for (int k = 0; k <= n; ++k) {
            unsigned long long exact = exact_choose(n, k);
            for (int modulus = 1; modulus <= 300; ++modulus) {
                assert(composite_binomial::choose_mod_composite(
                           n, k, modulus) == (long long)(exact % modulus));
            }
        }
    }
    for (int prime : {2, 3, 5, 7, 11, 97, 101}) {
        LucasBinomial lucas(prime);
        for (int n = 0; n <= 60; ++n) {
            for (int k = 0; k <= n; ++k) {
                assert(lucas.choose(n, k) ==
                       (int)(exact_choose(n, k) % prime));
            }
        }
    }
}
'@

$automataTest = @'
int main() {
    mt19937 random_engine(7654321);
    for (int test = 0; test < 1000; ++test) {
        int size = random_engine() % 18;
        string text(size, 'a');
        for (char& character : text) {
            character = char('a' + random_engine() % 3);
        }

        SuffixAutomaton sam;
        PalindromicTree pam;
        for (char character : text) {
            sam.extend(character);
            pam.add(character);
        }
        set<string> substrings;
        set<string> palindromes;
        for (int left = 0; left < size; ++left) {
            for (int right = left; right < size; ++right) {
                string part = text.substr(left, right - left + 1);
                substrings.insert(part);
                string reversed = part;
                reverse(reversed.begin(), reversed.end());
                if (part == reversed) palindromes.insert(part);
            }
        }
        assert(sam.distinct_substring_count() ==
               (long long)substrings.size());
        assert(pam.distinct_palindrome_count() ==
               (int)palindromes.size());

        AhoCorasick aho;
        vector<string> patterns;
        vector<int> terminals;
        for (int id = 0; id < 10; ++id) {
            int pattern_size = 1 + (int)(random_engine() % 5);
            string pattern(pattern_size, 'a');
            for (char& character : pattern) {
                character = char('a' + random_engine() % 3);
            }
            patterns.push_back(pattern);
            terminals.push_back(aho.insert(pattern));
        }
        aho.build();
        vector<long long> counts = aho.count_occurrences(text);
        for (int id = 0; id < (int)patterns.size(); ++id) {
            long long expected = 0;
            for (int begin = 0;
                 begin + (int)patterns[id].size() <= size; ++begin) {
                expected +=
                    text.compare(begin, patterns[id].size(), patterns[id]) == 0;
            }
            assert(counts[terminals[id]] == expected);
        }
    }
}
'@

$suffixApplicationsTest = @'
int brute_lcp(const string& text, int lhs, int rhs) {
    int result = 0;
    while (lhs + result < (int)text.size() &&
           rhs + result < (int)text.size() &&
           text[lhs + result] == text[rhs + result]) {
        ++result;
    }
    return result;
}

int sign_of(int value) {
    return (value > 0) - (value < 0);
}

int main() {
    mt19937 random_engine(20260907);
    for (int test = 0; test < 500; ++test) {
        int size = 1 + (int)(random_engine() % 16);
        string text(size, 'a');
        for (char& character : text) {
            character = char('a' + random_engine() % 3);
        }

        SuffixArrayApplications sa_queries(text);
        for (int lhs = 0; lhs < size; ++lhs) {
            for (int rhs = 0; rhs < size; ++rhs) {
                assert(sa_queries.suffix_lcp(lhs, rhs) ==
                       brute_lcp(text, lhs, rhs));
            }
        }

        vector<SuffixArraySubstring> substrings;
        for (int start = 0; start <= size; ++start) {
            for (int length = 0; start + length <= size; ++length) {
                substrings.push_back({start, length});
            }
        }
        for (SuffixArraySubstring lhs : substrings) {
            string lhs_text = text.substr(lhs.start, lhs.length);
            for (SuffixArraySubstring rhs : substrings) {
                string rhs_text = text.substr(rhs.start, rhs.length);
                assert(sa_queries.equal(lhs, rhs) ==
                       (lhs_text == rhs_text));
                assert(sa_queries.compare(lhs, rhs) ==
                       sign_of(lhs_text.compare(rhs_text)));
            }
        }

        vector<long long> start_weight(size);
        for (int start = 0; start < size; ++start) {
            start_weight[start] = (long long)(random_engine() % 11) - 5;
            sa_queries.add_start_weight(start, start_weight[start]);
        }
        for (int start = 0; start < size; ++start) {
            for (int length = 1; start + length <= size; ++length) {
                SuffixArraySubstring pattern{start, length};
                auto [left, right] = sa_queries.matching_interval(pattern);
                int expected_count = 0;
                long long expected_weight = 0;
                for (int candidate = 0;
                     candidate + length <= size; ++candidate) {
                    if (text.compare(candidate, length, text,
                                     start, length) == 0) {
                        ++expected_count;
                        expected_weight += start_weight[candidate];
                        int rank = sa_queries.rank()[candidate];
                        assert(left <= rank && rank <= right);
                    }
                }
                assert(sa_queries.static_occurrence_count(pattern) ==
                       expected_count);
                assert(right - left + 1 == expected_count);
                assert(sa_queries.matching_weight(pattern) ==
                       expected_weight);
            }
        }

        SuffixAutomatonApplications sam_queries(text);
        vector<long long> end_weight(size);
        for (int end = 0; end < size; ++end) {
            end_weight[end] = (long long)(random_engine() % 11) - 5;
            sam_queries.add_end_weight(end, end_weight[end]);
        }

        struct EndSubstring {
            int end;
            int length;
            string value;
        };
        vector<EndSubstring> end_substrings;
        for (int end = 0; end < size; ++end) {
            for (int length = 1; length <= end + 1; ++length) {
                string value = text.substr(end - length + 1, length);
                end_substrings.push_back({end, length, value});

                long long expected_weight = 0;
                for (int candidate_end = length - 1;
                     candidate_end < size; ++candidate_end) {
                    if (text.compare(candidate_end - length + 1,
                                     length, value) == 0) {
                        expected_weight += end_weight[candidate_end];
                    }
                }
                assert(sam_queries.substring_endpos_weight(end, length) ==
                       expected_weight);
            }
        }
        for (const EndSubstring& lhs : end_substrings) {
            for (const EndSubstring& rhs : end_substrings) {
                assert(sam_queries.equal(
                           lhs.end, lhs.length, rhs.end, rhs.length) ==
                       (lhs.value == rhs.value));
                bool same_key =
                    sam_queries.substring_key(lhs.end, lhs.length) ==
                    sam_queries.substring_key(rhs.end, rhs.length);
                assert(same_key == (lhs.value == rhs.value));
            }
        }
    }
}
'@

$generalizedSamTest = @'
int main() {
    mt19937 random_engine(11235813);
    for (int test = 0; test < 5000; ++test) {
        int string_count = random_engine() % 8;
        vector<string> strings(string_count);
        GeneralizedSuffixAutomaton sam;
        map<string, long long> expected_count;
        for (string& text : strings) {
            int length = random_engine() % 9;
            text.resize(length);
            for (char& character : text) {
                character = char('a' + random_engine() % 3);
            }
            sam.insert(text);
            for (int left = 0; left < length; ++left) {
                string pattern;
                for (int right = left; right < length; ++right) {
                    pattern.push_back(text[right]);
                    ++expected_count[pattern];
                }
            }
        }
        sam.build();
        assert(sam.distinct_substring_count() ==
               (long long)expected_count.size());
        vector<long long> count = sam.occurrence_counts(strings);
        for (const auto& [pattern, occurrences] : expected_count) {
            assert(sam.contains(pattern));
            assert(sam.occurrences_of(pattern, count) == occurrences);
        }

        vector<string> candidates{"a", "b", "c"};
        for (int length = 2; length <= 5; ++length) {
            int previous_size = (int)candidates.size();
            int begin = previous_size;
            while (begin > 0 &&
                   (int)candidates[begin - 1].size() == length - 1) {
                --begin;
            }
            for (int index = begin; index < previous_size; ++index) {
                for (char character = 'a'; character <= 'c'; ++character) {
                    candidates.push_back(candidates[index] + character);
                }
            }
        }
        for (const string& pattern : candidates) {
            auto iterator = expected_count.find(pattern);
            long long expected = iterator == expected_count.end()
                ? 0 : iterator->second;
            assert(sam.contains(pattern) == (expected != 0));
            assert(sam.occurrences_of(pattern, count) == expected);
        }

        const auto& states = sam.data();
        assert(states[0].link == -1);
        for (int state = 1; state < (int)states.size(); ++state) {
            assert(0 <= states[state].link &&
                   states[states[state].link].length < states[state].length);
        }
    }
}
'@

$mergeableStructuresTest = @'
int main() {
    mt19937 random_engine(24681357);
    LeftistHeap<int> heap;
    vector<int> roots(20);
    vector<multiset<int>> expected_heaps(20);
    for (int step = 0; step < 10000; ++step) {
        int heap_id = (int)(random_engine() % roots.size());
        int operation = random_engine() % 3;
        if (operation == 0 || expected_heaps[heap_id].empty()) {
            int value = (int)(random_engine() % 1000);
            roots[heap_id] = heap.push(roots[heap_id], value);
            expected_heaps[heap_id].insert(value);
        } else if (operation == 1) {
            assert(heap.top(roots[heap_id]) == *expected_heaps[heap_id].begin());
            roots[heap_id] = heap.pop(roots[heap_id]);
            expected_heaps[heap_id].erase(expected_heaps[heap_id].begin());
        } else {
            int other = (int)(random_engine() % roots.size());
            if (other == heap_id) continue;
            roots[heap_id] = heap.merge(roots[heap_id], roots[other]);
            expected_heaps[heap_id].insert(
                expected_heaps[other].begin(), expected_heaps[other].end());
            roots[other] = 0;
            expected_heaps[other].clear();
        }
    }

    MergeableSegmentTree tree(-20, 20);
    vector<int> tree_roots(20);
    vector<array<long long, 41>> frequency(20);
    for (int step = 0; step < 10000; ++step) {
        int tree_id = (int)(random_engine() % tree_roots.size());
        if (random_engine() % 3 != 0) {
            int position = (int)(random_engine() % 41) - 20;
            int delta = random_engine() % 4;
            tree.add(tree_roots[tree_id], position, delta);
            frequency[tree_id][position + 20] += delta;
        } else {
            int other = (int)(random_engine() % tree_roots.size());
            if (other == tree_id) continue;
            tree_roots[tree_id] =
                tree.merge(tree_roots[tree_id], tree_roots[other]);
            for (int index = 0; index < 41; ++index) {
                frequency[tree_id][index] += frequency[other][index];
                frequency[other][index] = 0;
            }
            tree_roots[other] = 0;
        }
        long long total = accumulate(
            frequency[tree_id].begin(), frequency[tree_id].end(), 0LL);
        assert(tree.total(tree_roots[tree_id]) == total);
        if (total > 0) {
            long long rank = 1 + random_engine() % total;
            int expected = -20;
            long long prefix = 0;
            while (prefix + frequency[tree_id][expected + 20] < rank) {
                prefix += frequency[tree_id][expected + 20];
                ++expected;
            }
            assert(tree.kth(tree_roots[tree_id], rank) == expected);
        }
    }
}
'@

$centroidAndCycleTest = @'
int main() {
    mt19937 random_engine(135792468);
    for (int test = 0; test < 1000; ++test) {
        int size = 1 + (int)(random_engine() % 15);
        CentroidDistanceQueries solver(size);
        vector<vector<pair<int, int>>> tree(size);
        for (int node = 1; node < size; ++node) {
            int parent = random_engine() % node;
            int weight = random_engine() % 8;
            solver.add_edge(parent, node, weight);
            tree[parent].push_back({node, weight});
            tree[node].push_back({parent, weight});
        }
        vector<long long> queries(30);
        for (long long& query : queries) query = random_engine() % 50;
        vector<bool> expected(queries.size());
        for (int source = 0; source < size; ++source) {
            vector<long long> distance(size, -1);
            distance[source] = 0;
            queue<int> que;
            que.push(source);
            while (!que.empty()) {
                int node = que.front();
                que.pop();
                for (auto [next, weight] : tree[node]) {
                    if (distance[next] == -1) {
                        distance[next] = distance[node] + weight;
                        que.push(next);
                    }
                }
            }
            for (int target = source + 1; target < size; ++target) {
                for (int query_id = 0;
                     query_id < (int)queries.size(); ++query_id) {
                    expected[query_id] =
                        expected[query_id] ||
                        distance[target] == queries[query_id];
                }
            }
        }
        assert(solver.solve(queries) == expected);
    }

    for (int test = 0; test < 2000; ++test) {
        int size = 1 + (int)(random_engine() % 10);
        vector<vector<bool>> graph(size, vector<bool>(size));
        vector<pair<int, int>> edges;
        for (int lhs = 0; lhs < size; ++lhs) {
            for (int rhs = lhs + 1; rhs < size; ++rhs) {
                if (random_engine() % 3 == 0) {
                    graph[lhs][rhs] = graph[rhs][lhs] = true;
                    edges.push_back({lhs, rhs});
                }
            }
        }
        long long triangles = 0;
        for (int a = 0; a < size; ++a)
            for (int b = a + 1; b < size; ++b)
                for (int c = b + 1; c < size; ++c)
                    triangles += graph[a][b] && graph[b][c] && graph[c][a];
        assert(count_triangles(size, edges) == triangles);

        long long four_cycles = 0;
        for (int a = 0; a < size; ++a)
            for (int b = a + 1; b < size; ++b)
                for (int c = b + 1; c < size; ++c)
                    for (int d = c + 1; d < size; ++d) {
                        four_cycles += graph[a][b] && graph[b][c] &&
                                       graph[c][d] && graph[d][a];
                        four_cycles += graph[a][b] && graph[b][d] &&
                                       graph[d][c] && graph[c][a];
                        four_cycles += graph[a][c] && graph[c][b] &&
                                       graph[b][d] && graph[d][a];
                    }
        assert(count_four_cycles(size, edges) == four_cycles);
    }
}
'@

$algebraTest = @'
int main() {
    constexpr int prime = 101;
    mt19937 random_engine(20260904);

    for (int size = 0; size <= 6; ++size) {
        for (int test = 0; test < 300; ++test) {
            vector<vector<int>> matrix(size, vector<int>(size));
            for (auto& row : matrix) {
                for (int& value : row) {
                    value = (int)(random_engine() % prime);
                }
            }
            vector<int> permutation(size);
            iota(permutation.begin(), permutation.end(), 0);
            long long expected = 0;
            do {
                long long product = 1;
                int inversions = 0;
                for (int row = 0; row < size; ++row) {
                    product = product * matrix[row][permutation[row]] % prime;
                    for (int previous = 0; previous < row; ++previous) {
                        inversions += permutation[previous] > permutation[row];
                    }
                }
                expected += inversions & 1 ? -product : product;
            } while (next_permutation(permutation.begin(), permutation.end()));
            expected %= prime;
            if (expected < 0) expected += prime;
            assert(determinant_mod_prime(matrix, prime) == expected);
        }
    }

    for (int size = 1; size <= 15; ++size) {
        vector<int> coefficient(size);
        for (int& value : coefficient) value = (int)(random_engine() % prime);
        auto evaluate = [&](int x) {
            long long value = 0;
            for (int degree = size - 1; degree >= 0; --degree) {
                value = (value * x + coefficient[degree]) % prime;
            }
            return (int)value;
        };
        vector<int> x(size), y(size);
        iota(x.begin(), x.end(), 0);
        for (int i = 0; i < size; ++i) y[i] = evaluate(x[i]);
        for (int target = -20; target <= 120; ++target) {
            int normalized = (target % prime + prime) % prime;
            assert(lagrange_interpolation(x, y, target, prime) ==
                   evaluate(normalized));
        }
    }

    for (int bits = 0; bits <= 6; ++bits) {
        int size = 1 << bits;
        for (int test = 0; test < 100; ++test) {
            vector<int> lhs(size), rhs(size);
            for (int& value : lhs) value = (int)(random_engine() % prime);
            for (int& value : rhs) value = (int)(random_engine() % prime);
            for (BitwiseConvolution type : {
                     BitwiseConvolution::bit_or,
                     BitwiseConvolution::bit_and,
                     BitwiseConvolution::bit_xor}) {
                vector<int> expected(size);
                for (int x_value = 0; x_value < size; ++x_value) {
                    for (int y_value = 0; y_value < size; ++y_value) {
                        int result_index = type == BitwiseConvolution::bit_or
                            ? (x_value | y_value)
                            : type == BitwiseConvolution::bit_and
                                ? (x_value & y_value)
                                : (x_value ^ y_value);
                        expected[result_index] = (int)(
                            (expected[result_index] +
                             (long long)lhs[x_value] * rhs[y_value]) % prime);
                    }
                }
                assert(bitwise_convolution(lhs, rhs, type, prime) == expected);
            }

            vector<int> expected_subset(size);
            for (int mask = 0; mask < size; ++mask) {
                for (int subset = mask;; subset = (subset - 1) & mask) {
                    expected_subset[mask] = (int)(
                        (expected_subset[mask] +
                         (long long)lhs[subset] * rhs[mask ^ subset]) % prime);
                    if (subset == 0) break;
                }
            }
            assert(subset_convolution(lhs, rhs, prime) == expected_subset);
        }
    }
}
'@

$cdqTest = @'
int main() {
    using namespace polynomial;
    mt19937 random_engine(19260817);
    for (int test = 0; test < 1000; ++test) {
        int size = 1 + (int)(random_engine() % 100);
        vector<int> base(size), kernel(size);
        for (int& value : base) value = (int)(random_engine() % mod);
        kernel[0] = 0;
        for (int index = 1; index < size; ++index) {
            kernel[index] = (int)(random_engine() % mod);
        }
        vector<int> expected = base;
        for (int i = 0; i < size; ++i) {
            for (int j = 0; j < i; ++j) {
                expected[i] = (int)(
                    (expected[i] + (i64)expected[j] * kernel[i - j]) % mod);
            }
        }
        assert(solve_convolution_recurrence(base, kernel) == expected);
    }
}
'@

$primitiveRootTest = @'
int main() {
    for (long long modulus = 2; modulus <= 300; ++modulus) {
        long long phi = euler_phi(modulus);
        long long expected = -1;
        for (long long candidate = 1; candidate < modulus; ++candidate) {
            if (gcd(candidate, modulus) != 1) continue;
            long long value = 1;
            long long order = 0;
            do {
                value = value * candidate % modulus;
                ++order;
            } while (value != 1 && order <= phi);
            if (order == phi) {
                expected = candidate;
                break;
            }
        }
        assert(minimum_primitive_root(modulus) == expected);
    }
}
'@

$convexHullTrickTest = @'
int main() {
    mt19937 random_engine(998244353);
    for (int test = 0; test < 2000; ++test) {
        MonotoneConvexHull hull;
        vector<pair<long long, long long>> lines;
        long long slope = 100;
        int line_count = 1 + (int)(random_engine() % 30);
        for (int id = 0; id < line_count; ++id) {
            slope -= 1 + (long long)(random_engine() % 5);
            long long intercept = (long long)(random_engine() % 2001) - 1000;
            hull.add_line(slope, intercept);
            lines.push_back({slope, intercept});
        }
        for (long long x = -100; x <= 100; ++x) {
            __int128_t expected = ((__int128_t)1 << 120);
            for (auto [line_slope, intercept] : lines) {
                expected = min(expected,
                               (__int128_t)line_slope * x + intercept);
            }
            assert(hull.query(x) == expected);
        }
    }

    MonotoneConvexHull duplicate_slopes;
    duplicate_slopes.add_line(3, 10);
    duplicate_slopes.add_line(3, 5);
    duplicate_slopes.add_line(1, 0);
    assert(duplicate_slopes.query(-10) == -25);
    assert(duplicate_slopes.query(10) == 10);
}
'@

$moTest = @'
struct PointUpdate {
    int position;
    int old_value;
    int new_value;
};

int main() {
    mt19937 random_engine(31415926);
    for (int test = 0; test < 500; ++test) {
        int size = 1 + (int)(random_engine() % 30);
        vector<int> initial(size);
        for (int& value : initial) value = (int)(random_engine() % 100);

        vector<MoQuery> static_queries;
        vector<long long> static_expected;
        for (int id = 0; id < 100; ++id) {
            int left = random_engine() % size;
            int right = random_engine() % size;
            if (left > right) swap(left, right);
            static_queries.push_back({left, right, id});
            static_expected.push_back(accumulate(initial.begin() + left,
                                                 initial.begin() + right + 1,
                                                 0LL));
        }
        long long current_sum = 0;
        auto static_answer = mo_algorithm<long long>(
            size, static_queries,
            [&](int index) { current_sum += initial[index]; },
            [&](int index) { current_sum -= initial[index]; },
            [&]() { return current_sum; });
        assert(static_answer == static_expected);

        vector<int> building = initial;
        vector<PointUpdate> updates;
        vector<TimedMoQuery> timed_queries;
        vector<long long> timed_expected;
        for (int operation = 0; operation < 100; ++operation) {
            if (random_engine() % 3 == 0) {
                int position = random_engine() % size;
                int new_value = (int)(random_engine() % 100);
                updates.push_back({position, building[position], new_value});
                building[position] = new_value;
            } else {
                int left = random_engine() % size;
                int right = random_engine() % size;
                if (left > right) swap(left, right);
                int id = (int)timed_queries.size();
                timed_queries.push_back(
                    {left, right, (int)updates.size(), id});
                timed_expected.push_back(accumulate(building.begin() + left,
                                                    building.begin() + right + 1,
                                                    0LL));
            }
        }

        vector<int> current = initial;
        current_sum = 0;
        auto add = [&](int index) { current_sum += current[index]; };
        auto remove = [&](int index) { current_sum -= current[index]; };
        auto apply = [&](int update_id, int left, int right) {
            const PointUpdate& update = updates[update_id];
            if (left <= update.position && update.position <= right) {
                remove(update.position);
                current[update.position] = update.new_value;
                add(update.position);
            } else {
                current[update.position] = update.new_value;
            }
        };
        auto rollback = [&](int update_id, int left, int right) {
            const PointUpdate& update = updates[update_id];
            if (left <= update.position && update.position <= right) {
                remove(update.position);
                current[update.position] = update.old_value;
                add(update.position);
            } else {
                current[update.position] = update.old_value;
            }
        };
        auto timed_answer = mo_with_updates<long long>(
            size, (int)updates.size(), timed_queries, add, remove,
            apply, rollback, [&]() { return current_sum; });
        assert(timed_answer == timed_expected);
    }
}
'@

$otherGraphTest = @'
int main() {
    mt19937 random_engine(27182818);
    for (int test = 0; test < 2000; ++test) {
        int size = 2 + (int)(random_engine() % 8);
        StoerWagner solver(size);
        vector<vector<long long>> weight(size, vector<long long>(size));
        for (int lhs = 0; lhs < size; ++lhs) {
            for (int rhs = lhs + 1; rhs < size; ++rhs) {
                long long edge_weight = random_engine() % 10;
                weight[lhs][rhs] = weight[rhs][lhs] = edge_weight;
                solver.add_edge(lhs, rhs, edge_weight);
            }
        }
        long long expected = numeric_limits<long long>::max();
        for (int mask = 1; mask + 1 < (1 << size); ++mask) {
            long long cut = 0;
            for (int lhs = 0; lhs < size; ++lhs) {
                for (int rhs = lhs + 1; rhs < size; ++rhs) {
                    if (((mask >> lhs) & 1) != ((mask >> rhs) & 1)) {
                        cut += weight[lhs][rhs];
                    }
                }
            }
            expected = min(expected, cut);
        }
        auto [answer, side] = solver.minimum_cut();
        assert(answer == expected);
        vector<bool> in_side(size);
        for (int vertex : side) in_side[vertex] = true;
        long long represented_cut = 0;
        for (int lhs = 0; lhs < size; ++lhs) {
            for (int rhs = lhs + 1; rhs < size; ++rhs) {
                if (in_side[lhs] != in_side[rhs]) {
                    represented_cut += weight[lhs][rhs];
                }
            }
        }
        assert(represented_cut == answer);
    }

    for (int test = 0; test < 3000; ++test) {
        int size = random_engine() % 16;
        MaximumIndependentSet solver(size);
        vector<unsigned long long> adjacent(size);
        for (int lhs = 0; lhs < size; ++lhs) {
            for (int rhs = lhs + 1; rhs < size; ++rhs) {
                if (random_engine() % 2 == 0) {
                    solver.add_edge(lhs, rhs);
                    adjacent[lhs] |= 1ULL << rhs;
                    adjacent[rhs] |= 1ULL << lhs;
                }
            }
        }
        int expected = 0;
        for (unsigned long long mask = 0; mask < (1ULL << size); ++mask) {
            bool independent = true;
            for (int vertex = 0; vertex < size; ++vertex) {
                if ((mask >> vertex & 1ULL) && (adjacent[vertex] & mask)) {
                    independent = false;
                    break;
                }
            }
            if (independent) expected = max(expected, popcount(mask));
        }
        auto [answer, selected] = solver.solve();
        assert(answer == expected);
        assert(popcount(selected) == answer);
        for (int vertex = 0; vertex < size; ++vertex) {
            if (selected >> vertex & 1ULL) {
                assert((adjacent[vertex] & selected) == 0);
            }
        }
    }
}
'@

$sparsePolynomialTest = @'
int main() {
    mt19937 random_engine(12344321);
    for (int test = 0; test < 1000; ++test) {
        int modulus = 1 + (int)(random_engine() % 50);
        int term_count = 1 + (int)(random_engine() % 8);
        vector<pair<unsigned long long, long long>> terms;
        for (int id = 0; id < term_count; ++id) {
            terms.push_back({random_engine() % 15,
                             (long long)(random_engine() % 101) - 50});
        }
        unsigned long long maximum_steps = random_engine() % 200;
        SparsePolynomialIteration solver(modulus, terms, maximum_steps);
        auto next_value = [&](int value) {
            long long answer = 0;
            for (auto [degree, coefficient] : terms) {
                long long power = 1 % modulus;
                long long base = value % modulus;
                unsigned long long remaining = degree;
                while (remaining > 0) {
                    if (remaining & 1) power = power * base % modulus;
                    base = base * base % modulus;
                    remaining >>= 1;
                }
                coefficient %= modulus;
                if (coefficient < 0) coefficient += modulus;
                answer = (answer + coefficient * power) % modulus;
            }
            return (int)answer;
        };
        long long start = (long long)(random_engine() % 201) - 100;
        int expected = (int)(start % modulus);
        if (expected < 0) expected += modulus;
        for (unsigned long long step = 0; step < maximum_steps; ++step) {
            expected = next_value(expected);
        }
        assert(solver.iterate(start, maximum_steps) == expected);
    }

    constexpr int prime = 101;
    for (int test = 0; test < 1000; ++test) {
        int degree = random_engine() % 30;
        int exponent = random_engine() % 15;
        vector<pair<int, int>> terms{{0, 1 + (int)(random_engine() % 100)}};
        vector<int> polynomial(degree + 1);
        polynomial[0] = terms[0].second;
        int extra_terms = random_engine() % 10;
        for (int id = 0; id < extra_terms; ++id) {
            int term_degree = degree == 0
                ? 1 : 1 + (int)(random_engine() % degree);
            int coefficient = random_engine() % prime;
            terms.push_back({term_degree, coefficient});
            if (term_degree <= degree) {
                polynomial[term_degree] += coefficient;
                polynomial[term_degree] %= prime;
            }
        }
        vector<int> expected(degree + 1);
        expected[0] = 1;
        for (int repeat = 0; repeat < exponent; ++repeat) {
            vector<int> product(degree + 1);
            for (int lhs = 0; lhs <= degree; ++lhs) {
                for (int rhs = 0; lhs + rhs <= degree; ++rhs) {
                    product[lhs + rhs] = (int)(
                        (product[lhs + rhs] +
                         (long long)expected[lhs] * polynomial[rhs]) % prime);
                }
            }
            expected = move(product);
        }
        assert(sparse_power_series(terms, exponent, degree, prime) == expected);
    }
}
'@

$orderedSetTest = @'
int main() {
    mt19937 random_engine(42424242);
    OrderedMultiSet<int> values;
    multiset<int> expected;
    for (int step = 0; step < 20000; ++step) {
        int value = (int)(random_engine() % 101) - 50;
        if (random_engine() % 3 != 0) {
            values.insert(value);
            expected.insert(value);
        } else {
            auto iterator = expected.find(value);
            bool erased = iterator != expected.end();
            assert(values.erase_one(value) == erased);
            if (erased) expected.erase(iterator);
        }
        assert(values.size() == (int)expected.size());
        assert(values.count_less(value) ==
               distance(expected.begin(), expected.lower_bound(value)));
        assert(values.count_less_equal(value) ==
               distance(expected.begin(), expected.upper_bound(value)));
        if (!expected.empty()) {
            int rank = (int)(random_engine() % expected.size());
            auto iterator = expected.begin();
            advance(iterator, rank);
            assert(values.kth(rank) == optional<int>(*iterator));
        }
        auto lower = expected.lower_bound(value);
        optional<int> predecessor;
        if (lower != expected.begin()) predecessor = *prev(lower);
        assert(values.predecessor(value) == predecessor);
        auto upper = expected.upper_bound(value);
        optional<int> successor = upper == expected.end()
            ? nullopt : optional<int>(*upper);
        assert(values.successor(value) == successor);
    }
}
'@

$virtualTreeTest = @'
int main() {
    mt19937 random_engine(987654321);
    for (int test = 0; test < 2000; ++test) {
        int size = 1 + (int)(random_engine() % 50);
        vector<vector<int>> tree(size);
        vector<int> parent(size, -1), depth(size), dfn(size), finish(size);
        for (int node = 1; node < size; ++node) {
            parent[node] = random_engine() % node;
            tree[parent[node]].push_back(node);
        }
        int timer = 0;
        auto dfs = [&](auto&& self, int node) -> void {
            dfn[node] = timer++;
            for (int child : tree[node]) {
                depth[child] = depth[node] + 1;
                self(self, child);
            }
            finish[node] = timer;
        };
        dfs(dfs, 0);
        auto is_ancestor = [&](int ancestor, int node) {
            return dfn[ancestor] <= dfn[node] && dfn[node] < finish[ancestor];
        };
        auto lca = [&](int lhs, int rhs) {
            while (depth[lhs] > depth[rhs]) lhs = parent[lhs];
            while (depth[rhs] > depth[lhs]) rhs = parent[rhs];
            while (lhs != rhs) {
                lhs = parent[lhs];
                rhs = parent[rhs];
            }
            return lhs;
        };

        int key_count = random_engine() % (size + 1);
        vector<int> keys(key_count);
        for (int& node : keys) node = random_engine() % size;
        VirtualTree result = build_virtual_tree(keys, dfn, lca, is_ancestor);
        sort(keys.begin(), keys.end());
        keys.erase(unique(keys.begin(), keys.end()), keys.end());
        if (keys.empty()) {
            assert(result.root == -1 && result.nodes.empty() &&
                   result.edges.empty());
            continue;
        }
        assert(result.edges.size() + 1 == result.nodes.size());
        assert(result.nodes.size() <= keys.size() * 2 - 1);
        set<int> nodes(result.nodes.begin(), result.nodes.end());
        for (int key : keys) assert(nodes.contains(key));
        for (int lhs : keys) {
            for (int rhs : keys) assert(nodes.contains(lca(lhs, rhs)));
        }
        assert(result.root == result.nodes[0]);
        for (auto [from, to] : result.edges) {
            assert(is_ancestor(from, to) && from != to);
            for (int node : result.nodes) {
                assert(node == from || node == to ||
                       !is_ancestor(from, node) || !is_ancestor(node, to));
            }
        }
    }
}
'@

$transitiveClosureTest = @'
int main() {
    mt19937 random_engine(123456789);
    for (int test = 0; test < 2000; ++test) {
        int size = 1 + (int)(random_engine() % 60);
        vector<bitset<64>> reachable(size);
        vector<vector<int>> graph(size);
        for (int from = 0; from < size; ++from) {
            for (int to = 0; to < size; ++to) {
                if (random_engine() % 7 == 0) {
                    reachable[from].set(to);
                    graph[from].push_back(to);
                }
            }
        }
        transitive_closure(reachable);
        for (int source = 0; source < size; ++source) {
            vector<bool> visited(size);
            queue<int> que;
            visited[source] = true;
            que.push(source);
            while (!que.empty()) {
                int node = que.front();
                que.pop();
                for (int next : graph[node]) {
                    if (!visited[next]) {
                        visited[next] = true;
                        que.push(next);
                    }
                }
            }
            for (int target = 0; target < size; ++target) {
                assert(reachable[source][target] == visited[target]);
            }
        }
    }
}
'@

$combinatoricsTest = @'
int main() {
    constexpr int prime = 101;
    PrimeCombinations combinations(100, prime);
    vector<vector<int>> choose(101, vector<int>(101));
    choose[0][0] = 1;
    for (int n = 1; n <= 100; ++n) {
        choose[n][0] = choose[n][n] = 1;
        for (int k = 1; k < n; ++k) {
            choose[n][k] = (choose[n - 1][k - 1] + choose[n - 1][k]) % prime;
        }
    }
    for (int n = 0; n <= 100; ++n) {
        for (int k = -1; k <= n + 1; ++k) {
            int expected = 0 <= k && k <= n ? choose[n][k] : 0;
            assert(combinations.choose(n, k) == expected);
            long long permutation = 1;
            if (0 <= k && k <= n) {
                for (int step = 0; step < k; ++step) {
                    permutation = permutation * (n - step) % prime;
                }
            } else {
                permutation = 0;
            }
            assert(combinations.permutations(n, k) == permutation);
        }
    }
    vector<int> catalan{1, 1, 2, 5, 14, 42, 132, 429, 1430};
    for (int n = 0; n < (int)catalan.size(); ++n) {
        assert(combinations.catalan(n) == catalan[n] % prime);
    }

    vector<int> result = derangements(8, prime);
    for (int n = 0; n <= 8; ++n) {
        vector<int> permutation(n);
        iota(permutation.begin(), permutation.end(), 0);
        int expected = 0;
        do {
            bool valid = true;
            for (int i = 0; i < n; ++i) valid &= permutation[i] != i;
            expected += valid;
        } while (next_permutation(permutation.begin(), permutation.end()));
        assert(result[n] == expected % prime);
    }
}
'@

$stirlingTest = @'
int main() {
    using namespace combinatorics;
    constexpr int maximum = 100;
    vector<vector<int>> first(maximum + 1, vector<int>(maximum + 1));
    vector<vector<int>> second(maximum + 1, vector<int>(maximum + 1));
    first[0][0] = second[0][0] = 1;
    for (int n = 1; n <= maximum; ++n) {
        for (int k = 1; k <= n; ++k) {
            first[n][k] = (int)(
                (first[n - 1][k - 1] +
                 (long long)(n - 1) * first[n - 1][k]) % mod);
            second[n][k] = (int)(
                (second[n - 1][k - 1] +
                 (long long)k * second[n - 1][k]) % mod);
        }
    }
    for (int n = 0; n <= maximum; ++n) {
        vector<int> expected_first(first[n].begin(), first[n].begin() + n + 1);
        vector<int> expected_second(second[n].begin(), second[n].begin() + n + 1);
        assert(stirling_first_row(n) == expected_first);
        assert(stirling_second_row(n) == expected_second);
    }
    for (int k = 0; k <= 25; ++k) {
        vector<int> first_column = stirling_first_column(maximum, k);
        vector<int> second_column = stirling_second_column(maximum, k);
        for (int n = 0; n <= maximum; ++n) {
            assert(first_column[n] == first[n][k]);
            assert(second_column[n] == second[n][k]);
        }
    }
}
'@

$sieveConvolutionTest = @'
int main() {
    constexpr int maximum = 300;
    constexpr int modulus = 1000000007;
    LinearSieve sieve(maximum);
    for (int value = 1; value <= maximum; ++value) {
        int phi = 0;
        for (int candidate = 1; candidate <= value; ++candidate) {
            phi += gcd(candidate, value) == 1;
        }
        assert(sieve.phi[value] == phi);
        int mobius_sum = 0;
        int phi_sum = 0;
        for (int divisor = 1; divisor <= value; ++divisor) {
            if (value % divisor == 0) {
                mobius_sum += sieve.mobius[divisor];
                phi_sum += sieve.phi[divisor];
            }
        }
        assert(mobius_sum == (value == 1));
        assert(phi_sum == value);
    }

    mt19937 random_engine(16180339);
    for (int test = 0; test < 1000; ++test) {
        int size = 1 + (int)(random_engine() % 60);
        vector<int> lhs(size + 1), rhs(size + 1);
        for (int value = 1; value <= size; ++value) {
            lhs[value] = random_engine() % 1000;
            rhs[value] = random_engine() % 1000;
        }
        vector<int> transformed = lhs;
        divisor_transform(transformed, false, modulus);
        divisor_transform(transformed, true, modulus);
        assert(transformed == lhs);
        transformed = lhs;
        multiple_transform(transformed, false, modulus);
        multiple_transform(transformed, true, modulus);
        assert(transformed == lhs);

        vector<int> expected_gcd(size + 1), expected_lcm(size + 1);
        for (int x = 1; x <= size; ++x) {
            for (int y = 1; y <= size; ++y) {
                long long product = (long long)lhs[x] * rhs[y] % modulus;
                expected_gcd[gcd(x, y)] = (int)(
                    (expected_gcd[gcd(x, y)] + product) % modulus);
                long long lcm = (long long)x / gcd(x, y) * y;
                if (lcm <= size) {
                    expected_lcm[(int)lcm] = (int)(
                        (expected_lcm[(int)lcm] + product) % modulus);
                }
            }
        }
        assert(gcd_convolution(lhs, rhs, modulus) == expected_gcd);
        assert(lcm_convolution(lhs, rhs, modulus) == expected_lcm);
    }
}
'@

$linearRecurrenceTest = @'
int main() {
    constexpr int prime = 101;
    mt19937 random_engine(14142135);
    vector<int> fibonacci_initial{0, 1};
    vector<int> fibonacci_recurrence{1, 1};
    assert(linear_recurrence_nth(fibonacci_initial,
                                 fibonacci_recurrence, 50, prime) == 0);

    for (int test = 0; test < 3000; ++test) {
        int order = 1 + (int)(random_engine() % 10);
        vector<int> recurrence(order), sequence(200);
        for (int& coefficient : recurrence) coefficient = random_engine() % prime;
        for (int i = 0; i < order; ++i) sequence[i] = random_engine() % prime;
        for (int i = order; i < (int)sequence.size(); ++i) {
            long long value = 0;
            for (int step = 1; step <= order; ++step) {
                value += (long long)recurrence[step - 1] * sequence[i - step];
                value %= prime;
            }
            sequence[i] = (int)value;
        }
        for (int index = 0; index < (int)sequence.size(); ++index) {
            assert(linear_recurrence_nth(
                       vector<int>(sequence.begin(), sequence.begin() + order),
                       recurrence, index, prime) == sequence[index]);
        }

        vector<int> prefix(sequence.begin(), sequence.begin() + 4 * order + 10);
        vector<int> inferred = berlekamp_massey(prefix, prime);
        if (inferred.empty()) {
            assert(all_of(sequence.begin(), sequence.end(),
                          [](int value) { return value == 0; }));
        } else {
            vector<int> inferred_initial(
                sequence.begin(), sequence.begin() + inferred.size());
            for (int index = 0; index < (int)sequence.size(); ++index) {
                assert(linear_recurrence_nth(inferred_initial, inferred,
                                             index, prime) == sequence[index]);
            }
        }
    }
}
'@

$cartesianTreeTest = @'
int main() {
    mt19937 random_engine(17320508);
    for (int test = 0; test < 5000; ++test) {
        int size = random_engine() % 100;
        vector<int> values(size);
        for (int& value : values) value = random_engine() % 30;
        CartesianTree tree = build_min_cartesian_tree(values);
        if (size == 0) {
            assert(tree.root == -1);
            continue;
        }
        assert(tree.parent[tree.root] == -1);
        vector<int> inorder;
        auto dfs = [&](auto&& self, int node) -> void {
            if (node == -1) return;
            self(self, tree.left_child[node]);
            inorder.push_back(node);
            self(self, tree.right_child[node]);
            for (int child : {tree.left_child[node], tree.right_child[node]}) {
                if (child != -1) {
                    assert(tree.parent[child] == node);
                    assert(values[node] <= values[child]);
                }
            }
        };
        dfs(dfs, tree.root);
        vector<int> expected_inorder(size);
        iota(expected_inorder.begin(), expected_inorder.end(), 0);
        assert(inorder == expected_inorder);

        auto lca = [&](int lhs, int rhs) {
            vector<bool> ancestor(size);
            for (int node = lhs; node != -1; node = tree.parent[node]) {
                ancestor[node] = true;
            }
            for (int node = rhs; node != -1; node = tree.parent[node]) {
                if (ancestor[node]) return node;
            }
            return -1;
        };
        for (int query = 0; query < 100; ++query) {
            int left = random_engine() % size;
            int right = random_engine() % size;
            if (left > right) swap(left, right);
            int expected = left;
            for (int index = left + 1; index <= right; ++index) {
                if (values[index] < values[expected]) expected = index;
            }
            assert(lca(left, right) == expected);
        }
    }
}
'@

$euclideanFloorSumsTest = @'
struct ExplicitWord {
    string value;

    friend ExplicitWord operator*(const ExplicitWord& left,
                                  const ExplicitWord& right) {
        return {left.value + right.value};
    }
};

int main() {
    FloorMoments example = floor_moments(5, 3, 2, 5);
    assert(example.floor_sum == 9);
    assert(example.square_sum == 19);
    assert(example.index_times_floor == 32);

    constexpr long long modulus = 998244353;
    for (long long n = 0; n <= 35; ++n) {
        for (long long a = 0; a <= 35; ++a) {
            for (long long b = 0; b <= 35; ++b) {
                for (long long c = 1; c <= 20; ++c) {
                    long long floor_sum = 0;
                    long long square_sum = 0;
                    long long index_times_floor = 0;
                    for (long long i = 0; i <= n; ++i) {
                        long long value = (a * i + b) / c;
                        floor_sum = (floor_sum + value) % modulus;
                        square_sum = (square_sum + value * value) % modulus;
                        index_times_floor =
                            (index_times_floor + i * value) % modulus;
                    }
                    FloorMoments answer =
                        floor_moments((u64)n, (u64)a, (u64)b, (u64)c);
                    assert(answer.floor_sum == floor_sum);
                    assert(answer.square_sum == square_sum);
                    assert(answer.index_times_floor == index_times_floor);
                }
            }
        }
    }

    ExplicitWord up{"U"};
    ExplicitWord right{"R"};
    for (u64 n = 0; n <= 12; ++n) {
        for (u64 a = 0; a <= 15; ++a) {
            for (u64 b = 0; b <= 15; ++b) {
                for (u64 c = 1; c <= 10; ++c) {
                    string expected;
                    if (n > 0) {
                        u64 previous_height = b / c;
                        expected.append((size_t)previous_height, 'U');
                        for (u64 index = 1; index <= n; ++index) {
                            u64 height =
                                (u64)(((u128)a * index + b) / c);
                            expected.append(
                                (size_t)(height - previous_height), 'U');
                            expected.push_back('R');
                            previous_height = height;
                        }
                    }
                    ExplicitWord actual =
                        euclidean_word(n, a, b, c, up, right);
                    assert(actual.value == expected);
                }
            }
        }
    }
}
'@

$advancedPolynomialTest = @'
using polyops::poly;

poly naive_poly_multiply(const poly& left, const poly& right,
                         int limit = 1000000) {
    if (left.empty() || right.empty() || limit == 0) return {};
    int size = min(limit, (int)left.size() + (int)right.size() - 1);
    poly result(size);
    for (int i = 0; i < (int)left.size(); ++i) {
        for (int j = 0; j < (int)right.size() && i + j < size; ++j) {
            result[i + j] = (int)(
                (result[i + j] + (long long)left[i] * right[j]) %
                polyops::mod);
        }
    }
    return result;
}

int evaluate_naively(const poly& values, int point) {
    long long result = 0;
    for (int i = (int)values.size() - 1; i >= 0; --i) {
        result = (result * point + values[i]) % polyops::mod;
    }
    return (int)result;
}

poly compose_naively(const poly& outer, const poly& inner) {
    int size = (int)outer.size();
    poly result(size), power{1};
    for (int coefficient : outer) {
        for (int i = 0; i < min(size, (int)power.size()); ++i) {
            result[i] = (int)(
                (result[i] + (long long)coefficient * power[i]) %
                polyops::mod);
        }
        power = naive_poly_multiply(power, inner, size);
        power.resize(size);
    }
    return result;
}

int main() {
    using namespace polyops;
    mt19937 random_engine(27182818);

    for (int test = 0; test < 120; ++test) {
        int size = 1 + (int)(random_engine() % 30);
        poly f(size);
        for (int& value : f) value = (int)(random_engine() % mod);
        if (f[0] == 0) f[0] = 1;

        poly inverse_f = fps_inv(f, size);
        poly identity = mul(f, inverse_f);
        identity.resize(size);
        assert(identity[0] == 1);
        for (int i = 1; i < size; ++i) assert(identity[i] == 0);

        poly logarithm_input(size);
        for (int i = 1; i < size; ++i) {
            logarithm_input[i] = (int)(random_engine() % mod);
        }
        poly restored = fps_ln(fps_exp(logarithm_input, size), size);
        assert(restored == logarithm_input);

        int exponent = (int)(random_engine() % 6);
        poly expected_power(size);
        expected_power[0] = 1;
        for (int repeat = 0; repeat < exponent; ++repeat) {
            expected_power = naive_poly_multiply(expected_power, f, size);
            expected_power.resize(size);
        }
        assert(fps_pow(f, to_string(exponent), size) == expected_power);

        poly root(size);
        for (int& value : root) value = (int)(random_engine() % mod);
        poly square = naive_poly_multiply(root, root, size);
        square.resize(size);
        poly recovered_root = fps_sqrt(square, size);
        assert(!recovered_root.empty());
        poly recovered_square = mul(recovered_root, recovered_root);
        recovered_square.resize(size);
        assert(recovered_square == square);
    }

    for (int test = 0; test < 150; ++test) {
        int divisor_size = 1 + (int)(random_engine() % 12);
        int quotient_size = 1 + (int)(random_engine() % 12);
        poly divisor(divisor_size), quotient(quotient_size);
        for (int& value : divisor) value = (int)(random_engine() % mod);
        for (int& value : quotient) value = (int)(random_engine() % mod);
        if (divisor.back() == 0) divisor.back() = 1;
        if (quotient.back() == 0) quotient.back() = 1;
        poly remainder(max(1, divisor_size - 1));
        for (int& value : remainder) value = (int)(random_engine() % mod);
        if (divisor_size == 1) remainder[0] = 0;

        poly dividend = naive_poly_multiply(divisor, quotient);
        if (dividend.size() < remainder.size()) dividend.resize(remainder.size());
        for (int i = 0; i < (int)remainder.size(); ++i) {
            dividend[i] += remainder[i];
            if (dividend[i] >= mod) dividend[i] -= mod;
        }
        auto [actual_quotient, actual_remainder] = divmod(dividend, divisor);
        normalize(quotient);
        normalize(remainder);
        assert(actual_quotient == quotient);
        assert(actual_remainder == remainder);
    }

    for (int test = 0; test < 100; ++test) {
        int size = 1 + (int)(random_engine() % 20);
        poly f(size);
        vector<int> points(size), expected(size);
        for (int& value : f) value = (int)(random_engine() % mod);
        for (int i = 0; i < size; ++i) {
            points[i] = i + 3;
            expected[i] = evaluate_naively(f, points[i]);
        }
        assert(multipoint_eval(f, points) == expected);
        poly reconstructed = fast_interpolate(points, expected);
        reconstructed.resize(size);
        assert(reconstructed == f);
    }

    int fibonacci_left = 0;
    int fibonacci_right = 1;
    for (int index = 0; index <= 100; ++index) {
        assert(bostan_mori({0, 1}, {1, mod - 1, mod - 1}, index) ==
               fibonacci_left);
        int next = fibonacci_left + fibonacci_right;
        if (next >= mod) next -= mod;
        fibonacci_left = fibonacci_right;
        fibonacci_right = next;
    }

    for (int test = 0; test < 30; ++test) {
        int size = 2 + (int)(random_engine() % 9);
        poly outer(size), inner(size);
        for (int& value : outer) value = (int)(random_engine() % mod);
        for (int& value : inner) value = (int)(random_engine() % mod);
        assert(compose(outer, inner) == compose_naively(outer, inner));

        int shift = (int)(random_engine() % 100);
        poly shifted = taylor_shift(outer, shift);
        for (int point = 0; point < 8; ++point) {
            assert(evaluate_naively(shifted, point) ==
                   evaluate_naively(outer, point + shift));
        }

        int target = (int)(random_engine() % size);
        int count = 1 + (int)(random_engine() % size);
        poly projected = power_projection(inner, target, count);
        poly current{1};
        for (int exponent = 0; exponent < count; ++exponent) {
            int expected = target < (int)current.size() ? current[target] : 0;
            assert(projected[exponent] == expected);
            current = naive_poly_multiply(current, inner, target + 1);
        }

        outer[0] = 0;
        if (outer[1] == 0) outer[1] = 1;
        poly inverse_function = compositional_inverse(outer, size);
        poly composed = compose(outer, inverse_function);
        assert(composed[0] == 0 && composed[1] == 1);
        for (int degree = 2; degree < size; ++degree) {
            assert(composed[degree] == 0);
        }
    }
}
'@

$graphEssentialsTest = @'
void verify_euler_result(const EulerTrail::Result& result,
                         const vector<pair<int, int>>& edges,
                         bool directed) {
    assert(result.vertices.size() == edges.size() + 1);
    assert(result.edge_ids.size() == edges.size());
    vector<bool> used(edges.size());
    for (int index = 0; index < (int)edges.size(); ++index) {
        int id = result.edge_ids[index];
        assert(0 <= id && id < (int)edges.size() && !used[id]);
        used[id] = true;
        auto [from, to] = edges[id];
        bool matches = from == result.vertices[index] &&
                       to == result.vertices[index + 1];
        if (!directed) {
            matches = matches ||
                      (to == result.vertices[index] &&
                       from == result.vertices[index + 1]);
        }
        assert(matches);
    }
}

int main() {
    mt19937 random_engine(57721566);
    constexpr long long infinity = (1LL << 60);
    for (int test = 0; test < 1000; ++test) {
        int n = 2 + (int)(random_engine() % 9);
        vector<KruskalReconstructionTree::Edge> edges;
        vector<vector<long long>> minimax(n, vector<long long>(n, infinity));
        for (int node = 0; node < n; ++node) minimax[node][node] = 0;
        for (int left = 0; left < n; ++left) {
            for (int right = left + 1; right < n; ++right) {
                if (random_engine() % 3 == 0) continue;
                long long weight = 1 + (long long)(random_engine() % 100);
                edges.push_back({left, right, weight});
                minimax[left][right] = min(minimax[left][right], weight);
                minimax[right][left] = minimax[left][right];
            }
        }
        for (int middle = 0; middle < n; ++middle) {
            for (int left = 0; left < n; ++left) {
                for (int right = 0; right < n; ++right) {
                    minimax[left][right] = min(
                        minimax[left][right],
                        max(minimax[left][middle], minimax[middle][right]));
                }
            }
        }
        KruskalReconstructionTree tree(n, edges);
        for (int left = 0; left < n; ++left) {
            for (int right = left + 1; right < n; ++right) {
                bool connected = minimax[left][right] < infinity;
                assert(tree.connected(left, right) == connected);
                if (connected) {
                    assert(tree.minimum_bottleneck(left, right) ==
                           minimax[left][right]);
                }
            }
        }
    }

    for (int test = 0; test < 1000; ++test) {
        int n = 1 + (int)(random_engine() % 100);
        vector<vector<int>> graph(n);
        vector<int> parent(n, -1), depth(n);
        for (int node = 1; node < n; ++node) {
            parent[node] = (int)(random_engine() % node);
            depth[node] = depth[parent[node]] + 1;
            graph[node].push_back(parent[node]);
            graph[parent[node]].push_back(node);
        }
        EulerTourLca lca(graph, {0});
        for (int query = 0; query < 300; ++query) {
            int left = (int)(random_engine() % n);
            int right = (int)(random_engine() % n);
            int lhs = left;
            int rhs = right;
            while (depth[lhs] > depth[rhs]) lhs = parent[lhs];
            while (depth[rhs] > depth[lhs]) rhs = parent[rhs];
            while (lhs != rhs) {
                lhs = parent[lhs];
                rhs = parent[rhs];
            }
            assert(lca.lca(left, right) == lhs);
            assert(lca.distance(left, right) ==
                   depth[left] + depth[right] - 2 * depth[lhs]);
        }
    }

    for (bool directed : {false, true}) {
        for (int test = 0; test < 1000; ++test) {
            int n = 1 + (int)(random_engine() % 15);
            EulerTrail trail(n, directed);
            vector<pair<int, int>> edges;
            int current = (int)(random_engine() % n);
            int length = (int)(random_engine() % 80);
            for (int edge = 0; edge < length; ++edge) {
                int next = (int)(random_engine() % n);
                trail.add_edge(current, next);
                edges.push_back({current, next});
                current = next;
            }
            auto result = trail.find_trail();
            assert(result.has_value());
            verify_euler_result(*result, edges, directed);
        }
    }
    EulerTrail disconnected(4, true);
    disconnected.add_edge(0, 0);
    disconnected.add_edge(1, 1);
    assert(!disconnected.find_trail().has_value());
    EulerTrail disconnected_undirected(4, false);
    disconnected_undirected.add_edge(0, 0);
    disconnected_undirected.add_edge(1, 1);
    assert(!disconnected_undirected.find_trail().has_value());
    EulerTrail invalid_directed_degrees(3, true);
    invalid_directed_degrees.add_edge(0, 1);
    invalid_directed_degrees.add_edge(0, 2);
    assert(!invalid_directed_degrees.find_trail().has_value());
    EulerTrail invalid_undirected_degrees(4, false);
    invalid_undirected_degrees.add_edge(0, 1);
    invalid_undirected_degrees.add_edge(0, 2);
    invalid_undirected_degrees.add_edge(0, 3);
    assert(!invalid_undirected_degrees.find_trail().has_value());
}
'@

$twoSatTest = @'
int main() {
    mt19937 random_engine(27182818);
    struct Clause { int x; bool x_value; int y; bool y_value; };
    for (int test = 0; test < 5000; ++test) {
        int n = 1 + (int)(random_engine() % 8);
        int clause_count = (int)(random_engine() % 31);
        vector<Clause> clauses;
        TwoSat solver(n);
        for (int i = 0; i < clause_count; ++i) {
            Clause clause{
                (int)(random_engine() % n), (bool)(random_engine() & 1),
                (int)(random_engine() % n), (bool)(random_engine() & 1)};
            clauses.push_back(clause);
            solver.add_or(clause.x, clause.x_value,
                          clause.y, clause.y_value);
        }

        int expected_mask = -1;
        for (int mask = 0; mask < (1 << n); ++mask) {
            bool valid = true;
            for (Clause clause : clauses) {
                bool left = ((mask >> clause.x & 1) != 0) == clause.x_value;
                bool right = ((mask >> clause.y & 1) != 0) == clause.y_value;
                if (!left && !right) valid = false;
            }
            if (valid) {
                expected_mask = mask;
                break;
            }
        }

        optional<vector<bool>> answer = solver.solve();
        assert(answer.has_value() == (expected_mask != -1));
        if (answer.has_value()) {
            for (Clause clause : clauses) {
                assert((*answer)[clause.x] == clause.x_value ||
                       (*answer)[clause.y] == clause.y_value);
            }
        }
    }
}
'@

$flowTricksTest = @'
int main() {
    mt19937 random_engine(31415926);

    Dinic self_loop_flow(2);
    self_loop_flow.add_edge(0, 0, 7);
    self_loop_flow.add_edge(0, 1, 3);
    assert(self_loop_flow.max_flow(0, 1) == 3);

    for (int test = 0; test < 3000; ++test) {
        int n = 1 + (int)(random_engine() % 9);
        vector<long long> weight(n);
        for (long long& value : weight) {
            value = (long long)(random_engine() % 21) - 10;
        }
        vector<pair<int, int>> dependencies;
        for (int u = 0; u < n; ++u) {
            for (int v = 0; v < n; ++v) {
                if (random_engine() % 8 == 0) dependencies.push_back({u, v});
            }
        }

        long long expected = numeric_limits<long long>::min();
        for (int mask = 0; mask < (1 << n); ++mask) {
            bool closed = true;
            for (auto [u, v] : dependencies) {
                if ((mask >> u & 1) && !(mask >> v & 1)) closed = false;
            }
            if (!closed) continue;
            long long sum = 0;
            for (int i = 0; i < n; ++i) if (mask >> i & 1) sum += weight[i];
            expected = max(expected, sum);
        }

        ClosureResult result = maximum_weight_closure(weight, dependencies);
        assert(result.value == expected);
        vector<bool> selected(n);
        long long selected_sum = 0;
        for (int v : result.selected) {
            assert(!selected[v]);
            selected[v] = true;
            selected_sum += weight[v];
        }
        for (auto [u, v] : dependencies) {
            assert(!selected[u] || selected[v]);
        }
        assert(selected_sum == result.value);
    }

    for (int test = 0; test < 500; ++test) {
        int n = 1 + (int)(random_engine() % 8);
        vector<pair<int, int>> edges;
        for (int u = 0; u < n; ++u) {
            for (int v = u + 1; v < n; ++v) {
                if (random_engine() % 3 == 0) edges.push_back({u, v});
            }
        }
        long double expected = 0;
        for (int mask = 1; mask < (1 << n); ++mask) {
            int vertex_count = __builtin_popcount((unsigned)mask);
            int edge_count = 0;
            for (auto [u, v] : edges) {
                if ((mask >> u & 1) && (mask >> v & 1)) ++edge_count;
            }
            expected = max(expected,
                           (long double)edge_count / vertex_count);
        }
        long double actual = maximum_density_subgraph(n, edges, 100000);
        assert(fabsl(actual - expected) <= 0.000006L);
    }

    for (int test = 0; test < 2000; ++test) {
        int n = 1 + (int)(random_engine() % 4);
        int edge_count = (int)(random_engine() % 7);
        vector<BoundedEdge> edges(edge_count);
        for (BoundedEdge& edge : edges) {
            edge.from = (int)(random_engine() % n);
            edge.to = (int)(random_engine() % n);
            edge.lower = (long long)(random_engine() % 3);
            edge.upper = edge.lower + (long long)(random_engine() % 3);
        }

        vector<long long> balance(n);
        auto brute = [&](auto&& self, int index) -> bool {
            if (index == edge_count) {
                return all_of(balance.begin(), balance.end(),
                              [](long long value) { return value == 0; });
            }
            const BoundedEdge& edge = edges[index];
            for (long long value = edge.lower; value <= edge.upper; ++value) {
                balance[edge.from] -= value;
                balance[edge.to] += value;
                if (self(self, index + 1)) return true;
                balance[edge.from] += value;
                balance[edge.to] -= value;
            }
            return false;
        };
        bool expected = brute(brute, 0);
        assert(feasible_circulation(n, edges) == expected);
    }

    {
        vector<BoundedEdge> edges{{0, 1, 2, 5}};
        assert(minimum_bounded_flow(2, 0, 1, edges)->value == 2);
        assert(maximum_bounded_flow(2, 0, 1, edges)->value == 5);
    }
    {
        vector<BoundedEdge> edges{{1, 0, 0, 5}};
        assert(minimum_bounded_flow(2, 0, 1, edges)->value == 0);
        assert(maximum_bounded_flow(2, 0, 1, edges)->value == 0);
    }
    {
        vector<BoundedEdge> edges{{1, 0, 1, 5}};
        assert(!minimum_bounded_flow(2, 0, 1, edges).has_value());
        assert(!maximum_bounded_flow(2, 0, 1, edges).has_value());
    }

    for (int test = 0; test < 1500; ++test) {
        int n = 2 + (int)(random_engine() % 3);
        int source = 0, sink = n - 1;
        int edge_count = (int)(random_engine() % 7);
        vector<BoundedEdge> edges(edge_count);
        for (BoundedEdge& edge : edges) {
            edge.from = (int)(random_engine() % n);
            edge.to = (int)(random_engine() % n);
            edge.lower = (long long)(random_engine() % 3);
            edge.upper = edge.lower + (long long)(random_engine() % 3);
        }

        vector<long long> balance(n);
        bool feasible = false;
        long long expected_minimum = numeric_limits<long long>::max();
        long long expected_maximum = numeric_limits<long long>::min();
        auto brute = [&](auto&& self, int index) -> void {
            if (index == edge_count) {
                for (int v = 0; v < n; ++v) {
                    if (v != source && v != sink && balance[v] != 0) return;
                }
                long long value = -balance[source];
                if (value < 0 || balance[sink] != value) return;
                feasible = true;
                expected_minimum = min(expected_minimum, value);
                expected_maximum = max(expected_maximum, value);
                return;
            }
            const BoundedEdge& edge = edges[index];
            for (long long value = edge.lower; value <= edge.upper; ++value) {
                balance[edge.from] -= value;
                balance[edge.to] += value;
                self(self, index + 1);
                balance[edge.from] += value;
                balance[edge.to] -= value;
            }
        };
        brute(brute, 0);

        auto minimum = minimum_bounded_flow(n, source, sink, edges);
        auto maximum = maximum_bounded_flow(n, source, sink, edges);
        assert(minimum.has_value() == feasible);
        assert(maximum.has_value() == feasible);
        if (!feasible) continue;
        assert(minimum->value == expected_minimum);
        assert(maximum->value == expected_maximum);

        auto validate = [&](const BoundedFlowResult& result) {
            vector<long long> net(n);
            assert(result.edge_flow.size() == edges.size());
            for (int i = 0; i < edge_count; ++i) {
                assert(edges[i].lower <= result.edge_flow[i]);
                assert(result.edge_flow[i] <= edges[i].upper);
                net[edges[i].from] -= result.edge_flow[i];
                net[edges[i].to] += result.edge_flow[i];
            }
            for (int v = 0; v < n; ++v) {
                if (v != source && v != sink) assert(net[v] == 0);
            }
            assert(-net[source] == result.value);
            assert(net[sink] == result.value);
        };
        validate(*minimum);
        validate(*maximum);
    }
}
'@

$persistentStructuresTest = @'
int main() {
    mt19937 random_engine(16180339);
    constexpr int coordinate_count = 50;
    PersistentSegmentTree persistent(coordinate_count);
    vector<int> values;
    for (int index = 0; index < 150; ++index) {
        int value = (int)(random_engine() % coordinate_count);
        values.push_back(value);
        persistent.add_version(index, value);
    }
    for (int test = 0; test < 5000; ++test) {
        int left = (int)(random_engine() % values.size());
        int right = left + 1 +
                    (int)(random_engine() % (values.size() - left));
        vector<int> sorted(values.begin() + left, values.begin() + right);
        sort(sorted.begin(), sorted.end());
        int k = 1 + (int)(random_engine() % sorted.size());
        assert(persistent.kth_between(left, right, k) == sorted[k - 1]);
        int query_left = (int)(random_engine() % coordinate_count);
        int query_right = query_left +
            (int)(random_engine() % (coordinate_count - query_left + 1));
        long long expected = count_if(
            values.begin(), values.begin() + right,
            [&](int value) { return query_left <= value && value < query_right; });
        assert(persistent.query_sum(right, query_left, query_right) == expected);
    }

    vector<int> initial(40);
    vector<int> possible;
    for (int value = -30; value <= 30; ++value) possible.push_back(value);
    for (int& value : initial) value = (int)(random_engine() % 61) - 30;
    DynamicChairmanTree dynamic(initial, possible);
    for (int operation = 0; operation < 5000; ++operation) {
        if (random_engine() % 2 == 0) {
            int position = (int)(random_engine() % initial.size());
            int value = (int)(random_engine() % 61) - 30;
            dynamic.assign(position, value);
            initial[position] = value;
        } else {
            int left = (int)(random_engine() % initial.size());
            int right = left + 1 +
                (int)(random_engine() % (initial.size() - left));
            vector<int> sorted(initial.begin() + left, initial.begin() + right);
            sort(sorted.begin(), sorted.end());
            int k = 1 + (int)(random_engine() % sorted.size());
            assert(dynamic.kth(left, right, k) == sorted[k - 1]);
        }
    }

    SegmentTreeOverTime<int> timeline(100);
    vector<long long> expected(100);
    for (int event = 0; event < 300; ++event) {
        int left = (int)(random_engine() % 101);
        int right = left + (int)(random_engine() % (101 - left));
        int value = (int)(random_engine() % 101) - 50;
        timeline.add_interval(left, right, value);
        for (int time = left; time < right; ++time) expected[time] += value;
    }
    long long current = 0;
    timeline.traverse(
        [&](int value) { current += value; },
        [&](int value) { current -= value; },
        [&](int time) { assert(current == expected[time]); });
    assert(current == 0);

    constexpr int node_count = 12;
    constexpr int time_count = 50;
    SegmentTreeOverTime<pair<int, int>> connectivity(time_count);
    struct ActiveEdge { int left, right, from, to; };
    vector<ActiveEdge> active_edges;
    for (int event = 0; event < 120; ++event) {
        int left = (int)(random_engine() % time_count);
        int right = left + 1 +
            (int)(random_engine() % (time_count - left));
        int from = (int)(random_engine() % node_count);
        int to = (int)(random_engine() % node_count);
        connectivity.add_interval(left, right, {from, to});
        active_edges.push_back({left, right, from, to});
    }
    RollbackDsu dsu(node_count);
    connectivity.traverse(
        [&](pair<int, int> edge) { dsu.merge(edge.first, edge.second); },
        [&](pair<int, int>) { dsu.undo(); },
        [&](int time) {
            vector<vector<int>> graph(node_count);
            for (auto [left, right, from, to] : active_edges) {
                if (left <= time && time < right) {
                    graph[from].push_back(to);
                    graph[to].push_back(from);
                }
            }
            for (int source = 0; source < node_count; ++source) {
                vector<bool> visited(node_count);
                queue<int> queue;
                visited[source] = true;
                queue.push(source);
                while (!queue.empty()) {
                    int node = queue.front();
                    queue.pop();
                    for (int next : graph[node]) {
                        if (!visited[next]) {
                            visited[next] = true;
                            queue.push(next);
                        }
                    }
                }
                for (int target = 0; target < node_count; ++target) {
                    assert(dsu.same(source, target) == visited[target]);
                }
            }
        });
    assert(dsu.component_count == node_count && dsu.history.empty());
}
'@

$rollingHashTest = @'
int main() {
    mt19937 random_engine(14159265);
    for (int test = 0; test < 1000; ++test) {
        int size = (int)(random_engine() % 100);
        string text(size, 'a');
        for (char& character : text) {
            character = (char)('a' + random_engine() % 5);
        }
        StringHash hash(text);
        for (int query = 0; query < 300; ++query) {
            int left = (int)(random_engine() % (size + 1));
            int right = left + (int)(random_engine() % (size - left + 1));
            int other = (int)(random_engine() % (size - (right - left) + 1));
            bool equal = text.substr(left, right - left) ==
                         text.substr(other, right - left);
            assert((hash.get(left, right) ==
                    hash.get(other, other + right - left)) == equal);

            array<int, 2> expected{};
            for (int k = 0; k < 2; ++k) {
                for (int i = left; i < right; ++i) {
                    expected[k] = (int)(
                        ((long long)expected[k] * StringHash::base +
                         (unsigned char)text[i] + 1) % StringHash::mod[k]);
                }
            }
            assert(hash.get(left, right) == expected);
        }
    }
}
'@

$linearAlgebraAndCrtTest = @'
int main() {
    mt19937 random_engine(17320508);
    for (int test = 0; test < 500; ++test) {
        int size = 1 + (int)(random_engine() % 8);
        vector<vector<long double>> matrix(size, vector<long double>(size));
        vector<long double> expected(size);
        for (int row = 0; row < size; ++row) {
            expected[row] = (int)(random_engine() % 21) - 10;
            for (int column = 0; column < size; ++column) {
                matrix[row][column] = (int)(random_engine() % 21) - 10;
            }
            matrix[row][row] += 50;
        }
        vector<long double> rhs(size);
        for (int row = 0; row < size; ++row) {
            for (int column = 0; column < size; ++column) {
                rhs[row] += matrix[row][column] * expected[column];
            }
        }
        LinearSystemResult solved = solve_linear_system(matrix, rhs);
        assert(solved.status == LinearSystemStatus::unique);
        for (int index = 0; index < size; ++index) {
            assert(fabsl(solved.solution[index] - expected[index]) < 1e-9L);
        }
        auto inverse = inverse_matrix(matrix);
        assert(inverse.has_value());
        for (int row = 0; row < size; ++row) {
            for (int column = 0; column < size; ++column) {
                long double product = 0;
                for (int middle = 0; middle < size; ++middle) {
                    product += matrix[row][middle] * (*inverse)[middle][column];
                }
                assert(fabsl(product - (row == column)) < 1e-9L);
            }
        }
    }
    auto none = solve_linear_system({{1}, {1}}, {0, 1});
    assert(none.status == LinearSystemStatus::no_solution);
    auto infinite = solve_linear_system({{1, 1}}, {2});
    assert(infinite.status == LinearSystemStatus::infinite);
    assert(matrix_rank({{1, 2}, {2, 4}}) == 1);

    constexpr int prime = 101;
    for (int test = 0; test < 500; ++test) {
        int size = 1 + (int)(random_engine() % 7);
        vector<vector<int>> matrix(size, vector<int>(size));
        vector<int> expected(size), rhs(size);
        for (int row = 0; row < size; ++row) {
            expected[row] = (int)(random_engine() % prime);
            for (int column = 0; column < size; ++column) {
                matrix[row][column] = (int)(random_engine() % prime);
            }
            matrix[row][row] = (matrix[row][row] + 1) % prime;
        }
        for (int row = 0; row < size; ++row) {
            for (int column = 0; column < size; ++column) {
                rhs[row] = (int)((rhs[row] +
                    (long long)matrix[row][column] * expected[column]) % prime);
            }
        }
        auto solved = solve_linear_system_mod(matrix, rhs, prime);
        if (solved.status == LinearSystemStatus::unique) {
            assert(solved.solution == expected);
            auto inverse = inverse_matrix_mod(matrix, prime);
            assert(inverse.has_value());
            for (int row = 0; row < size; ++row) {
                for (int column = 0; column < size; ++column) {
                    int product = 0;
                    for (int middle = 0; middle < size; ++middle) {
                        product = (int)((product +
                            (long long)matrix[row][middle] *
                            (*inverse)[middle][column]) % prime);
                    }
                    assert(product == (row == column));
                }
            }
        }
    }

    for (int test = 0; test < 1000; ++test) {
        int count = (int)(random_engine() % 13);
        vector<unsigned long long> values(count);
        XorLinearBasis basis;
        for (auto& value : values) {
            value = random_engine() % 1024;
            basis.insert(value);
        }
        set<unsigned long long> span;
        for (int mask = 0; mask < (1 << count); ++mask) {
            unsigned long long value = 0;
            for (int index = 0; index < count; ++index) {
                if (mask >> index & 1) value ^= values[index];
            }
            span.insert(value);
        }
        assert(basis.distinct_xor_count() == span.size());
        assert(basis.maximum_xor() == *span.rbegin());
        for (int value = 0; value < 1024; ++value) {
            assert(basis.contains(value) == span.contains(value));
        }
    }

    for (long long modulus = 1; modulus <= 15; ++modulus) {
        for (long long coefficient = -15; coefficient <= 15; ++coefficient) {
            for (long long right_hand_side = -15; right_hand_side <= 15;
                 ++right_hand_side) {
                long long expected = -1;
                for (long long value = 0; value < modulus; ++value) {
                    if (((__int128_t)coefficient * value - right_hand_side) %
                            modulus == 0) {
                        expected = value;
                        break;
                    }
                }
                CRTResult result = solve_congruences(
                    {{coefficient, right_hand_side, modulus}}, 100);
                assert((result.status == CRTStatus::NoSolution) ==
                       (expected == -1));
                if (expected != -1) {
                    assert(result.status == CRTStatus::Success);
                    assert(result.r == expected);
                    assert(0 <= result.r && result.r < result.mod);
                }
            }
        }
    }

    for (int test = 0; test < 30000; ++test) {
        Congruence first{
            (long long)(random_engine() % 41) - 20,
            (long long)(random_engine() % 41) - 20,
            1 + (long long)(random_engine() % 20)};
        Congruence second{
            (long long)(random_engine() % 41) - 20,
            (long long)(random_engine() % 41) - 20,
            1 + (long long)(random_engine() % 20)};
        long long period = std::lcm(first.m, second.m);
        long long expected = -1;
        for (long long value = 0; value < period; ++value) {
            bool satisfies_first =
                ((__int128_t)first.a * value - first.b) % first.m == 0;
            bool satisfies_second =
                ((__int128_t)second.a * value - second.b) % second.m == 0;
            if (satisfies_first && satisfies_second) {
                expected = value;
                break;
            }
        }
        long long limit = (long long)(random_engine() % 50);
        CRTResult result = solve_congruences({first, second}, limit);
        if (expected == -1) {
            assert(result.status == CRTStatus::NoSolution);
        } else if (expected > limit) {
            assert(result.status == CRTStatus::TooLarge);
            assert(result.r == expected);
        } else {
            assert(result.status == CRTStatus::Success);
            assert(result.r == expected);
        }
    }

    CRTResult reduced = solve_congruences({{2, 4, 6}}, 2);
    assert(reduced.status == CRTStatus::Success &&
           reduced.r == 2 && reduced.mod == 3);
    CRTResult negative = solve_congruences({{-3, -6, 9}}, 2);
    assert(negative.status == CRTStatus::Success &&
           negative.r == 2 && negative.mod == 3);
    assert(solve_congruences({{0, 1, 5}}, 100).status ==
           CRTStatus::NoSolution);
    CRTResult no_restriction = solve_congruences({{0, 0, 5}}, 0);
    assert(no_restriction.status == CRTStatus::Success &&
           no_restriction.r == 0 && no_restriction.mod == 1);

    CRTResult contained = solve_congruences(
        {{1, 6, 8}, {1, 2, 4}, {1, 6, 8}}, 6);
    assert(contained.status == CRTStatus::Success &&
           contained.r == 6 && contained.mod == 8);
    CRTResult late_contradiction = solve_congruences(
        {{1, 100, 101}, {1, 0, 101}}, 50);
    assert(late_contradiction.status == CRTStatus::NoSolution);

    CRTResult large_modulus_small_answer = solve_congruences(
        {{1, 1, 4000000000000000000LL}}, 1);
    assert(large_modulus_small_answer.status == CRTStatus::Success &&
           large_modulus_small_answer.r == 1);
    CRTResult answer_too_large = solve_congruences({{1, 100, 101}}, 50);
    assert(answer_too_large.status == CRTStatus::TooLarge &&
           answer_too_large.r == 100);
    CRTResult overflow = solve_congruences(
        {{1, 0, 4000000007LL}, {1, 0, 4000000009LL}}, 0);
    assert(overflow.status == CRTStatus::TooLarge);

    CRTResult empty = solve_congruences({}, 0);
    assert(empty.status == CRTStatus::Success &&
           empty.r == 0 && empty.mod == 1);
}
'@

$treeDecompositionsTest = @'
int main() {
    mt19937 random_engine(22360679);
    for (int test = 0; test < 500; ++test) {
        int n = 1 + (int)(random_engine() % 80);
        vector<vector<int>> tree(n);
        vector<int> parent(n, -1), depth(n);
        for (int node = 1; node < n; ++node) {
            parent[node] = (int)(random_engine() % node);
            depth[node] = depth[parent[node]] + 1;
            tree[node].push_back(parent[node]);
            tree[parent[node]].push_back(node);
        }

        vector<vector<int>> distance(n, vector<int>(n, n + 1));
        for (int source = 0; source < n; ++source) {
            queue<int> queue;
            queue.push(source);
            distance[source][source] = 0;
            while (!queue.empty()) {
                int node = queue.front();
                queue.pop();
                for (int next : tree[node]) {
                    if (distance[source][next] > distance[source][node] + 1) {
                        distance[source][next] = distance[source][node] + 1;
                        queue.push(next);
                    }
                }
            }
        }
        CentroidNearestMarked centroid(tree);
        vector<bool> active(n);
        for (int operation = 0; operation < 500; ++operation) {
            int node = (int)(random_engine() % n);
            if (random_engine() % 2 == 0) {
                centroid.toggle(node);
                active[node] = !active[node];
            } else {
                int expected = n + 1;
                for (int other = 0; other < n; ++other) {
                    if (active[other]) expected = min(expected, distance[node][other]);
                }
                if (expected == n + 1) expected = -1;
                assert(centroid.nearest_distance(node) == expected);
            }
        }

        LongChainAncestors ancestors(tree, 0);
        for (int node = 0; node < n; ++node) {
            for (int jump = 0; jump <= depth[node] + 1; ++jump) {
                int expected = node;
                for (int step = 0; step < jump && expected != -1; ++step) {
                    expected = parent[expected];
                }
                assert(ancestors.kth_ancestor(node, jump) == expected);
            }
        }

        HeavyLightDecomposition hld(tree);
        for (int query = 0; query < 100; ++query) {
            int u = (int)(random_engine() % n);
            int v = (int)(random_engine() % n);
            int left = u, right = v;
            while (depth[left] > depth[right]) left = parent[left];
            while (depth[right] > depth[left]) right = parent[right];
            while (left != right) {
                left = parent[left];
                right = parent[right];
            }
            int ancestor = left;
            assert(hld.lca(u, v) == ancestor);

            vector<bool> covered(n), expected_path(n);
            hld.path_vertices(u, v, [&](int begin, int end) {
                for (int position = begin; position < end; ++position) {
                    assert(!covered[position]);
                    covered[position] = true;
                }
            });
            for (int node = u; node != ancestor; node = parent[node]) {
                expected_path[node] = true;
            }
            for (int node = v; node != ancestor; node = parent[node]) {
                expected_path[node] = true;
            }
            expected_path[ancestor] = true;
            for (int node = 0; node < n; ++node) {
                assert(covered[hld.position[node]] == expected_path[node]);
            }

            fill(covered.begin(), covered.end(), false);
            hld.path_edges(u, v, [&](int begin, int end) {
                for (int position = begin; position < end; ++position) {
                    assert(!covered[position]);
                    covered[position] = true;
                }
            });
            expected_path[ancestor] = false;
            for (int node = 0; node < n; ++node) {
                assert(covered[hld.position[node]] == expected_path[node]);
            }
        }
        for (int node = 0; node < n; ++node) {
            auto [begin, end] = hld.subtree(node);
            for (int other = 0; other < n; ++other) {
                int current = other;
                while (current != -1 && current != node) current = parent[current];
                bool descendant = current == node;
                assert((begin <= hld.position[other] &&
                        hld.position[other] < end) == descendant);
            }
        }

        vector<int> color(n);
        for (int& value : color) value = (int)(random_engine() % 12);
        vector<int> frequency(12), answer(n);
        int distinct = 0;
        dsu_on_tree(
            tree, 0,
            [&](int node) {
                if (frequency[color[node]]++ == 0) ++distinct;
            },
            [&](int node) {
                if (--frequency[color[node]] == 0) --distinct;
            },
            [&](int node) { answer[node] = distinct; });
        for (int node = 0; node < n; ++node) {
            set<int> colors;
            vector<int> stack{node};
            while (!stack.empty()) {
                int current = stack.back();
                stack.pop_back();
                colors.insert(color[current]);
                for (int next : tree[current]) {
                    if (parent[next] == current) stack.push_back(next);
                }
            }
            assert(answer[node] == (int)colors.size());
        }
    }
}
'@

$advancedSievesTest = @'
int main() {
    constexpr int maximum = 100000;
    vector<int> phi(maximum + 1), mobius(maximum + 1), primes;
    vector<int> least_prime(maximum + 1);
    phi[1] = 1;
    mobius[1] = 1;
    for (int value = 2; value <= maximum; ++value) {
        if (least_prime[value] == 0) {
            least_prime[value] = value;
            primes.push_back(value);
            phi[value] = value - 1;
            mobius[value] = -1;
        }
        for (int prime : primes) {
            if (prime > maximum / value) break;
            least_prime[value * prime] = prime;
            if (value % prime == 0) {
                phi[value * prime] = phi[value] * prime;
                mobius[value * prime] = 0;
                break;
            }
            phi[value * prime] = phi[value] * (prime - 1);
            mobius[value * prime] = -mobius[value];
        }
    }
    vector<__int128_t> prefix_phi(maximum + 1);
    vector<long long> prefix_mobius(maximum + 1);
    vector<long long> prefix_prime_count(maximum + 1);
    vector<__int128_t> prefix_prime_sum(maximum + 1);
    for (int value = 1; value <= maximum; ++value) {
        prefix_phi[value] = prefix_phi[value - 1] + phi[value];
        prefix_mobius[value] = prefix_mobius[value - 1] + mobius[value];
        prefix_prime_count[value] = prefix_prime_count[value - 1];
        prefix_prime_sum[value] = prefix_prime_sum[value - 1];
        if (least_prime[value] == value) {
            ++prefix_prime_count[value];
            prefix_prime_sum[value] += value;
        }
    }

    DujiaoSieve dujiao(30);
    for (int value = 1; value <= 5000; ++value) {
        assert(dujiao.sum_phi(value) == prefix_phi[value]);
        assert(dujiao.sum_mobius(value) == prefix_mobius[value]);
    }
    for (int value = 1; value <= 1000; ++value) {
        Min25PhiSummatory min25(value);
        assert(min25.sum_phi() == prefix_phi[value]);
        LucyPrimeSums lucy(value);
        assert(lucy.prime_count() == prefix_prime_count[value]);
        assert(lucy.prime_sum() == prefix_prime_sum[value]);
    }
    mt19937 random_engine(14142135);
    for (int test = 0; test < 300; ++test) {
        int value = 1001 + (int)(random_engine() % 4000);
        Min25PhiSummatory min25(value);
        assert(min25.sum_phi() == prefix_phi[value]);
        LucyPrimeSums lucy(value);
        assert(lucy.prime_count() == prefix_prime_count[value]);
        assert(lucy.prime_sum() == prefix_prime_sum[value]);
    }
    for (int value : {9999, 12345, 99991, maximum}) {
        assert(dujiao.sum_phi(value) == prefix_phi[value]);
        assert(dujiao.sum_mobius(value) == prefix_mobius[value]);
        Min25PhiSummatory min25(value);
        assert(min25.sum_phi() == prefix_phi[value]);
        LucyPrimeSums lucy(value);
        assert(lucy.prime_count() == prefix_prime_count[value]);
        assert(lucy.prime_sum() == prefix_prime_sum[value]);
    }
}
'@

$minkowskiTest = @'
int main() {
    using namespace geometry;
    mt19937 random_engine(24494897);
    for (int test = 0; test < 5000; ++test) {
        vector<IPoint> left_points(1 + (int)(random_engine() % 15));
        vector<IPoint> right_points(1 + (int)(random_engine() % 15));
        for (IPoint& point : left_points) {
            point.x = (int)(random_engine() % 31) - 15;
            point.y = (int)(random_engine() % 31) - 15;
        }
        for (IPoint& point : right_points) {
            point.x = (int)(random_engine() % 31) - 15;
            point.y = (int)(random_engine() % 31) - 15;
        }
        vector<IPoint> left = convex_hull(left_points);
        vector<IPoint> right = convex_hull(right_points);
        vector<IPoint> all_sums;
        for (const IPoint& lhs : left) {
            for (const IPoint& rhs : right) all_sums.push_back(lhs + rhs);
        }
        vector<IPoint> expected = convex_hull(all_sums);
        vector<IPoint> actual = minkowski_sum(left, right);
        sort(expected.begin(), expected.end());
        sort(actual.begin(), actual.end());
        assert(actual == expected);
    }
}
'@

$potentialDsuTest = @'
int main() {
    PotentialDsu disconnected(3);
    assert(!disconnected.difference(0, 1).has_value());
    assert(disconnected.add_constraint(0, 1, -7));
    assert(disconnected.difference(0, 1) == -7);
    assert(disconnected.difference(1, 0) == 7);
    assert(!disconnected.add_constraint(0, 1, -6));

    mt19937 random_engine(27182818);
    for (int test = 0; test < 5000; ++test) {
        int n = 1 + (int)(random_engine() % 80);
        vector<long long> potential(n);
        for (long long& value : potential) {
            value = (long long)(random_engine() % 2000001) - 1000000;
        }
        vector<pair<int, int>> tree_edges;
        for (int node = 1; node < n; ++node) {
            tree_edges.push_back({(int)(random_engine() % node), node});
        }
        shuffle(tree_edges.begin(), tree_edges.end(), random_engine);

        PotentialDsu dsu(n);
        for (auto [x, y] : tree_edges) {
            if (random_engine() & 1U) swap(x, y);
            assert(dsu.add_constraint(x, y, potential[y] - potential[x]));
        }
        for (int query = 0; query < 100; ++query) {
            int x = (int)(random_engine() % n);
            int y = (int)(random_engine() % n);
            assert(dsu.difference(x, y) == potential[y] - potential[x]);
            assert(dsu.add_constraint(x, y, potential[y] - potential[x]));
            assert(!dsu.add_constraint(x, y,
                                       potential[y] - potential[x] + 1));
        }
    }
}
'@

$gf2GaussianTest = @'
int main() {
    mt19937 random_engine(57721566);
    for (int test = 0; test < 5000; ++test) {
        int variable_count = (int)(random_engine() % 11);
        int equation_count = (int)(random_engine() % 14);
        vector<bitset<11>> matrix(equation_count);
        for (auto& row : matrix) {
            for (int column = 0; column < variable_count; ++column) {
                row[column] = random_engine() & 1U;
            }
            row[variable_count] = random_engine() & 1U;
        }

        int solution_count = 0;
        for (int mask = 0; mask < (1 << variable_count); ++mask) {
            bool valid = true;
            for (const auto& row : matrix) {
                bool lhs = false;
                for (int column = 0; column < variable_count; ++column) {
                    lhs ^= row[column] && (mask >> column & 1);
                }
                if (lhs != row[variable_count]) valid = false;
            }
            if (valid) {
                ++solution_count;
            }
        }

        XorGaussResult result = xor_gaussian<10>(matrix, variable_count);
        assert(result.consistent == (solution_count > 0));
        if (!result.consistent) continue;
        assert(solution_count == (1 << (variable_count - result.rank)));
        for (const auto& row : matrix) {
            bool lhs = false;
            for (int column = 0; column < variable_count; ++column) {
                lhs ^= row[column] && result.solution[column];
            }
            assert(lhs == row[variable_count]);
        }
    }
}
'@

$partitionNumbersTest = @'
int main() {
    for (int modulus : {1, 2, 6, 1000, 1000000007, 2147483647}) {
        constexpr int maximum = 300;
        vector<int> expected(maximum + 1);
        expected[0] = 1 % modulus;
        for (int part = 1; part <= maximum; ++part) {
            for (int sum = part; sum <= maximum; ++sum) {
                expected[sum] = (int)(
                    ((long long)expected[sum] + expected[sum - part]) % modulus);
            }
        }
        assert(partition_numbers(maximum, modulus) == expected);
    }

    vector<int> known{1, 1, 2, 3, 5, 7, 11, 15, 22, 30, 42};
    vector<int> actual = partition_numbers(10, 1000000007);
    assert(actual == known);
}
'@

Invoke-CppTest "geometry" @(
    "geometry/01-geometry.md",
    "geometry/02-convex-hull.md",
    "geometry/03-floating-geometry.md",
    "geometry/04-half-plane-intersection.md"
) $geometryTest

Invoke-CppTest "polynomial" @(
    "math/16-polynomial.md",
    "math/14-*.md"
) $polynomialTest

Invoke-CppTest "number-theory" @(
    "math/02-miller rabin.md",
    "math/06-Rho.md"
) $numberTheoryTest

Invoke-CppTest "discrete-log" @("math/07-Bsgs.md") $discreteLogTest
Invoke-CppTest "tarjan" @("graph/02-tarjan.md") $tarjanTest
Invoke-CppTest "max-flow" @("graph/03-maxflow.md") $flowTest
Invoke-CppTest "min-cost-flow" @("graph/04-mincostmaxflow.md") $minCostFlowTest
Invoke-CppTest "matching" @(
    "graph/02-tarjan.md",
    "graph/06-match.md"
) $matchingTest
Invoke-CppTest "link-cut-tree" @("data_structure/04-*.md") $dynamicTreeTest
Invoke-CppTest "li-chao-tree" @("data_structure/07-*.md") $liChaoTest
Invoke-CppTest "string-basics" @(
    "string/04-min.md",
    "string/05-manacher.md",
    "string/06-Z Algorithm.md",
    "string/07-Kmp.md",
    "string/08-Sa.md",
    "string/09-Lyndon.md"
) $stringTest
Invoke-CppTest "binomial" @(
    "math/09-*.md",
    "math/15-Lucas.md"
) $binomialTest
Invoke-CppTest "string-automata" @(
    "string/01-Sam.md",
    "string/02-ACam.md",
    "string/03-Pam.md"
) $automataTest
Invoke-CppTest "suffix-applications" @(
    "string/08-Sa.md",
    "string/01-Sam.md",
    "adder/00-range-query.md",
    "adder/01-sa-applications.md",
    "adder/02-sam-applications.md"
) $suffixApplicationsTest
Invoke-CppTest "generalized-sam" @("string/11-generalized-sam.md") $generalizedSamTest
Invoke-CppTest "mergeable-structures" @(
    "data_structure/01-*.md",
    "data_structure/06-*.md"
) $mergeableStructuresTest
Invoke-CppTest "centroid-and-cycles" @(
    "data_structure/05-*.md",
    "graph/07-circlecounter.md"
) $centroidAndCycleTest
Invoke-CppTest "algebra" @(
    "math/03-det.md",
    "math/08-*.md",
    "math/10-*.md",
    "math/11-*.md"
) $algebraTest
Invoke-CppTest "cdq-convolution" @(
    "math/16-polynomial.md",
    "math/04-cdqfft.md"
) $cdqTest
Invoke-CppTest "primitive-root" @("math/05-*.md") $primitiveRootTest
Invoke-CppTest "convex-hull-trick" @("math/12-*.md") $convexHullTrickTest
Invoke-CppTest "mo-algorithm" @("data_structure/08-*.md") $moTest
Invoke-CppTest "other-graph" @("other/01-basic.md", "other/03-other.md") $otherGraphTest
Invoke-CppTest "sparse-polynomial" @("math/13-*.md") $sparsePolynomialTest
Invoke-CppTest "ordered-multiset" @("data_structure/02-pbds.md") $orderedSetTest
Invoke-CppTest "virtual-tree" @("data_structure/03-*.md") $virtualTreeTest
Invoke-CppTest "transitive-closure" @("graph/01-tricky.md") $transitiveClosureTest
Invoke-CppTest "combinatorics" @("math/17-combinatorics.md") $combinatoricsTest
Invoke-CppTest "stirling" @(
    "math/16-polynomial.md",
    "math/18-stirling.md"
) $stirlingTest
Invoke-CppTest "sieve-convolutions" @("math/19-sieve-convolutions.md") $sieveConvolutionTest
Invoke-CppTest "linear-recurrence" @("math/20-linear-recurrence.md") $linearRecurrenceTest
Invoke-CppTest "cartesian-tree" @("data_structure/09-cartesian-tree.md") $cartesianTreeTest
Invoke-CppTest "euclidean-floor-sums" @("math/22-euclidean-floor-sums.md") $euclideanFloorSumsTest
Invoke-CppTest "advanced-polynomial" @("math/23-polynomial-advanced.md") $advancedPolynomialTest
Invoke-CppTest "graph-essentials" @(
    "graph/09-kruskal-reconstruction-tree.md",
    "graph/10-euler-tour-lca.md",
    "graph/11-euler-trail.md"
) $graphEssentialsTest
Invoke-CppTest "two-sat" @("graph/12-two-sat.md") $twoSatTest
Invoke-CppTest "flow-models" @(
    "graph/03-maxflow.md",
    "graph/05-flowtrick.md"
) $flowTricksTest
Invoke-CppTest "persistent-structures" @(
    "data_structure/10-persistent-segment-tree.md",
    "data_structure/11-segment-tree-over-time.md"
) $persistentStructuresTest
Invoke-CppTest "rolling-hash" @("string/12-rolling-hash.md") $rollingHashTest
Invoke-CppTest "linear-algebra-and-crt" @(
    "math/25-gaussian-elimination.md",
    "math/26-xor-linear-basis.md",
    "math/27-crt.md"
) $linearAlgebraAndCrtTest
Invoke-CppTest "tree-decompositions" @(
    "data_structure/12-centroid-tree.md",
    "data_structure/13-dsu-on-tree.md",
    "data_structure/14-long-chain-decomposition.md",
    "data_structure/15-heavy-light-decomposition.md"
) $treeDecompositionsTest
Invoke-CppTest "potential-dsu" @(
    "data_structure/16-potential-dsu.md"
) $potentialDsuTest
Invoke-CppTest "gf2-gaussian" @("math/31-gf2-gaussian.md") $gf2GaussianTest
Invoke-CppTest "partition-numbers" @(
    "math/24-counting-formulas.md"
) $partitionNumbersTest
Invoke-CppTest "advanced-sieves" @(
    "math/28-dujiao-sieve.md",
    "math/29-min25-sieve.md",
    "math/30-lucy-sieve.md"
) $advancedSievesTest
Invoke-CppTest "minkowski-sum" @(
    "geometry/01-geometry.md",
    "geometry/02-convex-hull.md",
    "geometry/05-minkowski-sum.md"
) $minkowskiTest

Write-Host "All core template tests passed."
