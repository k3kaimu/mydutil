/++
分数型を構成します。Rational型は整数及び分数型に対して、ほぼすべての算術演算を備えています。
+/

module mydutil.arith.rational;

import std.bigint;

BigInt gcd(BigInt a, BigInt b){
    while(a != 0 && b != 0){
        if(a > b)
            a %= b;
        else
            b %= a;
    }
    if(a == 0)
        return b;
    else
        return a;
}

private BigInt lcm(BigInt a, BigInt b){
    return a / gcd(a, b) * b;
}

struct Rational{
private:
    BigInt _num;    //分子
    BigInt _den;    //分母
    bool _sign;     //符号
    
    invariant(){
        assert(_den != 0);
    }
    
public:
    ///n/1
    this(T)(T n){
        if(n >= 0)
            _num = n;
        else{
            _num = -n;
            _sign = true;
        }
        _den = 1;
    }
    
    ///n/d
    this(T, U)(T n, U d){
        _num = n;
        _den = d;
        
        if(n.sign)
        
        normalize();
    }
    
    
    ///約分します
    void normalize(){
        BigInt _gcd = gcd(_num, _den);
        _num /= _gcd;
        _den /= _gcd;
        
        if(_den < 0){
            _den = -_den;
            _num = -_num;
        }
    }
    
    
    ///逆数にします
    void invert(){
        BigInt tmp = _num;
        _num = _den;
        _den = tmp;
    }

    
    ///4則演算
    Rational opBinary(string op)(Rational r)if(op == "+" || op == "-"){
        BigInt gcdDen = gcd(_den, r._den);
        
        return Rational(mixin("_num * (r._den / gcdDen)" ~ op ~ "r._num * (_den / gcdDen)"), _den / gcdDen * r._den);
    }
    
    ///ditto
    Rational opBinary(string op)(Rational r)if(op == "*" || op == "/"){
        static if(op == "/")
            r.invert;
        
        BigInt gcd1 = gcd(_num, r._den);
        BigInt gcd2 = gcd(r._num, _den);
        
        return Rational((_num/gcd1) * (r._num / gcd2),
                        (_den/gcd2) * (r._den / gcd1));
    }
    
    
    ///4則複合代入演算
    void opOpAssign(string op)(Rational r)if(op == "+" || op == "-"){
        BigInt gcdDen = gcd(_den, r._den);
        
        _num = mixin("_num * (d / gcdDen)" ~ op ~ "r._num * (b / gcdDen)");
        _den = b / gcdDen * d;
    }
    
    ///ditto
    void opOpAssign(string op)(Rational r)if(op == "*" || op == "/"){
        static if(op == "/")
            r.invert;
        
        BigInt gcd1 = gcd(_num, r._den);
        BigInt gcd2 = gcd(r._num, _den);
        
        _num = (_num/gcd1) * (r._num / gcd2);
        _den = (_den/gcd2) * (r._den / gcd1);
    }
}