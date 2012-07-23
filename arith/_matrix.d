module mydutil.arith.matrix;

import std.c.stdlib;
import std.stdio;
import std.math;
import std.array;
import mydutil.arith.fraction;
import mydutil.util.utility;

struct Matrix(T){
	alias Mat this;
	//コンストラクタ
	this(int R,int C){
		Mat.length = R;
		for(int i=0;i<R;i++)
			Mat[i].length = C;
	}
	this(int R,int C,T src){
		Mat.length = R;
			for(int i=0;i<R;i++)
				Mat[i].length = C;
			for(int i=0;i<row;i++)
				for(int j=0;j<column;j++)
					Mat[i][j] = src;
	}
	
	//メンバ関数
	Matrix!(T) opAssign(T n){
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				Mat[i][j] = n;
		return this;
	}
	Matrix!(T) opAssign(Matrix!(T) M){
		Mat.length = M.row;
		for(int i=0;i<M.row;i++){
			Mat[i].length = M.column;
			for(int j=0;j<M.column;j++)
				Mat[i][j] = M[i][j];
		}
		return this;
	}
	
	Matrix!(T) opBinary(string s:"+")(Matrix!(T) M)
	in{assert(Mat.length == M.row && Mat[0].length == M.column);}
	body{
		Matrix!(T) ret = Matrix!(T)(Mat.length , Mat[0].length);
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				ret[i][j] = Mat[i][j] + M[i][j];
		return ret;
	}
	Matrix!(T)opOpAssign(string s:"+")(Matrix!(T) M)
	in{assert(Mat.length == M.row && Mat[0].length == M.column);}
	body{
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				Mat[i][j] += M[i][j];
		return this;
	}
	
	Matrix!(T) opBinary(string s:"-")(Matrix!(T) M)
	in{assert(Mat.length == M.row && Mat[0].length == M.column);}
	body{
		Matrix!(T) ret = Matrix!(T)(Mat.length , Mat[0].length);
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				ret[i][j] = Mat[i][j] - M[i][j];
		return ret;
	}
	Matrix!(T)opOpAssign(string s:"-")(Matrix!(T) M)
	in{assert(Mat.length == M.row && Mat[0].length == M.column);}
	body{
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				Mat[i][j] -= M[i][j];
		return this;
	}
	
	Matrix!(T) opBinary(string s:"*")(Matrix!(T) M)
	in{assert(Mat[0].length == M.row);}
	body{
		Matrix!(T) ret = Matrix!(T)(Mat.length,Mat[0].length,0);
		for(int i=0;i<ret.row;i++)
			for(int j=0;j<ret.column;j++)
				for(int n=0;n<Mat[0].length;n++)
					ret[i][j] += Mat[i][n] * M[n][j];
		return ret;
	}
	Matrix!(T) opOpAssign(string s:"*")(Matrix!(T) M)
	in{assert(Mat[0].length == M.row);}
	body{
		Matrix!(T) A = dup;
		opAssign(0);
		
		for(int i=0;i<ret.row;i++)
			for(int j=0;j<ret.column;j++)
				for(int n=0;n<ret[0].length;n++)
					Mat[i][j] += A[i][n] * M[n][j];
		
		return ret;
	}
	
	Vector!(T) opBinary(string s:"*")(Vector!(T) V)
	in{assert(Mat[0].length == V.length);}
	body{
		Vector!(T) ret = Vector!(T)(V.length,0);
		for(int i=0;i<ret.length;i++)
			for(int n=0;n<Mat[0].length;n++)
				ret[i] += Mat[i][n] * V[n];
		return ret;
	}
	
