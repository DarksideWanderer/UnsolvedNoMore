# Lucas

```cpp
template<typename T>
mint CalcCp(mtype p,TI<T>n,TI<T>m){
	if(m>n||m<0)return 0;
	return Mp(p,F[n],Powp<long long>(p,F[m],p-2),Powp<long long>(p,F[n-m],p-2));
}

template<typename T>
mint Lucasp(mtype p,TI<T>n,TI<T>m){
	if(m>n||m<0)return 0;
	if(m==0)return 1;
	return Mp(p,CalcCp<T>(p,n%p,m%p),Lucasp<T>(p,n/p,m/p));
}
```