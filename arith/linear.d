module mydutil.arith.linear;

import std.algorithm;
import std.stdio;
import std.array;
import std.conv:toImpl;
import std.math;
import std.typecons;
import std.range;

//isCSVinはisCSVin(a,b)とすることでカンマ区切りされたbの要素の中にaが存在するかどうかを返す。
import mydutil.file.csv : isCSVin;

private immutable BinArrayOp = "+,-,*,/,%,^,&,|";
private immutable UnaArrayOp = "-,~";
private immutable RiNotLeOp = "/,%,^^,<<,>>,>>>,~,in";
private immutable RiEqLeOp = "+,-,*,&,|,^";
private immutable VecMat7 = "Vector!,Matrix!";
private immutable ArithOp = "+,-,*,/,%,^^,&,|,^,<<,>>,>>>";

version(unittest){
	import std.random;
	pragma(lib,"mydutil");
	unittest{
		writeln("Start Unittest ",__LINE__);
		Random ran = Random(unpredictableSeed);
		Matrix!real A = Matrix!real(3,3);A = 1;
		Matrix!real B = Matrix!real(3,3);B = 6;
		Matrix!real C = Matrix!real(3,3);C = 7;
		assert(C == (A+B));
		assert(A == C - 6);
		auto D = A[[0,1]..[0,3]];
		D[0][0] = 8;
		assert(A[0][0] == 8);
		
		A.roop(cast(real)uniform(-1024,1024,ran));
		
		auto lup = A.lupdec!(double);
		writeln("End Unittest ",__LINE__);
	}
	
	void main(){
		writeln("Unittest Done.");
	}
}



///別名定義
template PermMatrix(string RC){
	alias Matrix!("permutation",RC) PermMatrix;
}

///ditto
template LUPTuple(T){
	alias Tuple!(PermMatrix!"row","p",Matrix!T,"l",Matrix!T,"u") LUPTuple;
}

///ditto
template DiagMatrix(T)if(__traits(isArithmetic,T)){
	alias Matrix!("diagonal",T) DiagMatrix;
}


///一般行列
struct Matrix(T)if(__traits(isArithmetic,T)){
private:
	T[][] _val;
	
	/* 不変条件 速度低下が怖い場合は-releaseすること (dmd -O -release -inline で最高速度)　*/
	invariant(){
		//行の大きさはすべて同じ
		int x=-1 , y;
		for(int i=0;i<_val.length;i++){
			if(x < 0){
				x = _val[i].length;
				continue;
			}
			y = _val[i].length;
			assert(x == y);
			x = y;
		}
		
	}

public:

	///r行c列の行列を作成
	this(size_t r,size_t c)
	in{
		assert(r > 0 && c > 0 );
	}
	body{
		_val.length = r;
		for(int i=0;i<r;i++)
			_val[i].length = c;
	}
	
	///r行c列でnで初期化された行列を作成する
	this(size_t r,size_t c,T n)
	in{
		assert(r > 0 && c > 0 );
	}
	body{
		_val.length = r;
		for(int i=0;i<r;i++){
			_val[i].length = c;
			_val[i][] = n;
		}
	}
	
	///配列vaaから行列を作る。
	this(T[][] vaa)
	in{
		assert(vaa.length > 0);
		assert(vaa[0].length > 0);
	}
	body{
		_val.length = vaa.length;
		for(int i=0;i<vaa.length;i++){
			_val[i].length = vaa[i].length;
			_val[i][] = vaa[i][];
		}
	}
	/*
	///代入。参照をコピー
	ref Matrix!T opAssign(T n){
		for(int i=0;i<_val.length;++i)
			_val[i][] = n;
		return this;
	}
	
	///ditto
	ref Matrix!T opAssign(Matrix!T src){
		_val = src._val;
		return this;
	}*/
	
	///行列の代入
	ref Matrix!T opAssign(E)(E src){
		static if(is(E:T)){
			for(int i=0;i<_val.length;++i)
				_val[i][] = src;
			return this;
		}else static if(is(E == Matrix!T)){
			_val = src._val.dup;
			return this;
		}else static if(E.stringof[0..6] == "Matrix" && is(typeof(E.det):T)){
			if(row != src.row || column != src.column)
				resize(src.row,src.column);
			
			for(int i=0;i<_val.length;++i)
				for(int j=0;j<_val[i].length;++j)
					_val[i][j] = src[i][j];
			return this;
		}
	}
	
	unittest{
		Matrix!int A = Matrix!int(3,3,1);
		auto D = A;
		D[0][0] = 0;
		assert(A[0][0] == 0);
	}
	
	///行列の積
	Matrix!T opBinary(string s:"*")(Matrix!T src)
	in{
		assert(_val[0].length == src._val.length);
	}
	body{
		Matrix!T dst = Matrix!T(_val.length,_val[0].length,0);
		for(int i=0;i<_val.length;++i)
			for(int j=0;j<_val[i].length;++j)
				for(int n=0;n<_val[i].length;++n)
					dst[i][j] += _val[i][n] * src[n][j];
					
		return dst;
	}
	
	///ditto
	ref Matrix!T opOpAssign(string s:"*")(Matrix!T src)
	in{
		assert(_val[0].length == src._val.length);
	}
	body{
		Matrix!T Temp = Matrix!T(_val);
		for(int i=0;i<_val.length;++i)
			for(int j=0;j<_val[i].length;++j){
				_val[i][j] = 0;
				for(int n=0;n<_val[i].length;++n)
					_val[i][j] += Temp[i][n] * src[n][j];
			}
		return this;
	}
	
