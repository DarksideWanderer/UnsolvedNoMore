# Kmp

```cpp
int main(){
	scanf("%s",B+1);m=strlen(B+1);
	scanf("%s",A+1);n=strlen(A+1);
	int j;
	j=0;
	for(int i=2;i<=n;i++){
		while(j>0&&A[i]!=A[j+1])j=Next[j];
		if(A[i]==A[j+1])j++;
		Next[i]=j;
	}
	j=0;
	for(int i=1;i<=m;i++){
		while(j>0&&(B[i]!=A[j+1]||j==n))j=Next[j];
		if(B[i]==A[j+1])j++;
		if(j==n)printf("%d\n",i-n+1);
	}
	j=0;
	
	for(int i=1;i<=n;i++)
		printf("%d ",Next[i]);
	
	return 0;
}
```

## Kmp 自动机

```cpp
for(int i = 1, fail = 0; i <= n; i ++) {
        fail = nxt[fail][s[i]]; // 注意这一行不能和下一行互换
        nxt[i - 1][s[i]] = i;
        for(int j = 0; j < m; j ++)
                nxt[i][j] = nxt[fail][j];
}
```