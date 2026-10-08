#include <iostream>
#include <algorithm>
#include <vector>
#include <cassert>
using namespace std;

const int mod = 998244353;

int A(int x, int y){ return x + y >= mod ? x + y - mod : x + y; }
int S(int x, int y){ return x - y < 0 ? x + mod - y : x - y; }
int N(int x){ return x ? mod - x : 0; }

void fwt(vector<int>& a, int lim, bool inv){
	for(int i = 1; i < lim; i <<= 1)
		for(int j = 0; j < lim; j += i << 1)
			for(int k = 0; k < i; k++){
				int x = a[j + k], y = a[j + k + i];
				a[j + k + i] = !inv ? A(x, y) : S(y, x);
			}
}

using FPS = vector<vector<int>>;

// FWT 意义下逐点卷积，结果截断到前 K 项；lim 是点数
FPS bag(const FPS& a,const FPS& b,int lim,int K){
	FPS c(K,vector<int>(lim));
	int na=min((int)a.size(),K);
	int nb=min((int)b.size(),K);
	for(int i=0;i<na;i++)
		for(int j=0;j<nb && i+j<K;j++){
			const auto &x=a[i];
			const auto &y=b[j];
			auto &z=c[i+j];
			for(int s=0;s<lim;s++)
				z[s]=(z[s]+1ll*x[s]*y[s])%mod;
		}
	return c;
}

int _pow(int a, int b){
	int r = 1;
	while(b){
		if(b & 1) r = 1LL * r * a % mod;
		a = 1LL * a * a % mod;
		b >>= 1;
	}
	return r;
}
#define pc(x) __builtin_popcount(x)

/*
子集卷积求逆（按集合大小递推）：
1. 定义 (f*g)[S] = sum_{T subseteq S} f[T]g[S\T]，要求 f*g=e，
   其中 e[空集]=1，其余为 0。代入 S=空集，得
     f[0]g[0]=1，即 g[0]=f[0]^{-1}，因此要求 f[0]!=0（模 mod）。
   对非空 S，把 T=空集这一项单独提出：
     f[0]g[S] + sum_{非空 T subseteq S} f[T]g[S\T] = 0，
   所以递推式为
     g[S] = -f[0]^{-1} * sum_{非空 T subseteq S} f[T]g[S\T]。
   因为 T 非空，所以 |S\T|<|S|；按 |S| 从小到大计算即可，且解唯一。
   直接枚举 S、T 需要 O(3^n)，下面用分层 zeta 加速每一层的求和。
2. 记 F_i[S]=sum_{T subseteq S, |T|=i} f[T]，
        G_j[S]=sum_{T subseteq S, |T|=j} g[T]。
   计算第 k 层时，G_0,...,G_{k-1} 已知。先在变换域计算
     C_k[S] = sum_{i=1}^k F_i[S]G_{k-i}[S]。
   展开后，它枚举 A,B subseteq S，满足 A 非空、|A|+|B|=k。
   对 C_k 做 Möbius 逆变换，把“并集包含于 S”变成“并集恰为 S”：
     c[S] = sum_{A union B=S, A 非空, |A|+|B|=k} f[A]g[B]。
   只取 |S|=k 的位置，由 |A|+|B|=|A union B|+|A intersect B|
   可知 A intersect B=空集，于是 B=S\A，恰好得到递推式中的求和。
   因而代码中 g[S]=-c[S]*invf0，再把这些值放入第 k 层并做 zeta，
   得到 G_k，供后续各层使用。i 从 1 开始，故不需要变换 F_0。
3. 这里的 G_k 始终是“仅保留 |S|=k 的 g 后做 zeta”的结果，
   每轮都先逆变换、提取第 k 层，再重新变换；与下方 Newton 版本
   直接维护逐点普通幂级数的逆不同，不能混用两者的中间层含义。
复杂度：时间 O(n^2*2^n)，空间 O(n*2^n)（n=0 时为 O(1)）。
*/
vector<int> sps_inv(const vector<int>& f,int n){
	int lim = 1 << n;
	FPS F(n + 1, vector<int>(lim));
	FPS G(n + 1, vector<int>(lim));
	for(int s = 0; s < lim; s++)
		F[pc(s)][s] = f[s];
	// F[0] 后面不会参与卷积，不需要变换
	for(int i = 1; i <= n; i++)
		fwt(F[i], lim, false);
	int invf0 = _pow(f[0], mod - 2);
	vector<int> g(lim);
	g[0] = invf0;
	// zeta({g[0], 0, 0, ...}) 后所有位置都是 g[0]
	fill(G[0].begin(), G[0].end(), invf0);
	for(int k = 1; k <= n; k++){
		vector<int> c(lim);
		for(int i = 1; i <= k; i++)
			for(int s = 0; s < lim; s++)
				c[s] = (c[s] + 1ll * G[k-i][s] * F[i][s]) % mod;
		fwt(c, lim, true);
		for(int s = 0; s < lim; s++){
			if(pc(s) != k) continue;
			g[s] = 1ll * N(c[s]) * invf0 % mod;
			G[k][s] = g[s];
		}
		fwt(G[k], lim, false);
	}

	return g;
}