	///行列の+,-,/,<<,>>,>>>,&,|,^,%はそれぞれの要素をそれぞれ演算したものになる。
	Matrix!T opBinary(string s)(Matrix!T src)if(!s.isCSVin("*,^^,~,in"))
	in{
		assert(src._val.length == _val.length);
		assert(src._val[0].length == _val[0].length);
	}
	body{
		Matrix!T dst = Matrix!T(src._val.length , src._val[0].length);
		for(int i=0;i<_val.length;++i){
			static if(s.isCSVin("<<,>>,>>>")){
				for(int j=0;j<_val[i].length;++j)
					mixin(q{dst._val[i][j] = _val[i][j]}~s~q{src._val[i][j];});
			}else{
				mixin(q{dst._val[i][] = _val[i][]}~s~q{src._val[i][];});
			}
		}
		return dst;
	}
	
	///ditto
	ref Matrix!T opOpAssign(string s)(Matrix!T src)if(!s.isCSVin("*,^^,~,in"))
	in{
		assert(src._val.length == _val.length);
		assert(src._val[0].length == _val[0].length);
	}
	body{
		for(int i=0;i<_val.length;++i){
			static if(s.isCSVin("<<,>>,>>>")){	//配列演算が使えない場合
				for(int j=0;j<_val[i].length;++j)
					mixin(q{_val[i][j]}~s~q{= src._val[i][j];});
			}else{
				mixin("_val[i][]"~s~"= src._val[i][];");
			}
		}
		return this;
	}
	
	///行列とベクトルの積
	Vector!T opBinary(string s:"*")(Vector!T src)
	in{
		assert(src.length == _val[0].length);
	}
	body{
		Vector!T dst = Vector!T(_val[0].length,0);
		for(int i=0;i<dst.length;++i){
			for(int j=0;j<_val[i].length;++j)
				dst[i] += _val[i][j] * src[j];
		}
		return dst;
	}
	
	///ditto
	Vector!T opBinaryRight(string s:"*")(Vector!T src)
	in{
		assert(src.length == _val.length);
	}
	body{
		Vector!T dst = Vector!T(_val.length,0);
		for(int i=0;i<dst.length;++i){
			for(int j=0;j<_val.length;++j)
				dst[i] += src[j] * _val[j][i];
		}
		return dst;
	}
	
	///ただの数との演算+,-,*,/,^,&,|,<<,>>,>>>
	Matrix!T opBinary(string s,U)(U n)if(s.isCSVin("+,-,*,/,%,^,&,|,<<,>>,>>>")&&__traits(isArithmetic,U)){
		Matrix!T dst = Matrix!T(_val.length,_val[0].length);
		for(int i=0;i<_val.length;++i){
			static if(s.isCSVin("+,-,*,/,%,^,&,|")){
				mixin("dst._val[i][] = _val[i][] "~s~"n;");
			}else{
				for(int j=0;j<_val[i].length;++j)
					mixin("dst._val[i][j] = _val[i][j] "~s~" n;");
			}
		}
		return dst;
	}
	
	///ditto
	Matrix!T opBinaryRight(string s,U)(U n)if(s.isCSVin("+,*,^,&,|") && __traits(isArithmetic,U)){
		Matrix!T dst = Matrix!T(_val.length,_val[0].length);
		for(int i=0;i<_val.length;++i){
			static if(s.isCSVin("+,*,^,&,|")){
				mixin("dst._val[i][] = _val[i][] "~s~"n ;");
			}else{
				for(int j=0;j<_val[i].length;++j)
					mixin("dst._val[i][j] = n"~s~"_val[i][j];");
			}
		}
		return dst;
	}
	
	///ditto
	ref Matrix!T opOpAssign(string s,U)(U n)if(s.isCSVin("+,-,*,/,%,^,&,|,<<,>>,>>>") && __traits(isArithmetic,U)){
		for(int i=0;i<_val.length;++i){
			static if(s.isCSVin("+,-,*,/,%,^,&,|")){
				mixin("_val[i][] "~s~"= n");
			}else{
				for(int j=0;j<_val[i].length;++j)
					mixin("dst._val[i][j] "~s~"= n;");
			}
		}
		return this;
	}
	
	///単項演算++,--,-,~
	Matrix!T opUnary(string s)()if(/+s=="-"||s=="~"+/s.isCSVin("-,~,++,--")){
		Matrix!T dst = Matrix!T(_val);
		for(int i=0;i<_val.length;++i){
			static if(s.isCSVin("-,~")){
				dst._val[i][] = mixin(s~"_val[i][]");
			}else{
				for(int j=0;j<_val[i].length;++j)
					mixin(s~"_val[i][j];");
			}
		}
		return dst;
	}
	
	///等号演算子
	bool opEquals(Matrix!T src){
		if(src._val.length != _val.length)
			return false;
		
		for(int i=0;i<_val.length;++i){
			if(_val[i].length != src._val[i].length)
				return false;
				
			for(int j=0;j<_val[i].length;++j){
				if(_val[i][j] != src._val[i][j])
					return false;
			}
		}
		return true;
	}
	
	///インデックス演算子
	ref T[] opIndex(size_t r)
	in{
		assert(_val.length > r);
	}
	body{
		return _val[r];
	}
	
	///代入インデックス演算子
	ref T[] opIndexAssign(ref T[] x,size_t r)
	in{
		assert(_val.length > r);
		assert(x.length == _val.length);
	}
	body{
		_val[r][] = x[];
		return _val[r];
	}
	

	///2次インデックス演算子
	ref T opIndex(size_t r,size_t c)
	in{
		assert(_val.length > r);
		assert(_val[r].length > c);
	}
	body{
		return _val[r][c];
	}
	

