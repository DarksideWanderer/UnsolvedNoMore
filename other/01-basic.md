# 基本模版

```cpp
#define gep(k,from,Head,Er) for(int k=Head[from];k!=-1;k=Er[k].nxt)
#define rep(i,a,b) for(int i=a,rep##i=b;i<=rep##i;i++)
#define per(i,a,b) for(int i=a,rep##i=b;i>=rep##i;i--)
#define sz(x) (static_cast<int>(x.size()))
#define all(x) x.begin(),x.end()
template<typename T>void Clear(T&x){T y;x.swap(y);}
```

1. 添加数组 : `*(type(*)[num])array`
2. `(long long(*)[20])A._M_impl._M_start`

```cpp
g++ Sol.cpp -Wall -std=c++23 -g -Wl,-stack_size -Wl,0x20000000 -o Sol -DLOCAL
```