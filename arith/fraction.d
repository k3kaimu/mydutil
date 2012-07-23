/++
分数型を構成します。Fractionは整数及び分数型に対して、ほぼすべての算術演算を備えています。
+/

module mydutil.arith.fraction;

import std.bigint;
import std.stdio;
import std.math;
import std.numeric;
import std.traits;

import mydutil.arith.method;
import mydutil.util.utility;
import mydutil.util.tmp;

version(unittest){
	pragma(lib,"mydutil");
}
///分数を作ります
Fraction fraction(T...)(T src){
	static if(T.length == 2){
		return Fraction(src);
	}else static if(T.length == 1){
		static if(isFloatingPoint!(T[0]))
			return Fraction.generate(src[0]);
		else
			return Fraction(src,1);
	}else
		static assert(0,"fraction needs 1 or 2arguments.");
}

///分数型
struct Fraction{

	///2引数を取り、分数形式で初期化
	this(T)(T N,T D){
		static if(isAnySame!(T,string,int)){
			_num = BigInt(N);
			_den = BigInt(D);
		}else static if(isAnySame!(T,long,BigInt)){
			_num = N;
			_den = D;
		}else static assert(0);
	}
	
	///代入
	Fraction opAssign(T)(T x){
		static if(isIntegral!T){
			_num = x;
			_den = 1;
			return this;
		}else static if(is(T == Fraction)){
			_num = x._num;
			_den = x._den;
			return this;
		}
	}
	
	///2項演算子。+,-,*,/,<<,>>,^^に対応
	Fraction opBinary(string s,T)(T src){
		static if(s == "+" || s == "-"){
			static if(isIntegral!T){
				Fraction dst = Fraction(_num,_den);
				mixin("dst._num = _num"~s~"_den*src;");
				return dst;
			}
			else static if(is(T == Fraction)){
				Fraction dst;
				mixin("dst._num = _num * A._den"~s~"A._num * _den;");
				dst._den = _den*A._den;
				return dst;
			}
			else
				static assert(0);
		}else static if(s == "*"){
			static if(isIntegral!T)
				return fraction(_num*src,_den);
			else static if(is(T == Fraction))
				return fraction(_num*src._num,_den*src._den);
			else
				static assert(0);
		}else static if(s == "/"){
			static if(isIntegral!T)
				return fraction(_num,_den*src);
			else static if(is(T == Fraction))
				return fraction(_num*src._den,_den*src._num);
			else
				static assert(0);
		}else static if(s == "^^"){
			static assert(isIntegral!T);
			if(src > 0)
				return fraction(_num^^src,_den^^src);
			else if(src < 0)
				return fraction(_den^^src,_num^^src);
			else
				return fraction(1,1);
		}else static if(s == ">>"){
			static assert(isIntegral!T);
			return fraction(_num,_den<<src);
		}else static if(s == "<<"){
			static assert(isIntegral!T);
			return fraction(_num<<src,_den);
		}else static assert(0);
	}
	
	Fraction opBinaryRight(string s,T)(T src){
		static if(s == "+" || s == "*")
			return opBinary!(s,T)(src);
		else static if(s == "-" || s == "/"){
			static if(s == "-")
				return fraction(src*_den-_num,_den);
			else static if(s == "/")
				return fraction(src*_den,_num);
			else static assert(0);
		}else static assert(0);
	}
	
	Fraction opOpAssign(string s,T)(T src){
		static if(s == "+" || s == "-"){
			static if(isIntegral!T)
				mixin("_num "~s~"= _den *  src;");
			else static if(is(T == Fraction)){
				mixin("_num = _num * src._den "~s~" src._num * _den");
				_den *= src._den;
			}else static assert(0);
		}else static if(s == "*"){
			static if(isIntegral!T)
				_num *= src;
			else static if(is(T == Fraction)){
				_num *= src._num;
				_den *= src._den;
			}else static assert(0);
		}else static if(s == "/"){
			static if(isIntegral!T)
				_den *= src;
			else static if(is(T == Fraction)){
				_num *= src._den;
				_den *= src._num;
			}else static assert(0);
		}else static if(s == ">>"){
			static assert(isIntegral!T);
			_den >>= src;
		}else static if(s == "<<"){
			static assert(isIntegral!T);
			_num <<= src;
		}else static if(s == "^^"){
			static assert(isIntegral!T);
			_num ^^= src;
			_den ^^= src;
		}
		return this;
	}
	
	///約分を行います。
	@property void reduce(){
		if(_den < 0){
			_num = -_num;
			_den = -_den;
		}
		BigInt G = Gcd(_num,_den);
		while(G!=1){
			_num /= G;
			_den /= G;
			G = Gcd(_num,_den);
		}
	}