	///2次代入インデックス演算子
	ref T opIndexAssign(T val, size_t r,size_t c)
	in{
		assert(_val.length > r);
		assert(_val[r].length > c);
	}
	body{
		_val[r][c] = val;
		return _val[r][c];
	}
	
	///スライス。コピーを返す。
	Matrix!T opSlice(){
		Matrix!T dst;
		dst._val.length = _val.length;
		for(int i=0;i<_val.length;++i)
			dst._val[i] = _val[i].dup;
		return dst;
	}
	unittest{
		Matrix!int A = Matrix!int(3,3,1);
		auto D = A[];	//コピーを返す。
		D[0][0] = 0;
		assert(A[0][0] == 1);
	}
	
	
	///スライス。rとcに行,列の範囲を入れると参照で返す。
	Matrix!T opSlice(uint[2] r,uint[2] c)
	in{
		assert(r[0] < r[1]);
		assert(c[0] < c[1]);
		assert(r[1] <= _val.length);
		assert(c[1] <= _val[0].length);
	}
	body{
		Matrix!T dst;
		dst._val.length = r[1] - r[0];
		for(int i=r[0];i<r[1];++i){
			dst._val[i] = _val[i][c[0]..c[1]];
		}
		return dst;
	}
	unittest{
		Matrix!int A = Matrix!int(3,3,1);
		auto D = A[[0,3]..[0,1]];	//0列目を参照で返す
		D[1][0] = 0;
		assert(A[1][0] == 0);
	}
	
	
	///"r"または"c"とstringに入れ込むと、そのidxの行又は列が配列として返ってくる。
	T[] opIndex(string s,size_t idx)
	in{
		assert(s=="r"||s=="c");
		if(s=="r"){
			assert(_val.length > idx);
		}else if(s=="c"){
			assert(_val[0].length > idx);
		}else
			assert(0);
	}
	body{
		if(s == "r"){
			return _val[idx];
		}else if(s == "c"){
			T[] dst;
			for(int i=0;i<_val.length;++i)
				dst ~= _val[i][idx];
			return dst;
		}else
			assert(0);
	}
	
	///"r"または"c"とstringに入れ込むと、そのidxの行又は列に配列を入れ込むことができる。
	ref Matrix!T opIndexAssign(ref T[] src, string s,size_t idx)
	in{
		assert(s=="r"||s=="c");
		if(s=="r"){
			assert(_val.length > idx);
			assert(_val[0].length == src.length);
		}else if(s=="c"){
			assert(_val[0].length > idx);
			assert(_val.length == src.length);
		}else
			assert(0);
	}
	body{
		if(s == "r"){
			_val[idx][] = src[];
		}else if(s == "c"){
			for(int i=0;i<_val.length;++i)
				_val[i][idx] = src[i];
		}else
			assert(0);
		
		return this;
	}
	
	///キャスト　cast(U)でMatrix!U型にキャストする。
	Matrix!U ElementCast(U)()if(__traits(compiles,cast(U)T.init) && __traits(isArithmetic,U) && !is(T == U)){
		Matrix!U dst = Matrix!U(_val.length,_val[0].length);
		for(int i=0;i<_val.length;++i)
			for(int j=0;j<_val[0].length;++j)
				dst[i][j] = cast(U)_val[i][j];
		return dst;
	}
	
	///逆行列を返す。
	Matrix!R inverse(R=T)()if(__traits(isFloating,R)&&__traits(compiles,cast(R)T.init))
	in{
		int rsize = _val.length;
		assert(rsize != 0);
		int csize = _val[0].length;
		assert(rsize == csize);
	}
	body{
		try{
			/*LUP分解からP,L,U行列をそれぞれ持ってくる。
			* ここで、A*B=EとなるBを考えると、
			* P*L*U*B=Eとなる。
			* 両辺にPをかけて
			* L*U*B=Pとなる。ここで、
			* L*U*B[][i] = P[][i]となることに注目すると、
			* 任意のB[][i]は
			* UB[][i] = Z[][i]として
			* LZ[][i] = P[][i]が成り立つ。
			* ここで、Z[][i]について解くと、Z[i]が求まるので、
			* UB[][i] = Z[][i]　を使い、
			* B[][i] も求まる。
			* この操作をすべての列について行えば、B行列がもとまり、
			* B行列はAの逆行列であることがわかる。
			*/
			auto lup = lupdec!R;
			Matrix!R dst = Matrix!R(_val.length,_val[0].length);
			Matrix!R Z = Matrix!R(_val.length,_val[0].length);
			auto p = cast(Matrix!real)lup[0];
			
			//このループではZを求める。
			for(int k=0;k<_val.length;++k)
				for(int i=0;i<_val.length;++i){
					Z[i][k] = p[i][k];
					for(int j=0;j<i;++j)
						Z[i][k] -= lup[1][i][j] * Z[j][k];
				}
			
			//このループではZから逆行列を求める
			for(int k=0;k<_val.length;++k)
				for(int i=_val.length-1;i>=0;--i){
					dst[i][k] = Z[i][k];
					for(int j=i+1;j<_val.length;++j)
						dst[i][k] -= lup[2][i][j] * dst[j][k];
					dst[i][k] /= lup[2][i][i];
				}
			return dst;
		}
		catch(Exception ex){
			/*余因子行列の転置行列の要素すべてを
			* もとの行列の行列式の値でわれば
			* 逆行列となる。
			*/
			R Det = cast(R)det();
			if(Det == 0)throw new Exception("this matrix is not regular matrix");
			static if(typeid(R) == typeid(T))
				return (adjoint().trans())/Det;
			else
				return (adjoint().trans().ElementCast!R)/Det;
		}
	}
	
