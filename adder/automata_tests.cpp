// Test driver: assembled with the Markdown templates by verify_automata.ps1.

bool is_palindrome(string_view text) {
    return equal(text.begin(), text.end(), text.rbegin());
}

vector<string> binary_strings(int maximum_length) {
    vector<string> result;
    for (int length = 0; length <= maximum_length; ++length) {
        for (int mask = 0; mask < (1 << length); ++mask) {
            string text(length, 'a');
            for (int i = 0; i < length; ++i) {
                text[i] = char('a' + (mask >> i & 1));
            }
            result.push_back(text);
        }
    }
    return result;
}

void check_parent_tree(mt19937& rng) {
    for (int trial = 0; trial < 300; ++trial) {
        int n = 1 + (int)(rng() % 50);
        vector<int> permutation(n);
        iota(permutation.begin(), permutation.end(), 0);
        shuffle(permutation.begin(), permutation.end(), rng);
        vector<int> parent(n, -1);
        for (int i = 1; i < n; ++i) {
            parent[permutation[i]] = permutation[rng() % (unsigned)i];
        }
        ParentTreeIndex tree(parent);
        vector<long long> values(n);
        for (long long& value : values) value = (long long)(rng() % 19) - 9;
        auto subtree = tree.subtree_fold(values, plus<long long>{});
        auto path = tree.root_path_fold(values, plus<long long>{});
        for (int v = 0; v < n; ++v) {
            long long expected_path = 0;
            for (int p = v; p != -1; p = parent[p]) expected_path += values[p];
            assert(path[v] == expected_path);
            long long expected_subtree = 0;
            for (int u = 0; u < n; ++u) {
                bool ancestor = false;
                for (int p = u; p != -1; p = parent[p]) ancestor |= p == v;
                assert(tree.is_ancestor(v, u) == ancestor);
                if (ancestor) expected_subtree += values[u];
            }
            assert(subtree[v] == expected_subtree);
        }
    }
}

void check_kmp_and_subsequence(const vector<string>& texts) {
    auto patterns = binary_strings(4);
    for (const string& text : texts) {
        int n = (int)text.size();
        KmpBorderQueries borders(text);
        auto nonoverlapping = nonoverlapping_border_counts(text);
        for (int length = 0; length <= n; ++length) {
            long long count = 0;
            for (int p = 0; p + length <= n; ++p) {
                count += text.compare(p, length, text, 0, length) == 0;
            }
            assert(borders.prefix_occurrences(length) == count);
            int border_count = 0;
            for (int b = 1; 2 * b <= length; ++b) {
                border_count += text.compare(0, b, text, length - b, b) == 0;
            }
            assert(nonoverlapping[length] == border_count);
            for (int other = 0; other <= n; ++other) {
                for (bool proper : {false, true}) {
                    int expected = 0;
                    for (int b = 1; b <= min(length, other); ++b) {
                        if (proper && (b == length || b == other)) continue;
                        if (text.compare(0, b, text, length - b, b) == 0 &&
                            text.compare(0, b, text, other - b, b) == 0) {
                            expected = b;
                        }
                    }
                    assert(borders.longest_common_border(length, other, proper)
                           == expected);
                }
            }
        }
        SubsequenceAutomaton sequence(text);
        map<string, vector<int>> embeddings;
        for (int mask = 0; mask < (1 << n); ++mask) {
            string value;
            vector<int> positions;
            for (int i = 0; i < n; ++i) {
                if (mask >> i & 1) {
                    value += text[i];
                    positions.push_back(i);
                }
            }
            auto found = embeddings.find(value);
            if (found == embeddings.end() || positions < found->second) {
                embeddings[value] = positions;
            }
        }
        for (int modulus : {1, 2, 7, INT_MAX}) {
            assert(sequence.distinct_subsequence_count(modulus) ==
                   (int)((embeddings.size() - 1) % (unsigned)modulus));
        }
        for (const string& pattern : patterns) {
            auto embedding = sequence.earliest_embedding(pattern);
            assert(embedding.has_value() == embeddings.contains(pattern));
            assert(sequence.contains(pattern) == embeddings.contains(pattern));
            if (embedding) assert(*embedding == embeddings.at(pattern));

            KmpAutomaton machine(pattern);
            int state = 0, seen = pattern.empty() ? 1 : 0;
            for (int end = 0; end < n; ++end) {
                state = machine.transition(state, text[end]);
                int expected_state = 0;
                for (int len = 1; len <= min(end + 1, (int)pattern.size()); ++len) {
                    if (text.compare(end - len + 1, len, pattern, 0, len) == 0) {
                        expected_state = len;
                    }
                }
                assert(state == expected_state);
                seen += state == (int)pattern.size();
            }
            assert(seen == (int)kmp_search(text, pattern).size());
        }
    }
}

