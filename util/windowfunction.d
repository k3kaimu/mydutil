module mydutil.util.windowfunction;

import std.math;


///窓関数
pure real[] vorbis(real[] data){
	real[] dst;
	foreach(uint idx , real val ; data)
		dst ~= sin(std.math.PI_2*pow(sin(std.math.PI*(cast(real)idx/cast(real)data.length)),2)) * val;
	return dst;
}
///ditto
pure real[] hann(real[] data){
	real[] dst;
	foreach(uint idx , real val ; data)
		dst ~= (0.5 - 0.5*cos(2.0*std.math.PI*(cast(real)idx/cast(real)data.length))) * val;
	return dst;
}
///ditto
pure real[] hamming(real[] data){
	real[] dst;
	foreach(uint idx , real val ; data)
		dst ~= (0.54 - 0.46*cos(2.0*std.math.PI*(cast(real)idx/cast(real)data.length))) * val;
	return dst;
}
///ditto
pure real[] blackman(real[] data){
	real[] dst;
	foreach(uint idx , real val ; data)
		dst ~= (0.42 - 0.5*cos(2.0*std.math.PI*(cast(real)idx/cast(real)data.length)) + 0.08*cos(4.0*std.math.PI*(cast(real)idx/cast(real)data.length))) * val;
	return dst;
}
///ditto
pure real[] sine(real[] data){
	real[] dst;
	foreach(uint idx , real val ; data)
		dst ~= sin(std.math.PI*(cast(real)idx/cast(real)data.length)) * val;
	return dst;
}

