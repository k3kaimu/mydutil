module mydutil.arith.matrixs;

import std.traits;

version(unittest){
	import std.stdio;
	void main(){
		auto a = Matrix!(int,3,3)((int a,int b)=>a+b);
		Matrix!(int,3,3) b = 12;
		
		Matrix!int c = Matrix!int(12,12);
		assert(c.rows == 12);
		assert(c.cols == 12);
		auto d = a.ElementCast!long;
		auto e = a.ElementCast!string;
	}
}

/++行列を作成します。行列の大きさに指定がない(R=C=0)なら、その行列は動的な配列で構成される行列になります。
+ Example:
+ ---------------------
void main(){
	Matrix!int a;
	Matrix!(int,3,3) b;
	assert(a.rows == 0);
	assert(b.rows == 3);
}
+ ---------------------
+ 動的な行列では静的な行列と違う部分が多々あります。
+ たとえば、静的な行列同士の演算の場合には、ループの展開が行われます。
+ しかし、動的な行列と静的な行列,動的な行列同士の演算はループの展開は行われません。
+　動的行列と静的行列の演算の返り値は動的行列になるので注意が必要です。
+ また、静的行列はコンパイル時に大きさの判定ができるので、動的行列より高速に動作します。
+ さらに、release時には動的なチェックは行われませんので、静的な行列の方が安全です。
+ しかし、巨大な行列を扱う際には静的行列(10×10以上)ではコンパイルに時間がかかるため、動的行列を使うことを強く薦めます。
+ これらはmydutil.arith.vectorにも共通して言えることです。
+/
struct Matrix(T,uint R:0 = 0,uint C:0 = 0){		//動的な行列の場合
package:
	T[][] _val;
	
public:
	this(int r,int c){
		_val.length = r;
		for(int i=0;i<r;++i)
			_val[i].length = c;
	}
	
	@property size_t rows(){return _val.length;}
	@property size_t cols(){return _val[0].length;}
}

///ditto
struct Matrix(T,uint R=0,uint C=0){				//静的な行列の場合
private:
	alias IotaTuple!(0,R) ItR;
	alias IotaTuple!(0,C) ItC;

package:
	T[R][C] _val;
	
public:
	alias R rows;
	alias C cols;
	
//ここからは行列の初期化に関する宣言
	///コンストラクタ.UがT型に代入可能な型なら全要素にそれを代入します
	this(U)(U n)if(isAssignable!(T,U) && !isSomeFunction!U){
		foreach(i;ItR)
			_val[i][] = n;
	}
	
	
	///関数を渡すと、その関数から個々の要素を設定します。
	this(U)(U f)if(isSomeFunction!U){
		static assert(ParameterTypeTuple!(f).length == 2,"Number of function arguments must be two, not "~ParameterTypeTuple!(f).length.stringof);
		foreach(i;ItR)
			foreach(j;ItC)
				_val[i][j] = f(i,j);
	}
	

//ここからはプロパティの宣言
	///全要素をU型にキャストしたものを返します。
	@property Matrix!(U,R,C) ElementCast(U)(){
		static assert(__traits(compiles,cast(U)T.init) && __traits(isArithmetic,U) && !is(T == U),"can't be cast from "~T.stringof~" to "~U.stringof);
		Matrix!(U,R,C) dst;
		foreach(i;ItR)
			foreach(j;ItC)
				dst._val[i][j] = cast(U)_val[i][j];
		return dst;
	}
	
	///転置行列を返します
	@property Matrix!(T,C,R) trans(){
		Matrix!(T,C,R) dst;
		foreach(i;ItR)
			foreach(j;ItC)
				dst._val[j][i] = _val[i][j];
		return dst;
	}
	
