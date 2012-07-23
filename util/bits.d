module mydutil.util.bits;

private{
    enum BinArrayOp = "+,-,*,/,%,^,&,|";
    enum UnaArrayOp = "-,~";
    enum RiNotLeOp = "/,%,^^,<<,>>,>>>,~,in";
    enum RiEqLeOp = "+,-,*,&,|,^";
    enum VecMat7 = "Vector!,Matrix!";
    enum ArithOp = "+,-,*,/,%,^^,&,|,^,<<,>>,>>>";
    enum BinBitOp = "&,|,^";
    enum UnaBitOp = "~";
    enum ShiftOp = "<<,>>,>>>";
}

import std.array	: popBack,array,appender;
import std.traits	: isArray;
import std.bigint;
import std.algorithm;
import std.format;
import std.stdio    : writeln;
import std.array;

import core.bitop	: bsr,bt,bts,btr;

import mydutil.file.csv	: isCSVin;
import mydutil.arith.method:splitdigit,BigIntToString;
import mydutil.arith.squence  :   popFrontWhile;

version(unittest){
	pragma(lib,"mydutil");
	import std.stdio;
	void main(){
		writeln("Unittest done.");
	}
}

///ビット列を作る
struct BitList{
private:
	ubyte[] _val;
	size_t _size;		//[1111,1110]なら7
	
public:
	///sizeの大きさのビット列を作る。
	this(size_t size){
		_size = size;
		_val.length = (size >> 3) + ((size&7)? 1 : 0);
	}
    
	///ubyteの配列からビット列を作る。
	this(ubyte[] src){
		_val = src.dup;
		_size = _val.length <<3;
	}
	unittest{
		writeln("Unittest Start ",__LINE__);
		//BitList b = BitList(cast(ubyte[])(Cast!ubyte([1,2,3,4,5]).reverse));
		BitList b = BitList(cast(ubyte[])(array(map!"cast(ubyte)(a)"([1,2,3,4,5])).reverse));
		assert(b.length == 40);
		writeln("Unittest End ",__LINE__);
	}
	
	///ビット列の大きさを返す
	@property const size_t length(){return _size;}
	
	///ビット列の大きさを変更する。
	@property size_t length(size_t newsize){
		if(_size < newsize && (_size & 7) != 0)
			_val[$-1] &= ubyte.max >> (8-_size&7);	//マスク
		
		_val.length = (newsize >> 3) + (((newsize&7)==0)? 0 : 1);
		_size = newsize;
		return _size;
	}
	
	///ビット反転
	BitList opUnary(string s:"~")(){
		BitList dst = BitList(_size);
		dst._val[] = ~_val[];
		
		if((_size & 7)!=0)
			bitreset(dst._val[$-1],_size&7);
		return dst;
	}
	unittest{
		writeln("Unittest Start ",__LINE__);
		BitList b = BitList(16);
        b[0] = true;
        b[1] = true;
        auto c = ~b;
        assert(!c[0]);
        assert(!c[1]);
        assert(c[2]);
        assert(c[3]);
		writeln("Unittest End ",__LINE__);
	}
	
	/// ビット列同士の&|^演算子
	BitList opBinary(string s)(BitList src)if(s.isCSVin(BinBitOp)){
		BitList dst;
		size_t bigidx,minidx;
		
		if(_val.length > src._val.length){
			minidx = src._val.length;
			
			dst._val.length = _val.length;
			mixin("dst._val[0..minidx][] = _val[0..minidx][]"~s~"src._val[];");
			mixin("dst._val[minidx..$][] = _val[minidx..$][]"~s~"cast(ubyte)0;");
			dst._size = _size;
		}else{
			bigidx = src._val.length;
			minidx = _val.length;
			
			dst._val.length = src._val.length;
			mixin("dst._val[0..minidx][] = src._val[0..minidx][]"~s~"_val[];");
			mixin("dst._val[minidx..$][] = src._val[minidx..$][]"~s~"cast(ubyte)0;");
			dst._size = _size > src._size ? _size : src._size;
		}
		return dst;
	}
    
