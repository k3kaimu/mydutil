module mydutil.math;

import std.math;
import std.array;
import std.bigint;
import std.traits	: isSomeFunction , isArray;
import std.numeric	: gcd;
import std.algorithm;
import std.conv		: roundTo;
import std.functional;
import core.bitop;
import std.range;
import std.typecons;

import mydutil.range;

///素数かどうか判定する
pure bool isPrime(T)(T src)if(__traits(isIntegral,T)){
	if(src <= 1)return false;
	else if(src < 4)return true;
	else if(!(src&1))return false;
	else if(((src+1)%6) && ((src-1)%6))return false;
	
	T root = cast(T)sqrt(cast(float)src) + 1;
	
	for(T i = 5; i < root; i += 6)
		if(!((src%i) && ((src)%(i+2))))
			return false;

	return true;
}
unittest{
	import std.range;
	assert(equal(filter!isPrime_lowspeed(iota(1L,100000L)) , filter!isPrime(iota(1L,100000L))));
}

///BigIntの最大公約数を返す
BigInt gcd(BigInt x, BigInt y){
	if(x == 0 || y == 0)
		return BigInt(1);
	

	while(x!=0 && y!=0){
		if(x > y)x %= y;
		else y %= x;
	}
	return x != 0 ? x : y;
}

///最小公倍数を返す
pure T lcm(T)(T x, T y){
	if(x == 0 || y == 0)
		return 0;
	
	return x * (y / gcd(x, y));
}

///階乗を返す。
BigInt factorial(T:BigInt, U)(U X){
	if(X == 0)return BigInt(1);
    
	BigInt ret=X;
    
    foreach(i; 2..X)
		ret *= i;
    
	return ret;
}

///ditto
pure T factorial(T = long, U)(U x){
	if(x <= 1)return 1;
	else{
		T ret = x;
		foreach(i; 2..x)
			ret *= i;
		return ret;
	}
}

///すべての約数を配列にして返す。
pure T[] divisor(T)(T x){
	//xが持つ約数をすべて上げて配列にして返す
	if(x == 0){
		T[] dst;
		return dst;
	}
	
	T root = cast(T)sqrt(cast(float)x);
	bool sq;
	if(root^^2 == x)
		sq = true;
		
	++root;
	T[] dst;
	T[] dst_b;
	foreach(i; 1..root)
		if(!(x%i)){
			dst ~= i;
			dst_b ~= (x / i);
		}
	if(sq && !dst.empty)dst.popBack;
	return dst ~ dst_b.reverse;
}