	Matrix!(T) opBinary(string s:"+")(T n){
		Matrix!(T) ret = Matrix!(T)(Mat.length , Mat[0].length);
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				ret[i][j] = Mat[i][j] + n;
		return ret;
	}
	Matrix!(T) opBinary(string s:"-")(T n){
		Matrix!(T) ret = Matrix!(T)(Mat.length , Mat[0].length);
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				ret[i][j] = Mat[i][j] - n;
		return ret;
	}
	Matrix!(T) opBinary(string s:"*")(T n){
		Matrix!(T) ret = Matrix!(T)(Mat.length , Mat[0].length);
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				ret[i][j] = Mat[i][j] * n;
		return ret;
	}
	Matrix!(T) opBinary(string s:"/")(T n){
		Matrix!(T) ret = Matrix!(T)(Mat.length , Mat[0].length);
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				ret[i][j] = Mat[i][j] / n;
		return ret;
	}
	Matrix!(T) opBinary(string s:"^^")(T n){
		Matrix!(T) ret = Matrix!(T)(Mat.length , Mat[0].length);
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				ret[i][j] = Mat[i][j] ^^ n;
		return ret;
	}
	Matrix!(T) opBinary(string s:"%")(T n){
		Matrix!(T) ret = Matrix!(T)(Mat.length , Mat[0].length);
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				ret[i][j] = Mat[i][j] % n;
		return ret;
	}
	
	Matrix!(T) opBinaryRight(string s:"+")(T n){
		Matrix!(T) ret = Matrix!(T)(Mat.length , Mat[0].length);
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				ret[i][j] = Mat[i][j] + n;
		return ret;
	}
	Matrix!(T) opBinaryRight(string s:"-")(T n){
		Matrix!(T) ret = Matrix!(T)(Mat.length , Mat[0].length);
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				ret[i][j] = Mat[i][j] - n;
		return ret;
	}
	Matrix!(T) opBinaryRight(string s:"*")(T n){
		Matrix!(T) ret = Matrix!(T)(Mat.length , Mat[0].length);
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				ret[i][j] = Mat[i][j] * n;
		return ret;
	}
	Matrix!(T) opBinaryRight(string s:"/")(T n){
		Matrix!(T) ret = Matrix!(T)(Mat.length , Mat[0].length);
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				ret[i][j] = n / Mat[i][j];
		return ret;
	}
	Matrix!(T) opBinaryRight(string s:"^^")(T n){
		Matrix!(T) ret = Matrix!(T)(Mat.length , Mat[0].length);
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				ret[i][j] = n ^^ Mat[i][j];
		return ret;
	}
	Matrix!(T) opBinaryRight(string s:"%")(T n){
		Matrix!(T) ret = Matrix!(T)(Mat.length , Mat[0].length);
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				ret[i][j] = n % Mat[i][j];
		return ret;
	}
	
	Matrix!(T) opOpAssign(string s:"+")(T n){
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				Mat[i][j] += n;
		return this;
	}
	Matrix!(T) opOpAssign(string s:"-")(T n){
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				Mat[i][j] -= n;
		return this;
	}
	Matrix!(T) opOpAssign(string s:"*")(T n){
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				Mat[i][j] *= n;
		return this;
	}
	Matrix!(T) opOpAssign(string s:"/")(T n){
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				Mat[i][j] /= n;
		return this;
	}
	Matrix!(T) opOpAssign(string s:"^^")(T n){
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				Mat[i][j] ^^= n;
		return this;
	}
	Matrix!(T) opOpAssign(string s:"%")(T n){
		for(int i=0;i<Mat.length;i++)
			for(int j=0;j<Mat[0].length;j++)
				Mat[i][j] %= n;
		return this;
	}
	
	Matrix!(T) dup(){
		Matrix!(T) ret = Matrix!(T)(row,column);
		for(int i=0;i<row;i++)
			for(int j=0;j<column;j++)
				ret.Mat[i][j] = Mat[i][j];
		return ret;
	}
	void clear(){
		for(int i=0;i<row;i++)
			Mat[i].clear();
		Mat.clear();
	}
	void resize(int R,int C){
		Mat.length = R;
		for(int i=0;i<R;i++)
			Mat[i].length = C;
	}
	
