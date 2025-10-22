# LinkCutTree

```cpp
struct LinkCutTrees{
        #define MaxN 410000
        int Son[MaxN][2],Dad[MaxN];
        int Sum[MaxN],Data[MaxN];
        bool Rev[MaxN];
        void PushUp(int now){
                //Size[now]=Size[Son[now][0]]+Size[Son[now][1]]+1;
                Sum[now]=Sum[Son[now][0]]^Sum[Son[now][1]]^Data[now];
        }
        void PushDown(int now){
                if(Rev[now]){
                        if(Son[now][0]){
                                Rev[Son[now][0]]^=1;
                                std::swap(Son[Son[now][0]][0],Son[Son[now][0]][1]);
                        }
                        if(Son[now][1]){
                                Rev[Son[now][1]]^=1;
                                std::swap(Son[Son[now][1]][0],Son[Son[now][1]][1]);
                        }
                        Rev[now]=false;
                }
        }
        bool NotRoot(int now){return Son[Dad[now]][0]==now||Son[Dad[now]][1]==now;}
        bool Which(int now){return Son[Dad[now]][1]==now;}
        void Union(int dad,int son){if(son!=0)Dad[son]=dad;}
        void Rotate(int now){
                int dad=Dad[now];bool flag=Which(now);
                Son[dad][flag]=Son[now][!flag];
                Union(dad,Son[now][!flag]);
                if(NotRoot(dad))Son[Dad[dad]][Which(dad)]=now;//虚边不能乱接 
                Union(Dad[dad],now);
                Son[now][!flag]=dad;
                Union(now,dad);
                PushUp(dad);PushUp(now);
                return;
        }
        void SplayInit(int now){
                if(NotRoot(now))SplayInit(Dad[now]);
                PushDown(now);
        }
        void Splay(int now){
                SplayInit(now);
                for(int dad=Dad[now];NotRoot(now);Rotate(now),dad=Dad[now])
                        if(NotRoot(dad))Rotate(Which(now)^Which(dad)?now:dad);
        }
        void Access(int now){
                for(int tmp=0;now;tmp=now,now=Dad[now])//son比now深,所以now的右儿子为son 
                        Splay(now),Son[now][1]=tmp,PushUp(now);
        }
        void MakeRoot(int now){
                Access(now);Splay(now);//now到根之后,没有左子树,深度最深 
                Rev[now]^=1;//翻转之后,没有右子树,深度最浅,即为根 
                std::swap(Son[now][0],Son[now][1]);
        }
        int FindRoot(int now){
                Access(now);Splay(now);
                while(Son[now][0])PushDown(now),now=Son[now][0];//找一个深度最小的点就是根 
                Splay(now);
                return now;
        }
        bool Link(int x,int y){
                MakeRoot(x);
                if(FindRoot(y)==x)return false;//在一棵树内 
                Dad[x]=y;
                return true;
        }
        void Split(int x,int y){//把 x-y 拉成一条链 
                MakeRoot(x);Access(y);Splay(y);
        //把 y 当成 Splay 根,然后就可以通过 y 询问链信息 
        }
        bool Cut(int x,int y){
                MakeRoot(x);
                if(FindRoot(y)!=x||Dad[y]!=x||Son[y][0])return false;
        //建议手模
                Dad[y]=0;Son[x][1]=0;
                return true;
        }
        int Query(int x,int y){Split(x,y);return Sum[y];}
        void Modify(int x,int v){Access(x);Splay(x);Data[x]=v;PushUp(x);}
        #undef MaxN
};
```