	///行列式の値
	@property R det(R=T)()if(__traits(compiles,cast(R)T.init))
	in{
		int rsize = _val.length;
		assert(rsize != 0);
		int csize = _val[0].length;
		assert(rsize == csize);
	}
	body{
		static if(__traits(isFloating,R)){
			try{
				auto lup = lupdec!R;
				R dst = 1;
				for(int i=0;i<_val.length;++i)
					dst *= lup[2][i][i];
				return dst;
			}
			catch(Exception ex){
				//1行目(r=0)の余因子展開により求める。
				R dst = 0;
				for(int i=0;i<_val.length;++i)
					dst += _val[0][i] * confactor(0,i);
				return dst;
			}
		}else{
			R dst = 0;
			for(int i=0;i<_val.length;++i)
				dst += _val[0][i] * confactor(0,i);
			return dst;
		}
	}
	
	///i,j余因子
	T confactor(int x,int y)
	in{
		//不変条件invariantですべての行の大きさが等しいことは保証される
		int l1 = _val.length;
		assert(l1 != 0);
		
		//正方行列かつ大きさは0でない
		assert(l1 == _val[0].length);
		
		//x,yはl1以下である
		assert(l1 > x);
		assert(l1 > y);
	}
	body{
		Matrix!T Temp = Matrix!T(_val.length-1,_val[0].length-1);
		
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
	
	///余因子行列
	@property Matrix!T adjoint()
	in{
		//不変条件invariantですべての行の大きさが等しいことは保証される
		int l1 = _val.length;
		
		//正方行列かつ大きさは0でない
		assert(l1 != 0);
		assert(l1 == _val[0].length);
	}
	body{
		Matrix!T dst = Matrix!T(_val.length,_val[0].length);
		for(int i=0;i<_val.length;++i)
			for(int j=0;j<_val[i].length;++j)
				dst[i][j] = confactor(j,i);
		return dst;
	}
	
	/**
	* LUP分解. Aに対して PA = LU となるLUPを返す.
	* 
	* Example:
	* --------------------------
	* auto LUP = A.lupdec();
	* assert(LUP[0]*LUP[1]*LUP[2]==A);
	* --------------------------
	* 
	* Return: P,L,Uの順番で入れられたTupleを返す
	* Throw: 失敗時,Exception
	* 
	*/
	//浮動小数点でないと、LUP分解できないようにしておかないと正常にLUP分解できない
	//すべて整数値で結果が欲しい場合にはA.lupdec!(real).to!intというようにキャストする
	@property LUPTuple!R lupdec(R=T)()if(__traits(isFloating,R)&&__traits(compiles,cast(R)T.init))
	in{
		assert(_val.length != 0);
		assert(_val.length == _val[0].length);
	}
	body{
		//LU分解を行う
		Matrix!R L = Matrix!R(row,column,0);
		Matrix!R U = Matrix!R(row,column,0);
		PermMatrix!"row" P = PermMatrix!"row"(row);
		Matrix!R A = Matrix!R(row,column,0);
		
		//Lの対角成分をすべて1に
		for(int i=0;i<row && i<column;++i)
			L[i][i] = 1;
		
	//static ifを使うことにより、コンパイルを条件分岐。TとRが異なる型の場合にはelseがコンパイルされる。
	//本当はaliasを使ったほうが効率がいいが、なぜかコンパイラに怒られる
		static if(T.stringof == R.stringof){
			Matrix!R SRC = Matrix!R(_val);
		}else{
			Matrix!R SRC = ElementCast!R;
		}
		if(SRC[0][0] == 0){
			//置換を行う
			for(int i=1;i<row;++i){
				if(SRC[i][0] != 0){//入れ替え
					A._val[0] = SRC._val[i];
					A._val[i] = SRC._val[0];
					
					P.swap(0,i);
				}else{
					A._val[i] = SRC._val[i];
				}
			}
		}else{
			for(int i=0;i<row;++i)
				A._val[i] = SRC._val[i];
		}
		//もし未だに(0,0)成分が0ならすべての0行目の成分は0であり、LUP分解は不可能。
		if(A[0][0] == 0)
			throw new Exception("all row:0 element are 0.");
		
		//まずUの一列目の計算を行う
		for(int j=0;j<column;++j)
			U[0][j] = A[0][j];
		
		//1行目のLについて計算を行う
		for(int i=1;i<row;++i)
			L[i][0] = A[i][0] / U[0][0];
		
		//1列目(行目)以降のL,Uについて計算する
		for(int i=1;i<row;i++){
			//Uについて
			for(int j=i;j<column;++j){
				U[i][j] = A[i][j];
				//ここから引いていく
				for(int k=0;k<i;++k)
					U[i][j] -= L[i][k]*U[k][j];
			}
			//0なら入れ替え
			if(U[i][i] == 0){
				bool finish;
				if(i == row)throw new Exception("final diagonal element is 0.");	//つまり最終成分が0なら例外
				for(int l=i+1;l<row;++l)
					if(_val[l][l] != _val[i][i]){//入れ替え
						R[] temp;
						temp = A._val[i];
						A._val[i] = A._val[l];
						A._val[l] = temp;

						P.swap(i,l);
						finish = true;
						break;
					}
				if(!finish)
					throw new Exception("Can't LUPdecompose this Matrix.\n"~A.toString());
				--i;
				continue;
			}
			
			//Lについて
			for(int j=i+1;j<row;j++){
				L[j][i] = A[j][i];
				//ここから引いていく
				for(int k=0;k<i;++k)
					L[j][i] -= L[j][k]*U[k][i];
				//最後に割ってやる
				L[j][i] /= U[i][i];
			}
		}
		
		//Matrix!R[] dst;
		LUPTuple!R dst;
		dst[0] = P;
		dst[1] = L;
		dst[2] = U;
		return dst;
	}
	unittest{
		writeln("Start Unittest ",__LINE__);
		Matrix!real A = Matrix!real([[1,1,1],[11,13,23],[1,52,1]]);
		auto lup = A.lupdec!real;
		auto Adelta = lup[0] * lup[1] * lup[2];
		writeln("End Unittest ",__LINE__);
	}
	
	///転置行列を返す
	@property Matrix!T trans()
	in{
		assert(_val.length != 0);
		assert(_val[0].length != 0);
	}
	body{
		Matrix!T dst = Matrix!T(_val[0].length,_val.length);
		for(int i=0;i<_val.length;++i)
			for(int j=0;j<_val[i].length;++j)
				dst[j][i] = _val[i][j];
		return dst;
	}
	
	///行列のコピーを返す
	@property Matrix!T dup(){
		return Matrix!T(_val);
	}
	
	///行列の大きさを0x0にする.
	@property void clear(){
		for(int i=0;i<_val.length;++i)
			_val[i].length = 0;
		_val.length = 0;
	}
	
	///行列の大きさの変更
	void resize(size_t R,size_t C)
	in{
		assert(R > 0);
		assert(C > 0);
	}
	body{
		_val.length = R;
		for(int i=0;i<R;++i)
			_val[i].length = C;
	}
	
	///行の大きさ
	@property size_t row(){
		return _val.length;
	}
	
	///列の大きさ
	@property size_t column()
	in{assert(_val.length != 0);}
	body{
		return _val[0].length;
	}
	
	///文字列化
	string toString(){
		string dst;
		for(int i=0;i<_val.length;++i){
			for(int j=0;j<_val.length;++j)
				dst ~= toImpl!(string,T)(_val[i][j]) ~ "\t";
			dst ~= "\n";
		}
		return dst;
	}
	unittest{
		Matrix!int a = Matrix!int(3,3);
		//writeln(a);
	}
	
	///関数などを引数有りで入れてやると面白い事になるだけ
	void roop(lazy T dg){
		for(int i=0;i<_val.length;++i)
			for(int j=0;j<_val[i].length;++j)
				_val[i][j] = dg();
	}
	
}

///n次置換行列
struct Matrix(string MT:"permutation",string RC="row")if(RC == "row" || RC == "column"){
private:
	size_t[] _val;
	
public:
	
