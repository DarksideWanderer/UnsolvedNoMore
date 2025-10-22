# 二叉搜索树

```cpp
template<typename T>
struct ChxSet{
        typedef __gnu_pbds::tree<T,__gnu_pbds::null_type,std::less<T>,__gnu_pbds::rb_tree_tag,__gnu_pbds::tree_order_statistics_node_update> Type;
        Type S;
        void insert(T x){S.insert(x);}
        bool have(T x){return S.find(x)!=S.end();}
        bool erase(T x){return S.erase(x);}
        typename Type::iterator find(T x){return S.find(x);}
        typename Type::iterator erase(typename Type::iterator it){return S.erase(it);}
        int getrank(T x){return S.order_of_key(x);}//返回严格小于 x 的元素个数(以 Cmp_Fn 作为比较逻辑),即从 0 开始的排名
        typename Type::iterator select(int x){return S.find_by_order(x);}//返回 Cmp_Fn 比较的排名所对应元素的迭代器
        typename Type::iterator prev(T x){//<x 严格前驱
                int t=S.order_of_key(x);
                if(t==0)return S.end();
                else return S.find_by_order(x-1);
        }
        typename Type::iterator succ(T x){//>x 严格后继
                return S.upper_bound(x);
        }
        typename Type::iterator lower_bound(T x){return S.lower_bound(x);}
        typename Type::iterator upper_bound(T x){return S.upper_bound(x);}
        typename Type::iterator begin(){return S.begin();}
        typename Type::iterator end(){return S.end();}
        bool empty(){return S.empty();}
        size_t size(){return S.size();}
        
};

template<typename T,int MaxN>//MaxN:总共入队次数
struct ChxMultiSet{
        typedef __gnu_pbds::tree<std::pair<T,int>,__gnu_pbds::null_type,std::less<std::pair<T,int>>,__gnu_pbds::rb_tree_tag,__gnu_pbds::tree_order_statistics_node_update> Type;
        Type S;
        int index;
        void insert(T x){index++;S.insert({x,index});}
        bool have(T x) {
                int rank = S.order_of_key({x, 0});
                if (rank >= static_cast<int>(S.size())) return false;
                auto it = S.find_by_order(rank);
                return it!=S.end()&&it->first == x;
        }
        typename Type::iterator find(T x){
                int rank = S.order_of_key({x, 0});
                if (rank >= static_cast<int>(S.size())) return S.end();
                auto it = S.find_by_order(rank);
                if(it==S.end()||(*it).first!=x)return S.end();
                return it;
        }
        bool erase(T x){
                auto p=find(x);
                if(p!=S.end()){
                        S.erase(p);return true;
                }
                return false;
        }
        typename Type::iterator erase(typename Type::iterator it){return S.erase(it);}
        int getrank(T x){return S.order_of_key({x,0});}//返回严格小于 x 的元素个数(以 Cmp_Fn 作为比较逻辑),即从 0 开始的排名
        typename Type::iterator select(int x){return S.find_by_order(x);}//返回 Cmp_Fn 比较的排名所对应元素的迭代器
        typename Type::iterator prev(T x){//<x 严格前驱
                int t=S.order_of_key({x,0});
                if(t==0)return S.end();
                else return select(t-1);
        }
        typename Type::iterator succ(T x){//>x 严格后继
                return S.upper_bound({x,MaxN});
        }
        typename Type::iterator lower_bound(T x){return S.lower_bound({x,0});}
        typename Type::iterator upper_bound(T x){return S.upper_bound({x,MaxN});}
        typename Type::iterator begin(){return S.begin();}
        typename Type::iterator end(){return S.end();}
        bool empty(){return S.empty();}
        size_t size(){return S.size();}
};
```