// 分层 zeta / 最后逆变换并提取对角层。
FPS sps_zeta(const vector<int>& f,int n){
	int lim = 1 << n;
	assert((int)f.size() == lim);
	FPS F(n + 1, vector<int>(lim));
	for(int s = 0; s < lim; s++) F[pc(s)][s] = f[s];
	for(auto &a : F) fwt(a, lim, false);
	return F;
}

vector<int> sps_extract(FPS& F,int n){
	int lim = 1 << n;
	vector<int> g(lim);
	for(int k = 0; k <= n; k++){
		fwt(F[k], lim, true);
		for(int s = 0; s < lim; s++)
			if(pc(s) == k) g[s] = F[k][s];
	}
	return g;
}

vector<int> small_inverses(int n){
	vector<int> inv(n + 1);
	if(n) inv[1] = 1;
	for(int i = 2; i <= n; i++)
		inv[i] = mod - 1LL * (mod / i) * inv[mod % i] % mod;
	return inv;
}

// 普通 FPS：a[0]=1，b=ln(a)。由 a*b'=a' 比较 x^(k-1)：
// b[k]=a[k]-1/k * sum_{i=1}^{k-1} i*b[i]*a[k-i]。
vector<int> fps_ln(const vector<int>& a,const vector<int>& inv){
	assert(a[0] == 1);
	int K = (int)a.size();
	vector<int> b(K);
	for(int k = 1; k < K; k++){
		int sum = 0;
		for(int i = 1; i < k; i++)
			sum = (sum + 1LL * i * b[i] % mod * a[k-i]) % mod;
		b[k] = S(a[k], 1LL * sum * inv[k] % mod);
	}
	return b;
}

// 普通 FPS：a[0]=0，b=exp(a)。由 b'=a'*b：
// b[0]=1，b[k]=1/k * sum_{i=1}^k i*a[i]*b[k-i]。
vector<int> fps_exp(const vector<int>& a,const vector<int>& inv){
	assert(a[0] == 0);
	int K = (int)a.size();
	vector<int> b(K);
	b[0] = 1;
	for(int k = 1; k < K; k++){
		int sum = 0;
		for(int i = 1; i <= k; i++)
			sum = (sum + 1LL * i * a[i] % mod * b[k-i]) % mod;
		b[k] = 1LL * sum * inv[k] % mod;
	}
	return b;
}

// 子集卷积 ln：f[0]=1。逐点求普通 FPS 的 ln，最后提取对角层。
vector<int> sps_ln(const vector<int>& f,int n){
	assert(!f.empty() && f[0] == 1);
	FPS F = sps_zeta(f, n);
	auto inv = small_inverses(n);
	for(int s = 0; s < (1 << n); s++){
		vector<int> a(n + 1);
		for(int k = 0; k <= n; k++) a[k] = F[k][s];
		auto b = fps_ln(a, inv);
		for(int k = 0; k <= n; k++) F[k][s] = b[k];
	}
	return sps_extract(F, n);
}

// 子集卷积 exp：f[0]=0。所有非对角系数都保留到计算结束。
vector<int> sps_exp(const vector<int>& f,int n){
	assert(!f.empty() && f[0] == 0);
	FPS F = sps_zeta(f, n);
	auto inv = small_inverses(n);
	for(int s = 0; s < (1 << n); s++){
		vector<int> a(n + 1);
		for(int k = 0; k <= n; k++) a[k] = F[k][s];
		auto b = fps_exp(a, inv);
		for(int k = 0; k <= n; k++) F[k][s] = b[k];
	}
	return sps_extract(F, n);
}