	///size × sizeの大きさの置換行列を作る。
	this(size_t size){
		_val.length = size;
		for(int i=0;i<size;++i)
			_val[i] = i;
	}
	
	///a行(列)とb行(列)を入れ替える。
	void swap(size_t a,size_t b)
	in{
		assert(a < _val.length);
		assert(b < _val.length);
	}
	body{
		size_t temp = _val[a];
		_val[a] = _val[b];
		_val[b] = temp;
	}
	
	///大きさを返す
	@property size_t row(){return _val.length;}
	///ditto
	alias row column;
	
	static if(RC == "row"){
		///一般行列との積。つまり一般行列を行について置換する。
		Matrix!T opBinary(string s:"*",T)(Matrix!T src)
		in{assert(_val.length == src.row);}
		body{
			Matrix!T dst = Matrix!T(src.row,src.column);
			for(int i=0;i<_val.length;++i)
					dst._val[i] = src._val[_val[i]].dup;
			return dst;
		}
	}else{
		///一般行列との積。つまり一般行列を列について置換する。
		Matrix!T opBinaryRight(string s:"*",T)(Matrix!T src)
		in{assert(_val.length == src.column);}
		body{
			Matrix!T dst = Matrix!T(src._val);
			for(int j=0;j<_val.length;++j)
				if(j != _val[j])
					for(int i=0;i<src.row;++i)
						dst[i][j] = src[i][_val[j]];
			return dst;
		}
	}	
	
	///基本行列型に変換する。
	U opCast(U)()if(U.stringof[0..7] == "Matrix!" ){
		static assert(is(U A:Matrix!V,V),"not cast to "~U.stringof);
		static assert(!is(typeof(V) == string),"not cast to "~U.stringof);
		U dst = U(_val.length,_val.length,0);
		for(int i=0;i<_val.length;++i){
			static if(RC == "row")
				dst[i][_val[i]] = 1;
			else
				dst[_val[i]][i] = 1;
		}
		return dst;
	}
	
	///置換行列同士のコピー
	ref typeof(this) opAssign(typeof(this) src){
		_val = src._val;
		return this;
	}
	
	///コピーを返す。
	typeof(this) opSlice(){
		Matrix!(MT,RC) dst;
		dst._val = _val.dup;
		return dst;
	}
	
	///インデックス演算子
	size_t opIndex(size_t s)
	in{assert(s < _val.length);}
	body{
		return _val[s];
	}
	