	T det(){
		auto Tri = triangle;
		T ret=1;
		for(int i=0;i<row;i++)
			ret *= Tri[i][i];
		return ret;
	}
	
	alias adjoint adj;
	//(i,j)余因子行列
	Matrix!(T) adjoint()
	in{
		//不変条件invariantですべての行の大きさが等しいことは保証される
		int l1 = Mat.length;
		int l2 = Mat[0].length;
		
		//正方行列かつ大きさは0でない
		assert(l1 == l2);
		assert(l1 != 0);
		assert(l2 != 0);
	}
	body{
		Matrix!(T) Temp;
		int lx = Mat.length,ly = Mat[0].length; 
		Temp.resize(lx,ly);
		
		for(int i=0;i<lx;i++)
			for(int j=0;j<ly;j++)
				Temp[i][j] = confactor(j,i);
		return Temp;
	}
	
	//行列式の(x,y)余因子
	T confactor(int x,int y)
	in{
		//不変条件invariantですべての行の大きさが等しいことは保証される
		int l1 = Mat.length;
		int l2 = Mat[0].length;
		
		//正方行列かつ大きさは0でない
		assert(l1 == l2);
		assert(l1 != 0);
		assert(l2 != 0);
		
		//x,yはl1,l2以下である
		assert(l1 > x);
		assert(l2 > y);
	}
	body{
		Matrix!(T) Temp;
		Temp.resize(Mat.length-1,Mat[0].length-1);
		
		for(int i=0,i1=0;i<Mat.length;++i){
			if(i == x)continue;
			
			for(int j=0,j1=0;j<Mat[i].length;++j){
				if(j == y)continue;
				
				Temp[i1][j1] = Mat[i][j];
				++j1;
			}
			++i1;
		}
		
		T Ret = Temp.det;
		return (Ret * (((x+y)%2)?-1:1));
	}
	
