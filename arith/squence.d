/++
+ レンジを扱ったり、数列を扱ったりするためのモジュール
+/

module mydutil.arith.squence;

import std.functional;
import std.traits;
import std.algorithm;
import std.math;
import std.range;
import std.stdio    : writeln,write;
import std.conv;
import std.array    : array, popFront, popBack;
import std.typetuple:staticMap, allSatisfy, NoDuplicates;
import std.typecons    :Tuple,tuple;

import mydutil.arith.method;
import mydutil.util.utility;
import mydutil.util.tmp;

version(unittest){
    pragma(lib,"mydutil");
    
    void main(){
        writeln("Unittest Done");
    }
}

///Rangeの総和
alias reduce!"a + b" sum;

deprecated{
/++predを満たし、startから始まる数列を返します。ただし、startがpredを満たさない場合には、start以上で、predを満たす最小値が初項になります。
Example:
---------------------------------------------------------------------
//0から始まる偶数のみの無限数列[0,2,4,6,8,...]
auto a = satisfysquence!"!(a&1)"(0);
---------------------------------------------------------------------
+/
auto satisfysquence(alias pred,T)(T start){
    return filter!pred(recurrence!"a[n-1]　+　1"(start));
}
}


/++複数の配列を総当り的にたどる前進レンジを構築します。<br/>
引数は可変長で、ランダムアクセスレンジならどのようなものでも受け取れます。<br/>
もし、引数のレンジでfrontの返り値がすべて等しく、Array=trueならこのレンジのfrontの値は配列になります。<br/>
そうでないなら、このレンジのfrontの型は引数のレンジのfrontの返り値の列挙のタプル<b>std.typecons.Tuple!(staticMap!(ElementType,T))</b>になります。

Example:
---------------------------------------------------------------------
auto perm = exhaustive([1,2],[1,2],[1,2]);
assert(equal(perm,[[1,1,1],[1,1,2],[1,2,1],[1,2,2],[2,1,1],[2,1,2],[2,2,1],[2,2,2]]));
    
auto p2 = exhaustive([1,2],["ab","cd"],[1.2,3.4]);        //レンジの要素が違うなら、タプルにして返す。
assert(equal(p2,[tuple(1,"ab",1.2),tuple(1,"ab",3.4),tuple(1,"cd",1.2),tuple(1,"cd",3.4),
     tuple(2,"ab",1.2),tuple(2,"ab",3.4),tuple(2,"cd",1.2),tuple(2,"cd",3.4)]));
---------------------------------------------------------------------
+/
Exhaustive!(returnArray,T) exhaustive(bool returnArray = true,T...)(T a)if(T.length > 1 && allSatisfy!(isRandomAccessRange,T)){
    return Exhaustive!(returnArray,T)(a);
}
unittest{
    auto perm = exhaustive([1,2],[1,2],[1,2]);
    assert(equal(perm,[[1,1,1],[1,1,2],[1,2,1],[1,2,2],[2,1,1],[2,1,2],[2,2,1],[2,2,2]]));
    
    auto p2 = exhaustive([1,2],["ab","cd"],[1.2,3.4]);
    assert(equal(p2,[tuple(1,"ab",1.2),tuple(1,"ab",3.4),tuple(1,"cd",1.2),tuple(1,"cd",3.4),
                     tuple(2,"ab",1.2),tuple(2,"ab",3.4),tuple(2,"cd",1.2),tuple(2,"cd",3.4)]));
}

///ditto
struct Exhaustive(bool returnArray = true, T...)if(T.length > 1 && allSatisfy!(isRandomAccessRange,T)){
private:
    T _val;                            //要素の集合
    uint[T.length] _idx;            //現在の最初要素の位置
    uint[T.length] _lens;            //レンジの長さ達
    uint _idxNum = 0;
    uint _length;        
    bool _EndFlag = false;

public:

    this(T a){
        _length = 1;
        foreach(i, t; T){
            _val[i] = a[i];
            _idx[i] = 0;
            _lens[i] = a[i].length;
            _length *= _lens[i];
        }
    }
    
    @property void popFront(){
        if(empty)return;
        ++_idxNum;
        /*
        for(int i=_val.length-1;i>=0;--i){
            ++_idx[i];
            if(_idx[i] >= _lens[i]){
                _idx[i] = 0;
                if(i == 0 && (_idxNum == _length))
                    _EndFlag =true;
            }
            else
                break;
        }
        */
        foreach_reverse(i, ref e; _idx){
            ++e;
            if(e >= _lens[i]){
                e = 0;
                if(i == 0 && (_idxNum == _length))
                    _EndFlag =true;
            }
            else
                break;
        }
    }
    