	invariant(){
		bool[] ch;
		ch.length = _val.length;
		for(int i=0;i<_val.length;++i){
			assert(ch[_val[i]] == false);
			ch[_val[i]] = true;
		}
	}
}
unittest{
	//writeln("Start Unittest ",__LINE__);
	import std.algorithm;
	Matrix!int A = Matrix!int([[0,1,2],[3,4,5],[6,7,8]]);
	
	auto Pr = Matrix!"permutation"(3);
	auto Pc = Matrix!("permutation","column")(3);
	assert(Pr.row == 3);
	assert(Pr.column == 3);
	Pr.swap(1,2);
	Pr.swap(0,1);
	
	Pc.swap(1,2);
	Pc.swap(0,1);
	//(1,2)と(0,1)をすると、abcは最終的にはcabとなる。	
	auto Ars = Pr * A;
	auto Acs = A * Pc;
	
	assert(reduce!"a+b"(A[0]) == reduce!"a+b"(Ars[1]));
	assert(reduce!"a+b"(A[1]) == reduce!"a+b"(Ars[2]));
	assert(reduce!"a+b"(A[2]) == reduce!"a+b"(Ars[0]));
	
	assert(reduce!"a+b"(A._val.transversal(0)) == reduce!"a+b"(Acs._val.transversal(1)));
	assert(reduce!"a+b"(A._val.transversal(1)) == reduce!"a+b"(Acs._val.transversal(2)));
	assert(reduce!"a+b"(A._val.transversal(2)) == reduce!"a+b"(Acs._val.transversal(0)));
	
	//auto PrToInt = Pr.to!"row";
	//auto PcToInt = Pc.to!"column";
	auto PrToInt = cast(Matrix!int)Pr;
	auto PcToInt = cast(Matrix!int)Pc;
	
	auto AIntPr = PrToInt * A;
	auto AIntPc = A * PcToInt;
	assert(AIntPr == Ars);
	assert(AIntPc == Acs);
	//writeln("End Unittest ",__LINE__);
}

///n次対角正方
struct Matrix(string MT:"diagonal",T)if(isArithmetic,T){
	T[] _val;
	
	///sizeの大きさの対角行列(正方行列)
	this(size_t size){
		_val.length = size;
		_val[] = cast(T)1;
	}
	this(T[] src){
		_val = src.dup;
	}
	
	///行列の行の大きさ
	@property size_t row(){
		return _val.length;
	}
	///行列の列の大きさ
	alias row column;
	
	///一般行列との積。つまり、それぞれの行をn倍する。
	Matrix!T opBinary(string s:"*")(Matrix!T src)
	in{
		assert(_val.length == src._val.length);
		assert(src._val[0].length != 0);
	}
	body{
		Matrix!T dst = Matrix!T(src._val.length,src._val[0].length);
		for(int i=0;i<_val.length;++i)
			dst._val[i][] = src._val[i][] * _val[i];
		return dst;
	}
	unittest{
		writeln("Unittest Start ",__LINE__);
		DiagMatrix!int d = DiagMatrix!int([1,2,3]);
		Matrix!int test = Matrix!int(3,3,1);
		Matrix!int check = Matrix!int([[1,1,1],[2,2,2],[3,3,3]]);
		assert(d*test == check);
		writeln("Unittest End ",__LINE__);
	}
	
	///一般行列との積。つまり、それぞれの列をn倍する。
	Matrix!T opBinaryRight(string s:"*")(Matrix!T src)
	in{
		assert(src._val.length != 0);
		assert(_val._val[0].length == src._val.length);
	}
	body{
		Matrix!T dst = Matrix!T(src._val.length,src._val[0].length);
		for(int i=0;i<src._val.length;++i)
			dst._val[i][] = src._val[i][] * _val[];
		return dst;
	}
	unittest{
		writeln("Unittest Start ",__LINE__);
		DiagMatrix!int d = DiagMatrix!int([1,2,3]);
		Matrix!int test = Matrix!int(3,3,1);
		Matrix!int check = Matrix!int([[1,2,3],[1,2,3],[1,2,3]]);
		assert(test*d == check);
		writeln("Unittest End ",__LINE__);
	}
	
	///代入
	ref typeof(this) opAssign(typeof(this) src){
		_val = src._val;
		return this;
	}
	
	///インデックス演算子
	T[] opIndex(size_t idx)
	in{
		assert(_val.length > idx);
	}
	body{
		T[] dst;
		static if(T.init == 0){
			dst[idx] = _val[idx];
			return dst;
		}else{
			dst[] = cast(T)0;
			dst[idx] = _val[idx];
			return dst;
		}
	}
	
	T opIndex(size_t idx1,size_t idx2)
	in{
		assert(_val.length > idx1 && _val.length > idx2);
	}
	body{
		if(idx1 == idx2)
			return _val[idx1];
		else
			return cast(T)0;
	}
	
	///コピーを返す。
	typeof(this) opSlice(){
		typeof(this) dst;
		dst._val = _val.dup;
		return dst;
	}
	
	///T型からU型の対角行列に変換
	@property Matrix!("diagonal",U) to(U)()if((U.stringof != T.stringof) && __traits(compiles,cast(U)T.init)){
		Matrix!("diagonal",U) dst;
		dst._val = cast(U)(_val.dup);
	}
	
	///T型のMatrix!Tに変換する。
	@property Matrix!T to(){
		Matrix!T dst = Matrix!T(_val.length,_val.length);
		for(int i=0;i<_val.length;++i)
			dst._val[i][i] = _val[i];
		return dst;
	}
}

/+	巡回行列
struct Matrix(string MT:"circulant",T)
+/

///ベクトル
struct Vector(T)if(__traits(isArithmetic,T)){
private:
	T[] _val;
	
public:
	///size次元のベクトルを作成
	this(size_t size,T init = T.init)
	in{assert(size > 0);}
	body{
		_val.length = size;
		_val[] = init;
	}
	
	///配列からベクトルを作成
	this(T[] src){
		_val = src.dup;
	}
	
	///インデックス演算子
	ref T opIndex(size_t idx)
	in{assert(idx < _val.length);}
	body{return _val[idx];}
	
