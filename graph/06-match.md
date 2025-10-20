# Match

K Algorithm

```cpp
struct Graph {
    struct Edge {
        int to;
        int nxt;
    };
    vector<int> head;
    vector<Edge> edges;
    Graph(int n = 0) { init(n); }
    void init(int n) {
        head.assign(n + 1, -1);
        edges.clear();
    }
    void insert_edge(int u, int v) {
        edges.push_back({v, head[u]});
        head[u] = (int)edges.size() - 1;
    }
};
Graph G;
int n, m, ans;
int Pre[MaxN], Match[MaxN], Mark[MaxN];
void augment(int from) {
    int tmp;
    while (from != -1) {
        tmp = Match[Pre[from]];
        Match[Pre[from]] = from;
        Match[from] = Pre[from];
        from = tmp;
    }
}
bool bfs(int start) {
    queue<int> Q;
    Q.push(start);
    while (!Q.empty()) {
        int from = Q.front(); Q.pop();
        for (int k = G.head[from]; k != -1; k = G.edges[k].nxt) {
            int to = G.edges[k].to;
            if (Mark[to] == start) continue;
            Mark[to] = start;
            Pre[to] = from;
            if (Match[to] == -1) {
                augment(to);
                return true;
            } else {
                Q.push(Match[to]);
            }
        }
    }
    return false;
}
void reinit() {
    fill(Match, Match + MaxN, -1);
    fill(Mark, Mark + MaxN, -1);
}
void work() {
    ans = 0;
    for (int i = 1; i <= n; ++i) {
        if (Match[i] == -1)
            ans += bfs(i);
    }
}
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    int k;
    cin >> n >> m >> k;
    G.init(n + m);
    reinit();
    for (int i = 0; i < k; ++i) {
        int x, y;
        cin >> x >> y;
        G.insert_edge(x, y + n); // 左部点编号 1~n, 右部点编号 n+1~n+m
    }
    work();
    cout << ans << "\n";
    for (int i = 1; i <= n; ++i) {
        if (Match[i] == -1 || Match[i] > n + m)
            cout << 0 << ' ';
        else
            cout << Match[i] - n << ' ';
    }
    cout << '\n';
    return 0;
}
```

KM Algorithm

```cpp
using ll = long long;
const ll Inf = 1e18;
const int MaxV1 = 510 * 2;
const int MaxV2 = 510 * 2;
ll Weight[MaxV1][MaxV2],Expect1[MaxV1],Expect2[MaxV2],Slack[MaxV2];
int Match1[MaxV1],Match2[MaxV2],Pre[MaxV2];
int Visit1[MaxV1],Visit2[MaxV2];
int sizev1, sizev2;
void Augment(int from) {
    int tmp;
    while (from != -1) {
        tmp = Match1[Pre[from]];
        Match1[Pre[from]] = from;
        Match2[from] = Pre[from];
        from = tmp;
    }
}
ll Calc(int from, int to) {
    return Expect1[from] + Expect2[to] - Weight[from][to];
}
bool KuhnMunkres(int start) {
    fill(Slack, Slack + MaxV2, Inf);
    queue<int> Q;
    Q.push(start);
    while (true) {
        while (!Q.empty()) {
            int from = Q.front(); Q.pop();
            Visit1[from] = start;
            for (int to = 1; to <= sizev2; ++to) {
                if (Visit2[to] == start) continue;
                ll gap = Calc(from, to);
                if (gap < Slack[to]) {
                    Slack[to] = gap;
                    Pre[to] = from;
                    if (Slack[to] == 0) {
                        Visit2[to] = start;
                        if (Match2[to] == -1) {
                            Augment(to);
                            return true;
                        } else {
                            Q.push(Match2[to]);
                        }
                    }
                }
            }
        }
        ll delta = Inf;
        for (int i = 1; i <= sizev2; ++i)
            if (Visit2[i] != start)
                delta = min(delta, Slack[i]);
        for (int i = 1; i <= sizev1; ++i)
            if (Visit1[i] == start)
                Expect1[i] -= delta;
        for (int i = 1; i <= sizev2; ++i) {
            if (Visit2[i] == start)
                Expect2[i] += delta;
            else
                Slack[i] -= delta;
        }
        for (int i = 1; i <= sizev2; ++i)
            if (Visit2[i] != start && Slack[i] == 0) {
                Visit2[i] = start;
                if (Match2[i] == -1) {
                    Augment(i);
                    return true;
                } else {
                    Q.push(Match2[i]);
                }
            }
    }
}
void ReInit() {
    for (int i = 0; i < MaxV1; ++i)
        fill(Weight[i], Weight[i] + MaxV2, 0);
    fill(Match1, Match1 + MaxV1, -1);
    fill(Match2, Match2 + MaxV2, -1);
    fill(Expect1, Expect1 + MaxV1, -Inf);
    fill(Expect2, Expect2 + MaxV2, 0);
}
int main() {
	freopen(".in","r",stdin);
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    ReInit();
    int n, m, k;
    cin >> n >> m >> k;
    sizev1 = n;
    sizev2 = max(m, n);
    for (int i = 1; i <= k; ++i) {
        int x, y;
        ll w;
        cin >> x >> y >> w;
        Weight[x][y] = w;
        Expect1[x] = max(Expect1[x], w);
    }
    for (int i = 1; i <= n; ++i)
        KuhnMunkres(i);
    ll ans = 0;
    for (int i = 1; i <= n; ++i)
        ans += Weight[i][Match1[i]];
    cout << ans << '\n';
    for (int i = 1; i <= n; ++i) {
        if (Match1[i] == -1 || Match1[i] > m || Weight[i][Match1[i]] == 0)
            cout << 0 << ' ';
        else
            cout << Match1[i] << ' ';
    }
    cout << '\n';
    return 0;
}
```