    //配列で返すか、タプルで返すかの選択
    static if(returnArray && NoDuplicates!(staticMap!(ElementType,T)).length == 1){
        @property ElementType!(T[0])[T.length] front(){
            if(empty){
                typeof(return) dst;
                return dst;
            }
            typeof(return) dst;
            /*foreach(i; IotaTuple!(0, T.length))
                dst[i] = _val[i][_idx[i]];*/
            foreach(i, E; T)
                dst[i] = _val[i][_idx[i]];
            
            return dst;
        }
    }else{
        @property Tuple!(staticMap!(ElementType,T)) front(){
            if(empty){
                typeof(return) dst;
                return dst;
            }
            typeof(return) dst;
            /*
            foreach(i;IotaTuple!(0,T.length))
                dst[i] = _val[i][_idx[i]];
            */
            foreach(i, E; T)
                dst[i] = _val[i][_idx[i]];
            
            return dst;
        }
    }
    
    @property bool empty(){
        return (_idxNum >= _length) || _EndFlag;
    }

    typeof(this) opAssign(typeof(this) src){
        _val = src._val;
        _idx = src._idx;
        _idxNum = src._idxNum;
        _length = src._length;
        _lens = src._lens;
        _EndFlag = src._EndFlag;
        return this;
    }
    
    @property
    typeof(this) save(){
        typeof(this) dst;
        foreach(i, a; dst._val)
            dst._val[i] = _val[i].save;
        dst._idx = _idx;
        dst._lens= _lens;
        dst._idxNum = _idxNum;
        dst._length = _length;
        dst._EndFlag = _EndFlag;
        return dst;
    }
}


/++複数の配列または単一の配列のインデックスを組み合わせ的に辿るレンジです。<br/>
複数配列の場合は必ず辞書順になるとは限りません。引数は可変長で、ランダムアクセスレンジならどのようなものでも受け取れます。<br/>
もし、引数のレンジでfrontの返り値がすべて等しく、Array=trueならこのレンジのfrontの値は配列になります。<br/>
そうでないなら、このレンジのfrontの型は引数のレンジのfrontの返り値の列挙のタプル<b>std.typecons.Tuple!(staticMap!(ElementType,T))</b>になります。

Example:
---------------------------------------------------------------------
auto comb = combination([1,2,3], [1,2]);
assert(equal(comb, [[1,1], [2,1], [3,1], [2,2], [3,2]]));

auto comb2 = combination([1,2], [1,2,3]);
assert(equal(comb2, [[1,1], [1,2], [1,3], [2,2], [2,3]]));

auto comb3 = combination([1,2,3],["a","b","c"]);
assert(equal(comb3, [tuple(1,"a"), tuple(1,"b"), tuple(1,"c"),
     tuple(2,"b"), tuple(2,"c"), tuple(3,"c")]));

auto comb4 = combination([1,2,3],2);    //3個から2個選ぶ
assert(equal(array(comb4), [[1,2],[1,3],[2,3]]));

auto comb5 = combination([1,2,3,4],4);
assert(equal(comb5, [[1,2,3,4]]));