	alias triangle tri;
	Matrix!(T) triangle(){
		//三角行列を作成
		/*
		一応計算は可能であるが、未完成。
		もし対角成分に0が含まれていた場合には正常に動作しない
		*/
		T temp;
		Matrix!(T) ret;
		ret = dup;
		for(int j=0;j<column;j++){
			//j列目の消去
			for(int i=j+1;i<row;i++){
				//j列目はj+i行以下の行を0にする。
				//まず各行について倍率を決めて、
				if(ret[j][j] == 0)
					return Matrix!(T)(row,column);
				
				temp = ret[i][j]/ret[j][j];
				for(int k=j;k<column;k++)
					ret[i][k] -= ret[j][k]*temp;
			}
		}
		return ret;
	}
	alias trans t;
	Matrix!(T) trans(){
		//転置行列を作成する。
		Matrix!(T) ret = Matrix!(T)(column,row,cast(T)0);
		for(int i=0;i<row;i++)
			for(int j=0;j<column;j++)
				ret[j][i] = Mat[i][j];
		return ret;
	}
	alias inverse inv;
	Matrix!(T) inverse()
	in{
		//不変条件invariantですべての行の大きさが等しいことは保証される
		int l1 = Mat.length;
		int l2 = Mat[0].length;
		
		//正方行列かつ大きさは0でない
		assert(l1 == l2);
		assert(l1 != 0);
		assert(l2 != 0);
	}
	body{
		Matrix!(T) tmp = Matrix!(T)(row*2,column*2);
		Matrix!(T) ret = Matrix!(T)(row,column);
		for(int i=0;i<row;i++)
			for(int j=0;j<row;j++){
				tmp.Mat[i][j] = Mat[i][j];
				tmp.Mat[i+row][j] = Mat[i][j];
				tmp.Mat[i][j+column] = Mat[i][j];
				tmp.Mat[i+row][j+column] = Mat[i][j];
			}
		
		Matrix!(T) forDet = Matrix(row -1,column -1);
		for(int i=0;i<column;i++)
			for(int j=0;j<row;j++){
				//ここで行列式を出すための行列をつくる
				for(int x=0;x<row-1;x++)
					for(int y=0;y<column-1;y++)
						forDet.Mat[x][y] = tmp.Mat[i+1+x][j+1+y];
				
				//逆行列の各値はこの様になる
				ret.Mat[j][i] = forDet.det;
			}
			
		return ret;
				
	}
	alias ludec lu;
	Matrix!(T)[] ludec(){
		//LU分解を行う
		Matrix!(T) L = Matrix!(T)(row,column,0);
		Matrix!(T) U = Matrix!(T)(row,column,0);
		
		//Lの対角成分をすべて1に
		for(int i=0;i<row && i<column;i++)
			L[i][i] = 1;
		
		//まずUの一列目の計算を行う
		for(int j=0;j<column;j++)
			U[0][j] = Mat[0][j];
		
		//1行目のLについて計算を行う
		for(int i=1;i<row;i++)
			L[i][0] = Mat[i][0] / U[0][0];
		
		//1列目(行目)以降のL,Uについて計算する
		for(int i=1;i<row;i++){
			//Uについて
			for(int j=i;j<column;j++){
				U[i][j] = Mat[i][j];
				//ここから引いていく
				for(int k=0;k<i;k++)
					U[i][j] -= L[i][k]*U[k][j];
			}
			
			//Lについて
			for(int j=i+1;j<row;j++){
				L[j][i] = Mat[j][i];
				//ここから引いていく
				for(int k=0;k<i;k++)
					L[j][i] -= L[j][k]*U[k][i];
				//最後に割ってやる
				L[j][i] /= U[i][i];
			}
		}
		
		Matrix!(T)[] x;
		x ~= L;
		x ~= U;
		return x;
	}
	
	
	/**
	* PLU分解をする
	* Authors: Kazuki
	* Bugs: ときどき返却できないで例外を投げる.
	* Data: December 10, 2011
	*
	* Example:
	* --------------------------
	* auto PLU = A.pludec();
	* assert(PLU[0]*PLU[1]*PLU[2]==A);
	* --------------------------
	*
	* Return: P,L,Uの順番で入れられた配列Matrix!T[]
	* Throw: 失敗時,Exception
	* 
	*/
	Matrix!(T)[] pludec(){
		//LU分解を行う
		Matrix!T L = Matrix!T(row,column,0);
		Matrix!T U = Matrix!T(row,column,0);
		Matrix!T P = Matrix!T(row,column,0);
		Matrix!T A = Matrix!T(row,column,0);
		
		//Lの対角成分をすべて1に
		for(int i=0;i<row && i<column;i++)
			L[i][i] = 1;
		
		
		
		if(Mat[0][0] == 0){
			//置換を行う
			int skipidx=-1;
			for(int i=1;i<row;i++){
				if(Mat[i][0] != 0){//入れ替え
					A[0][] = Mat[i][];
					A[i][] = Mat[0][];
					
					P[0][i] = 1;
					P[i][0] = 1;
				}else{
					A[i][] = Mat[i][];
					P[i][i] = 1;
				}
			}
		}else{
			for(int i=0;i<row;i++){
				P[i][i] = 1;
				A[i][] = Mat[i][];
			}
		}
		//もし未だに(0,0)成分が0ならすべての0行目の成分は0であり、PLU分解は不可能。
		if(Mat[0][0] == 0)
			throw new Exception("all row:0 element are 0.");
		
		
		//まずUの一列目の計算を行う
		for(int j=0;j<column;j++)
			U[0][j] = A[0][j];
		
		//1行目のLについて計算を行う
		for(int i=1;i<row;i++)
			L[i][0] = A[i][0] / U[0][0];
		
		//1列目(行目)以降のL,Uについて計算する
		for(int i=1;i<row;i++){
			//Uについて
			for(int j=i;j<column;j++){
				U[i][j] = A[i][j];
				//ここから引いていく
				for(int k=0;k<i;k++)
					U[i][j] -= L[i][k]*U[k][j];
			}
			
			//0なら入れ替え
			if(U[i][i] == 0){
				bool finish;
				if(i == row)throw new Exception("final diagonal element is 0.");	//つまり最終成分が0なら例外
				for(int l=i+1;l<row;++l)
					if(Mat[l][0] != 0){//入れ替え
						T[] temp;
						temp = A.Mat[i];
						A.Mat[i] = A.Mat[l];
						A.Mat[l] = temp;

						temp = P.Mat[i];
						P.Mat[i] = P.Mat[l];
						P.Mat[l] = temp;
						finish = true;
						break;
					}
				if(!finish)
					throw new Exception("row:"~to!string(i)~" diagonal element is 0.");
				--i;
				continue;
			}
			
			//Lについて
			for(int j=i+1;j<row;j++){
				L[j][i] = A[j][i];
				//ここから引いていく
				for(int k=0;k<i;k++)
					L[j][i] -= L[j][k]*U[k][i];
				//最後に割ってやる
				L[j][i] /= U[i][i];
			}
		}
		Matrix!T[] dst;
		dst ~= P;
		dst ~= L;
		dst ~= U;
		return dst;
	}
	
