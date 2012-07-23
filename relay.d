/** シーケンサーのためのモジュールです
*/

module mydutil.relay;

import std.stdio;
import std.functional;

alias bool delegate(real) dgHigh;

interface DigitalTerminal{
    bool high(real t);
}

class Input(alias fun) : DigitalTerminal{
public:
    override
    bool high(real t){
        return unaryFun!fun(t);
    }
    
    Coil opBinary(string s : "*")(Coil c){
        Coil.set(&this.high);
        return c;
    }
    
    Output!"&&" opBinary(string s : "*", alias E)(Relay!E r){
        return new Output!"&&"(&this.high, &r.high);
    }
}

class Output(string op) : DigitalTerminal{
private:
    dgHigh _input0;
    dgHigh _input1;
    
public:
    this(dgHigh a, dgHigh b){
        _input0 = a;
        _input1 = b;
    }
    
    override
    bool high(real t){
        return mixin("_input0(t) " ~ op ~ "_input1(t)");
    }
    
    Coil opBinary(string s : "*")(Coil c){
        c.set(&this.high);
    }
    
    Output!"&&" opBinary(string s : "*", T)(T o)
    if(is(T E == Relay!E) || is(T E == Output!E))
    {
        return new Output!"&&"(&this.high, &o.high);
    }
    
    Output!"||" opBinary(string s : "+", T)(T o)
    if(is(T E == Relay!E) || is(T E == Output!E))
    {
        return new Output!"||"(&this.high, &o.high);
    }
    
}

class Coil : DigitalTerminal{
private:
    dgHigh _input0;
    
public:
    this(){}
    this(dgHigh a){
        _input0 = a;
    }
    
    void set(dgHigh a){
        _input0 = a;
    }

    override
    bool high(real t){
        return _input0(t);
    }
}

class Relay(alias C) : DigitalTerminal{
    this(){}
    
    override
    bool high(real t){
        return C.high(t);
    }
    
    Output!"&&" opBinary(string s : "*", T)(T o)
    if(is(T E == Relay!E) || is(T E == Output!E))
    {
        return new Output!"&&"(&this.high, &o.high);
    }
    
    Output!"||" opBinary(string s : "+", T)(T o)
    if(is(T E == Relay!E) || is(T E == Output!E))
    {
        return new Output!"||"(&this.high, &o.high);
    }
}

/*
void main(){
    Input!"cast(bool)(cast(int)(a)&1)" i0;
    Input!"cast(bool)(cast(int)(a/2)&1)" i1;
    
    Coil c0 = new Coil(&i0.high), c1 = new Coil(&i1.high);
    Relay!c0 r0 = new Relay!c0();
    Relay!c1 r1 = new Relay!c1();
    
    auto output = new Output!"&&"(&r0.high, &r1.high);
    
    foreach(i; 0..50){
        //writeln(i0.high(i/10.0));
        //writeln(output.high(i/10.0));
    }
    
}
*/