# 字符串应用补充索引

本目录保存应用层与接入片段，基础构造引用原模板。复制题目代码时按依赖顺序组合；`cpp` 块为完整类/函数，`cpp-member` 是要放入原类 `public:` 区域的成员片段。目录中的验证脚本只读原模板，在内存里组合源码。

代码采用竞赛用的公开 `struct` 与短变量：`BIT/RMQ`、`SAQuery/SAMQuery`、`TreeOrder`、`ACQuery/PAMQuery`、`KMP/BorderQuery`、`SeqAM`、`TriePAM`。保留已有调用名的单行别名及查询接口，方便旧测试继续使用；手写时可省略别名。下标、字符和输入结构须满足各篇前提，不逐层重复校验；状态容器公开是为了方便题目内扩展，构造后不能随意改动而继续使用旧的预处理结果。

| 文件 | 内容与依赖 |
|---|---|
| `00-range-query.md` | 共用 Fenwick 与静态 RMQ |
| `01-sa-applications.md` | SA LCP、子串比较、匹配区间与动态起点权重；依赖原 SA + `00` |
| `02-sam-applications.md` | SAM suffix link、子串状态键与动态 endpos；依赖原 SAM + `00` |
| `03-sa-sam-pam-audit.md` | 原库缺口与重复项审计 |
| `04-parent-tree-tricks.md` | Parent 树双向 DP、DFS 区间与端点离线查询技巧 |
| `05-ac-applications.md` | AC 接入片段、动态模式权重、禁串 DP；依赖原 AC + `00` + `04` |
| `06-pam-applications.md` | 回文后缀统计、fail 子树权重、首次/末次出现、series DP；依赖原 PAM + `00` + `04` |
| `07-kmp-automaton.md` | KMP 自动机、前缀次数、公共/受限 border；依赖原 KMP；树查询另需 `04` + 原 Euler LCA |
| `08-subsequence-automaton.md` | 子序列最早匹配与不同内容计数，可单独使用 |
| `09-trie-pam.md` | Trie 广义 PAM，direct link 保证构造按 Trie 节点数计；独立模板 |

## PAM / AC / KMP / 序列自动机验证

在仓库根目录执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\adder\verify_automata.ps1
```

测试驱动为 `automata_tests.cpp` 与 `trie_pam_tests.cpp`。脚本读取 Markdown 的实际代码块，以 C++20 和 `-Wall -Wextra -Wshadow -Wconversion -pedantic` 编译；AC 的只读接口只插入内存中的代码副本，不改写原类文件。临时可执行文件在本目录生成，结束后自动删除。

- Parent 树：300 棵随机重编号树，祖先关系、子树和、根路径和与暴力比较。
- KMP/序列自动机：穷举长度不超过 8 的全部 511 个二元串；验证 border 次数、真/非真公共 border、受限 border、重叠匹配、空模式、最早子序列位置与不同内容计数。
- PAM：上述 511 个串加 500 个较长随机串；与枚举回文子串、朴素划分 DP 比较，验证反复正负加权和首次/末次端点。
- AC：300 组随机模式集，动态加权/撤销、文本重置、重复模式与暴力后缀匹配比较；禁串 DP 与穷举生成串比较，包含空禁串及模数 1。
- 十万长度全相同字符：检查 PAM series DP 与受限 border 统计，覆盖 fail 长链。
- Trie 广义 PAM：676 棵穷举二元 Trie、1000 棵随机重编号 Trie，逐项核对回文集合、最长回文后缀、fail/direct link 和正负端点权重；100001 节点的长链挂分叉 Trie 检查退化情况及字典重数计数。

若编译器具备相应运行库，可加 `-Sanitize` 开启 ASan/UBSan；默认测试不依赖它们。本脚本覆盖 `04`～`09` 的新增应用及共用 BIT，SA/SAM 应用测试仍是仓库的 `suffix-applications` 组。
