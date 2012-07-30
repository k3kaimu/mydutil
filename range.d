/++
+ レンジを扱ったりするためのモジュール
+/

module mydutil.range;

import std.functional;
import std.traits;
import std.algorithm;
import std.math;
import std.range;
import std.stdio    : writeln,write;
import std.conv;
import std.array    : array, popFront, popBack;
import std.typetuple:staticMap, allSatisfy, NoDuplicates;
import std.typecons :Tuple,tuple;

import mydutil.arith.method;
import mydutil.util.utility;
import mydutil.util.tmp;

version(unittest){
    pragma(lib,"mydutil");
    
    void main(){
        writeln("Unittest Done");
    }
}


/++aをBase進数の桁的に巡回させたものをすべて返す。
Example:
---------------------------------------------------------------------
assert(equal(rotation(123), [123,231,312]));
---------------------------------------------------------------------
+/
T[] rotationDigit(uint Base = 10,T)(T a)if(__traits(isIntegral,T)){
    //まず桁ごとにくぎる
    T[] dst;
    auto digit = splitdigit!Base(a).reverse;
    
    foreach(i, Unuse; digit)
        dst ~= reduce!((a,b) => a * Base + b)(digit[i..$]~digit[0..i]);
    return dst;
}
unittest{
    import std.algorithm;
    writeln("Unittest Start ",__LINE__);
    assert(equal(rotation(123),[123,231,312]));
    writeln("Unittest End ",__LINE__);
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


