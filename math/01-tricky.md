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
11. 树上背包
    
   	我们假设 $v$ 是 $u$ 的儿子，现在对这两个进行合并。其中 $size$ 是已经合并的子树总大小，$siz[x]$ 是根节点为 $x$ 的子树大小。

   - $size < m, siz[v] < m$  

     这相当于没有限制。我们发现一对点只会在他们的 $lca$ 为 $u$ 时才会匹配，越过 $lca$ 就已经在一棵子树里了。时间复杂度 $O(n^2)$。

   - $size \ge m, siz[v] \ge m$  

     所有的极小大于树都不会相交，所以最多有 $\frac{n}{m}$ 个。这种情况的出现，其实就是 v 已经合并的子树中有极小大于树（注意不是指 v 的单个子树是极小大于树，而是合并途中出现这样的树），v 中有极小大于树。我们知道，两棵子树合并之后就是一个整体，不会再被裂开了。那么其实这类情况的合并次数应该是极小大于树个数 $-1$。单次合并时间复杂度 $O(m^2)$，总时间复杂度

     $$
     O(m^2 \times \frac{n}{m}) = O(n \times m)
     $$

   - $size \ge m, siz[v] < m$  

     总时间复杂度 $O(m \times \sum siz[v])$。考虑出现了这样一种情况，那么容易发现，v 的子树内部不可能发生这种类型的合并，这样的合并只可能发生在外面。如果外面又发生了这种情况，那么其对应的 v' 内部也不可能发生这种类型的合并…每一个被记入的 $siz[v]$ 都不会被重新加进 $sum$ 了。所以可以将 $\sum siz[v]$ 看作 $n$（实际肯定比 n 小）。总时间复杂度 $O(m \times n)$。

   - $size < m, siz[v] \ge m$  

     同理可证。