/++フェルマーの方法(平方差分法)から素因数分解を行います。
Example:
---
assert(equal(primefactor(128),[tuple(2,7u)]));
assert(equal(primefactor(412),[tuple(2,2u),tuple(103,1u)]));
assert(equal(primefactor(512),[tuple(2,9u)]));
assert(equal(primefactor(27),[tuple(3,3u)]));
assert(equal(primefactor(153),[tuple(3,2u),tuple(17,1u)]));
assert(equal(primefactor(14402),[tuple(2,1u),tuple(19,1u),tuple(379,1u)]));
assert(equal(primefactor(75),[tuple(3,1u),tuple(5,2u)]));
---
+/
Tuple!(T,uint)[] primefactor(T)(T n)
in{assert(n >= 0);}
body{
    typeof(return) dst;

    if(!(n&1)){
        if(n == 0)
            return dst;
        
        static if(is(T == int) || is(T == uint)){
            dst ~= Tuple!(int,uint)(2,bsf(cast(uint)n));
            n >>= dst[0][1];
        }else{
            dst ~= Tuple!(T,uint)(2,0);
            while(!(n&1)){
                n >>= 1;
                ++dst[0][1];
            }
        }
        if(n == 1)
            return dst;
    }
    
    if(isPrime(n))
        return dst ~ Tuple!(T,uint)(n,1u);
    
    T x = cast(T)sqrt(cast(real)n);
    T y = 0;
    T diff = x^^2 - y^^2 - n;
    while(diff != 0){
        if(diff < 0){
            diff += x;
            ++x;
            diff += x;
        }else{
            diff -= y;
            ++y;
            diff -= y;
        }
    }
    T p = x+y, q = x-y;
    if(p == q){
        auto tmp = primefactor(p);
        foreach(ref tp;tmp)
            tp[1] += tp[1];
        return dst ~ tmp;
    }
    
    bool bp = !isPrime(p), bq = !isPrime(q);
    
    if(bp || bq){
        auto ps = appender!(T[])();
        if(bp)
            foreach(g; primefactor(p))
                foreach(i; 0..g[1])
                    ps.put(g[0]);
        else
            ps.put(p);
        
        if(bq)
            foreach(g; primefactor(q))
                foreach(i; 0..g[1])
                    ps.put(g[0]);
        else
            ps.put(q);
        
        auto psd = ps.data;
        psd.sort;
        auto d = group(psd);
        if(d.front[0] == 1)
            d.popFront;
        
        return dst ~ array(d);
    }
    if(p == q)
        return dst ~ [Tuple!(T,uint)(q,2u)];
    return dst ~ [Tuple!(T,uint)(q,1u),Tuple!(T,uint)(p,1u)];
}
unittest{
    assert(equal(primefactor(128),[tuple(2,7u)]));
    assert(equal(primefactor(412),[tuple(2,2u),tuple(103,1u)]));
    assert(equal(primefactor(512),[tuple(2,9u)]));
    assert(equal(primefactor(27),[tuple(3,3u)]));
    assert(equal(primefactor(153),[tuple(3,2u),tuple(17,1u)]));
    assert(equal(primefactor(14402),[tuple(2,1u),tuple(19,1u),tuple(379,1u)]));
    assert(equal(primefactor(75),[tuple(3,1u),tuple(5,2u)]));
}

///数をbase進の桁ごとに区切った配列を返す。例123→[1,2,3].reverse
pure int[] splitDigit(uint Base = 10,T)(T a){
	int[] dst;
	//Tを桁ごとに区切ったものを配列として返す。
	while(a != 0){
		static if(Base != 2){
			dst ~= a%Base;
			a /= Base;
		}else{
			dst ~= a&1;
			a >>= 1;
		}
	}
	return dst;
}
unittest{
	import std.algorithm;
	assert(equal(splitDigit(123),[1,2,3].reverse));
}

///回文数かどうか判定
bool isPalindromic(uint Base = 10,T)(T a){
	auto spdg = splitDigit!Base(a);
	return equal(spdg,spdg.dup.reverse);
}

///三角数かどうか判定する。
pure bool isTraiangular(T)(T a)if(__traits(isIntegral,T)){
	T sq = cast(int)sqrt(cast(float)(a<<1));
	if((sq*(sq+1)) == a<<1)
		return true;
	return false;
}
unittest{
	assert(isTraiangular(1));
	assert(isTraiangular(3));
	assert(isTraiangular(6));
	assert(isTraiangular(10));
	assert(isTraiangular(15));
}

///過剰数かどうか判定する
pure bool isAbundant(T)(T n)if(__traits(isIntegral,T)){
	if(n == 0 || n == 1)return false;
	if(reduce!"a+b"(divisor(n)[0..$-1]) > n)
		return true;
	else
		return false;
}

///標準では完全数かどうか判定するのみ
pure bool isPerfect(alias pred = "a == b",T)(T n)if(__traits(isIntegral,T)&&__traits(compiles,binaryFun!(pred)(T.init,T.init) == true)){
	if(n == 0)return false;
	if(binaryFun!(pred)(reduce!"a+b"(divisor(n)[0..$-1]),n))
		return true;
	else
		return false;
}

///Pandigital数(0からBase-1までの数が１回でも桁に存在する)かどうか判定
bool isPandigital(uint Base = 10,bool type : false = false,T)(T src)if(__traits(isIntegral,T)){
	return reduce!"a~b[0]"(cast(T[])[],group(splitdigit(src).sort)).length == Base;
}
unittest{
	assert(isPandigital(1234567890));
	assert(isPandigital(1234567890123L));
}