	///real型にキャスト可能
	real opCast(T : real)(){
		//筆算と同じ方法で行う
		int e=0;
		real ret=0;
		int sign=0;
		BigInt S = _num;
		BigInt M = _den;
		
		if(_num < 0 && _den > 0){S = -S;sign = 1;}
		else if(_num > 0 && _den < 0){M = -M;sign = 1;}
		else if(_num < 0 && _den < 0){S=-S;M=-M;}
		
		//まず割る数より割られる数が大きくなるようにする
		if(S<M)
			while(S < M){
				S*=10;
				--e;
			}
		else//同程度まで割る数を大きくする
			while((S/M) >= 10){
				M *= 10;
				++e;
			}
		
		//これで割り算した結果はX.~になる
		//ここからは筆算と同様に計算する
		long temp;
		for(int i=0;i<_pre;i++){
			temp = (S/M).toInt();
			ret += temp;
			ret *= 10;
			S %= M;
			S *= 10;
			--e;
		}
		
		if(e > 0)
			for(int i=0;i<e;i++)
				ret *= 10;
		else if(e < 0)
			for(int i=0;i<-e;i++)
				ret /= 10;
		
		return ret * (sign ? -1:1);
	}
	
	///分子numや分母denの設定と取得
	@property auto num(){return _num;}
	///ditto
	@property auto num(BigInt N){_num = N;return _num;}
	///ditto
	@property auto num(long N){_num = N;return _num;}
	///ditto
	@property auto den(){return _den;}
	///ditto
	@property auto den(BigInt D){_den = D;return _den;}
	///ditto
	@property auto den(long D){_den = D;return _den;}
	
	
	///等号演算子
	bool opEquals(ref Fraction K){
		reduce;
		K.reduce;
		if(_num == K._num && _den == K._den)
			return true;
		else
			return false;
	}
	
	///比較演算子
	int opCmp(ref Fraction K){
		reduce;
		K.reduce;
		
		BigInt A = _num * K._den;
		BigInt B = K._num * _den;
		return A.opCmp(B);
	}
	
	Fraction generate(real R,int prec = 20){
		Fraction K;
		K._num = 0;
		K._den = 1;
		int sign = R>=0.0L ? 0 : 1; 
		int e=0;
		R = sign ? -R : R;//絶対値化
		
		//まずRを1以下にする。つまり0.~形式
		if(R>=1){
			while(R>=1){
				R /= 10.0L;
				++e;
			}
		}else{//1に満ていなければ、0.1以上になるまで10倍していく
			while(R<0.1){
				R *= 10.0L;
				--e;
			}
		}
		
		//上のif else 文を抜けると、Rの値は0.~という形式である
		
		//格納していく
		int temp;
		for(int i=0;i<=prec;i++){
			R*=10.0L;
			temp = cast(int)R % 10;
			K._num += temp;
			R -= cast(real)temp;
			
			K._num *= 10;
			K._den *= 10;
		}
		K._num /= 10;
		
		if(e>0)
			for(int i=0;i<e;i++)
				K._num *= 10;
		else if(e<0)
			for(int i=0;i<(-e);i++)
				K._den *= 10;
		
		K.reduce;
		K._num *= sign ? -1 : 1;
		return K;
	}
	
	///逆数にして返す
	@property Fraction inverse(){
		BigInt tmp = _num;
		_num = _den;
		_den = tmp;
		return this;
	}
	
private:
	BigInt _num;//分子
	BigInt _den;//分母
}

/+
void main(){
	Fraction pi= Fraction(0,1);
	//Fraction tmp = Fraction(0,1);
	BigInt num,den;
	int j;
	clock_t st = clock();
	for(int i=0;i<1000;i++){
		num = 1;
		den = 2;
		/* 分子の計算 */
		j = (i%2 == 0)?i+1:i+2;
		for(;j<2*i;j+=2){
			num *= j;
		}
		den <<= 4*i - (i+1)/2;//通常は4*i+1-(i+1)/2であるが、denはもともと2であるので4*i-(i+1)/2
		j = 2*i+1;
		den *= factorial(i/2) * j;
		pi += Fraction(num,den);
		writeln(i);
	}
	pi = pi * Fraction(6,1);
	clock_t end1 = clock();
	writeln(pi.toReal(60));
	clock_t end2 = clock();
	/*
	auto fp = File("pi.txt","w");
	fp.writeln(pi.toReal(10));
	*/
	writeln("end");
	writefln("%d[ms]\n%d[ms]\n",end1-st,end2-end1);
}

+/



/*
arcsin(1/2)=π/6=sum(0→∞) (2n)! / ((2^(4n+1))*((n!)^2)*(2n+1))
*/