	///ditto
	ref T opIndexAssign(T v,size_t idx)
	in{assert(idx < _val.length);}
	body{_val[idx] = v;return _val[idx];}
	
	///スライス演算子。コピーを返す
	Vector!T opSlice(){
		return Vector!T(_val);
	}
	
	///スライス演算子。組み込み配列のように動作する。
	Vector!T opSlice(uint a,uint b)
	in{
		assert(b > a);
		assert(b <= _val.length);
	}
	body{
		Vector!T dst;
		dst._val = _val[a..b];
		return dst;
	}
	
	///代入。ベクトルの場合は参照をコピーし、値の場合はすべての要素に値を代入する。
	ref Vector!T opAssign(T n){
		_val[] = n;
		return this;
	}
	///ditto
	ref Vector!T opAssign(Vector!T V){
		_val = V._val;
		return this;
	}
	
	///ベクトルの足し算、引き算
	Vector!T opBinary(string s)(Vector!T V)if(s=="+"||s=="-")
	in{
		assert(_val.length == V.length);
	}
	body{
		Vector!T dst = Vector!T(_val.length);
		mixin("dst._val[] = _val[]"~s~"V._val[];");
		return dst;
	}
	
	///ditto
	ref Vector!T opOpAssign(string s)(Vector!T V)if(s=="+"||s=="-")
	in{
		assert(_val.length == V.length);
	}
	body{
		mixin("_val[] "~s~"= V._val[];");
		return this;
	}
	
	///ベクトルと数の+,-,*,/,%,^,&,|演算
	Vector!T opBinary(string s,U)(U n)if(s.isCSVin("+,-,*,/,%,^,&,|")&&__traits(isArithmetic,U)){
		Vector!T dst = Vector!T(_val.length);
		mixin("dst._val[] = _val[] "~s~" n;");
		return dst;
	}
	
	///ditto
	ref Vector!T opOpAssign(string s,U)(U n)if(s.isCSVin("+,-,*,/,%,^,&,|")&&__traits(isArithmetic,U)){
		mixin("_val[] "~s~"= n;");
		return this;
	}
	
	///n op Vector という形での+,-,*,/,%,^,&,|演算
	Vector!T opBinaryRight(string s,U)(U n)if(s.isCSVin("+,*,^,&,|")&&__traits(isArithmetic,U)){
		Vector!T dst = Vector!T(_val.length);
		mixin("dst._val[] = _val[]"~s~"n;");
		return dst;
	}
	
	///ditto
	Vector!T opBinaryRight(string s,U)(U n)if(s.isCSVin("-,/,%")&&__traits(isArithmetic,U)){
		Vector!T dst = Vector!T(_val.length);
		mixin("dst._val[] = n"~s~"_val[]");
		return dst;
	}
	
	///等号演算子
	bool opEquals(Vector!T v){
		if(v.length != _val.length)return false;
		for(int i=0;i<_val.length;++i)
			if(_val[i] != v._val[i])return false;
		return true;
	}
	
	///大きさをリサイズする。
	@property void resize(size_t size){_val.length = size;}
	
	///ベクトルの次元数
	@property size_t length(){return _val.length;}
	///ditto
	@property size_t length(size_t resize){_val.length = resize;return _val.length;}
	
	///ドル記号
	@property size_t opDollar(){return _val.length;}
	
	///ベクトルが管理している配列を返す。
	@property ref T[] array(){return _val;}
	
	///ベクトルの文字列表現
	@property string toString(){return toImpl!(string,T[])(_val);}
	
	///ベクトルのノルムを返す。
	@property U abs(U=T)()if(__traits(isFloating,U)){
		U dst=0;
		for(int i=0;i<_val.length;++i)
			dst += _val[i]^^2;
		return sqrt(dst);
	}
	
	///ベクトルの大きさを返す
	@property clear(){_val.length = 0;}
	
	///ベクトルのコピーを返す。
	@property Vector!T dup(){return Vector!T(_val);}
	
	///要素のキャスト変換を行う
	@property Vector!U ElementCast(U)()
	if(__traits(compiles,cast(U)T.init) && __traits(isArithmetic,U) && !is(T == U)){
		return Vector!U(std.array.array(map!(a => cast(U)a)(_val)));
	}
	
	///キャスト:配列に変換可能
	U opCast(U:T[])(){
		return _val.dup;
	}	
	
	///スカラー積(内積)　sはscalar,Scalar,sのいずれか
	T prod(string s)(Vector!T src)if(s.isCSVin("scalar,Scalar,s"))
	in{assert(_val.length == src._val.length);}
	body{
		T ret = 0;
		for(int i=0;i<_val.length;++i)
			ret += _val[i] * src._val[i];
		return ret;
	}
	