auto comb6 = combination([1,2,3,4],2);
assert(equal(comb6, [[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]));

auto comb7 = combination([1,2,3,4],1);
assert(equal(comb7, [[1],[2],[3],[4]]));
---------------------------------------------------------------------
+/
auto combination(bool returnArray = true, T...)(T a)if(T.length > 1){
    static if(allSatisfy!(isRandomAccessRange, T))
        return Combination!(returnArray, false, T)(a);
    else static if(isRandomAccessRange!(T[0])){
        static if(T.length == 1)
            return Combination!(true, true, T[0])(a, a.length);
        else static if(T.length == 2 && is(T[1]:int))
            return Combination!(true, true, T[0])(a);
        else
            static assert(0, "combination need some ranges ,or a range and int");
    }
    else
        static assert(0, "combination need some ranges ,or a range and int");
}

///ditto
struct Combination(bool returnArray, bool homogeneous:false, T...){
private:
    T _val;                        //要素の集合
    uint[T.length] _idx;        //現在の最初要素の位置。ソートされていない
    uint[T.length] _lengths;    //初期ではそれぞれの配列の最後の要素のインデックスが格納されている。ソートされていない
    bool _empty;                //終了しているか
    uint[T.length] _sort;        //ソートされた後の順番が入っている
    
public:
    this(T src){
        uint[] tmp;
        foreach(i, E; T){
            _val[i] = src[i];
            _idx[i] = 0;
            _lengths[i] = src[i].length;
            tmp ~= i;
        }
        sort!"a[2] < b[2]"(zip(tmp, _idx.dup, _lengths.dup));
        
        /*
        for(int i = 0; i < T.length; ++i)
            _sort[tmp[i]] = i;
        */
        foreach(i, e; tmp)
            _sort[e] = i;
    }
    
    @property bool empty(){
        if(_empty)return true;
        /*for(int i = 0; i < T.length; ++i)
            if(_idx[i] < _lengths[i])
                return false;*/
        foreach(i, e; _idx)
            if(e < _lengths[i])
                return false;
        
        return true;
    }
    
    @property void popFront(){
        if(empty)return;
        /+
        for(int i = T.length - 1; i >= 0; --i){
            if(_idx[_sort[i]]+1 == _lengths[_sort[i]]){
                if(i == 0){
                    _empty = true;
                    return;
                }
                continue;
            }else{
                //この要素以下のもののインデックスをこれと同じにする。
                ++_idx[_sort[i]];
                /+
                for(int j = i + 1; j < T.length; ++j)
                    _idx[_sort[j]] = _idx[_sort[i]];
                +/
                foreach(ref e; _idx[i..$])
                    e = _idx[_sort[i]];
                
                break;
            }
        }
        +/
        foreach_reverse(i, se; _sort){
            if(_idx[se]+1 == _lengths[se]){
                if(i == 0){
                    _empty = true;
                    return;
                }
                continue;
            }else{
                //この要素以下のもののインデックスをこれと同じにする。
                ++_idx[se];
                
                foreach(e; _sort[i..$])
                    _idx[e] = _idx[se];
                
                break;
            }
        }
    }
    
    static if(returnArray && NoDuplicates!(staticMap!(ElementType,T)).length == 1){
        @property ElementType!(T[0])[] front(){
            if(empty){
                typeof(return) dst;
                return dst;
            }
            
            typeof(return) dst;
            dst.length = T.length;
            foreach(i;IotaTuple!(0,T.length))
                dst[i] = _val[i][_idx[i]];
            return dst;
        }
    }else{
        @property Tuple!(staticMap!(ElementType,T)) front(){
            if(empty){
                typeof(return) dst;
                return dst;
            }
            
            typeof(return) dst;
            foreach(i;IotaTuple!(0,T.length))
                dst[i] = _val[i][_idx[i]];
            return dst;
        }
    }
    
    typeof(this) opAssign(typeof(this) src){
        _val = src._val;
        _idx = src._idx.dup;
        _empty = empty;
        _sort = _sort.dup;
        return this;
    }
}
unittest{
    auto comb = combination([1,2,3], [1,2]);
    assert(equal(comb, [[1,1], [2,1], [3,1], [2,2], [3,2]]));
    
    auto comb2 = combination([1,2], [1,2,3]);
    assert(equal(comb2, [[1,1], [1,2], [1,3], [2,2], [2,3]]));
    
    auto comb3 = combination([1,2,3],["a","b","c"]);
    assert(equal(comb3, [tuple(1,"a"), tuple(1,"b"), tuple(1,"c"),
                         tuple(2,"b"), tuple(2,"c"), tuple(3,"c")]));
}

struct Combination(bool returnArray, bool homogeneout:true, T){
private:
    T _range;
    size_t[] _idx;
    size_t[] _length;
    bool _empty;

public:
    this(T src, size_t r){
        _range = src;
        _idx.length = r;
        _length.length = r;
        
        assert(_range.length >= r);
        
        /*
        for(int i=0;i<r;++i){
            _length[i] = _range.length - (r-i) + 1;
            _idx[i] = i;
        }*/
        foreach(i; 0..r){
            _length[i] = _range.length - (r-i) + 1;
            _idx[i] = i;
        }
    }
    
    @property void popFront(){
        assert(!empty,"This range is empty.");
        ++_idx[$-1];
        /*
        for(int i=_idx.length-1;i>=0;--i){
            if(_idx[i] == _length[i]){
                if(i == 0){
                    _empty = true;
                    _idx[] = 0;
                }else
                    ++_idx[i-1];
            }else{
                for(int j=i;j<_idx.length;++j)
                    _idx[j] = _idx[i] + (j-i);
                break;
            }
        }*/
        foreach_reverse(i, ei; _idx){
            if(ei == _length[i]){
                if(i == 0){
                    _empty = true;
                    _idx[] = 0;
                }else
                    ++_idx[i-1];
            }else{
                foreach(j, ref ej; _idx[i..$])
                    ej = ei + j;
                break;
            }
        }
    }
    
    @property ElementType!(T)[] front(){
        assert(!empty,"This range is empty.");
        ElementType!(T)[] dst;
        /*
        for(int i=0;i<_idx.length;++i)
            dst ~= _range[_idx[i]];
        */
        foreach(e; _idx)
            dst ~= _range[e];
        
        return dst;
    }
    
    @property bool empty(){
        return _empty;
    }
    
    typeof(this) opAssign(typeof(this) src){
        _range = src._range;
        _idx = src._idx.dup;
        _length = src._length.dup;
        _empty = src._empty;
        return this;
    }
    
    @property
    typeof(this) save(){
        typeof(this) dst;
        dst._range = _range.save;
        dst._idx = _idx.dup;
        dst._length = _length.dup;
        dst._empty = _empty;
        return dst;
    }
    
}

unittest{
    auto comb4 = combination([1,2,3],2);
    assert(equal(array(comb4), [[1,2],[1,3],[2,3]]));
    
    auto comb5 = combination([1,2,3,4],4);
    assert(equal(comb5, [[1,2,3,4]]));
    
    auto comb6 = combination([1,2,3,4],2);
    assert(equal(comb6, [[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]));
    
    auto comb7 = combination([1,2,3,4],1);
    assert(equal(comb7, [[1],[2],[3],[4]]));
}

deprecated{
    /**関数型言語によくあるtakeWhileの実装です。レンジの先頭から連続したpredを満たす区間をレンジで返します。
    Example:
    ---------------------------------------------------------------------
    auto A = takeWhile(recurrence!"a[n-1]+1"(1), 5);
    assert(equal(A, [1,2,3,4]));
    auto B = takeWhile!("a<=b")(recurrence!"a[n-2]+a[n-1]"(1, 1), 34);
    assert(equal(B, [1,1,2,3,5,8,13,21,34]));
    ---------------------------------------------------------------------

    Deprecated: std.algorithm.untilを使用してください
    */
    TakeWhile!(pred, Range, T) takeWhile(alias pred="a < b", Range, T)(Range range, T end = 0){
        return TakeWhile!(pred, Range, T)(range, end);
    }

    ///ditto
    struct TakeWhile(alias pred, Range, T){
        Range _val;
        T _end;
        //alias toPredicate!(pred,ElementType!(Range),"binary") funcpred;
        alias binaryFun!pred funcpred;
        
        this(Range range, T end = 0){
            _val = range;
            _end = end;
        }
        
        @property
        void popFront(){
            if(empty)return;
            _val.popFront;    
        }
        
        @property
        auto front(){
            if(empty)assert(0,"this range is empty.");
            else return _val.front;
        }
        
        @property
        bool empty(){
            return (_val.empty || !funcpred(_val.front,_end));
        }
        
        typeof(this) opAssign(typeof(this) src){
            _val = src._val;
            _end = src._end;
            return this;
        }
        
        @property
        typeof(this) save(){
            return typeof(this)(_val,_end);
        }

    }
    unittest{
        import std.algorithm;
        import std.range;
        writeln("Unittest Start ",__LINE__);
        auto A = takeWhile(recurrence!"a[n-1]+1"(1),5);
        assert(equal(A,[1,2,3,4]));
        auto B = takeWhile!("a<=b")(recurrence!"a[n-2]+a[n-1]"(1,1),34);
        assert(equal(B,[1,1,2,3,5,8,13,21,34]));
        writeln("Unittest End ",__LINE__);
    }
}



/++aをBase進数の桁的に巡回させたものをすべて返す。
Example:
---------------------------------------------------------------------
assert(equal(rotation(123), [123,231,312]));
---------------------------------------------------------------------
+/
T[] rotation(uint Base = 10,T)(T a)if(__traits(isIntegral,T)){
    //まず桁ごとにくぎる
    T[] dst;
    auto digit = splitdigit!Base(a).reverse;
    for(int i=0;i<digit.length;++i)
        //dst ~= reduce!"a * "" + b"(digit[i..$]~digit[0..i]);
        dst ~= reduce!((a,b) => a * Base + b)(digit[i..$]~digit[0..i]);
    return dst;
}
unittest{
    import std.algorithm;
    writeln("Unittest Start ",__LINE__);
    assert(equal(rotation(123),[123,231,312]));
    writeln("Unittest End ",__LINE__);
}

deprecated{
    /**配列に格納されたレンジのすべての要素を一つ進める
    * Deprecated: ranges.map!(a => (a.popFront, a))を使用してください
    *
    * Example:
    * ---------------------------------------------------------------------
    int[][] arrays;
    for(int i=0; i<2; i++)
        arrays ~= [i+1];
    assert(equal(arrays.emptyAll, [false,false]));
    arrays.popFrontAll;
    assert(equal(arrays.emptyAll, [true,true]));
    * ---------------------------------------------------------------------
    */
    void popFrontAll(T)(ref T[] ranges){
        /*
        for(int i = 0; i < ranges.length; ++i)
            ranges[i].popFront;
        */
        foreach(ref e; ranges)
            e.popFront;
    }
}

deprecated{
    /**配列に格納されたレンジのすべての要素のfrontを配列にして返します
    Deprecated: ranges.map!"a.front"を使用してください
    
    Example:
    ---------------------------------------------------------------------
    int[][] arrays;
    for(int i=0; i<2; i++)
        arrays ~= [i+1];
    assert(equal(arrays.frontAll, [1,2]));
    ---------------------------------------------------------------------
    */
    ElementType!(T)[] frontAll(T)(ref T[] ranges){
        typeof(return) dst;
        for(int i=0;i<ranges.length;++i)
            dst ~= ranges[i].front;
        return dst;
    }
}

deprecated{
    /**配列に格納されたレンジのすべての要素についてemptyかどうか検証し、配列で返します。
    * Deprecated: ranges.map!"a.empty"としてください。
    *
    * Example:
    * ---------------------------------------------------------------------
    int[][] arrays;
    for(int i=0; i<2; i++)
        arrays ~= [i+1];
    assert(equal(arrays.emptyAll, [false,false]));
    arrays.popFrontAll;
    assert(equal(arrays.emptyAll, [true,true]));
    * ---------------------------------------------------------------------

    また、「配列中のどれか一つのレンジの要素が0であれば(empty == true)、trueを返す」ということを書きたい場合には以下のようにstd.algorithm.reduceを使い、
    ---
    if(reduce!"a || b"(ranges.emptyAll))
        //trueのときの処理
    ---
    などとします。
    */
    bool[] emptyAll(T)(ref T[] ranges){
        bool[] dst;
        for(int i=0;i<ranges.length;++i)
            dst ~= ranges[i].empty;
        return dst;
    }
}

/++ランダムアクセスレンジを受け取り、その中からn個取り出したときの順列を前進レンジで返します。ただし、無限レンジは受け取れません。順列の順番は辞書順で返します。repeatedにtrueを入れると、重複順列のレンジになります。また、n=0の時には個数はレンジの長さに等しくなります。
+ Example:
+ ---------------------------------------------------------------------
auto p1 = permutations([1,2,3],3);
assert(equal(p1,[[1,2,3],[1,3,2],[2,1,3],[2,3,1],[3,1,2],[3,2,1]]));

auto p2 = permutations([0,1,2],2);
assert(equal(p2,[[0,1],[0,2],[1,0],[1,2],[2,0],[2,1]]));

auto p3 = permutations!true([0,1,2],2);    
assert(equal(p3,exhaustive([0,1,2],[0,1,2])));

auto p4 = permutations!true([0,1,2]);
assert(equal(p4,exhaustive([0,1,2],[0,1,2],[0,1,2])));
+ ---------------------------------------------------------------------
+/
Permutations!(RARange,repeated) permutations(bool repeated = false,RARange)(RARange range,uint n = 0)/*if(isRandomAccessRange!RARange && !isInfinite!RARange)*/{
    if(n == 0)
        return Permutations!(RARange,repeated)(range,range.length);
    else
        return Permutations!(RARange,repeated)(range,n);
}

struct Permutations(RARange,bool repeated)/*if(isRandomAccessRange!RARange && !isInfinite!RARange)*/{
    RARange _range;
    int _length;
    int _n;
    int[] _set;
    bool _empty;
    
    this(RARange range,uint n){
        _range = range.save;
        _length = _range.length;
        _n = n;
        _set.length = n;
        for(int i=0;i<n;++i){
            static if(repeated){
                _set[i] = 0;
            }else{
                _set[i] = i;
            }
        }
    }
    
    @property void popFront(){
        _set[$-1] += 1;
        for(int i=_n-1;i>=0;--i){
            if(i == 0 && _set[i] == _length){
                _empty = true;
                return;
            }else if(_set[i] == _length && i != 0){
                _set[i] = 0;
                _set[i-1] += 1;
            }else{
                break;
            }
        }
        static if(!repeated){
            if(!matchnum())
                popFront();
        }
    }
    
    @property ElementType!(RARange)[] front(){
        typeof(return) dst;dst.length = _n;
        for(int i=0;i<_n;++i)
            dst[i] = _range[_set[i]];
        return dst;
    }
    
    @property bool empty(){
        return _empty || _set[0] == _length;
    }
    
    typeof(this) opAssign(typeof(this) src){
        _range = src._range.save;
        _length = src._length;
        _n = src._n;
        _set = src._set.dup;
        _empty = src._empty;
        return this;
    }
    
    @property
    typeof(this) save(){
        auto dst = typeof(this)(_range.save,_n);
        dst._length = _length;
        dst._set = _set.dup;
        dst._empty = _empty;
        return dst;
    }
    
    ///重複順列でなければ
    static if(!repeated){
        private:
            bool matchnum(){
                bool[] b;
                b.length = _length;
                /*
                for(int i=0;i<_n;++i){
                    if(b[_set[i]])
                        return false;
                    else
                        b[_set[i]] = true;
                }*/
                foreach(i, e; _set){
                    if(b[e])
                        return false;
                    else
                        b[e] = true;
                }
                return true;
            }
    }
    
}

unittest{
    auto p1 = permutations([1,2,3]);        //n=3を指定していると同じ
    assert(equal(p1,[[1,2,3],[1,3,2],[2,1,3],[2,3,1],[3,1,2],[3,2,1]]));
    auto p2 = permutations([0,1,2],2);
    assert(equal(p2,[[0,1],[0,2],[1,0],[1,2],[2,0],[2,1]]));
    auto p3 = permutations!true([0,1,2],2);
    auto exh3 = exhaustive([0,1,2],[0,1,2]);
    assert(equal(p3,exhaustive([0,1,2],[0,1,2])));
    auto p4 = permutations!true([0,1,2]);
    assert(equal(p4,exhaustive([0,1,2],[0,1,2],[0,1,2])));
}
deprecated{
    /**predがtrueになる間だけレンジを進めます。predは標準ではa < bとなります。テンプレートパラメータのReturnにtrueを入れると、popされた部分を配列として返します。
    Deprecated: std.algorithm.findを使用してください。
    Example:
    ---------------------------------------------------------------------
    auto rec = recurrence!"a[n-1]+1"(1);
    popFrontWhile(rec,10);        //先頭を10まで進ませる。
    assert(equal(take(rec,3),[10,11,12]));
    auto a = popFrontWhile!("a < b",true)(rec,20);
    assert(equal(a,[10,11,12,13,14,15,16,17,18,19]));
    ---------------------------------------------------------------------
    */
    void popFrontWhile(alias pred = "a < b", bool Return:false = false, Range, T)(ref Range range, T b = T.init){
        alias binaryFun!pred Fun;
        while(Fun(range.front, b) && !range.empty){
            range.popFront;
        }
    }

    ///ditto
    ElementType!Range[] popFrontWhile(alias pred = "a < b", bool Return:true, Range, T)(ref Range range, T b = T.init){
        alias binaryFun!pred Fun;
        typeof(return) dst;
        while(Fun(range.front ,b) && !range.empty){
            dst ~= range.front;
            range.popFront;
        }
        return dst;
    }

    unittest{
        auto rec = recurrence!"a[n-1]+1"(1);
        popFrontWhile(rec,10);        //先頭を10まで進ませる。
        assert(equal(take(rec,3),[10,11,12]));
        auto a = popFrontWhile!("a < b",true)(rec,20);
        assert(equal(a,[10,11,12,13,14,15,16,17,18,19]));
    }
}

/++素数列を生成します。無駄な判定を省くことによりfilter!isPrime(recurrence!"a[n-1]+1"(1))より高速に動作します。レンジの種類は無限レンジになります。
Example:
---------------------------------------------------------------------
auto ps = primeSquence(1);
assert(equal(take(ps,10),[2,3,5,7,11,13,17,19,23,29]));
---------------------------------------------------------------------
+/
PrimeSquence!T primeSquence(T)(T start){
    return PrimeSquence!T(start);
}
///ditto
struct PrimeSquence(T){
private:
    T _front;
    int _sw;        //frontが6n-1の形式なら-1,6n+1の形式なら1、2か3なら0
    pure bool _isPrime(T)(T src)if(__traits(isIntegral,T)){        
        T root = cast(T)sqrt(cast(float)src) + 1;
        
        for(T i=5;i<root;i+=6)
            if(!((src%i) && ((src)%(i+2))))
                return false;

        return true;
    }
    
public:
    enum empty = false;

    this(T src){
        while(!isPrime(src))
            ++src;
        if(src == 2 || src == 3)
            _sw = 0;
        else if(!((src+1)%6))
            _sw = 1;
        else if(!((src-1)%6))
            _sw = -1;
        else{
            writeln(src);
            assert(0);
        }
        _front = src;
    }
    
    @property void popFront(){
        if(_sw == -1){
            _front += 2;
            _sw = 1;
        }
        else if(_sw == 1){
            _front += 4;
            _sw = -1;
        }
        else{
            if(_front == 2)
                _front = 3;
            else{
                _front = 5;
                _sw = -1;
            }
            return;
        }
        while(!_isPrime(_front)){
            if(_sw == -1){
                _front += 2;
                _sw = 1;
            }else{
                _front += 4;
                _sw = -1;
            }
        }
    }
    
    @property T front(){
        return _front;
    }
    
    typeof(this) opAssign(typeof(this) src){
        _front = src._front;
        _sw = src._sw;
        return this;
    }
    
    @property
    typeof(this) save(){
        return typeof(this)(_front);
    }
}
unittest{
    auto ps = primeSquence(1);
    assert(equal(take(ps,10),[2,3,5,7,11,13,17,19,23,29]));
}

/++等差数列を作ります。レンジの種類は無限レンジになります。
Example:
----------------------------------------------------------------------
auto inf = iotaInfinite(12);
assert(equal(take(inf, 10), [12,13,14,15,16,17,18,19,20,21]));
inf = iotaInfinite(10, -1);
assert(equal(take(inf, 10), [10,9,8,7,6,5,4,3,2,1]));
----------------------------------------------------------------------
+/
/*
IotaInfinite!T iotaInfinite(T)(T start,T diff = 1){
    return IotaInfinite!T(start,diff);
}
///ditto
struct IotaInfinite(T){
private:
    T _front;
    T _diff;
public:
    enum empty = false;

    this(T s, T d){
        _front = s;
        _diff = d;
    }
    
    void popFront(){
        _front += _diff;
    }
    
    T front(){
        return _front;
    }
    
    typeof(this) opAssign(typeof(this) src){
        _front = src._front;
        _diff = src._diff;
        return this;
    }
    
    @property
    typeof(this) save(){
        return typeof(this)(_front, _diff);
    }
}
*/
IotaInfinite!(pred, T) iotaInfinite(alias pred = "a + b", T)(T start, T diff = 1){
    return typeof(return)(start,diff);
}
///ditto
struct IotaInfinite(alias pred = "a + b", T){
private:
    T _front;
    T _diff;
public:
    enum empty = false;

    this(T s, T d){
        _front = s;
        _diff = d;
    }
    
    void popFront(){
        _front = binaryFun!pred(_front, _diff);
    }
    
    T front(){
        return _front;
    }
    
    @property
    typeof(this) save(){
        return this;
    }
}
unittest{
    auto inf = iotaInfinite(12);
    assert(equal(take(inf, 10), [12,13,14,15,16,17,18,19,20,21]));
    inf = iotaInfinite(10, -1);
    assert(equal(take(inf, 10), [10,9,8,7,6,5,4,3,2,1]));
}

/++Haskellのtailの実装
Example:
---
auto a = [1,2,3,4,5,6,7];
assert(a.tail.front == 2);
assert(a.tail.tail.front == 3);
---
+/
Range tail(Range)(Range a)if(isInputRange!Range){
    a.popFront;
    return a;
}
unittest{
    auto a = [1,2,3,4,5,6,7];
    assert(a.tail.front == 2);
    assert(a.tail.tail.front == 3);
}

deprecated{
    /++Haskellのtailsの実装です。
    Example:
    ---------------------------------
    int[] a = [1,2,3,4,5,6,7,8,9];
    auto t = tails(a);
    assert(equal(t.front, [1,2,3,4,5,6,7,8,9]));
    t.popFront;
    assert(equal(t.front, [2,3,4,5,6,7,8,9]));
    t.popFront;
    assert(equal(t.front, [3,4,5,6,7,8,9]));
    ---------------------------------
    +/
    Tails!Range tails(Range)(Range src){
        return Tails!Range(src);
    }

    ///ditto
    struct Tails(Range){
    private:
        Range _range;

    public:
        this(Range r){
            _range = r.save;
        }
        
        static if(isInfinite!Range){
            enum empty = false;
        }else{
            @property
            bool empty(){
                return _range.empty;
            }
        }
        
        @property
        void popFront(){
            _range.popFront;
        }
        
        @property
        Range front(){
            return _range;
        }
        
        @property
        typeof(this) opAssign(typeof(this) src){
            _range = src._range.save;
            return this;
        }
        
        @property
        typeof(this) save(){
            return typeof(this)(_range.save);
        }
    }
    unittest{
        int[] a = [1,2,3,4,5,6,7,8,9];
        auto t = tails(a);
        assert(equal(t.front,[1,2,3,4,5,6,7,8,9]));
        t.popFront;
        assert(equal(t.front,[2,3,4,5,6,7,8,9]));
        t.popFront;
        assert(equal(t.front,[3,4,5,6,7,8,9]));
    }
}

/++レンジの要素がさらにレンジであれば、そのレンジの要素を並べていく。つまり、深さ優先探索のような感じ。前進レンジ.
Example:
---
auto fr = flatten([1,2,3,4,5]);
static assert(isForwardRange!(typeof(fr)));
assert(equal(fr, [1,2,3,4,5]));
auto fr1 = flatten([[1,2],[3,4]]);
assert(equal(fr1, [1,2,3,4]));
auto fr2 = flatten([[[1,2],[3,4]],[[5,6]],[[7]]]);
assert(equal(fr2, [1,2,3,4,5,6,7]));
auto fr3 = flatten([[],[],[1],[],[3]]);
assert(equal(fr3, [1,3]));
---
+/
Flatten!(Range) flatten(Range)(Range range)if(isForwardRange!Range){
    return typeof(return)(range);
}

///ditto
struct Flatten(Range)if(isForwardRange!(ElementType!Range)){
private:
    Flatten!(ElementType!Range) _r;
    Range _range;
    bool _empty;

public:
    this(Range range){
        _range = range.save;
        if(_range.empty)
            _empty = true;
        else
            _r = Flatten!(ElementType!Range)(_range.front);
        if(_r.empty)
            popFront();
    }
    
    @property
    void popFront(){
        assert(!empty,"Range is End.");
        if(_r.empty){
            if(_range.empty){
                _empty = true;
                return;
            }
            _range.popFront;
            if(_range.empty){
                _empty = true;
                return;
            }
            _r = Flatten!(ElementType!Range)(_range.front);
            if(_r.empty)
                popFront();
        }else{
            _r.popFront;
            if(_r.empty)
                popFront();
        }
    }
    
    @property
    auto front(){
        assert(!empty);
        return _r.front;
    }
    
    @property
    bool empty(){
        return _empty || (_range.empty && _r.empty);
    }
    
    @property
    typeof(this) save(){
        typeof(return) dst;
        dst._r = _r.save;
        dst._range = _range.save;
        dst._empty = _empty;
        return dst;
    }
    
    typeof(this) opAssign(typeof(this) src){
        _r = src._r.save;
        _range = src._range.save;
        _empty = src._empty;
        return this;
    }
    
}
///ditto
struct Flatten(Range)if(!isForwardRange!(ElementType!Range)){
private:
    Range _range;
    
public:
    this(Range range){
        _range = range.save;
    }
    
    @property
    ElementType!Range front(){
        assert(!empty);
        return _range.front;
    }
    
    @property
    void popFront(){
        assert(!_range.empty);
        _range.popFront;
    }
    
    @property
    bool empty(){
        return _range.empty;
    }
    
    @property
    typeof(this) save(){
        return typeof(return)(_range);
    }
    
    typeof(this) opAssign(typeof(this) src){
        _range = src._range.save;
        return this;
    }
    
}
unittest{
    auto fr = flatten([1,2,3,4,5]);
    static assert(isForwardRange!(typeof(fr)));
    assert(equal(fr, [1,2,3,4,5]));
    auto fr1 = flatten([[1,2],[3,4]]);
    assert(equal(fr1, [1,2,3,4]));
    auto fr2 = flatten([[[1,2],[3,4]],[[5,6]],[[7]]]);
    assert(equal(fr2, [1,2,3,4,5,6,7]));
    auto fr3 = flatten([[],[],[1],[],[3]]);
    assert(equal(fr3,[1,3]));
}

