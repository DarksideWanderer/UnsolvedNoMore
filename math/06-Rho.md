# 质因数分解

```cpp
inline long long PR(long long x){
	long long a,b,c,v,g;
	int i,j;
	while(true){
		a=b=rnd()%(x-1)+1;c=rnd()%(x-1)+1;
		v=1;
		i=0;j=1;
		while(++i){
			a=(One*a*a+c)%x;
			v=One*v*abs(a-b)%x;
			if(a==b||!v)break;
			if(!(i%63)||i==j){
				g=GetGcd(v,x);
				if(g>1)return g;
				if(i==j)b=a,j<<=1;
			}
		}
	}
}
long long maxi;
inline void Solve(long long x){
	if(x<=maxi||x<2)return ;
	if(IsPrime(x)){
		maxi=x;
		return ;
	}
	long long p=PR(x);
	while(x%p==0)x/=p;
	Solve(x),Solve(p);
}
long long n;
int main(){
	int Task;scanf("%d",&Task);
	while(Task--){
		scanf("%lld",&n);
		if(IsPrime(n))puts("Prime");
		else maxi=1,Solve(n),printf("%lld\n",maxi);
	}
	return 0;
}
```