	///ditto
	ref BitList opOpAssign(string s)(BitList src)if(s.isCSVin(BinBitOp)){
		size_t bigidx,minidx;
		if(_val.length > src._val.length){
			mixin("_val[0..src._val.length][] "~s~"= src._val[0..$][];");
			mixin("_val[src._val.length..$][] "~s~"= 0;");
		}else{
			mixin("_val[0..$][] "~s~"= src._val[0.._val.length][];");
			_val.length = src._val.length;
			mixin("_val[_val.length..$][]"~s~"=0;");
			_size = _size > src._size ? _size : src._size;
		}
		return this;
	}
	unittest{
		writeln("Unittest Start ",__LINE__);
		BitList A = BitList([0xFF,0x00,0x55,0x22]);
		BitList B = BitList([0x22,0x33,0x44,0x55]);
		
		assert(equal((A&B)._val,[0xFF&0x22,0x00&0x33,0x55&0x44,0x22&0x55]));
		assert(equal((A|B)._val,[0xFF|0x22,0x00|0x33,0x55|0x44,0x22|0x55]));
		assert(equal((A^B)._val,[0xFF^0x22,0x00^0x33,0x55^0x44,0x22^0x55]));
		BitList C = A.dup;
		C &= B;
		assert((A&B) == C);
		C = A.dup;
		C |= B;
		assert((A|B) == C);
		C = A.dup;
		C ^= B;
		assert((A^B) == C);
		writeln("Unittest End ",__LINE__);
	}
    
	///ビット列のシフト演算と累乗演算
	BitList opBinary(string s)(uint ui)if(s.isCSVin(">>,<<")){
		BitList A;
		mixin("return A = toBigInt() "~s~" ui;");
	}
	
	///ditto
	BitList opOpAssign(string s)(uint ui)if(s.isCSVin(">>,<<,^^")){
		return mixin("opAssign(toBigInt() "~s~" ui);");
	}
	unittest{
		writeln("Unittest Start ",__LINE__);
		BitList A = BitList([0xFF]);
		A = A << 16u;
		assert(equal(A._val,[0,0,0xff]));
		writeln("Unittest End ",__LINE__);
	}
	
	///ビット列の結合
	BitList opBinary(string s:"~")(BitList src){
        if(src._size == 0)
            return this;
        else if(_size == 0)
            return src;
        else{
            BitList dst;
            if(src._size&7){
                auto _tmp = opBinary!"<<"(src._size&7)._val;
                dst._val = _tmp[0..$-1] ~ (_tmp[$-1]|src._val[0]) ~ src._val[1..$];;
                dst._size = _size + src._size;
            }else{
                dst._val = _val ~ src._val;
                dst._size = _size + src._size;
            }
            return dst;
        }
	}
	unittest{
		writeln("Unittest Start ",__LINE__);
		BitList A,B,C;
		A = [0xFF,0xCC];
		B = [0xCC,0xEE];
		C = [0xCC,0xEE,0xFF,0xCC];
		assert(B~A == C);
        A = [0xFF];
        B._val = [];
        B._size = 0;
        assert(B~A == (C=[0xFF]));
        assert(A~B == (C=[0xFF]));
		writeln("Unittest Start ",__LINE__);
	}
	
	///ditto
	BitList opOpAssign(string s:"~")(BitList src){
		return opAssign(opBinary!"<<"(src._size) | src);
	}
    
    ///文字列化b,x,s
    void toString(void delegate(const(char)[]) sink,string formatString){
        auto data = appender!(string)();
        switch(formatString){
            case "%x","%X","%s":
                foreach_reverse(v;_val)
                    formattedWrite(data,formatString[0..1]~"02"~formatString[1..2],v);
                break;
            
            case "%b":
                foreach_reverse(i,v;_val){
                    for(int j=7;j>=0;--j)
                        if((i<<3)+j > (_size-1))continue;
                        else if((v & (1<<j))!=0)data.put("1");
                        else data.put("0");
                }
                break;
            
            default:
                writeln(formatString);
                assert(0);
        }
        
        sink(data.data);
    }
	
