# Tarjan 

## 点双连通分量对边染色

```cpp
static std::function<void(int,int)> Tarjan=[&](int from,int root)->void {
    dfn[from]=low[from]=++tot;
    insta[from]=true;
    for(auto to:To[from]){
        if(!dfn[to]){
            int siz=sta.size();
            Tarjan(to,root);
            low[from]=std::min(low[from],low[to]);
            if(dfn[from]<=low[to]){
                do{
                    auto now=sta.back();sta.pop_back();
                    insta[now.first]=false;
                    insta[now.second]=false;
                }while((int)sta.size()!=siz);
                insta[from]=true;
            }
        }
        else {
            low[from]=std::min(low[from],dfn[to]);
            if(insta[to])sta.push_back({from,to});
        }
    }
};
for(int i=1;i<=n;i++)
    if(!dfn[i])Tarjan(i,i);
```

## 点双连通分量对点染色

```cpp
static std::function<void(int, int)> Tarjan = [&](int from, int root) -> void {
	Dfn[from] = Low[from] = ++tot;
	S.push_back(from);
	if (from == root && G[from].empty()){
		VDcc[++vdcc].push_back(from);
		return;
	}
	int flag = 0;
	for (int to : G[from]){
		if (!Dfn[to]){
			Tarjan(to, root);
			Low[from] = std::min(Low[from], Low[to]);
			if (Dfn[from] <= Low[to]){
				flag++;
				if (from != root || flag > 1){
					Cut[from] = true;
				}
				vdcc++;
				int now;
				do{
					now = S.back();
					S.pop_back();
					VDcc[vdcc].push_back(now);
				} while (now != to);
				VDcc[vdcc].push_back(from);
			}
		}
		else{
			Low[from] = std::min(Low[from], Dfn[to]);
		}
	}
};
std::vector<int> Tree[2 * MaxN];
std::vector<int> Id(MaxN, 0);
int num = 0;
inline void Insert(std::vector<int> adj_list[], int u, int v){
	adj_list[u].push_back(v);
}
inline void Work(){
	num = vdcc;
	for (int i = 1; i <= n_nodes; i++){
		if (Cut[i]){
			Id[i] = ++num;
		}
	}
	for (int i = 1; i <= vdcc; i++){
		for (int v : VDcc[i]){
			if (Cut[v]){
				Insert(Tree, i, Id[v]);
				Insert(Tree, Id[v], i);
			}
			else{
				Belong[v] = i;
			}
		}
	}
}
```

## 边双连通分量

```cpp
int Belong[MaxN],edcc;
inline void Dfs(int from){
	Belong[from]=edcc;
	for(rgeister int k=G.Last[from];k!=-1;k=G.Next[k]){
		if(Belong[G.To[k]]||Bridge[k])continue;
		Dfs(G.To[k]);
	}
}

Graphs<MaxN,MaxN>Tree;

inline void Work(){
	for(register int i=1;i<=n;i++){
		if(!Belong[i]){
			edcc++;
			Dfs(i);
		}
	}
	for(register int i=0;i<G.cntm;i++){
		if(Belong[G.To[i^1]]==Belong[G.To[i]])continue;
		Insert(Tree,Belong[G.To[i^1]],Belong[G.To[i]]);
	}
}
```

## 强连通分量

```cpp
Graphs<MaxN,MaxM>G;
Stack<int,MaxN>S;
vector<int>Scc[MaxN];
int Dfn[MaxN],Low[MaxM],tot,scc;
bool Visit[MaxN];
inline void Tarjan(int from){
	Dfn[from]=Low[from]=++tot;
	S.Push(from);Visit[from]=true;
	for(register int k=G.Last[from];k!=-1;k=G.Next[k]){
		if(!Dfn[G.To[k]]){
			Tarjan(G.To[k]);
			Low[from]=Min(Low[from],Low[G.To[k]]);
		}
		else if(Visit[G.To[k]])
			Low[from]=Min(Low[from],Dfn[G.To[k]]);
	}
	if(Dfn[from]==Low[from]){
		scc++;int now;
		do{
			now=S.Top();S.Pop();Visit[now]=false;
			Belong[now]=scc;Scc[scc].push_back(now);
		}while(from!=now);
	}
}
Graphs<MaxN,MaxN>Tree;
inline void Work(){
	for(register int i=1;i<=n;i++)
		for(register int k=G.Last[i];k!=-1;k=G.Next[k]){
			if(Belong[i]==Belong[G.To[k]])continue;
			Insert(Tree,Belong[i],Belong[G.To[k]]);
		}
}
```