	/+
	Matrix!(T)[] PQLUdec(){
		Matrix!T P = Matrix!T(row,column,0);
		Matrix!T Q = Matrix!T(row,column,0);
		Matrix!T L = Matrix!T(row,column,0);
		Matrix!T U = Matrix!T(row,column,0);
		
		
	}
	+/
	ref T at(int x, int y){return Mat[x][y];}
	
	alias column col;
	@property size_t row(){return Mat.length;}
	@property size_t column(){return Mat[0].length;}//不変条件ですべての行の大きさは等しいことは保証されている
	@property void cout(){
		for(int i=0;i<Mat.length;i++){
			for(int j=0;j<Mat[0].length;j++)
				writef("%s	",Mat[i][j]);
			writef("\n");
		}
	}
	
	/* 不変条件 速度低下が怖い場合は-releaseすること (dmd -O -release -inline で最高速度)　*/
	invariant(){
		//行の大きさはすべて同じ
		int x=-1 , y;
		for(int i=0;i<Mat.length;i++){
			if(x < 0){
				x = Mat[i].length;
				continue;
			}
			y = Mat[i].length;
			assert(x == y);
			x = y;
		}
	}
	
	T[][] Mat;
}

struct Vector(T){
	this(int n){val.length = n;}
	this(int n,T src){
		for(int i=0;i<n;i++)
			val ~= src;
	}
	this(Vector!(T) src){
		for(int i=0;i<src.length;i++)
			val ~= src[i];
	}
	this(T[] src){
		for(int i=0;i<src.length;i++)
			val ~= src[i];
	}
	
	ref T opIndex(int idx){return val[idx];}
	Vector!(T) opAssign(T n){
		for(int i=0;i<val.length;i++)
			val[i] = n;
		return this;
	}
	Vector!(T) opAssign(Vector!(T) V){
		val.length = V.length;
		for(int i=0;i<V.length;i++)
			val[i] = V[i];
		return this;
	}
	Vector!(U) opCast(U)(){
		Vector!(U) ret = Vector!(U)(val.length);
		for(int i=0;i<val.length;i++)
			ret[i] = cast(U)val[i];
		return ret;
	}
	
	Vector!(T) opBinary(string s : "+")(Vector!(T) V)
	in{assert(val.length == V.length);}
	body{
		Vector!(T) Ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			Ret[i] = val[i] + V[i];
		return Ret;
	}
	Vector!(T) opOpAssign(string s:"+")(Vector!(T) V)
	in{assert(val.length == V.length);}
	body{
		for(int i=0;i<val.length;i++)
			val[i] += V[i];
		return this;
	}
	
