module mydutil.file.csv;

import std.stdio;
import std.c.stdlib;
import std.string;
import std.array;
import std.algorithm;
import std.file;

version(unittest){
	void main(){
		writeln("Unittest End");
	}
}

char[] CSVin(int row,int column,string filename){
	//その行があるか無いかはlengthが0であるかないかで判断できる。
	auto file=File(filename,"r");
	
	char[] linecopy;
	char[] ret;
	//読み込みたい行だけbufに読み込む
	foreach(ulong i,string buf;lines(file))
		if(i == row){
			linecopy ~= cast(char[])buf;
			break;
		}
	/*
	if(linecopy.length == 0)
		writefln("%s Line is not.",row);
	*/
	for(int i=0,j=0;i<linecopy.length;i++){
		if(linecopy[i] == ','){
			j++;
			continue;
		}
		if(j == column)
			ret ~= linecopy[i];
			
		if(j > column)
			break;
	}
	//if(ret.length==0){writefln("line %s:Column %s is not.",row,column);}
	return ret;
}

int CSVcolmax(string filename){
	auto file = File(filename,"r");
	//linecopyにデータをコピーする
	char[][] linecopy;
	int max=0,num=0;
	foreach(int i,string buf;lines(file))
		linecopy ~= cast(char[])buf;
	
	foreach(int i,char[] buf;linecopy){
		//各行について
		num = 0;
		for(int j=0;j<buf.length;j++)
			if(buf[j] == ','){//カンマがあれば1つ追加
				num++;
				continue;
			}
		
		//ここにくるとnumにその行の列の数が入っているはず。
		if(num > max)max = num;//コピーする
	}
	return max;
}

int CSVrowmax(string filename){
	auto file = File(filename,"r");
	//linecopyにデータをコピーする
	char[][] linecopy;
	int max;
	foreach(int i,string buf;lines(file))
		linecopy ~= cast(char[])buf;
	
	max = linecopy.length;
	
	//後ろの行から空行(先頭要素にカンマすらない)を削除していく。
	foreach_reverse(int i,char[] buf;linecopy){
		if(buf.length == 0)max--;
		else break;
	}
	return max;
}

///CSVファイルを読み取り、管理する
class CSV{
	
	///コンストラクタ
	this(){}

	///ファイル名を指定して、そのファイルをCSV形式で読み込む。
	this(string FileName,char splitchar = ','){
		auto strings = readText(FileName);
		_filename = FileName;
		
		string[] lines = splitLines(strings);
		_map.length = lines.length;
		for(int i=0;i<lines.length;++i)
			_map[i] = array(splitter(lines[i],splitchar));
		_splitchar = splitchar;
	}
	
	///文字列stringから作る。
	void create(string src,char splitchar = ','){
		string[] lines = splitLines(src);
		_map.length = lines.length;
		for(int i=0;i<lines.length;++i)
			_map[i] = array(splitter(lines[i],splitchar));
		_splitchar = splitchar;
	}
	/+
	string opIndex(size_t a,size_t b)
	in{
		assert(a < _map.length);
		assert(b < _map[a].length);
	}
	body{
		return _map[a][b];
	}
	+/
	
	///インデックス演算子
	ref string[] opIndex(size_t a)
	in{
		assert(a < _map.length);
	}
	body{
		return _map[a];
	}
	
	///ditto
	string[] opIndexAssign(string[] src,int idx){
		if(idx >= _map.length)_map.length = idx + 1;
		_map[idx] = src.dup;
		return _map[idx];
	}
	
	///ditto
	string opIndexAssign(string src,int Ridx,int Cidx){
		if(Ridx >= _map.length)_map.length = Ridx + 1;
		if(Cidx >= _map[Ridx].length)_map[Ridx].length = Cidx + 1;
		
		_map[Ridx][Cidx] = src;
		return _map[Ridx][Cidx];
	}
	
	///CSVファイルの大きさをリサイズする。
	void resize(int Row,int Col){
		_map.length = Row;
		for(int i=0;i<Row;i++)
			_map[i].length = Col;
	}
	
	///ファイルとして書きだす。
	void csvout(string filename = _filename){
		auto csvout = reduce!(q{a~"\n"~b})(array(map!(reduce!(q{a~","~b}))(_map)));
		auto file = File(filename,"w");
		file.writeln(csvout);
	}
	
	alias _map this;
	char _splitchar;
	string _filename;
	string[][] _map;
}
unittest{
	CSV A = new CSV("Test.csv");
	writeln(A[0]);
	A.csvout("Test2.csv");
}

///ファイルを行ごとに保持しておく。
class FileHost{
	alias map this;
	this(string FileName){
		filename = FileName;
		File fp = File(FileName,"r");
		foreach(string buf;lines(fp))
			map ~= buf;
	}
	string filename;
	string[] map;
}

///sがcsvsrc中に含まれていればtrue,含まれていなければfalse
bool isCSVin(string s,string csvsrc){
	string[] temp = csvsrc.split(",");
	
	for(int i=0;i<temp.length;++i)
		if(temp[i] == s)return true;
	return false;
}


