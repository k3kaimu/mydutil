/++
wavファイルを簡単に扱うためのクラス、構造体、関数(メソッド)群
現在はリニアPCMしか扱えない.しかも8bit未対応
というか8bitとか対応しなくていいよね
+/

module mydutil.file.wav;


import std.file;
import std.numeric;
import std.complex;

import mydutil.util.utility;
import mydutil.util.windowfunction;

class WAV{
	this(string FileName){
		
		alias mydutil.util.utility.ByteArrayTo!(ushort,"little") BAToUS;
		alias mydutil.util.utility.ByteArrayTo!(uint,"little") BAToUI;
		
		_data = cast(ubyte[])read(FileName);
		char[] temp = cast(char[])(_data[0..4]);
		assert(cast(string)temp == "RIFF");
		
		temp = cast(char[])(_data[8..12]);
		assert(cast(string)temp == "WAVE");
		
		temp = cast(char[])(_data[12..16]);
		assert(cast(string)temp == "fmt ");
		
		assert(BAToUI(_data[16..20]) == 16);
		
		_fmt.formatid = BAToUS(_data[20..22]);
		assert(_fmt.formatid == 1);
		
		_fmt.channelnum = BAToUS(_data[22..24]);
		_fmt.samplingrate = BAToUI(_data[24..28]);
		_fmt.byteps = BAToUI(_data[28..32]);
		_fmt.blockborder = BAToUS(_data[32..34]);
		_fmt.bitpersample = BAToUS(_data[34..36]);
		//現在は8bitより大きいbyte単位に対応。
		assert(_fmt.bitpersample != 8 && !(_fmt.bitpersample & 8));
		
		//dataが出現するインデックスを探す
		int idx;
		for(int i=36;i<_data.length;++i){
			temp = cast(char[])(_data[i..i+4]);
			if(cast(string)temp == "data"){
				idx = i;
				break;
			}
		}
		idx += 4;
		_data_idx = idx;
		
		_wavedata = wavdata!(short);
	}
	
	T[][] wavdata(T)(){
		T[][] dst;
		dst.length = _fmt.channelnum;
		uint data_size = ByteArrayTo!(uint,"little")(_data[_data_idx.._data_idx+4]);
		for(size_t i = _data_idx+4;i < data_size;i+=_fmt.blockborder)
			for(int j=0;j<_fmt.channelnum;++j)
				dst[j] ~= ByteArrayTo!(T,"little")(_data[i+j*(_fmt.bitpersample/8)..i+(j+1)*(_fmt.bitpersample/8)]);
			
		return dst;
	}
	
	ubyte[] _data;
	fmt_data _fmt;
	size_t _data_idx;
	short[][] _wavedata;
	alias _wavedata this;
}

struct fmt_data{
	ushort formatid;		//フォーマットID
	ushort channelnum;		//チャンネル数
	uint samplingrate;		//サンプル/秒
	uint byteps;			//バイト/秒
	ushort blockborder;		//モノラル16bit→1*2=2、ステレオ16bit→2*2=4な感じ
	ushort bitpersample;	//サンプルあたりのビット数
}

Complex!real[][] fft_wav(string filename,int sample,int channel)
in{
	//sampleは2の累乗根
	for(int i=1;i<sample;i<<=1){
		assert(!(sample & i));
	}
	//sample数は4で割り切れる必要がある。
	assert(sample % 4 == 0);
}
body{
	WAV wav = new WAV(filename);
	Fft FFT = new Fft(sample);
	Complex!real[][] dst;
	assert(wav._fmt.channelnum >= channel);
	//sample/4 + sample/2 + sample4個の合計sample個のデータからFFT変換を行う。
	//一回に前に進むサンプル数はsample/2個
	//もし最終的にsample数に足りない場合にはそのfftはしない。
	//ただし、最終回は切り捨てるので
	//全体では(N-(sample/4))/(sample/2)-1回の走査である。
	int r_max = (wav[0].length-(sample/4))/(sample/2);
	
	//FFT
	real[] data;
	for(int i=0;i<r_max;++i){
		//窓関数の適用
		data = vorbis(cast(real[])data[(sample/2)*i..(sample/2)*(i+1)]);
		//FFTの実行
		dst[i] ~= FFT.fft!real(data);
	}
	return dst;
}

version(unittest){
	import std.stdio;
	pragma(lib,"mydutil");

	unittest{
		WAV test = new WAV("testfile.wav");
		writeln(test._fmt.formatid);
		writeln(test._fmt.channelnum);
		writeln(test._fmt.samplingrate);
		writeln(test._fmt.byteps);
		writeln(test._fmt.blockborder);
		writeln(test._fmt.bitpersample);
		
		short[][] data = test.wavdata!short;
		writeln(data);
		Complex!real[][] d1 = fft_wav("testfile.wav",1024,1);
		Complex!real[][] d2 = fft_wav("testfile.wav",1024,2);
		writeln(d1);
		writeln(d2);
	}
	
	void main(){
		writeln("end");
	}
}