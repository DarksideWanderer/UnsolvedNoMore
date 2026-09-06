# 数学部分索引

赛场上按需求查找：

| 需求 | 文件 |
| --- | --- |
| 阶乘、组合数、常见恒等式 | `17-combinatorics.md`、`24-counting-formulas.md` |
| Stirling 数、幂与下降幂换基 | `18-stirling.md` |
| OGF/EGF 建模与系数提取 | `21-generating-functions.md`、`24-counting-formulas.md` |
| 重复抽样的顺序计数、指数换元、一次标记 | `21-generating-functions.md` |
| 单项式记录总权重、线性映射、容斥多项式 | `21-generating-functions.md` |
| 联合成功概率、二项式矩、阈值等待时间反演 | `34-probability-expectation.md`、`24-counting-formulas.md` |
| 二元卷积与 Kronecker 代换 | `21-generating-functions.md`；代码见 `23-polynomial-advanced.md` 的 `BiPoly` |
| 概率、期望、方差、尾和、收集与吸收过程 | `34-probability-expectation.md` |
| PGF、随机和、泊松化、Chernoff 界 | `34-probability-expectation.md` |
| 分拆、五边形数、Euler 变换、Newton 恒等式 | `24-counting-formulas.md` |
| 非 NTT 模数下的选择路线 | `24-counting-formulas.md` 的“没有 NTT 友好模数时” |
| 完整 NTT/FPS、除法、复合与转置 | `23-polynomial-advanced.md` |
| 线性递推、BM、Bostan--Mori | `20-linear-recurrence.md`、`14-分式求系数.md` |
| 反演、GCD/LCM 卷积、筛法卷积 | `24-counting-formulas.md`、`19-sieve-convolutions.md` |
| 线性同余、CRT/exCRT | `27-crt.md` |
| 数论定理与整除估值 | `33-number-theory-theorems.md` |
| 素性、分解、离散对数、原根 | `02-miller rabin.md`、`06-Rho.md`、`07-Bsgs.md`、`05-原根.md` |
| 积性函数前缀和 | `28-dujiao-sieve.md`、`29-min25-sieve.md`、`30-lucy-sieve.md` |
| 实数/模素数/GF(2) 线性方程 | `25-gaussian-elimination.md`、`31-gf2-gaussian.md` |
| 异或空间 | `26-xor-linear-basis.md` |
| 公平组合游戏 | `32-sprague-grundy.md` |

## 从题目结构找到建模方法

| 观察到的结构 | 为什么能转化，以及去哪里查 |
| --- | --- |
| 方案难枚举，但某个元素的贡献容易算 | 交换“枚举方案”和“枚举贡献”的顺序；随机问题用指示变量与期望线性性，见 `34-probability-expectation.md` |
| 重复选择，各类只有次数限制 | EGF 的阶乘分母自动统计时间位置的交错，见 `21-generating-functions.md` |
| 子集贡献只取决于权重之和 | 先用指数记录总权重，再对单项式施加线性映射，见 `21-generating-functions.md` |
| 指定若干事件同时成功容易算，但成功个数分布难算 | 联合概率之和是二项式矩，用反演恢复分布或阈值概率，见 `34-probability-expectation.md` |
| 只问某个统计量的和或平方和 | 用标记变量的一、二阶导数，可能不必保存完整分布，见 `21-generating-functions.md` |
| “全部满足”很难，但指定一些条件失败很容易 | 对失败集合容斥；恰好满足若干项用二项式反演，见 `24-counting-formulas.md` |
| 出现 $k^r$，直接求和困难 | 用 Stirling 数转成下降幂；下降幂对应有序选取，见 `18-stirling.md`、`24-counting-formulas.md` |
| 求和带 $\gcd$ 或 $\operatorname{lcm}$ | 用整除关系把条件拆开，转换为约数或倍数求和，见 `19-sieve-convolutions.md`、`24-counting-formulas.md` |
| 旋转、翻转后的方案算相同 | 稳定子大小未必相同，不能直接除群大小；按不动点使用 Burnside，见 `24-counting-formulas.md` |
| 问递推序列极远的一项 | 用特征多项式降幂或有理生成函数求系数，见 `20-linear-recurrence.md`、`14-分式求系数.md` |
| 隐式方程 $F=x\phi(F)$ 描述递归结构 | 用 Lagrange 反演直接求系数，见 `01-tricky.md` |
| 二元下标范围都可控 | 用足够大的基数打包成一元卷积，见 `21-generating-functions.md` |

先检查模数是否为素数、所除元素是否可逆、答案是否需要完整整数，以及卷积规模是否真的值得使用 NTT。很多计数题在这些前提不同后，公式仍成立，但实现方法并不相同。
