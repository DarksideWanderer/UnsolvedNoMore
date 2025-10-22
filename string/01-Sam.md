# 后缀自动机

```cpp
long long ans=0;
struct SAutomatons{
	struct Nodes{
		int link,len,siz;
		std::array<int,26>Son;
		Nodes():link(0),len(0),siz(0){
			std::fill(Son.begin(),Son.end(),0);
		}
	};
	vector<Nodes>N;
	vector<vector<int>>To;
	int tot,last;
	SAutomatons(const int&l){Clear(l);}
	void Clear(const int&l){
		Clr(N);
		N.resize(2*l+10);//预防边界情况
		To.resize(2*l+10);//预防边界情况
		tot=last=0;
		N[last].link=-1;
	}
	void Add(int c){
		int now=last;N[last=++tot].siz=1;N[last].len=N[now].len+1;
		for(;now!=-1&&N[now].Son[c]==0;now=N[now].link)
			N[now].Son[c]=tot;
		if(now==-1)N[last].link=0;
		else{
			int tmp=N[now].Son[c];
			if(N[tmp].len==N[now].len+1)N[last].link=tmp;
			else{
				int newtmp=++tot;
				N[newtmp].len=N[now].len+1;
				std::copy(N[tmp].Son.begin(), N[tmp].Son.end(), N[newtmp].Son.begin());
				N[newtmp].link=N[tmp].link;
				N[tmp].link=newtmp;
				N[last].link=newtmp;
				for(;now!=-1&&N[now].Son[c]==tmp;now=N[now].link)N[now].Son[c]=newtmp;
			}
		}
	}
	void Build(){
		rep(i,1,tot)To[N[i].link].push_back(i);
	}
	void Dfs(int from){
		for(auto t:To[from]){
			Dfs(t);
			N[from].siz+=N[t].siz;
		}
		if(N[from].siz!=1){
			ans=std::max(ans,1ll*N[from].siz*N[from].len);
		}
	}
};
SAutomatons SAM(1000000);
int n;char St[1100000];
signed main(){
	scanf("%s",St+1);
	n=strlen(St+1);
	for(int i=1;i<=n;i++)SAM.Add(St[i]-'a');
	SAM.Build();
	SAM.Dfs(0);
	printf("%lld",ans);
	return 0;
}
```

# 广义后缀自动机

```cpp
struct GsAutomatons{
	struct Tries{
		struct Nodes{
			int dad;
			char which;
			std::array<int,26>Son;
			Nodes(){
				std::fill(Son.begin(),Son.end(),0);
			}
		};
		vector<Nodes>T;
		int cnt;
		Tries(const int&l){Clear(l);}
		void Clear(const int&l){
			cnt=0;
			//Clr(T);
			T.resize(l+10);
		}
	}Tr;
	struct Nodes{
		int link,len,pos;
		std::array<int,26>Son;
		Nodes():link(0),len(0),pos(0){
			std::fill(Son.begin(),Son.end(),0);
		}
	};
	vector<Nodes>N;
	int tot;
	GsAutomatons(const int&l):Tr(l){Clear(l);}
	void Clear(const int&l){
		//Tr.Clear(l);
		tot=0;
		Clr(N);
		N.resize(2*l+10);
		N[0].link=-1;
	}
	void Insert(const std::string&S){
		int now=0;
		for(auto s:S){
			if(!Tr.T[now].Son[s-'a']){
				Tr.T[now].Son[s-'a']=++Tr.cnt;
				Tr.T[Tr.cnt].dad=now;
				Tr.T[Tr.cnt].which=s-'a';
			}
			now=Tr.T[now].Son[s-'a'];
		}
	}
	int Add(int c,int last){
		int now=last;last=++tot;
		N[last].len=N[now].len+1;
		for(;now!=-1&&N[now].Son[c]==0;now=N[now].link)
			N[now].Son[c]=tot;
		if(now==-1)N[last].link=0;
		else{
			int tmp=N[now].Son[c];
			if(N[tmp].len==N[now].len+1)N[last].link=tmp;
			else{
				int newtmp=++tot;
				std::copy(N[tmp].Son.begin(), N[tmp].Son.end(), N[newtmp].Son.begin());
				N[newtmp].len=N[now].len+1;
				N[newtmp].link=N[tmp].link;
				N[tmp].link=newtmp;
				N[last].link=newtmp;
				for(;now!=-1&&N[now].Son[c]==tmp;now=N[now].link)N[now].Son[c]=newtmp;
			}
		}
		return last;
	}
	
	void Build(){
		std::queue<int,std::list<int>>Q;
		for(int i=0;i<=25;i++)
			if(Tr.T[0].Son[i])Q.push(Tr.T[0].Son[i]);
		while(!Q.empty()){
			int from=Q.front();Q.pop();
			N[from].pos=Add(Tr.T[from].which,N[Tr.T[from].dad].pos);
			for(int i=0;i<=25;i++)
				if(Tr.T[from].Son[i])Q.push(Tr.T[from].Son[i]);
		}
	}
};GsAutomatons GSAM(1000010);
void Main(int Case){
	int n;InPut(n);
	std::string S;
	for(int i=1;i<=n;i++){
		InPut(S);
		GSAM.Insert(S);
	}
	GSAM.Build();
	long long ans=0;
	for(int i=1;i<=GSAM.tot;i++)
		ans+=GSAM.N[i].len-GSAM.N[GSAM.N[i].link].len;
	OutPut(ans,'\n');
	OutPut(GSAM.tot+1,'\n');
}
```