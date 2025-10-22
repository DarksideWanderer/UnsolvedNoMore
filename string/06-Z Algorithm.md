# Z函数

```cpp
int main(){
	scanf("%s",A+1);
	la=strlen(A+1);
	scanf("%s",B+1);
	lb=strlen(B+1);
	for(int i=1;i<=lb;i++)
		C[i]=B[i];
	for(int i=1;i<=la;i++)
		C[i+lb]=A[i];
	//拼接是常用的技巧 当然用 z of B 求出 z of A 也可行 
	Zi[1]=la+lb-1;
	for(int i=2,l=0,r=0;i<=la+lb;i++){
		if(i<=r&&Zi[i-l+1]<=r-i)
			Zi[i]=Zi[i-l+1];
		else{	
			Zi[i]=max(0,r-i);
			while(i+Zi[i]<=la+lb&&C[Zi[i]+1]==C[i+Zi[i]])
				Zi[i]++;
		}
		if(i+Zi[i]-1>r)l=i,r=i+Zi[i]-1;
	}
	ans=0;
	for(int i=1;i<=lb;i++)
		ans^=1ll*i*(min(Zi[i],lb-i+1)+1);
	printf("%lld\n",ans);
	ans=0;
	for(int i=lb+1;i<=lb+la;i++)
		ans^=1ll*(i-lb)*(min(Zi[i],lb)+1);
	printf("%lld\n",ans);
	return 0;
} 
```