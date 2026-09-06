# 2-SAT

`add_or(x,x_value,y,y_value)` 加入子句 `(x==x_value) or (y==y_value)`。每个文字是一个点，子句 $a\lor b$ 加两条蕴含边 $\lnot a\to b$、$\lnot b\to a$。单独加入蕴含 $a\Rightarrow b$ 时也必须同时加入逆否命题 $\lnot b\Rightarrow\lnot a$；构造赋值应按当前 SCC 实现的编号方向，不能套用别的模板的大小关系。

```cpp
#include <bits/stdc++.h>
using namespace std;

struct TwoSat {
    int variable_count, timer = 0, component_count = 0;
    vector<vector<int>> graph;
    vector<int> dfn, low, component, stack;
    vector<bool> in_stack;

    explicit TwoSat(int n) : variable_count(n), graph(2 * n), dfn(2 * n),
        low(2 * n), component(2 * n, -1), in_stack(2 * n) {}

    int literal(int variable, bool value) const {
        return 2 * variable + value;
    }

    void add_or(int x, bool x_value, int y, bool y_value) {
        int a = literal(x, x_value);
        int b = literal(y, y_value);
        graph[a ^ 1].push_back(b);
        graph[b ^ 1].push_back(a);
    }

    void force(int x, bool value) {
        add_or(x, value, x, value);
    }

    void dfs(int u) {
        dfn[u] = low[u] = ++timer;
        stack.push_back(u);
        in_stack[u] = true;
        for (int v : graph[u]) {
            if (dfn[v] == 0) {
                dfs(v);
                low[u] = min(low[u], low[v]);
            } else if (in_stack[v]) {
                low[u] = min(low[u], dfn[v]);
            }
        }
        if (low[u] != dfn[u]) return;
        while (true) {
            int v = stack.back();
            stack.pop_back();
            in_stack[v] = false;
            component[v] = component_count;
            if (v == u) break;
        }
        ++component_count;
    }

    optional<vector<bool>> solve() {
        for (int u = 0; u < 2 * variable_count; ++u) {
            if (dfn[u] == 0) dfs(u);
        }
        vector<bool> answer(variable_count);
        for (int x = 0; x < variable_count; ++x) {
            if (component[2 * x] == component[2 * x + 1]) return nullopt;
            // Tarjan 弹栈顺序是反拓扑序，编号较小的 SCC 先取真。
            answer[x] = component[2 * x + 1] < component[2 * x];
        }
        return answer;
    }
};
```

时间与空间复杂度都是 $O(n+m)$。`solve()` 只应调用一次；若继续加子句，应重新建对象。递归深度最坏为 $O(n)$，极大稀疏图需要留意栈空间。
