# 行列式求值

```cpp
struct Matrix {
    static const int MAXN = 610;
    array<array<int, MAXN>, MAXN> data{};
    int n;
    array<int, MAXN>& operator[](int i) { return data[i]; }
};
inline int add(int x, int y) { int t = x + y; return t >= Mod ? t - Mod : t; }
inline int sub(int x, int y) { int t = x - y; return t < 0 ? t + Mod : t; }
inline int mul(int x, int y) { return int(1LL * x * y % Mod); }
int determinant(Matrix mat) {
	int det = 1;
	for(int i=0;i<=mat.n;i++){//未知元
		for(int j=i+1;j<=mat.n;j++){//方程
			while(mat[i][i]){
				int div=mat[j][i]/mat[i][i];
				for(int k=i;k<mat.n;k++)
					mat[j][k]=sub(mat[j][k],mul(div,mat[i][k]));
				for(int k=i;k<mat.n;k++)
					std::swap(mat[j][k],mat[i][k]);
				det=mul(det,Mod-1);
			}
			for(int k=i;k<=mat.n;k++)
				std::swap(mat[j][k],mat[i][k]);
			det=mul(det,Mod-1);
		}
	}
	for(int i=0;i<mat.n;i++)
		det=mul(det,mat[i][i]);

    return det;
}
```

```cpp
struct Matrixes{
	double Arr[550][550];int n,m;
	inline double* operator[](const int&idx){return Arr[idx];}
};
Matrixes A;
int n;
int main(){
	scanf("%d",&n);
	for(int i=1;i<=n;++i)
		for(int j=1;j<=n+1;j++)
			if(scanf("%lf",&A[i][j]) != 1) return 0;
	int now=1;
	for(int i=1;i<=n;i++){
		int maxi=now;
		for(int j=now+1;j<=n;j++)
			if(abs(A[j][i]) > abs(A[maxi][i]))
				maxi=j;
		if(abs(A[maxi][i]) < EPS) continue;
		for(int j=1;j<=n+1;j++)
			swap(A[now][j],A[maxi][j]);
        double pivot = A[now][i];
        for(int j=i; j<=n+1; j++)
            A[now][j] /= pivot;
		for(int j=1;j<=n;j++){
			if(j==now)continue;
			
			double tmp=A[j][i];
            
			for(int k=i;k<=n+1;k++)
				A[j][k]-=A[now][k]*tmp;
		}
		++now;
	}
    int rank = now - 1;
	for(int i = rank + 1; i <= n; i++){
		if(fabs(A[i][n+1]) > EPS)
			return puts("-1"),0;
	}
	if(rank < n)
		return puts("0"),0;
	for(int i=1;i<=n;i++){
		printf("x%d=%.2lf\n",i,A[i][n+1]/A[i][i]);
	}
	return 0;
}
```