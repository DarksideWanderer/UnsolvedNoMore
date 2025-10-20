# Min Cost Max Flow

Spfa

```cpp
namespace MCMF{
	using flowtype=long long;
	using costtype=long long;
	using std::vector;
	struct Graphs{
		vector<int>Head,Cur;
		vector<costtype>Dist;
		vector<bool>Vis;
		struct Edges{
			int to,nxt;
			flowtype flow;
			costtype cost;
			Edges(int _to=0,int _nxt=-1,flowtype _flow=0,costtype _cost=0):
				to(_to),nxt(_nxt),flow(_flow),cost(_cost){}
		};
		vector<Edges>Er;
		int cnt,tot,src,snk;
		Graphs(){clear();}
		void init(int _n,int _src,int _snk){
			tot=_n;src=_src;snk=_snk;
			Head.resize(_n,-1);
			Cur.resize(_n);
			Dist.resize(_n);
			Vis.resize(_n);
		}
		void clear(){
			cnt=0;
			Clear(Head);Clear(Er);
		}
		void insert(int u,int v,flowtype f,costtype c){
			Er.push_back((Edges){v,Head[u],f,c});
			Head[u]=cnt++;
		}
	};
	const long long Inf=1e18;
	bool Spfa(Graphs&g){
		std::fill(all(g.Dist), Inf);
		std::fill(all(g.Vis), false);
		std::queue<int>Q;
		Q.push(g.src); g.Dist[ g.src ] = 0; g.Vis[ g.src ] = true;
		while(!Q.empty()){
			auto fr=Q.front();Q.pop();
			g.Cur[fr] = g.Head[fr];
			g.Vis[fr] = false; 
			gep(k, fr, g.Head, g.Er){
				auto flow = g.Er[k].flow;
				if(! (flow>0) )continue;
				auto to = g.Er[k].to;
				auto cost = g.Er[k].cost;
				if(g.Dist[to] > g.Dist[fr] + cost){
					g.Dist[to] = g.Dist[fr] + cost;
					if(!g.Vis[to]){
						g.Vis[to] = true;
						Q.push(to);
					}
				}
			}
		}
		return g.Dist[g.snk] != Inf;
	}
	flowtype Dfs(Graphs&g, int fr, flowtype f) {
		if(fr == g.snk) return f;
		flowtype test, ret = 0;
		g.Vis[fr] = true;
		for(auto &k = g.Cur[fr]; k != -1; k = g.Er[k].nxt){
			auto to = g.Er[k].to;
			auto flow = g.Er[k].flow;
			auto cost = g.Er[k].cost;
			if(!g.Vis[to] && flow > 0 && g.Dist[to] == g.Dist[fr] + cost) {
				test = Dfs(g, to, std::min(flow, f-ret));
				ret += test;
				g.Er[k].flow -= test;
				g.Er[k^1].flow += test;
				if(f == ret){
					g.Vis[fr] = false;
					return f;
				}
			}
		}
		return ret;
	}
}
/*Main*/
while(MCMF::Spfa(g)){
	test=MCMF::Dfs(g,s,Inf);
	ansf+=test;
	ansc+=g.Dist[t]*test;
}
```

Dijkstra (没有负圈的情况下)

```cpp
namespace MCMF{
	using flowtype=long long;
	using costtype=long long;
	using std::vector;
	struct Graphs{
		vector<int>Head;
		vector<costtype>Dist,High;
		vector<bool>Vis;
		struct Edges{
			int to,nxt;
			flowtype flow;
			costtype cost;
			Edges(int _to=0,int _nxt=-1,flowtype _flow=0,costtype _cost=0):
				to(_to),nxt(_nxt),flow(_flow),cost(_cost){}
		};
		vector<Edges>Er;
		int cnt,tot,src,snk;
		Graphs(){clear();}
		void init(int _n,int _src,int _snk){
			tot=_n;src=_src;snk=_snk;
			Head.resize(_n,-1);
			Dist.resize(_n);
			High.resize(_n,0);
			Vis.resize(_n);
		}
		void clear(){
			cnt=0;
			Clear(Head);Clear(Er);Clear(High);
		}
		void insert(int u,int v,flowtype f,costtype c){
			Er.push_back((Edges){v,Head[u],f,c});
			Head[u]=cnt++;
		}
	};
	const long long Inf=1e18;
	
	inline costtype Calc(Graphs&g,const int&k){
		return g.Er[k].cost+g.High[g.Er[k^1].to]-g.High[g.Er[k].to];
	}
	bool Dijkstra(Graphs&g){
		std::fill(all(g.Dist), Inf);
		std::fill(all(g.Vis), false);
		
		std::priority_queue<std::pair<costtype,int>>Q;
		Q.push({0,g.src}); 
		g.Dist[ g.src ] = 0;
		
		while(!Q.empty()){
			auto fr=Q.top().second;Q.pop();
			if(g.Vis[fr])continue;
			g.Vis[fr] = true; 
			gep(k, fr, g.Head, g.Er){
				auto flow = g.Er[k].flow;
				auto to = g.Er[k].to;
				if(flow&&g.Dist[to] > g.Dist[fr] + Calc(g,k)){
					g.Dist[to] = g.Dist[fr] + Calc(g,k);
					Q.push({-g.Dist[to],to});
				}
			}
		}
		return g.Dist[g.snk] != Inf;
	}
	flowtype Dfs(Graphs&g,int fr, flowtype f) {
		if(fr == g.snk) return f;
		flowtype test, ret = 0;
		g.Vis[fr] = true;
		for(auto k = g.Head[fr]; k != -1; k = g.Er[k].nxt){
			auto to = g.Er[k].to;
			auto flow = g.Er[k].flow;
			if(!g.Vis[to] && flow > 0 && g.Dist[to] == g.Dist[fr] + Calc(g,k)) {
				test = Dfs(g,to, std::min(flow, f-ret));
				ret += test;
				g.Er[k].flow -= test;
				g.Er[k^1].flow += test;
				if(f == ret){
					g.Vis[fr] = false;
					return f;
				}
			}
		}
		return ret;
	}
}
/*Main*/
while(MCMF::Dijkstra(g)){
	std::fill(all(g.Vis), false);
	test=MCMF::Dfs(g,s,MCMF::Inf);
	for(int i=0;i<g.tot;i++)
		if(g.Dist[i]!=MCMF::Inf)g.High[i]+=g.Dist[i];
	ansf+=test;
	ansc+=g.High[t]*test;
}
```