void check_pam(const vector<string>& texts, mt19937& rng) {
    for (const string& text : texts) {
        int n = (int)text.size();
        PalindromicApplications query(text);
        const auto& nodes = query.pam().data();
        map<string, vector<int>> occurrences;
        vector<int> dp(n + 1, n + 1);
        dp[0] = 0;
        vector<long long> weights(n);
        for (int end = 0; end < n; ++end) {
            int count = 0;
            long long length_sum = 0;
            for (int start = 0; start <= end; ++start) {
                string part = text.substr(start, end - start + 1);
                if (!is_palindrome(part)) continue;
                occurrences[part].push_back(end);
                ++count;
                length_sum += (int)part.size();
                dp[end + 1] = min(dp[end + 1], dp[start] + 1);
            }
            assert(query.ending_count(end) == count);
            assert(query.ending_length_sum(end) == length_sum);
        }
        assert(query.minimum_partition_counts() == dp);
        assert(nodes.size() == occurrences.size() + 2);
        auto [first, last] = query.occurrence_extrema();
        auto counts = query.pam().occurrence_counts();
        for (int round = 0; round < 4; ++round) {
            for (int end = 0; end < n; ++end) {
                long long delta = (long long)(rng() % 21) - 10;
                weights[end] += delta;
                query.add_end_weight(end, delta);
            }
            for (int v = 2; v < (int)nodes.size(); ++v) {
                int length = nodes[v].length;
                assert(first[v] >= length - 1 && last[v] < n);
                string part = text.substr(first[v] - length + 1, length);
                assert(occurrences.contains(part));
                const auto& ends = occurrences.at(part);
                assert(first[v] == ends.front() && last[v] == ends.back());
                assert(counts[v] == (long long)ends.size());
                long long expected = 0;
                for (int end : ends) expected += weights[end];
                assert(query.palindrome_weight(v) == expected);
            }
        }
    }
}

void check_ac(mt19937& rng) {
    auto pool = binary_strings(3);
    for (int trial = 0; trial < 300; ++trial) {
        vector<string> patterns;
        int k = (int)(rng() % 8);
        for (int i = 0; i < k; ++i) {
            patterns.push_back(pool[1 + rng() % (pool.size() - 1)]);
        }
        DynamicAhoPatterns dynamic(patterns);
        vector<long long> weights(k);
        string text;
        for (int step = 0; step < 100; ++step) {
            if (k > 0 && rng() % 3 == 0) {
                int id = (int)(rng() % (unsigned)k);
                long long delta = (long long)(rng() % 7) - 3;
                weights[id] += delta;
                dynamic.add_pattern_weight(id, delta);
            }
            if (rng() % 9 == 0) {
                text.clear();
                dynamic.reset_text();
            }
            char c = char('a' + rng() % 3);
            text += c;
            long long expected = 0;
            for (int id = 0; id < k; ++id) {
                if (text.ends_with(patterns[id])) expected += weights[id];
            }
            assert(dynamic.feed(c) == expected);
        }
        if (trial % 7 == 0) patterns.push_back("");
        if (trial % 11 == 0) patterns.push_back("c");
        for (int length = 0; length <= 6; ++length) {
            int expected = 0;
            for (const string& candidate : binary_strings(length)) {
                if ((int)candidate.size() != length) continue;
                bool legal = true;
                for (const string& pattern : patterns) {
                    if (candidate.find(pattern) != string::npos) legal = false;
                }
                expected += legal;
            }
            for (int modulus : {1, 7, INT_MAX}) {
                assert(count_avoiding_patterns(patterns, length, 2, modulus) ==
                       expected % modulus);
            }
        }
    }
}

void check_trie_pam(mt19937& rng);

int main() {
    mt19937 rng(20260908);
    auto texts = binary_strings(8);
    check_parent_tree(rng);
    cout << "[PASS] parent-tree DP (300 random trees)\n";
    check_kmp_and_subsequence(texts);
    cout << "[PASS] KMP/borders/subsequence (511 exhaustive binary strings)\n";
    // Longer random strings exercise series-link cache reuse.
    vector<string> pam_texts = texts;
    for (int trial = 0; trial < 500; ++trial) {
        string text(1 + rng() % 70, 'a');
        for (char& c : text) c = char('a' + rng() % 4);
        pam_texts.push_back(text);
    }
    check_pam(pam_texts, rng);
    cout << "[PASS] PAM/series DP (511 exhaustive + 500 random strings)\n";
    check_ac(rng);
    cout << "[PASS] AC dynamic patterns/forbidden DP (300 random dictionaries)\n";
    check_trie_pam(rng);
    const int large = 100000;
    PalindromicApplications unary(string(large, 'a'));
    auto partition = unary.minimum_partition_counts();
    for (int i = 1; i <= large; ++i) assert(partition[i] == 1);
    assert(unary.ending_count(large - 1) == large);
    auto borders = nonoverlapping_border_counts(string(large, 'a'));
    assert(borders.back() == large / 2);
    cout << "[PASS] 100000-character repeated-string regression\n";
}