	///ベクトル積　sはvector,Vector,vのいずれか。さらに次元数が1,3,7しか定義されていない。
	Vector!T prod(string s)(Vector!T src)if(s.isCSVin("vector,Vector,v"))
	in{
		assert(_val.length == src._val.length);
		assert(_val.length == 1 || _val.length == 3 || _val.length == 7);
	}
	body{
		Vector!T ret = Vector!T(_val.length,0);
		switch(_val.length){
			case 1:
				return ret;
			
			case 3:
				ret[0] = _val[1] * src[2] - _val[2] * src[1];
				ret[1] = _val[2] * src[0] - _val[0] * src[2];
				ret[2] = _val[0] * src[1] - _val[1] * src[0];
				
			case 7:
				ret[0] = _val[1]*V[2] - _val[2]*V[1] - _val[3]*V[4] + _val[4]*V[3] - _val[5]*V[6] + _val[6]*V[5];
				ret[1] =-_val[0]*V[2] + _val[2]*V[0] - _val[3]*V[5] + _val[4]*V[6] + _val[5]*V[3] - _val[6]*V[4];
				ret[2] = _val[0]*V[1] - _val[1]*V[0] - _val[3]*V[6] - _val[4]*V[5] + _val[5]*V[4] + _val[6]*V[3];
				ret[3] = _val[0]*V[4] + _val[1]*V[5] + _val[2]*V[6] - _val[4]*V[0] - _val[5]*V[1] - _val[6]*V[2];
				ret[4] =-_val[0]*V[3] - _val[1]*V[6] + _val[2]*V[5] + _val[3]*V[0] - _val[5]*V[2] + _val[6]*V[1];
				ret[5] = _val[0]*V[6] - _val[1]*V[3] - _val[2]*V[4] + _val[3]*V[1] + _val[4]*V[2] - _val[6]*V[0];
				ret[6] =-_val[0]*V[5] + _val[1]*V[4] - _val[2]*V[3] + _val[3]*V[2] - _val[4]*V[1] + _val[5]*V[0];
				return Ret;
			
			default:
				assert(0);
		}
	}
	
	///テンソル積　sはtensor,Tensor,tのいずれか
	Matrix!T prod(string s)(Vector!T src)if(s.isCSVin("tensor,Tensor,t"))
	in{assert(_val.length == src._val.length);}
	body{
		Matrix!T ret = Matrix!T(_val.length,src._val.length);
		for(int i=0;i<_val.length;++i)
			for(int j=0;j<src._val.length;++j)
				ret[i][j] = _val[i] * src._val[j];
		return ret;
	}
	
	///外積　sはexterior,Exterior,eのいずれか
	Matrix!T prod(string s)(Vector!T src)if(s.isCSVin("exterior,Exterior,e"))
	in{assert(_val.length == src._val.length);}
	body{
		Matrix!T ret = Matrix!T(_val.length,src._val.length);
		for(int i=0;i<_val.length;++i)
			for(int j=0;j<src._val.length;++j)
				ret._val[i][j] = _val[i]*src._val[j] - _val[j]*src._val[i];
		return ret;
	}

}

unittest{
	writeln("Start Unittest ",__LINE__);
		Vector!int A = Vector!int(3,3);
		Vector!int B = Vector!int(3,4);
		Vector!int C = Vector!int(3);
		C = 7;
		Vector!int D;
		D = A+B;
		assert(C==D);
	writeln("End Unittest ",__LINE__);
	//writeln(A[$-1]);
}

///Ax = b型の連立一次方程式を解く。 O(n^2) 
Vector!T lupsolve(T)(LUPTuple!T lup,Vector!T b)
in{
	assert(lup[0].row == b.length);
}
body{
	/*Ax = bという連立一次方程式でAをLUP分解すると
	* PLUx = y
	* LUx = Py
	* Lz = Py
	* これを解くと、ベクトルzが求まる
	* z = Uxなので、これを解くと、ベクトルxが求まる。
	*/
	Vector!T dst = Vector!T(b.length);
	T[] z;
	z.length = b.length;
	
	for(int i=0;i<z.length;++i){
		z[i] = b[lup[0][i]];			//ここで置換
		for(int j=0;j<i;++j)
			z[i] -= lup[1][i][j] * z[j];
	}
	
	for(int i=b.length-1;i>=0;--i){
		dst[i] = z[i];
		for(int j=i+1;j<b.length;++j)
			dst[i] -= lup[2][i][j] * dst[j];
		dst[i] /= lup[2][i][i];
	}
	return dst;
}

///Cramerの公式から連立一次方程式の解を出す
Vector!T cramersolve(T)(Matrix!T src,Vector!T b)
in{
	assert(src.row == b.length);
	assert(src.row == src.column);
}
body{
	auto dst = Vector!T(b.length,0);
	Matrix!T temp;
	auto srcdet = src.det!T;
	for(int i=0;i<b.length;++i){
		temp = src;
		dst[i] = (temp["c",i] = b.array).det!T / srcdet;
	}
	return dst;
}


///LUP分解の結果から行列の行列式の値を返す
@property T det(T)(LUPTuple!T lup){
	T dst = 1;
	for(int i=0;i<lup[2].row;++i)
		dst *= lup[2][i][i];
	return dst;
}

///LUP分解の結果から行列の行列式の値を返す。
@property Matrix!T inverse(T)(LUPTuple!T lup){
	int size = lup[1].row;
	Matrix!T dst = Matrix!T(size,size);
	Matrix!T Z = Matrix!T(size,size);
	auto p = cast(Matrix!T)(lup[0]);
	
	//このループではZを求める。
	for(int k=0;k<size;++k)
		for(int i=0;i<size;++i){
			Z[i][k] = p[i][k];
			for(int j=0;j<i;++j)
				Z[i][k] -= lup[1][i][j] * Z[j][k];
		}
	
	//このループではZから逆行列を求める
	for(int k=0;k<size;++k)
		for(int i=size-1;i>=0;--i){
			dst[i][k] = Z[i][k];
			for(int j=i+1;j<size;++j)
				dst[i][k] -= lup[2][i][j] * dst[j][k];
			dst[i][k] /= lup[2][i][i];
		}
	return dst;
}
unittest{
	Matrix!real A = Matrix!real([[2,1],[5,3]]);
	assert(A.inverse!real == inverse!real(A.lupdec!real));
}
unittest{
	import std.random;
	Matrix!real A = Matrix!real(100,100);
	A.roop(cast(real)uniform!"[]"(-1024,1024));
	//writeln(A.inverse!real);
}
