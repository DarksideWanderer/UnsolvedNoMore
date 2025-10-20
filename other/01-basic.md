# 基本模版

```cpp
#define gep(k,from,Head,Er) for(int k=Head[from];k!=-1;k=Er[k].nxt)
#define rep(i,a,b) for(int i=a,rep##i=b;i<=rep##i;i++)
#define per(i,a,b) for(int i=a,rep##i=b;i>=rep##i;i--)
#define sz(x) (static_cast<int>(x.size()))
#define all(x) x.begin(),x.end()
template<typename T>void Clear(T&x){T y;x.swap(y);}
```