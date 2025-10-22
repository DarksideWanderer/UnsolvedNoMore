# Manacher

```cpp
int main(){
	scanf("%s",St+1);n=strlen(St+1);
	Tmp[++len]='?';
	for(int i=1;i<=n;i++){
		Tmp[++len]='#';
		Tmp[++len]=St[i];
	}
	Tmp[++len]='#';
	Tmp[++len]='&';
	int mid=1,ans=0;
	Res[1]=0;
	for(int i=2;i<=len-2;i++){
		int right=mid+Res[mid];
		if(i<=right)
			Res[i]=min(i+Res[2*mid-i],right)-i;
		while(Tmp[i-Res[i]-1]==Tmp[i+Res[i]+1])
			++Res[i];
		if(i+Res[i]>=mid)mid=i;
		ans=max(ans,Res[i]);
	}
	printf("%d\n",ans);
	return 0;
}
```