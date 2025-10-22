# 分治 FFT

```cpp
void InitNtt(const int&L){
    for(int i=1,t=1;i<L;i<<=1,t++){
        Pw[t]=Pow(g,(Mod-1)/(i<<1));
        IPw[t]=Pow(Pw[t],Mod-2);
    }
}
void Ntt(vector<int>&Ar,int lim,int len,bool flag=false){
    vector<int>Rev(lim);
    for(int i=1;i<lim;i++)
        Rev[i]=(Rev[i>>1]>>1)|((i&1)<<(len-1));
    for(int i=1;i<lim;i++)
        if(i<Rev[i])std::swap(Ar[i],Ar[Rev[i]]);
    for(int i=1,t=1;i<lim;i<<=1,t++){
        int T=!flag?Pw[t]:IPw[t];
        for(int j=0;j<lim;j+=(i<<1)){
            for(int k=0,W=1;k<i;k++,W=M(W,T)){
                int x=Ar[j+k],y=M(W,Ar[j+k+i]);
                Ar[j+k]=A(x,y);
                Ar[j+k+i]=A(x,N(y));
            }
        }
    }
    if(!flag)return ;
    int I=Pow(lim,Mod-2);
    for(int i=0;i<lim;i++)Ar[i]=M(Ar[i],I);
}
vector<int>F(200000),G(200000),AA(200000),BB(200000);
void Cdq(int L,int R,int len){
    if(L==R)return ;
    int MM=(L+R)>>1;
    Cdq(L,MM,len-1);
    int lim=(1<<len);
    std::copy(F.begin()+L,      F.begin()+MM+1,AA.begin());
    std::fill(AA.begin()+MM-L+1,AA.begin()+lim,0);
    std::copy(G.begin(),        G.begin()+R-L+1,BB.begin());
    Ntt(AA,lim,len);Ntt(BB,lim,len);
    for(int i=0;i<lim;i++)BB[i]=M(AA[i],BB[i]);
    Ntt(BB,lim,len,true);
    for(int i=MM+1;i<=R;i++)F[i]=A(F[i],BB[i-L]);
    Cdq(MM+1,R,len-1);
}
int main(){
    int n;
    InPut(n);
    for(int i=1;i<=n-1;i++)
        InPut(G[i]);
    F[0]=1;
    int len=0,lim=1;
    while(lim<n-1)lim<<=1,len++;
    InitNtt(lim);
    Cdq(0,lim-1,len);
    for(int i=0;i<=n-1;i++)
        OutPut(F[i],' ');
    return 0;
}
```