# 数学技巧与易错点

本页只保留没有独立模板承载的技巧。GCD/LCM 卷积统一见 `19-sieve-convolutions.md` 和 `24-counting-formulas.md`，Burnside--Pólya 统一见 `24-counting-formulas.md`。

## 整除分块

对固定正整数 $n$，$\lfloor n/i\rfloor$ 在一段连续下标上相同。已知左端点 $l$ 时，

$$
q=\left\lfloor\frac nl\right\rfloor,
\qquad
r=\left\lfloor\frac nq\right\rfloor.
$$

枚举下一段令 $l=r+1$，总段数为 $O(\sqrt n)$。涉及向上取整时，优先用

$$
\left\lceil\frac ab\right\rceil
=\left\lfloor\frac{a+b-1}{b}\right\rfloor
$$

（仅适用于这里的非负整数），避免混用左右端点公式。

## 0/1 分数规划与 WQS 二分

- 判定是否存在 $A/B\ge x$（$B>0$），可改为判定 $A-xB\ge0$。
- WQS 二分给“选择数量”附加线性代价，要求最优选择数量随参数单调。相等时统一按数量较多或较少破同值，否则二分边界可能不稳定。

## Lagrange--Bürmann 反演

设 $f(0)=g(0)=0$、$f'(0)g'(0)\ne0$，且 $f$ 与 $g$ 互为复合逆。对 $n>0$，

$$
[x^n]\Phi(f(x))
=\frac1n[t^{n-1}]\Phi'(t)\left(\frac{t}{g(t)}\right)^n.
$$

等价的留数形式为

$$
[x^n]\Phi(f(x))
=[t^{-1}]\frac{\Phi(t)g'(t)}{g(t)^{n+1}}.
$$

模质数实现要同时确认 $n$ 以及所需常数项在模意义下可逆。

## 树上背包复杂度

合并儿子时不要机械地把每次卷积都估成 $O(n^2)$。常见计数方法是把一对状态归到它们第一次相遇的 LCA；每对点只贡献一次，因此许多无额外上限的树背包总复杂度就是 $O(n^2)$。若状态上限为 $m$，将循环边界截到子树大小与 $m$ 的较小值，常可得到 $O(nm)$，但必须针对具体转移证明，不能只凭“子树大小和”为 $n$。
