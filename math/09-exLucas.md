# Lucas

```cpp
inline void ExGcd(long long a,long long b,long long&x,long long&y){
	if(a==0)puts("Error");
	if(b==0){x=1,y=0;return ;}
	ExGcd(b,a%b,y,x);y-=(a/b)*x;
}
inline long long GetInv(long long a,long long p){
	long long x,y;
	ExGcd(a,p,x,y);
	return (x%p+p)%p;
}
inline long long GetPow(long long x,long long n,long long p){
	long long r=1;r%=p;
	while(n){
		if(n&1)r=r*x%p;
		x=x*x%p;n>>=1;
	}
	return r;
}
inline long long GetV(long long x,long long p){
	long long ans=0;
	while(x){ans+=(x/=p);}
	return ans;
}
long long Save[1100000];
inline long long GetR(long long x,long long p,long long mod){
	if(x==0)return 1;
	return GetR(x/p,p,mod)*GetPow(Save[mod-1],x/mod,mod)%mod*Save[x%mod]%mod;
}
inline long long CalcC(long long n,long long m,long long p,long long mod){
	long long c=GetV(n,p)-GetV(m,p)-GetV(n-m,p);
	long long ans=GetPow(p,c,mod);
	if(!ans)return 0;
	Save[0]=1;
	for(int i=1;i<mod;i++){
		if(i%p==0)Save[i]=Save[i-1];
		else Save[i]=Save[i-1]*i%mod;
	}
	ans=ans*GetR(n,p,mod)%mod;
	ans=ans*GetInv(GetR(m,p,mod),mod)%mod;
	ans=ans*GetInv(GetR(n-m,p,mod),mod)%mod;
	return ans;
}
long long res,tmod=1;
inline void Insert(long long now,long long mod){
	long long newmod=mod*tmod;
	res=(res*mod%newmod*GetInv(mod,tmod)%newmod+now*tmod%newmod*GetInv(tmod,mod)%newmod)%newmod;
	tmod=newmod;
}
long long n,m,p;
int main(){
	scanf("%lld%lld%lld",&n,&m,&p);
	for(long long i=2;i*i<=p;i++){
		if(p%i==0){
			long long mod=1;
			while(p%i==0){
				mod*=i;
				p/=i;
			}
			Insert(CalcC(n,m,i,mod),mod);
		}
	}
	if(p>1)Insert(CalcC(n,m,p,p),p);
	printf("%lld\n",res);
	return 0;
}
```