	Vector!(T) opBinary(string s : "-")(Vector!(T) V)
	in{assert(val.length == V.length);}
	body{
		Vector!(T) Ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			Ret[i] = val[i] - V[i];
		return Ret;
	}
	Vector!(T) opOpAssign(string s:"-")(Vector!(T) V)
	in{assert(val.length == V.length);}
	body{
		for(int i=0;i<val.length;i++)
			val[i] -= V[i];
		return this;
	}
	
	Vector!(T) opBinary(string s : "+")(T n){
		Vector!(T) Ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			Ret[i] = val[i] + n;
		return Ret;
	}
	Vector!(T) opBinaryRight(string s : "+")(T n){
		Vector!(T) Ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			Ret[i] = val[i] + n;
		return Ret;
	}
	Vector!(T) opBinary(string s : "-")(T n){
		Vector!(T) Ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			Ret[i] = val[i] - n;
		return Ret;
	}
	Vector!(T) opBinaryRight(string s : "-")(T n){
		Vector!(T) Ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			Ret[i] = val[i] - n;
		return Ret;
	}
	Vector!(T) opBinary(string s : "*")(T n){
		Vector!(T) Ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			Ret[i] = val[i] * n;
		return Ret;
	}
	Vector!(T) opBinaryRight(string s : "*")(T n){
		Vector!(T) Ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			Ret[i] = val[i] * n;
		return Ret;
	}
	Vector!(T) opBinary(string s : "/")(T n){
		Vector!(T) Ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			Ret[i] = val[i] / n;
		return Ret;
	}
	Vector!(T) opBinaryRight(string s : "/")(T n){
		Vector!(T) Ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			Ret[i] = n / val[i];
		return Ret;
	}
	Vector!(T) opBinary(string s : "^^")(T n){
		Vector!(T) Ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			Ret[i] = val[i] ^^ n;
		return Ret;
	}
	Vector!(T) opBinaryRight(string s : "^^")(T n){
		Vector!(T) Ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			Ret[i] = n ^^ val[i];
		return Ret;
	}
	Vector!(T) opBinary(string s : "%")(T n){
		Vector!(T) Ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			Ret[i] = val[i] % n;
		return Ret;
	}
	Vector!(T) opBinaryRight(string s : "%")(T n){
		Vector!(T) Ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			Ret[i] = n % val[i];
		return Ret;
	}
	
	Vector!(T) opOpAssign(string s:"+")(T n){
		for(int i=0;i<val.length;i++)
			val[i] += n;
		return this;
	}
	Vector!(T) opOpAssign(string s:"-")(T n){
		for(int i=0;i<val.length;i++)
			val[i] -= n;
		return this;
	}
	Vector!(T) opOpAssign(string s:"*")(T n){
		for(int i=0;i<val.length;i++)
			val[i] -= n;
		return this;
	}
	Vector!(T) opOpAssign(string s:"/")(T n){
		for(int i=0;i<val.length;i++)
			val[i] /= n;
		return this;
	}
	Vector!(T) opOpAssign(string s:"^^")(T n){
		for(int i=0;i<val.length;i++)
			val[i] ^^= n;
		return this;
	}
	Vector!(T) opOpAssign(string s:"%")(T n){
		for(int i=0;i<val.length;i++)
			val[i] %= n;
		return this;
	}
	
	void clear(){val.length = 0;}
	void resize(int size){val.length = size;}
	T norm(){
		T ret=0;
		for(int i=0;i<val.length;i++)
			ret += val[i] * val[i];
		return ret;
	}
	Vector!(T) dup(){
		Vector!(T) ret = Vector!(T)(val.length);
		for(int i=0;i<val.length;i++)
			ret[i] = val[i];
		return ret;
	}
	void cout(){
		for(int i=0;i<val.length;i++){
			if(i==0)write("[");
			write(val[i]);
			if(i!=(val.length-1))write(",");
			else write("]\n");
		}
	}
	@property auto length(){return val.length;}
	@property auto length(uint x){return (val.length = x);}
	//スカラー積とベクトル積(外積)とテンソル積と外積 テンソル積と外積については基底は考えないでいるので不完全
	T prod(string s)(Vector!(T) V)if((s=="Scalar")||(s=="S")||(s=="s")||(s=="scalar"))
	in{assert(val.length == V.length);}
	body{
		T ret = cast(T)0;
		for(int i=0;i<val.length;i++)
			ret += val[i] * V[i];
		return ret;
	}
	
