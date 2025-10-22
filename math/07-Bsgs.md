# Bsgs

```cpp
#include<cstdio>
#include<cstring>
#include<algorithm>
#include<map>
#include<cmath>
using namespace std;

inline int Gcd(int a,int b){
	return b==0?a:Gcd(b,a%b);
}
inline void ExGcd(int a,int b,int &x,int &y){
	if(b==0){x=1,y=0;return ;}
	ExGcd(b,a%b,y,x);y-=(a/b)*x;
}
inline int GetInv(int a,int p){
	int x,y;ExGcd(a,p,x,y);
	return (x%p+p)%p;
}

map<int,int>H;
inline int Bsgs(int a,int b,int p){
	if(1%p==b%p)return 0;
	a%=p,b%=p;
	H.clear();
	int k=ceill(sqrtl(p)),r=1;
	for(int t=0;t<k;t++){
		H[1ll*b*r%p]=t;
		r=1ll*r*a%p;
	}
	int ak=r;
	for(int t=1;t<=k;t++){
		auto q=H.find(r);
		if(q!=H.end())return 1ll*t*k-(*q).second;
		r=1ll*r*ak%p;
	}
	return -1;
}
inline int ExBsgs(int a,int b,int p){
	if(1%p==b%p)return 0;
	a%=p;b%=p;
	int g=Gcd(a,p);
	if(g!=1){
		if(b%g!=0)return -1;
		int t=ExBsgs(a,1ll*(b/g)*GetInv(a/g,p/g)%(p/g),(p/g));
		return t==-1?-1:t+1;
	}
	return Bsgs(a,b,p);
}
int a,b,p;
int main(){
	while(~scanf("%d%d%d",&a,&p,&b)&&!(a==0&&b==0&&p==0)){
		int t=ExBsgs(a,b,p);
		if(t==-1)puts("No Solution");
		else printf("%d\n",t);
	}
	return 0;
}
```