带花树

```cpp
struct Graph {
    struct Edge { int to, nxt; };
    vector<int> head;
    vector<Edge> edges;
    void init(int n) { head.assign(n + 1, -1); edges.clear(); }
    void add_edge(int u, int v) {
        edges.push_back({v, head[u]});
        head[u] = (int)edges.size() - 1;
    }
} G;

int n, m, ans;
int Dad[MaxN], Visit[MaxN], Pre[MaxN], Match[MaxN], Mark[MaxN];

int GetDad(int x) { return x == Dad[x] ? x : Dad[x] = GetDad(Dad[x]); }

int FindLca(int x, int y) {
    static int tim = 0; tim++;
    while (x != 0) {
        x = GetDad(x); Visit[x] = tim;
        x = Pre[Match[x]];
    }
    while (y != 0) {
        y = GetDad(y);
        if (Visit[y] == tim) return y;
        y = Pre[Match[y]];
    }
    return 0;
}

queue<int> Q;

void Group(int x, int lca) {
    while (x != lca) {
        int y = Match[x], z = Pre[y];
        if (GetDad(z) != lca) Pre[z] = y;
        if (Mark[y] == 2) Q.push(y), Mark[y] = 1;
        if (Mark[z] == 2) Q.push(z), Mark[z] = 1;
        Dad[x] = y; Dad[y] = z; x = z;
    }
}

bool Bfs(int start) {
    for (int i = 1; i <= n; i++) Dad[i] = i, Pre[i] = 0, Mark[i] = 0;
    Mark[start] = 1; while (!Q.empty()) Q.pop(); Q.push(start);
    while (!Q.empty()) {
        int from = Q.front(); Q.pop();
        for (int k = G.head[from]; k != -1; k = G.edges[k].nxt) {
            int to = G.edges[k].to;
            int lx = GetDad(from), ly = GetDad(to);
            if (Match[from] == to || lx == ly || Mark[to] == 2) continue;
            if (Mark[to] == 1) {
                int lca = FindLca(from, to);
                if (lx != lca) Pre[from] = to;
                if (ly != lca) Pre[to] = from;
                Group(from, lca); Group(to, lca);
            } else if (Mark[to] == 0) {
                if (Match[to] == 0) {
                    int x = from, y = to;
                    while (y != 0) {
                        int z = Match[x];
                        Match[y] = x; Match[x] = y;
                        y = z; x = Pre[y];
                    }
                    return true;
                } else {
                    Pre[to] = from;
                    Q.push(Match[to]);
                    Mark[Match[to]] = 1;
                    Mark[to] = 2;
                }
            }
        }
    }
    return false;
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    cin >> n >> m;
    G.init(n);
    for (int i = 1, x, y; i <= m; i++) {
        cin >> x >> y;
        G.add_edge(x, y);
        G.add_edge(y, x);
    }
    fill(Match, Match + n + 1, 0);
    ans = 0;
    for (int i = 1; i <= n; i++)
        if (Match[i] == 0 && Bfs(i)) ans++;
    cout << ans << '\n';
    for (int i = 1; i <= n; i++) cout << Match[i] << ' ';
    cout << '\n';
    return 0;
}
```
