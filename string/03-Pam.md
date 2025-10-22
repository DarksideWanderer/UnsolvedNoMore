# 回文自动机

```cpp
#include<cstdio>
#include<cstring>
#include<algorithm>
using namespace std;

template<int MaxN>
struct PAMs{
	char St[MaxN];int len;
	int Len[MaxN];//回文串长度
	int Son[MaxN][26];//转移边,加一个字符还是回文
	int Fail[MaxN];//最长回文后缀
	int Sum[MaxN];
	int Link[MaxN][26];//Link[x][c] 表示节点 x 所代表的的串向左扩展一个字符 c 找到的串.
	int last,cnt;
	PAMs(){
		cnt=1;
		Fail[0]=1;//偶回文中心
		for(int i=0;i<=25;i++)
			Link[1][i]=1;
		Fail[1]=1;//奇回文中心
		for(int i=0;i<=25;i++)
			Link[0][i]=1;
		Len[1]=-1;
	}
	inline void Add(char c){
		St[++len]=c;
	    int now=last,x=St[len]-'a';
	    if(St[len-Len[now]-1]!=St[len])now=Link[now][x];
	    if(!Son[now][x]) {
	        int np=++cnt; 
			Len[np]=Len[now]+2;
	        Fail[np]=Son[Link[now][x]][x];
	        memcpy(Link[np],Link[Fail[np]],sizeof(Link[Fail[np]]));
	        Link[np][St[len-Len[Fail[np]]]-'a']=Fail[np];
			Sum[np]=Sum[Fail[np]]+1;
	        Son[now][x]=np;
	    }
	    last=Son[now][x];
	}
};PAMs<510000>PAM;
int last;char c;
int main(){
	while((c=getchar())!='\r'){
		c=(c-97+last)%26+97;
		PAM.Add(c);
		printf("%d ",last=PAM.Sum[PAM.last]);
	}
	return 0;
}
```