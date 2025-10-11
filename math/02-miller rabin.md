# MillerRabin

```cpp
const ll Prime[]={2,3,5,7,11,13,17,37};
const __int128 I=1;
ll Mul(ll x,ll y,ll p){return I*x*y%p;}
ll Pow(ll a,ll b,ll p){
	ll r=1;
	while(b){
		if(b&1){r=r*a%p;}
		a=a*a%p;b>>=1;
	}
	return r;
}
bool MillerRabin(ll n,ll a){
	ll d=n-1,r=0;
	while(!(d&1))d>>=1,r++;
	ll z=Pow(a,d,n);
	if(z==1)return true;
	for(int i=0;i<r;i++){
		if(z==n-1)return true;
		z=Mul(z,z,n);
	}
	return false;
}
bool isPrime(ll n){
	if(n<=1)return false;
	for(int i=0;i<8;i++){
		if(n==Prime[i])return true;
		if(n%Prime[i]==0)return false;
		if(!MillerRabin(n,Prime[i]))return false;
	}
	return true;
}
```