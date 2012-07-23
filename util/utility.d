module mydutil.util.utility;

import std.stdio;
import std.bigint;
import std.array;
import std.conv : to;
import std.math : pow;
import std.conv;
import std.algorithm;
import std.typetuple;
import std.file;
import std.string;
//import std.typecons;
import std.traits;
import std.functional;

import mydutil.arith.method;

version(unittest){
	pragma(lib,"mydutil");
}


///E[0] == E[1] || E[0] == E[2] || … ||　E[0] == E[n-1]をする。
bool anysame(T)(T[] a ...){
	if(a.length < 2)return false;

	for(int i=1;i<a.length;++i)
		if(a[0] == a[i])
			return true;
	return false;
}

///E[0] == E[1] && E[0] == E[2] && … &&　E[0] == E[n-1]をする。
bool allsame(T)(T[] a ...){
	if(a.length < 2)return false;
	
	for(int i=1;i<a.length;++i)
		if(a[0] != a[i])
			return false;
	return true;
}
unittest{
	assert(anysame(1,2,3,4,5,1));
	assert(allsame!string("a","a","a","a","a"));
}

///バイトの列をエンディアン指定で数値型に変換する。
T ByteArrayTo(T,string s)(ubyte[] data)if(s == "little" || s == "big")
in{
	assert(T.sizeof == data.length);
}
body{
	T dst;
	static if(s == "little")
		foreach_reverse(ubyte ub ; data){
			dst <<= 8;
			dst |= cast(T)ub;
		}
	else static if(s == "big")
		foreach(ubyte ub ; data){
			dst <<= 8;
			dst |= cast(T)ub;
		}
	else
		static assert(0);
	
	return dst;
}

///srcをstd.conv.toを使って他の型に変換する
T StringTo(T)(string src){
	char[] buf = cast(char[])src;
	
	while(buf[0] == ' ')buf.popFront;
	while(buf[$-1] == ' ')buf.popBack;
	
	return to!T(cast(string)buf);
}

version(unittest){
	void main(){
		writeln("end");
	}
}

/**
 * 便利なキャスト
 * Deprecated: src.map!(a => cast(T)a)()とか使ってください
 * Exsample:
 * --------------------------
 * long[] a = Cast!(long)([1,2,3]);
 * --------------------------
*/
T[] Cast(T,U)(U[] src){
	T[] dst;
	for(int i=0;i<src.length;++i)
		dst ~= cast(T)src[i];
	return dst;
}

///文字列または数値を受け取るとそれを丸めた数値の文字列にして返す。
string SignNum(SR)(SR src,int signdig)if(SR.stringof == "string" || __traits(isArithmetic,SR))
in{assert(signdig > 0);}
body{
	//有効数字が4桁→まずそれを0.…形式に変換し、
	//10^4倍するとXXXX. .....という形式になるので、roundTo関数で丸めたあと
	//桁上げ(下げ)した分だけ桁下げ(桁上げ)しなおす。
	
	int digup = 0;
	bool sign = false;
	static if(__traits(isArithmetic,SR))
		real num = cast(real)src;
	else
		real num = StringTo!real(src);
	
	//まず0.の形式に変換
	if(num < 0){
		sign = true;
		num *= -1;
	}
	//桁下げ
	while(num > 1){
		num /= 10.0;
		++digup;
	}
	//桁上げ
	while(num < 0.1){
		num *= 10.0;
		--digup;
	}
	num *= pow(10.0,signdig);
	auto digsp = splitdigit(roundTo!long(num));
	digsp.reverse;
	//これでnumにはそれぞれの桁が入っている。
	assert(digsp.length == signdig);
	
	
	//もとの数が1以上なら
	if(digup > 0){
		if(signdig <= digup){
			for(int i=0;i<(digup - signdig);++i)
				digsp ~= 0;
			return (sign ? "-":"")~reduce!((string a,long b){return a~toImpl!string(b);})("",digsp);
		}else{
			string upper = (sign ? "-":"")~reduce!((string a,long b){return a~toImpl!string(b);})("",digsp[0..digup]) ~ ".";
			return upper ~ reduce!((string a,long b){return a~toImpl!string(b);})("",digsp[digup..$]);
		}
	}else{
		if((digup - signdig) < 0){
			digsp.reverse;
			int dgspl = digsp.length;
			for(int i=0;i<(signdig-digup-dgspl);++i)
				digsp ~= 0;
			digsp.reverse;
			return (sign ? "-":"")~reduce!((string a,long b){return a~toImpl!string(b);})("0.",digsp);
		}else{
			for(int i=0;i<(digup - signdig);++i)
				digsp ~= 0;
			return (sign ? "-":"")~reduce!((string a,long b){return a~toImpl!string(b);})("",digsp);
		}
	}
}
unittest{
	auto A = "-123456.4";
	auto B = "0.000003133";
	auto C = "1.012";
	auto D = 1.012;
	assert(SignNum(A,3) == "-123000");
	writeln(SignNum(A,3));
	assert(SignNum(A,10) == "-123456.4000");
	assert(SignNum(B,3) == "0.00000313");
	assert(SignNum(B,4) == "0.000003133");
	assert(SignNum(B,5) == "0.0000031330");
	assert(SignNum(C,5) == "1.0120");
	assert(SignNum(C,4) == "1.012");
	assert(SignNum(C,4) == SignNum(D,4));
}



///ファイルすべてを行ごとに区切った形式で返す。
string[] LineRead(string filename){
	return splitLines(readText(filename));
	//return filename.readText.splitLines;
}

struct CSVFile(string type : "r", string sep = ","){
private:
	File fp;
	
}
