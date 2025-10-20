# Max Flow

```cpp
namespace Dinic{
	using flowtype=long long;
	using std::vector;
	struct Graphs{
		vector<int>Head,Cur,High;
		struct Edges{
			int to,nxt;
			flowtype flow;
			Edges(int _to=0,int _nxt=-1,flowtype _flow=0):to(_to),nxt(_nxt),flow(_flow){}
		};
		vector<Edges>Er;
		int cnt,tot,src,snk;
		Graphs(){clear();}
		void init(int _n,int _src,int _snk){
			tot=_n;src=_src;snk=_snk;
			Head.resize(_n,-1);
			Cur.resize(_n);
			High.resize(_n);
		}
		void clear(){
			cnt=0;
			Clear(Head);Clear(Er);
		}
		void insert(int u,int v,flowtype f){
			Er.push_back((Edges){v,Head[u],f});
			Head[u]=cnt++;
		}
	};
	bool Bfs(Graphs&g){
		std::fill(all(g.High),0);
		std::queue<int>Q;
		Q.push(g.src);
		g.High[g.src]=1;
		while(!Q.empty()){
			int fr=Q.front();Q.pop();
			g.Cur[fr]=g.Head[fr];
			gep(k,fr,g.Head,g.Er){
				int to=g.Er[k].to;
				if(g.Er[k].flow>0&&g.High[to]==0){
					g.High[to]=g.High[fr]+1;
					if(to==g.snk)return true;
					Q.push(to);
				}
			}
		}
		return false;
	}
	flowtype Dfs(Graphs&g,int fr,flowtype f){
		if(fr==g.snk)return f;
		flowtype test,ret=0;
		for(auto&k=g.Cur[fr];k!=-1;k=g.Er[k].nxt){
			auto to=g.Er[k].to;
			auto flow=g.Er[k].flow;
			if(flow>0&&g.High[to]==g.High[fr]+1){
				test=Dfs(g,to,std::min(flow,f-ret));
				ret+=test;
				g.Er[k].flow-=test;
				g.Er[k^1].flow+=test;
				if(f==ret)return f;
			}
		}
		g.High[fr]=0;
		return ret;
	}
}
```