/*
子集卷积非负整数次幂，约定 f^{*0}=e（包括 f 全零）。
先按最低非零集合大小 r 判断：r>0 且 t>n/r 时结果为零。
对每个变换点单独找普通 FPS 的首个非零项 a[d]：
  A(x)=x^d*c*H(x)，H(0)=1，A(x)^t=x^(d*t)*c^t*exp(t*ln H(x))。
若该点全零，或 d>0 且 t>n/d，则该点结果全零。
注意不能在原子集数组中按下标平移；只在变换后的普通 FPS 中移位。
位移使用原始 t，ln 的倍数用 t%mod，非零 c 的幂指数用 t%(mod-1)。
时间 O(n^2*2^n + 2^n*log(mod))，空间 O(n*2^n)。
*/
vector<int> sps_pow(const vector<int>& f,int n,long long t){
	assert(t >= 0 && (int)f.size() == (1 << n));
	int lim = 1 << n;
	vector<int> zero(lim);
	if(t == 0){ zero[0] = 1; return zero; }
	int r = n + 1;
	for(int s = 0; s < lim; s++)
		if(f[s]) r = min(r, pc(s));
	if(r == n + 1 || (r > 0 && t > n / r)) return zero;
	FPS F = sps_zeta(f, n);
	auto inv = small_inverses(n);
	for(int s = 0; s < lim; s++){
		vector<int> a(n + 1);
		for(int k = 0; k <= n; k++){
			a[k] = F[k][s];
			F[k][s] = 0;
		}
		int d = 0;
		while(d <= n && a[d] == 0) d++;
		if(d > n || (d > 0 && t > n / d)) continue;
		int shift = d ? (int)(d * t) : 0;
		int K = n - shift + 1;
		int ic = _pow(a[d], mod - 2);
		int scale = _pow(a[d], (int)(t % (mod - 1)));
		vector<int> h(K);
		for(int k = 0; k < K; k++) h[k] = 1LL * a[d+k] * ic % mod;
		auto b = fps_ln(h, inv);
		for(int &x : b) x = 1LL * x * (t % mod) % mod;
		b = fps_exp(b, inv);
		for(int k = 0; k < K; k++) F[k+shift][s] = 1LL * b[k] * scale % mod;
	}
	return sps_extract(F, n);
}

/*
普通 FPS 复合集合幂级数：a(x)=sum a[k]*x^k，返回 sum a[k]*f^{*k}。
要求 f[0]=0；a 是普通系数，不是 EGF 系数。缺项补零，超过 n 次忽略。

推导（固定新元素所在的块）：
1. f^{*k} 枚举 k 个有序非空块；每个无序划分恰好出现 k! 次。
   令 b[k]=k!*a[k]，复合就是：枚举集合划分，分成 k 块时乘 b[k]，
   再乘所有块的 f 值。
2. H[r][S] 表示划分 S，分成 k 块时使用权值 b[r+k] 的结果。
   没有元素时只有空划分，所以 H[r][0]=b[r]。最终要求 H[0]。
3. 已处理低 m 位，加入新元素 v（对应位 lim=1<<m）。
   不含 v 的位置不变。含 v 时，其所在的块唯一，可写成 T union {v}；
   剩下 S\T 继续划分，已经选了一块，故权值偏移从 r 变成 r+1：
     H_new[r][S union {v}]
       = sum_{T subseteq S} f[T union {v}]*H_old[r+1][S\T]。
   令 q[T]=f[T union {v}]，右侧就是 q*H_old[r+1] 的子集卷积。
   q 去掉了 v，因此 q[0]=f[{v}] 可以非零。每轮只变换一次 q。
4. 加入 m 位后仅保留 r=0..n-m；下一轮计算 r=0..n-m-1。
   r 从小到大更新，读取 H[r+1] 时它仍是旧数组，卷积结果接到 H[r] 后。

每轮做 n-m 次 m 元子集卷积，时间
  sum_{m=0}^{n-1} (n-m)*O((m+1)^2*2^m) = O(n^2*2^n)。
因为令 d=n-m，(n-m)*2^m=2^n*d/2^d，而 sum d/2^d 收敛。
空间 O(n*2^n)，n=0 时 O(1)。只保留当前轮的 H，复用 q 的变换。
来源：李白天《信息学竞赛中的生成函数计算理论框架》，“逐点牛顿迭代法 / 复合”。
https://codeforces.com/blog/entry/92183
*/
vector<int> sps_compose(const vector<int>& a,const vector<int>& f,int n){
	assert(n >= 0 && n < 31);
	assert((int)f.size() == (1 << n) && f[0] == 0);
	if(a.empty()) return vector<int>(1 << n);
	// H 的第一维是权值偏移 r，不是分层 zeta 的大小层。
	vector<vector<int>> H(n + 1, vector<int>(1));
	int fac = 1;
	for(int r = 0; r <= n; r++){
		if(r) fac = 1LL * fac * r % mod;
		if(r < (int)a.size()) H[r][0] = 1LL * fac * a[r] % mod;
	}
	for(int m = 0; m < n; m++){
		int lim = 1 << m;
		vector<int> q(f.begin() + lim, f.begin() + (lim << 1));
		FPS Q = sps_zeta(q, m);
		for(int r = 0; r < n - m; r++){
			FPS R = sps_zeta(H[r+1], m);
			R = bag(Q, R, lim, m + 1);
			auto high = sps_extract(R, m);
			// 低半段继承旧值，高半段存含新元素的结果。
			H[r].insert(H[r].end(), high.begin(), high.end());
		}
		H.pop_back();
	}
	return H[0];
}