	///動的行列を返します
	@property Matrix!T dup(){
		Matrix!T dst = Matrix!T(R,C);
		foreach(i;ItR)
			dst._val[i][] = _val[i][];
		return dst;
	}
	
//正方行列かつ、数値の行列の場合にのみ実装
	static if(R == C && isNumeric!T){
		/**PLU分解. Aに対して PA = LU となるPLUを返す.
		* Example:
		* --------------------------
		* auto PLU = A.pludec();
		* assert(PLU[0]*PLU[1]*PLU[2]==A);
		* --------------------------
		* 
		* Return: P,L,Uの順番で入れられたTupleを返す
		* Throw: 失敗時,Exception
		* 
		*/
		@property LUPTuple!(F,R,C) lupdec(F=T)()if(isAssignable!(F,T)){
			typeof(return) L = Matrix!(F,R,C).create!((int a,int b) => a==b),
							U = 0,A = 0;
			PermMatrix!"row" P = PermMatrix!"row"(row);
			
			static if(is(T == R)){
				if(_val[0][0] == 0){
					//置換を行う
					for(int i=1;i<R;++i){
						if(_val[i][0] != 0){//入れ替え
							A._val[0] = _val[i];
							A._val[i] = _val[0];
							
							P.swap(0,i);
						}else
							A._val[i] = _val[i];
					}
				}else
					for(int i=0;i<row;++i)
						A._val[i] = _val[i];
			}else{
				Matrix!F SRC = ElementCast!F;
				if(SRC[0][0] == 0){
					//置換を行う
					for(int i=1;i<R;++i){
						if(SRC[i][0] != 0){//入れ替え
							A._val[0] = SRC._val[i];
							A._val[i] = SRC._val[0];
							
							P.swap(0,i);
						}else
							A._val[i] = SRC._val[i];
					}
				}else
					for(int i=0;i<row;++i)
						A._val[i] = SRC._val[i];
			}
			
			//もし未だに(0,0)成分が0ならすべての0行目の成分は0であり、PLU分解は不可能。
			if(A[0][0] == 0)
				throw new Exception("all row:0 element are 0.");
				
			//まずUの一列目の計算を行う
			foreach(j;ItC)
				U[0][j] = A[0][j];
			
			//1行目のLについて計算を行う
			for(i;ItR[1..$])
				L[i][0] = A[i][0] / U[0][0];
			
			//1列目(行目)以降のL,Uについて計算する
			foreach(i;ItR[1..$]){
				//Uについて
				foreach(j;IotaTuple!(i,C)){
					U[i][j] = A[i][j];
					//ここから引いていく
					foreach(k;IotaTuple!(0,i))
						U[i][j] -= L[i][k]*U[k][j];
				}
				//0なら入れ替え
				if(U[i][i] == 0){
					bool finish;
					if(i == R)throw new Exception("final diagonal element is 0.");	//つまり最終成分が0なら例外
					foreach(l;IotaTuple!(i+1,R))
						if(_val[l][l] != _val[i][i]){//入れ替え
							F[] temp;
							temp = A._val[i];
							A._val[i] = A._val[l];
							A._val[l] = temp;

							P.swap(i,l);
							finish = true;
							break;
						}
					if(!finish)
						throw new Exception("Can't PLUdecompose this Matrix.\n"~A.toString());
					--i;
					continue;
				}
				
				//Lについて
				foreach(j;IotaTuple(i+1,R)){
					L[j][i] = A[j][i];
					//ここから引いていく
					foreach(k;IotaTuple!(0,i))
						L[j][i] -= L[j][k]*U[k][i];
					//最後に割ってやる
					L[j][i] /= U[i][i];
				}
			}
			
			//Matrix!R[] dst;
			PLUTuple!F dst;
			dst[0] = P;
			dst[1] = L;
			dst[2] = U;
			return dst;
		}
	
	
		///正方行列の場合に行列式の値を計算します
		@property F det(F=T)()if(isAssignable!(T,F)){
		}
		
		
		/++逆行列を返します。
		+ Throws:失敗時,Exception
		+/
		@property Matrix!(F,R,C) inverse(F=T)()if(isAssignable!(F,T)){
			try{
				auto plu = pludec!F;
				Matrix!(F,R,C) dst,Z;
				
				foreach(k;ItR)
					foreach(i;ItR){
						Z[i][k] = (p[i] == k) ? 1 : 0;
						foreach(j;IotaTuple!(0,i))
							Z[i][k] -= plu[1][i][j] * z[j][k];
					}
				
				foreach(k;ItR)
					foreach(i;IotaTuple!(R-1,-1,-1)){
						dst[i][k] = Z[i][k];
						foreach(j;ItR[i+1..R])
							dst[i][k] -= plu[2][i][j] * dst[j][k];
						dst[i][k] /= plu[2][i][i];
					}
				return dst;
			}catch(Exception ex){
				F det = det!F();
				if(det == 0)throw new Exception("this matrix is not regular matrix");
				static if(is(F == T))
					return (adjoint().trans())/Det;
				else
					return (adjoint().trans().ElementCast!R)/Det;
			}
		}
		
		///i,j余因子を返します。
		T confactor(size_t x,size_t y)
		in{
			assert(x < R);
			assert(y < C);
		}body{
			Matrix!(T,R-1,C-1) Temp;
				for(int i=0,i1=0;i<_val.length;++i){
				if(i == x)continue;
				
				for(int j=0,j1=0;j<_val[i].length;++j){
					if(j == y)continue;
					
					Temp[i1][j1] = _val[i][j];
					++j1;
				}
				++i1;
			}
			return (Temp.det() * (((x+y)%2)?-1:1));
		}
		
		
		///余因子行列を返します。
		@property Matrix!(T,C,R) adjoint(){
			Matrix!(T,C,R) dst;
			foreach(i;ItR)
				foreach(j;ItC)
					dst[j][i] = confactor(i,j);
			return dst;
		}
		
		///行列式の値を返します。
		@property F det(F=T)()if(__traits(isAssignable!(F,T))){
			static if(__traits(isFloating,F)){
				try{
					auto lup = kupdec!F;
					F dst = 1;
					foreach(i;ItR)
						dst *= lup[2][i][i];
					return dst;
				}catch(Exception ex){
					F dst = 0;
					foreach(i;ItR)
						dst += _val[0][i] * confactor(0,i);
					return dst;
				}
			}else{
				F dst = 0;
				foreach(o;ItR)
					dst += _val[0][i] * confactor(0,i);
				return dst;
			}
		}
		
	}
	
	
	///文字列化します。
	@property string toString(){
		string dst;
		foreach(i;ItR){
			foreach(j;ItC)
				dst ~= to!string(_val[i][j]) ~ "\t";
			dst ~= "\n";
		}
		return dst;
	}
	
	
}


private template IotaTuple(int Start,int End,int Diff = 1){
	static assert(Diff);
	
	static if(Diff > 0)
		static assert(Start <= End);
	else
		static assert(Start >= End);
	
	static if(Start == End)
		alias TypeTuple!() IotaTuple;
	else
		alias TypeTuple!(Start,IotaTuple!(Start+Diff,End,Diff)) IotaTuple;
}

private template TypeTuple(E...){
	alias E TypeTuple;
}