// Independent oracle: enumerate palindromic suffixes at every Trie node.
void check_one_trie(const vector<array<int,26>>& tr, mt19937& rng) {
    int n = (int)tr.size();
    vector<int> order{0};
    vector<string> path(n);
    for (int i = 0; i < n; ++i) {
        int u = order[i];
        for (int c = 0; c < 26; ++c) if (int v = tr[u][c]) {
            order.push_back(v);
            path[v] = path[u] + char('a' + c);
        }
    }
    TriePAM pam(tr);
    assert((int)pam.t.size() <= n + 1);
    assert(pam.last[0] == 1);
    vector<string> value(pam.t.size());
    vector<bool> seen(pam.t.size());
    seen[0] = seen[1] = true;
    for (int v = 0; v < (int)pam.t.size(); ++v) {
        assert(seen[v]);
        for (int c = 0; c < 26; ++c) if (int u = pam.t[v].ch[c]) {
            assert(!seen[u]);
            seen[u] = true;
            char ch = char('a' + c);
            value[u] = v == 0 ? string(1, ch) : ch + value[v] + ch;
            assert((int)value[u].size() == pam.t[u].len);
            assert(is_palindrome(value[u]));
        }
    }
    map<string,int> state;
    state[""] = 1;
    for (int v = 2; v < (int)pam.t.size(); ++v) {
        assert(!state.contains(value[v]));
        state[value[v]] = v;
    }
    // Check every fail and direct link by scanning suffixes of its palindrome.
    for (int v = 2; v < (int)pam.t.size(); ++v) {
        const string& s = value[v];
        int fail = 1;
        array<int,26> direct{};
        for (int len = 0; len < (int)s.size(); ++len) {
            string suffix = s.substr(s.size() - (unsigned)len);
            if (!is_palindrome(suffix)) continue;
            assert(state.contains(suffix));
            int u = state.at(suffix);
            fail = u;
            direct[s[s.size() - (unsigned)len - 1] - 'a'] = u;
        }
        assert(pam.t[v].fail == fail);
        assert(pam.t[v].direct == direct);
    }
    for (int round = 0; round < 3; ++round) {
        vector<long long> w(n);
        for (auto& x : w) x = round == 0 ? 1 : (long long)(rng() % 15) - 7;
        map<string,long long> expected;
        for (int u = 1; u < n; ++u) {
            string longest;
            for (int len = 1; len <= (int)path[u].size(); ++len) {
                string suffix = path[u].substr(path[u].size() - (unsigned)len);
                if (is_palindrome(suffix)) {
                    expected[suffix] += w[u];
                    longest = suffix;
                }
            }
            assert(value[pam.last[u]] == longest);
        }
        assert(pam.size() == (int)expected.size());
        auto cnt = pam.count(w);
        for (int v = 2; v < (int)pam.t.size(); ++v) {
            assert(expected.contains(value[v]));
            assert(cnt[v] == expected.at(value[v]));
        }
    }
}

void check_trie_pam(mt19937& rng) {
    int tested = 0;
    // All 676 prefix-closed binary tries of height <= 3, including empty input.
    for (int mask = 0; mask < (1 << 14); ++mask) {
        bool valid = true;
        for (int v = 1; v <= 14; ++v) if (mask >> (v - 1) & 1) {
            int p = (v - 1) / 2;
            if (p && !(mask >> (p - 1) & 1)) valid = false;
        }
        if (!valid) continue;
        vector<array<int,26>> tr(1);
        vector<int> id(15);
        for (int v = 1; v <= 14; ++v) if (mask >> (v - 1) & 1) {
            int p = (v - 1) / 2, c = (v - 1) % 2;
            id[v] = (int)tr.size();
            tr.emplace_back();
            tr[id[p]][c] = id[v];
        }
        check_one_trie(tr, rng);
        ++tested;
    }
    assert(tested == 676);
    for (int test = 0; test < 1000; ++test) {
        vector<array<int,26>> tr(1);
        int words = (int)(rng() % 25);
        for (int i = 0; i < words; ++i) {
            int len = (int)(rng() % 25), u = 0;
            for (int j = 0; j < len; ++j) {
                int c = (int)(rng() % 4);
                if (!tr[u][c]) {
                    int v = (int)tr.size();
                    tr.emplace_back();
                    tr[u][c] = v;
                }
                u = tr[u][c];
            }
        }
        // Node IDs do not imply DFS/BFS order.
        vector<int> perm(tr.size());
        iota(perm.begin(), perm.end(), 0);
        shuffle(perm.begin() + 1, perm.end(), rng);
        vector<array<int,26>> shuffled(tr.size());
        for (int u = 0; u < (int)tr.size(); ++u)
            for (int c = 0; c < 26; ++c)
                if (tr[u][c]) shuffled[perm[u]][c] = perm[tr[u][c]];
        check_one_trie(shuffled, rng);
    }
    // Broom Trie: a^k backbone with a b leaf at each depth.
    // Repeated ordinary fail walks would take quadratic time.
    const int depth = 50000;
    vector<array<int,26>> tr(2 * depth + 1);
    for (int i = 1; i <= depth; ++i) {
        tr[i-1][0] = i;
        tr[i][1] = depth + i;
    }
    TriePAM pam(tr);
    assert(pam.size() == depth + 1);
    vector<long long> w(tr.size(), 1);
    auto cnt = pam.count(w);
    for (int i = 1; i <= depth; ++i) {
        assert(pam.t[pam.last[i]].len == i);
        assert(cnt[pam.last[i]] == depth - i + 1);
        assert(pam.t[pam.last[depth+i]].len == 1);
        assert(cnt[pam.last[depth+i]] == depth);
    }
    // Dictionary consists of all a^i b: shared prefix node weights differ.
    for (int i = 1; i <= depth; ++i) w[i] = depth - i + 1;
    cnt = pam.count(w);
    for (int i = 1; i <= depth; ++i) {
        long long k = depth - i + 1;
        assert(cnt[pam.last[i]] == k * (k + 1) / 2);
    }
    cout << "[PASS] Trie PAM (676 exhaustive + 1000 random tries + 100001-node broom)\n";
}