	Vector!(T) prod(string s)(Vector!(T) V)if(s == "Vector" || s == "V" || s == "v" || s == "vector")
	in{
		assert(val.length == V.length);
		assert(val.length == 1 || val.length == 3 || val.length == 7);
	}
	body{
		Vector!(T) Ret = Vector!(T)(val.length,0);
		switch(val.length){
			case 1:
				return Ret;
				
			case 3:
				//Ret = Vector!(T)(3,0);
				Ret[0] = val[1] * V[2] - val[2] * V[1];
				Ret[1] = val[2] * V[0] - val[0] * V[2];
				Ret[2] = val[0] * V[1] - val[1] * V[0];
				return Ret;
			
			case 7:
				//Ret = Vector!(T)(7);
				Ret[0] = val[1]*V[2] - val[2]*V[1] - val[3]*V[4] + val[4]*V[3] - val[5]*V[6] + val[6]*V[5];
				Ret[1] =-val[0]*V[2] + val[2]*V[0] - val[3]*V[5] + val[4]*V[6] + val[5]*V[3] - val[6]*V[4];
				Ret[2] = val[0]*V[1] - val[1]*V[0] - val[3]*V[6] - val[4]*V[5] + val[5]*V[4] + val[6]*V[3];
				Ret[3] = val[0]*V[4] + val[1]*V[5] + val[2]*V[6] - val[4]*V[0] - val[5]*V[1] - val[6]*V[2];
				Ret[4] =-val[0]*V[3] - val[1]*V[6] + val[2]*V[5] + val[3]*V[0] - val[5]*V[2] + val[6]*V[1];
				Ret[5] = val[0]*V[6] - val[1]*V[3] - val[2]*V[4] + val[3]*V[1] + val[4]*V[2] - val[6]*V[0];
				Ret[6] =-val[0]*V[5] + val[1]*V[4] - val[2]*V[3] + val[3]*V[2] - val[4]*V[1] + val[5]*V[0];
				return Ret;
			
			default:
				assert(0);
		}
	}
	
	Matrix!(T) prod(string s)(Vector!(T) V)if(s == "Tensor" || s == "T" || s == "t" || s == "tensor")
	in{assert(val.length == V.length);}
	body{
		Matrix!(T) Ret = Matrix!(T)(val.length,val.length);
		for(int i=0;i<val.length;i++)
			for(int j=0;j<V.length;j++)
				Ret[i][j] = val[i] * V[j];
		return Ret;
	}
	
	Matrix!(T) prod(string s)(Vector!(T) V)if(s == "Exterior" || s == "E" || s == "e" || s == "exterior")
	in{assert(val.length == V.length);}
	body{
		Matrix!(T) Ret = Matrix!(T)(val.length,val.length);
		for(int i=0;i<val.length;i++)
			for(int j=0;j<V.length;j++)
				Ret[i][j] = val[i] * V[j] - val[j] * V[i];
		return Ret;
	}
	
	ref T[] toArray(){return val;}
	
	T[] val;
}