	///代入
	ref BitList opAssign(BitList src){
		_size = src._size;
		_val = src._val;
		return this;
	}
	
	///ditto
	ref BitList opAssign(ubyte[] src){
		_val = src.dup;
		_size = src.length<<3;
		return this;
	}
	
	///ditto
	ref BitList opAssign(BigInt src)
	in{assert(src >= 0);}
	body{
		_val.length = 0;
		for(;src!=0;src>>=8)
			_val ~= cast(ubyte)((src%BigInt("0x100")).toInt);
		_size = ((_val.length-1)<<3) + bsr(_val[$-1])+1;
		return this;
	}
	unittest{
		writeln("Unitest Start ",__LINE__);
		BigInt src = "0xF8C5E3";
		BitList A;
		A = src;
		assert(A == [0xE3,0xC5,0xF8]);
		writeln("Unitest End ",__LINE__);
	}
	
	///等号演算子
	bool opEquals(BitList src){
		if(_val.length != src._val.length)
			return false;
		for(int i=0;i<_val.length;++i)
			if(_val[i] != src._val[i])
				return false;
		return true;
	}
	
	///ditto
	bool opEquals(ubyte[] src){
		if(_val.length != src.length)
			return false;
		for(int i=0;i<_val.length;++i)
			if(_val[i] != src[i])
				return false;
			return true;
	}
	
	///比較演算子
	int opCmp(BitList src){
		BigInt A = toBigInt();
		BigInt B = src.toBigInt();
		
		if(A == B)return 0;
		else if(A > B)return 1;
		else if(A < B)return -1;
		else assert(0);
	}
	
	///インデックス演算子。idxビット目が立っているか返す。
	bool opIndex(size_t idx)
	in{assert(idx < _size);}
	body{
		if(bt(cast(uint*)&(_val[idx>>3]),idx&7) != 0)
			return true;
		else
			return false;
	}
	unittest{
		writeln("Unittest Start ",__LINE__);
		BitList A = [0x11];
		assert(A[0]);
		assert(A[4]);
		assert(!A[1]);
		A = [0x11,0x01];
		assert(A[0]);
		assert(A[4]);
		assert(A[8+0]);
		writeln("Unittest End ",__LINE__);
	}
	
	///インデックス代入演算子
	bool opIndexAssign(bool b,size_t idx)
	in{assert(idx < _size);}
	body{
		if(b)
			bts(cast(uint*)&(_val[idx>>3]),idx&7);
		else
			btr(cast(uint*)&(_val[idx>>3]),idx&7);
		return b;
	}
	
	///コピーを返す。
	@property BitList dup(){
		BitList A;
		A._val = _val.dup;
		A._size = _size;
		return A;
	}
	
	invariant(){
		assert(_val.length == (_size>>3) || (_val.length-1)==(_size>>3));
	}
	
private:
	///後ろnビット以外を0にする。たとえば11001100の後ろ4ビットを残したいのならn=4
	void bitreset(ref ubyte src,uint n)
	in{assert(0 <= n && n <= 8);}
	body{
		src &= (ubyte.max >> (8-n));
	}
	
	///BigIntに変換する。
	@property BigInt toBigInt(){
		BigInt dst = "0";
		foreach_reverse(val;_val){
			dst <<= 8;
			dst += cast(uint)val;
		}
		return dst;
	}
	unittest{
		writeln("Start Unittest ",__LINE__);
		BitList bit;
		BigInt bint = "0xFF";
		bit = bint;
		assert(bit._val.length == 1 && bit._val[0] == 0xFF);
		assert(bit.toBigInt.toInt == 0xFF);
		writeln("End Unittest ",__LINE__);
	}
	
	///ドル記号対応
	size_t opDoller(){
		return _size;
	}
}

unittest{
	BitList a = BitList(3);
	assert(a._val.length == 1);
	a[0] = true;
	a[1] = false;
	a[2] = true;
	//writeln(a);
}
