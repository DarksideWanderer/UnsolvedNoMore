# SA / SAM / PAM / AC / KMP 应用审计

## 重复项检查

- SA 构造与 Kasai LCP 已在 `string/08-Sa.md`，本目录只从其返回值建立 `rank`、RMQ 和应用接口，没有复制倍增排序或 LCP 构造。
- SAM 的转移、克隆、suffix link 与静态出现次数已在 `string/01-Sam.md`，本目录只在每次调用既有 `extend` 后记录 `last_state()`，再建立 suffix link 树的 DFS 序和倍增表。
- SA 动态起点计数与 SAM 动态结束位置计数共用 `BIT`；SA 的后缀 LCP、子串判等、字典序比较和匹配区间二分共用同一份 `RMQ`。
- PAM 的建树、不同回文串计数与静态出现次数均已有代码，`06-pam-applications.md` 只添加回文后缀统计、端点应用和 series-link 划分 DP。
- AC 静态出现次数的逆 BFS 已经是 fail 树 DP，不重复写；动态模式集和禁串 DP 放在 `05-ac-applications.md`。原文件的私有字段通过本目录提供的只读接入片段访问，仓库原文件不变。
- 新增的 AC、PAM、KMP 树应用共用 `04-parent-tree-tricks.md`，不各自复制 DFS；KMP 的 LCA 复用 `graph/10-euler-tour-lca.md`，不重写 RMQ 或树剖。已有 SAM 应用维持其接口。

## 原先只有说明、没有直接接口的项目

- `string/08-Sa.md` 末尾只说明了“LCP 转 RMQ”，现在已有 $O(1)$ 后缀 LCP、子串判等/比较、$O(\log n)$ 匹配区间及静态/动态计数代码。
- `string/01-Sam.md` 的“后缀链接树与出现位置”原先只有做法说明，现在已有 `prefix_state`、DFS 子树区间、结束位置动态加权、状态/子串 `endpos` 求和及按 `(end,length)` 定位状态的代码。
- `string/01-Sam.md` 中“多串最长公共子串”“按出现次数重复计算的字典序第 k 小”“首次/末次出现、持久化区间查询”仍是按需改造说明。它们分别需要额外输入集合、计数口径或另一种数据结构，不和本次 QOJ 所需接口混写，以免产生两份近似但语义不同的实现。
- `string/03-Pam.md` 的基础接口都有代码，但经典应用说明缺失：回文后缀数量/长度和、fail 树端点统计、series link 与最少回文划分，现补于 `06-pam-applications.md`。
- `string/02-ACam.md` 未解释 fail 树双向 DP、动态模式权重与自动机禁串 DP，现补于 `04`、`05`。补充区别了总出现次数、出现过的模式种数、重复模式 ID 三种口径。
- `string/07-Kmp.md` 的前缀计数、公共 border 与 KMP 自动机原来只有说明，现补于 `07-kmp-automaton.md`；同时补充线性统计“不重叠 border 数”的长度限制技巧。
- 原库没有序列自动机，现补于 `08-subsequence-automaton.md`，包含最早子序列匹配与不同内容计数，明确区别于连续子串及下标选择方案。
- Trie 广义 PAM 补于 `09-trie-pam.md`：直接接受 Trie，使用 direct link 按 Trie 节点数构造。它是支持分叉的专用构造，不能用普通单串 PAM 的 fail 回退直接替代；没有改写原 PAM。

本次审计针对上述经典应用，不声称已经枚举字符串算法的一切扩展；未实现的矩阵快速幂、模式 bitmask DP、大字母表位置数组等均明确标为改造方向，不冒充可直接调用接口。

本次补充的所有区间约定保持一致：原串位置与 SA/SAM 状态均为 0-based；SA 匹配结果对外为闭区间 `[L,R]`，树状数组和 DFS 子树内部统一使用左闭右开区间。