///真のPandigital数(0からBase-1が一度ずつ桁に含まれる)ならtrueを返す。
pure bool isPandigital(uint Base = 10,bool type : true,T)(T src)if(__traits(isIntegral,T)){
	T[] digs = splitdigit(src);
	
	if(digs.length != Base)
		return false;
		
	bool[Base] b;
	
	for(int i=0;i<digs.length;++i){
		if(b[digs[i]])
			return false;
		else
			b[digs[i]] = true;
	}
	return true;
}

///nを2のべき乗で割って、n=d*2^^sとして[s,d]の形式で返す。
pure T[] tod2n(T)(T n)if(__traits(isIntegral,T)){
	T[] dst = [0,0];
	if(n == 0)return dst;
	
	dst[0] = bsf(n);
	dst[1] = n >> dst[0];
	return dst;
}

///b^^p(mod m)を計算。O(log p)
pure T powMod(T)(T b,T p,T m)if(__traits(isIntegral,T)){
	if(p == 0)		return 1;
	else if(!(p&1))	return powMod(b*b % m,p>>1,m);
	else			return b*powMod(b,p-1,m) % m;
}

///平方数であるか
pure bool isSquare(T)(T n)if(__traits(isIntegral,T)){
	real sq = sqrt(cast(real)n);
	return (sq == cast(int)sq);
}
unittest{
    assert(isSquare(10_000_000_000));
    assert(isSquare(100));
    assert(isSquare(49));
}

///int[]で与えられた各桁を置換した場合に作成可能な数の個数を返す。重複していた場合にはあわせて1つと数える。
long NumCountFromDigit(int[] dig){
	dig.sort;
	return factorial(dig.length) / reduce!((a,b) => a*factorial(b[1]))(1L,group(dig));;
}
unittest{
	assert(NumCountFromDigit([0,1,2]) == 3*2*1);//012,021,102,120,201,210
	assert(NumCountFromDigit([1,1,1]) == 1);
	assert(NumCountFromDigit([0,0,1,1]) == 3*2*1);//0011,0101,0110,1001,1010,1100
	assert(NumCountFromDigit([0,0,1,1,2,2]) == factorial(6)/(factorial(2)^^3));
}

///順列の個数を数える
pure T permcount(T)(T n,T m)if(__traits(isIntegral,T)){
	return reduce!"a*b"(cast(T)1,iota(m+1,n+1));
}

///エラトステネスの篩にかけて、素数リストを返します。
T[] sieve(T)(T End)
in{assert(End>0);}body{
	BitArray b;	//判定
	b.length = End;
	T[] prime = [2,3];//素数リスト
	T SQRTEND = cast(T)sqrt(cast(real)End);
	T n = 2;
	T limit, cnt = 0, pmax = 5;
    
	while(n < SQRTEND){		//リストのsqrtまで素数判定する
		for(T i = n * 2; i < End; i += n)
			b[i] = true;
		//素数リストを更新
		limit = n^^2;
		for(; pmax < limit; pmax += 2)
			if(!b[pmax])prime ~= pmax;
		++cnt;
		n = prime[cnt];
	}
	for(T i = pmax; i < End; i += 2)
		if(!b[i])prime ~= i;
	return prime;
}