/*
子集卷积求逆（分层 zeta + Newton）：
1. 定义 (f*g)[S] = sum_{T subseteq S} f[T]g[S\T]，单位元为 e[空集]=1，
   其余为 0。要求 f*g=e；当且仅当 f[0]!=0 时逆元存在且唯一。
2. 令 F_k[S]=sum_{T subseteq S, |T|=k} f[T]，即按 |T| 分层后做 zeta。
   对每个 S，把 F[S](x)=sum_k F_k[S]x^k 当作普通形式幂级数。
   层间乘法用 bag 完成；对乘积的第 k 层做 Möbius 逆变换，得到
     sum_{A union B=S, |A|+|B|=k} f[A]g[B]。
   取 k=|S| 时 A、B 必不相交，恰好得到子集卷积。
   因此可逐点求 G[S](x)=1/F[S](x) mod x^(n+1)，最后逆变换并取
   g[S]=G_{|S|}[S]。也可从 1/F=f[0]^{-1} sum_{j>=0}(-U/f[0])^j
   理解：U=F-f[0] 的每个因子代表非空子集，逆变换筛选并集为 S，
   总大小等于 |S| 又筛掉所有重叠，留下子集卷积逆元的展开。
3. 一般 Newton：若 H(G)=0 mod x^m，且 H'(G) 的常数项可逆，则
     G_new = G - H(G)/H'(G) mod x^K，K=min(2m,n+1)。
   修正量从 x^m 开始，Taylor 展开的二次及以上项均为 O(x^(2m))，
   故精度倍增。令 h=K-m，Q=(H(G)/x^m) mod x^h，
   J=1/H'(G) mod x^h，只需 C=Q*J mod x^h，再补 G[m+t]=-C[t]。
   这里 G 原来仅有前 m 项，计算 H(G) 时其余项视为 0。
4. 求逆套用 H(G)=F*G-1，H'(G)=F。初值 G_0[S]=1/f[0]；
   因 h<=m，已有 G 的前 h 项就是所需 J，无须另写 inv_dH。
   高半段 Q_t[S]=sum_{i+j=m+t, j<m} F_i[S]G_j[S]，然后用 bag(Q,G)。
   若套用其他方程，替换初值、Q 和 J 的计算，并先确认导数可逆；
   若 H 含求导等操作，还需单独检查上述精度倍增条件是否成立。
注意：迭代在逐点普通幂级数中进行，中途不能按 k==|S| 清零；
      G_k[S] 在 k>|S| 时也可能非零，必须保留，最后才提取对角层。
用法：auto g=sps_newton(f,n); f.size()==2^n，0<=f[S]<mod，f[0]!=0；
      n>=0 且 1<<n 可用 int 表示。返回 g，使 f*g=e（模 mod）。
复杂度：时间 O(n^2*2^n)，空间 O(n*2^n)（n=0 时为 O(1)）。
分层变换参考：https://arxiv.org/abs/cs/0611101
*/
vector<int> sps_newton(const vector<int>& f,int n){
	int lim = 1 << n;
	FPS F(n + 1, vector<int>(lim));
	for(int s = 0; s < lim; s++)
		F[pc(s)][s] = f[s];
	for(int k = 0; k <= n; k++)
		fwt(F[k], lim, false);

	FPS G(1, vector<int>(lim, _pow(f[0], mod - 2)));
	for(int m = 1; m <= n; m <<= 1){
		int K = min(n + 1, m << 1), h = K - m;
		// Q = [x^m,...,x^(K-1)](F*G-1)，常数 -1 不影响高半段。
		FPS Q(h, vector<int>(lim));
		for(int t = 0; t < h; t++)
			for(int j = 0; j < m; j++)
				for(int s = 0; s < lim; s++)
					Q[t][s] = (Q[t][s] + 1LL * F[m+t-j][s] * G[j][s]) % mod;

		// J = 1/F mod x^h = G mod x^h；bag 自动截断到 h 项。
		FPS C = bag(Q, G, lim, h);
		G.resize(K, vector<int>(lim));
		for(int t = 0; t < h; t++)
			for(int s = 0; s < lim; s++)
				G[m+t][s] = N(C[t][s]);
	}

	vector<int> g(lim);
	for(int k = 0; k <= n; k++){
		fwt(G[k], lim, true);
		for(int s = 0; s < lim; s++)
			if(pc(s) == k) g[s] = G[k][s];
	}
	return g;
}


int main(){
	ios::sync_with_stdio(false);
	cin.tie(nullptr);
	int n; cin >> n;
	vector<int> ar((1 << n));
	for(int i = 0; i < (1 << n); i++)
		cin >> ar[i];
	auto g = sps_exp(ar, n);
	for(int i = 0; i < (1 << n); i++)
		cout << g[i] << ' ';
	cout << '\n';
	return 0;
}
