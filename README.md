# ICPC 模板库

本仓库按主题保存 Markdown 模板，并由 `makeup.py` 合并生成 PDF。生成物位于 `pdf_output/`，不参与代码审查。

## 命名约定

- 类、结构体和枚举类型使用大驼峰，如 `LinkCutTree`、`SegmentRelation`。
- 函数和变量以小写开头；多个单词使用 `snake_case`，如 `build_level_graph`、`current_edge`。
- 常见且没有歧义的竞赛缩写可以保留，例如 `n`、`lcp`、`dfn`；跨越较大作用域时使用完整语义名称。
- 整数类型别名使用 `i64`、`u64`、`i128`；不使用容易遮蔽类型含义的宏。
- 模板优先采用 0-based 编号；例外必须在章节开头注明。

## 正确性约定

每份模板应写明输入前提、编号方式、复杂度、溢出范围和退化情形。能够自包含的核心代码块应通过 `-std=c++20 -Wall -Wextra -Wshadow -Wconversion -pedantic` 编译。

运行核心随机对拍：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\verify_core.ps1
```

只运行一个验证组时传入其名称，例如：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\verify_core.ps1 -Only suffix-applications
```

脚本会先扫描 Markdown 中漏写反斜杠的 LaTeX 间距命令，再编译并运行代码验证组。

需要检查越界和未定义行为时运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\verify_core.ps1 -Sanitize
```

Sanitizer 模式默认使用 `g++`；也可通过 `-Cxx clang++` 指定另一套编译器。编译器必须同时提供所需的标准库头文件和 ASan/UBSan 运行库，部分 MinGW 发行版并未附带这些运行库。

当前 46 个验证组覆盖计算几何与闵可夫斯基和、完整 NTT/FPS、多项式复合/幂投影/复合逆、Bostan–Mori、稀疏多项式、组合数与斯特林数、五边形数递推、筛法卷积、杜教筛、Min_25 筛、洲阁筛、线性递推、结构化万能欧几里得、普通/GF(2) 高斯消元、异或线性基、CRT/exCRT、行列式/插值/FWT、Miller–Rabin、Pollard–Rho、扩展 BSGS、Lucas/扩展 Lucas、原根、Tarjan、2-SAT、传递闭包、最大流、最小费用流、最大权闭合子图、最大密度子图、上下界可行流与有源汇最大/最小流、匹配与环计数、Kruskal 重构树、Euler 序 LCA、Hierholzer 欧拉路、Link–Cut Tree、点分治、点分树、DSU on tree、重链/长链剖分、带权并查集、莫队、笛卡尔树、可持久化线段树、动态主席树、线段树分治与可撤销并查集、李超线段树、左偏树、可合并线段树、虚树、PBDS、全局最小割、最大独立集、字符串哈希、SA/SAM 子串查询应用以及普通/广义后缀自动机等字符串模板。测试不能代替题目约束检查；复制模板时仍须核对模数、坐标范围、递归深度和答案类型。

## 差分测试器

`tester/tester.cpp` 可反复运行数据生成器、待测程序和暴力程序，并按空白分隔的 token 比较输出：

```powershell
g++ .\tester\tester.cpp -std=c++20 -O2 -Wall -Wextra -Wshadow -Wconversion -o .\tester\tester.exe
.\tester\tester.exe .\generator.exe .\candidate.exe .\reference.exe 10000
```

生成器会收到从 1 开始的轮数作为命令行参数，可直接把它用作随机种子。发现错误或子进程异常时，输入与两份输出会保留在打印出的临时目录中。

## 生成 PDF

```powershell
E:\Msys2\usr\bin\python3.exe .\makeup.py
```

也可以使用 PATH 中可用的 `python3`。脚本需要 Pandoc 和 XeLaTeX。