/++√mを連分数展開します。
Example:
------------------------------------
assert(equal(continuedFractionExpansion(2), [1,2]));
assert(equal(continuedFractionExpansion(3), [1,1,2]));
assert(equal(continuedFractionExpansion(5), [2,4]));
assert(equal(continuedFractionExpansion(6), [2,2,4]));
assert(equal(continuedFractionExpansion(7), [2,1,1,1,4]));
assert(equal(continuedFractionExpansion(8), [2,1,4]));
assert(equal(continuedFractionExpansion(10), [3,6]));
assert(equal(continuedFractionExpansion(11), [3,3,6]));
assert(equal(continuedFractionExpansion(12), [3,2,6]));
assert(equal(continuedFractionExpansion(13), [3,1,1,1,1,6]));
assert(equal(continuedFractionExpansion(23), [4,1,3,1,8]));
------------------------------------
+/
T[] continuedFractionExpansion(T)(T m)if(__traits(isIntegral,T))
in{assert(m > 0 && !isSquare(m));}body{
	auto dst = appender!(T[])();
	int a1 = cast(int)sqrt(cast(float)m);
	dst.put(a1);
	int Pn = 0,Qn = 1,pn = a1,qn = 1,an = a1,Pn_1,Qn_1,pn_1,qn_1,an_1,pn_2,qn_2;
	{		//n = 2
		Pn_1 = Pn;
		Qn_1 = Qn;
		pn_1 = pn;
		qn_1 = qn;
		an_1 = an;
		
		Pn = an_1;
		Qn = m - an_1^^2;
		an = cast(int)((a1+Pn)/Qn);
		pn = an * an_1 + 1;
		qn = an;
		dst.put(an);
	}
	do{
		pn_2 = pn_1;
		qn_2 = qn_1;
		Pn_1 = Pn;
		Qn_1 = Qn;
		pn_1 = pn;
		qn_1 = qn;
		an_1 = an;
		
		Pn = an_1 * Qn_1 - Pn_1;
		Qn = (m - Pn^^2)/Qn_1;
		an = cast(int)((a1+Pn)/Qn);
		pn = an * pn_1 + pn_2;
		qn = an * qn_1 + qn_2;
		dst.put(an);
	}while(Qn != 1);
	if(dst.data.length == 3 && dst.data[1] == dst.data[2])
		return dst.data[0..$-1];
	return dst.data;
}
unittest{
	assert(equal(continuedFractionExpansion(2), [1,2]));
	assert(equal(continuedFractionExpansion(3), [1,1,2]));
	assert(equal(continuedFractionExpansion(5), [2,4]));
	assert(equal(continuedFractionExpansion(6), [2,2,4]));
	assert(equal(continuedFractionExpansion(7), [2,1,1,1,4]));
	assert(equal(continuedFractionExpansion(8), [2,1,4]));
	assert(equal(continuedFractionExpansion(10), [3,6]));
	assert(equal(continuedFractionExpansion(11), [3,3,6]));
	assert(equal(continuedFractionExpansion(12), [3,2,6]));
	assert(equal(continuedFractionExpansion(13), [3,1,1,1,1,6]));
	assert(equal(continuedFractionExpansion(23), [4,1,3,1,8]));
}

/++
オイラーのφ関数
Example:
---
assert(eulersTotient(2) == 1);
assert(eulersTotient(3) == 2);
assert(eulersTotient(4) == 2);
assert(eulersTotient(5) == 4);
assert(eulersTotient(6) == 2);
assert(eulersTotient(7) == 6);
assert(eulersTotient(8) == 4);
assert(eulersTotient(9) == 6);
assert(eulersTotient(10) == 4);
---
+/
T eulersTotient(T)(T n)
in{assert(n > 1);}
body{
	return primefactor(n).map!(a => tuple(a[0]^^(a[1]-1),a[0]))().map!(a => a[0]*a[1] - a[0])().curry!(reduce!"a*b",1)();
}

///オイラーのφ関数をlimの数値まで計算して返します。primesには素数リストを渡しておきます。
T[] eulersTotient(T,U)(T lim, ref U[] primes)
in{assert(n > 1);}
body{
    auto faiapp = appender!(int[])([1,1]);
    if(primes[$-1] < sqrt(cast(float)lim)){
        auto p = primeSquence(primes[$-1]);
        primes.popFront;
        
        foreach(p; p.takeWhile(cast(int)sqrt(cast(float)lim)+1))
            primes ~= p;
    }
    
    foreach(n; 2..lim){
        if(prs[0] < n)
            popFrontWhile(prs,n);
        
        if(prs[0] == n){
            faiapp.put(n - 1);
            continue;
        }
        
        foreach(i; primes){
            if(!(n % i)){
                if(!((n / i) % i))
                    faiapp.put(faiapp.data[n/i] * i);
                else
                    faiapp.put(faiapp.data[n/i] * (i - 1));
                break;
            }
        }
    }
    return faiapp.data;
}
