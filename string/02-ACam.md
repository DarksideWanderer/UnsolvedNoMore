# Ac自动机

```cpp
vector<long long>Ans;
vector<int>Pos;
struct AcAutomatons{
	struct Nodes{
		int fail,siz;
		std::array<int,26>Son;
		Nodes():fail(0),siz(0){
			std::fill(Son.begin(),Son.end(),0);
		}
	};
	vector<Nodes>N;
	vector<vector<int>>To;
	int tot;
	AcAutomatons(const int&l){Clear(l);}
	void Clear(const int&l){
		//Clr(N);
		N.resize(l+10);
		To.resize(l+10);
		N[0].fail=-1;
		tot=0;
	}
	void Insert(const std::string&S,int id){
		int now=0;
		for(auto s:S){
			if(N[now].Son[s-'a']==0)
				N[now].Son[s-'a']=++tot;
			now=N[now].Son[s-'a'];
		}
		Pos[id]=now;
	}
	void Build(){
		std::queue<int,std::list<int>>Q;
		for(int i=0;i<=25;i++)
			if(N[0].Son[i])N[N[0].Son[i]].fail=0,Q.push(N[0].Son[i]);
		while(!Q.empty()){
			int fr=Q.front();Q.pop();
			for(int i=0;i<=25;i++){
				if(N[fr].Son[i]){
					N[N[fr].Son[i]].fail=N[N[fr].fail].Son[i];
					Q.push(N[fr].Son[i]);
				}
				else N[fr].Son[i]=N[N[fr].fail].Son[i];
			}
		}
	}
	void BuildT(){
		rep(i,1,tot)
			To[N[i].fail].push_back(i);
	}
	void Query(const std::string&S){
		int now=0;
		for(auto s:S){
			now=N[now].Son[s-'a'];
			Ans[now]++;
		}
	}
	void Dfs(int from){
		for(auto to:To[from]){
			Dfs(to);
			Ans[from]+=Ans[to];
		}
	}
};AcAutomatons acam(210000);

void Main(int Case){
	Ans.resize(210000);
	int n;InPut(n);
	Pos.resize(n+1);
	
	for(int i=1;i<=n;i++){
		std::string S;
		InPut(S);
		acam.Insert(S,i);
	}
	
	std::string T;
	InPut(T);
	acam.Build();
	acam.BuildT();
	acam.Query(T);
	acam.Dfs(0);
	
	for(int i=1;i<=n;i++)
		OutPut(Ans[Pos[i]],'\n');
}
```