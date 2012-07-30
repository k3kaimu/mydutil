/++
+ テンプレートメタプログラミングの要素をつめあわせたモジュールです。
+/

module mydutil.util.templates;

import std.typetuple;
import std.traits       : Unqual;

///funをカリー化して、指定された値に第(idx+1)引数を束縛する関数にします。
template curryIdx(alias fun, alias value, int idx = 0){
	static if(isSomeFunction!(fun)){
		ReturnType!fun curryIdx(ParameterTypeTuple!fun[0..idx] First,ParameterTypeTuple!fun[idx+1..$] Second){
			return fun(First,value,Second);
		}
	}else{
		auto curryIdx(Ts...)(Ts Arg){
			static if(is(typeof(fun(Arg[0..idx],value,Arg[idx..$])))){
				return fun(Arg[0..idx],value,Arg[idx..$]);
			}else{
				static string errormsg(){
					string msg = "Cannot call '" ~ fun.stringof ~ "' with arguments " ~
						"(" ~ value.stringof;
                    foreach(T; Ts)
						msg ~= ", " ~ T.stringof;
					msg ~= ").";
					return msg;
				}
				static assert(0, errormsg());
            }
		}
	}
}


///テンプレートパラメータの置換を行う
template Trans(uint x,uint y,E...)if(E.length > x && E.length > y){
	static if(x > y)
		alias Trans!(y,x,E) Trans;
	else static if(x == y)
		alias E Trans;
	else static if(x > 0)
		alias TypeTuple!(E[0],Trans!(x-1,y-1,E[1..$])) Trans;
	else static if(x == 0){
		static assert(E.length > y);
		alias TypeTuple!(E[y],E[1..y],E[0],E[y+1..$]) Trans;
	}else
		static assert(0);
}


///等差数列のタプルを作成
template IotaTuple(int Start,int End,int Diff = 1){
	static assert(Diff);
	
	static if(Diff > 0)
		static assert(Start <= End);
	else static if(Diff < 0)
		static assert(Start >= End);
	else
		static assert(0,"Diff of IotaTuple cannot 0");
	
	static if(Start == End)
		alias TypeTuple!() IotaTuple;
	else
		alias TypeTuple!(Start,IotaTuple!(Start+Diff,End,Diff)) IotaTuple;
}


///N次元の動的配列を作成
template NDimArray(T,uint N){
	static if(N == 0)
		alias T NDimArray;
	else
		alias NDimArray!(T,N-1)[] NDimArray;
}

///値タプルから型タプルを作成
template CreateTypeTuple(E...){
	static if(E.length == 0)
		alias TypeTuple!() CreateTypeTuple;
	else static if(!__traits(compiles,typeof(E[0])))
		static assert(0,E[0].stringof~" is Type.CreateTypeTuple need value");
	else
		alias TypeTuple!(typeof(E[0]),CreateTypeTuple!(E[1..$])) CreateTypeTuple;
}


///引数がすべて型であればtrueを返す。
template isAllType(E...){
	static if(E.length == 0)
		enum bool isAllType = false;
	else static if(E.length == 1)
		enum bool isAllType = !__traits(compiles,typeof(E[0]));
	else{
		static if(__traits(compiles,typeof(E[0])))
			enum bool isAllType = false;
		else
			enum bool isAllType = isAllType!(E[1..$]);
	}
}


///引数がすべて値であればtrueを返す。
template isAllValue(E...){
	static if(E.length == 0)
		enum bool isAllValue = false;
	else static if(E.length == 1)
		enum bool isAllValue = __traits(compiles,typeof(E[0]));
	else{
		static if(__traits(compiles,typeof(E[0])))
			enum bool isAllValue = isAllValue!(E[1..$]);
		else
			enum bool isAllValue = false;
	}
}