//LU分解から解を求める　※ピボット選択ナシ　0が含まれていればあばばばば
Vector!(T) LULinear(T)(Matrix!(T) A,Vector!(T) y)
in{assert(A.column == y.length);}
body{
	//Ax=yとなる連立一次方程式を解く関数
	/*
	Ax = y
	LUx= y
	Lz = y (z=Ux)
	これよりzが求まるので、
	Ux = z より、
	xベクトルも求めることができる。
	*/
	Vector!(T) x=Vector!(T)(y.length);
	
	//LU分解
	auto LU = A.ludec;
	
	
	T[] z;
	z.length = y.length;
	
	//zについての計算
	for(int i=0;i<z.length;i++){
		z[i] = y[i];
		for(int j=0;j<i;j++)
			z[i] -= LU[0][i][j] * z[j];
		
	}
	
	for(int i=x.length-1;i>=0;i--){
		x[i] = z[i];
		for(int j=i+1;j<z.length;j++)
			x[i] -= LU[1][i][j] * x[j];
		x[i] /= LU[1][i][i];
	}
	
	return x;
	
}

//掃き出し法から解を求める　※ピボット選択ナシ　0が含まれていればあばばばば
Vector!(T) GaussJordan(T)(Matrix!(T) A,Vector!(T) y)
in{assert(A.column==y.length);}
body{
	//Aとyから新規に合成した行列Gを作る
	Matrix!(T) G = Matrix!(T)(A.row,A.column+1);
	for(int i=0;i<A.row;i++)
		for(int j=0;j<A.column;j++)
			G[i][j] = A[i][j];
			
	for(int i=0;i<G.row;i++)
		G[i][A.column] = y[i];
	
	//前進消去
	G = G.triangle;//3角行列の作成
	T temp;
	for(int i=0;i<G.row;i++){
		temp = G[i][i];
		for(int j=i;j<G.column;j++)
			G[i][j] /= temp;
	}
	
	//後退代入
	for(int i=G.row-1;i>0;i--)
		for(int k=i-1;k>=0;k--)
			G[k][G.column-1] -= G[i][G.column -1]*G[k][i];
		
	
	//解を返す
	Vector!(T) ans = Vector!(T)(y.length);
	for(int i=0;i<y.length;i++)
		ans[i] = G[i][G.column-1];
	return ans;
}

//LU分解するだけ
Matrix!(T)[] ludec(T)(Matrix!(T) Mat){
	//LU分解を行う
	int row = Mat.row;//行数
	int column = Mat.column;//列数
	//row*columnの大きさで0で初期化されているL,U行列を作成
	auto L = Matrix!(T)(row,column,0);
	auto U = Matrix!(T)(row,column,0);
	
	//Lの対角成分をすべて1に
	for(int i=0;i<row && i<column;i++)
		L[i][i] = 1;
	
	//1列目(行目)以降のL,Uについて計算する
	for(int r=0;r<row;r++){
		//Uについて
		for(int j=r;j<column;j++){
			U[r][j] = Mat[r][j];
			
			//引いていく
			for(int k=0;k<r;k++)
				U[r][j] -= L[r][k]*U[k][j];
		}
		
		//Lについて
		for(int i=r+1;i<row;i++){
			L[i][r] = Mat[i][r];
			
			//引いていく
			for(int k=0;k<r;k++)
				L[i][r] -= L[i][k]*U[k][r];
				
			//最後に割ってやる
			L[i][r] /= U[r][r];
		}
	}
	Matrix!(T)[] Y;
	Y ~= L;
	Y ~= U;
	return Y;
}


version(unittest){
	pragma(lib,"myLib");
	unittest{
	}
	
	void main(){
		auto X = Matrix!real(3,3,0);
		X[0][0] = 2;	X[0][1] = 4;	X[0][2] = 8;
		X[1][0] = 6;	X[1][1] = 12;	X[1][2] = 9;
		X[2][0] = 10;	X[2][1] = 11;	X[2][2] = 12;
		
		Matrix!real[] DST;
		DST = X.pludec;
		X.cout;
		writeln("");
		(DST[0] * DST[1] * DST[2]).cout;
		writeln("");
		DST[0].cout;
		writeln("");
		DST[1].cout;
		writeln("");
		DST[2].cout;
		writeln("");
	}
}