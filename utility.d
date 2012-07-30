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

import win32.winnls : WideCharToMultiByte;


///E[0] == E[1] || E[0] == E[2] || … ||　E[0] == E[n-1]をする。
bool anysame(T)(T[] a ...){
	if(a.length < 2)return false;

	foreach(i, e; a[1..$])
		if(a[0] == e)
			return true;
	return false;
}

///E[0] == E[1] && E[0] == E[2] && … &&　E[0] == E[n-1]をする。
bool allsame(T)(T[] a ...){
	if(a.length < 2)return false;
	
	foreach(i, e; a[1..$])
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


///ワイド文字をShift JISに変換します
char[] toShiftJIS(inout(wchar)[] src){
    char[] result;
    result.length = WideCharToMultiByte(0,0, src.ptr, src.length, null, 0, null, null);
    WideCharToMultiByte(0, 0, src.ptr, src.length, result.ptr, result.length, null,null);
    
    return result;
}