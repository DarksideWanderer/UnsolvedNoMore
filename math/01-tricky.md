# Tricky

1. lcm 卷积
   
   接下来考虑卷积怎么做。假设我们要求 $h(x) = f(x) \times g(x)$，卷积是 lcm 卷积；我们构造 $F(n) = \sum_{d|n} f(d)$。有结论：
   
   $H(x) = F(x) \cdot G(x)$
   这里是点值对应相乘。然后我们根据莫比乌斯反演有 $f(n) = \sum_{d|n} \mu \left(\frac{n}{d}\right) F(d)$ 可以反演出 $h(x)$。单次卷积朴素调和级数是 $O(n \ln n)$，使用狄利克雷前缀和是 $O(n \ln \ln n)$。
   
   gcd 卷积反过来

2. 0/1 分数规划
3. 整除分块
   
   向上取整 , 从 $r$ 推出 $l$ , $l=\left\lceil \frac {n} {\lceil \frac n r \rceil}  \right\rceil$
   向下取整 , 从 $l$ 推出 $r$ , $r=\left\lfloor \frac {n} {\lfloor \frac n r \rfloor}  \right\rfloor$

4. dp 套 dp
5. dp 通过性质减少有效状态和转移
6. 树上背包 , $sz_u+sz_v$ 优化转移
7. wqs 二分 ?
8. 回顾 Burnside 引理。对于一个群 $G$ 和群 $G$ 作用下的状态空间集合 $X$，能得到的本质不同的状态数量等于：
   
   $$
   \frac{1}{|G|} \sum_{g \in G} \sum_{x \in X} [gx = x]
   $$
   
   即 $G$ 中各个元素的不动点数量的平均数。
9. 树上区间动态规划
10. Lagrange 反演公式
    
    令 $f(x),g(x)\in\mathbb{C}\lbrack\lbrack x\rbrack\rbrack$ 满足 $f(g(x))=g(f(x))=x$。取 $\Phi(x)\in\mathbb{C}\lbrack\lbrack x\rbrack\rbrack$（或 $\Phi(x)\in\mathbb{C}\left(\left(x\right)\right)$），那么
    
    $$
    \begin{aligned}
    \lbrack x^n\rbrack\Phi(f(x))&=\lbrack x^{n-1}\rbrack\Phi(x)\frac{g'(x)}{g(x)}\left(\frac{x}{g(x)}\right)^n \\
    &=\lbrack x^{-1}\rbrack\frac{\Phi(x)g'(x)}{g(x)^{n+1}}
    \end{aligned}
    $$
	
	有复合逆 , 需要满足常数项为0 , 一次项不为 0 .
	
	求复合逆可以推式子之后用牛顿迭代 . 