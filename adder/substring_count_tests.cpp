void check_substring_count(mt19937& rng) {
    {
        SAQuery sa("aba#abb");
        SubstrCount cnt(sa);
        cnt.add({4,3}); // Insert "abb", not its prefix "ab".
        assert(sa.suffix_lcp(0,4) == 2);
        assert(cnt.get({0,2}) == 0);
        assert(cnt.get({4,2}) == 0);
        assert(cnt.get({4,3}) == 1);
        cnt.add({4,2}, 2);
        assert(cnt.get({0,2}) == 2);
        cnt.add({0,2}, -2);
        assert(cnt.get({4,2}) == 0);
        assert(cnt.cnt.size() == 1);
        cnt.add({4,3}, -1);
        assert(cnt.cnt.empty());
    }
    {
        SAQuery sa("ab");
        // L alone is insufficient: different lengths may have the same L.
        assert(sa.key({0,1}).second == sa.key({0,2}).second);
        assert(sa.key({0,1}) != sa.key({0,2}));
    }
    auto texts = binary_strings(5);
    for (int test = 0; test < 300; ++test) {
        string s(rng() % 17, 'a');
        for (char& c : s) c = char('a' + rng() % 4);
        texts.push_back(s);
    }
    for (const string& s : texts) {
        SAQuery sa(s);
        SubstrCount cnt(sa);
        int n = (int)s.size();
        vector<SuffixArraySubstring> parts;
        for (int p = 0; p <= n; ++p)
            for (int len = 0; p + len <= n; ++len) parts.push_back({p,len});
        map<string,pair<int,int>> key_of_string;
        map<pair<int,int>,string> string_of_key;
        for (auto part : parts) {
            string value = s.substr(part.start, part.length);
            auto key = sa.key(part);
            auto [it1, inserted1] = key_of_string.emplace(value, key);
            auto [it2, inserted2] = string_of_key.emplace(key, value);
            assert(inserted1 == inserted2);
            assert(it1->second == key && it2->second == value);
        }
        map<string,long long> expected;
        for (int step = 0; step < 60; ++step) {
            auto part = parts[rng() % parts.size()];
            string value = s.substr(part.start, part.length);
            long long delta = (long long)(rng() % 11) - 5;
            cnt.add(part, delta);
            expected[value] += delta;
            if (expected[value] == 0) expected.erase(value);
            size_t old_size = cnt.cnt.size();
            for (auto query : parts) {
                auto it = expected.find(s.substr(query.start, query.length));
                long long answer = it == expected.end() ? 0 : it->second;
                assert(cnt.get(query) == answer);
            }
            assert(cnt.cnt.size() == old_size); // Missing queries must not insert.
            assert(cnt.cnt.size() == expected.size());
        }
        cnt.add({n,0}, 3);
        assert(cnt.get({0,0}) == cnt.get({n,0}));
        cnt.cnt.clear();
        for (auto part : parts) assert(cnt.get(part) == 0);
        assert(cnt.cnt.empty());
    }
    cout << "[PASS] exact substring map (LCP regression + 63 exhaustive/300 random strings)\n";
}
