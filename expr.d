/** 任意の型についてExpression Templateを実装します
*/

module mydutil.expr;

import std.conv : to;
import std.typecons;

import dranges.functional   : naryFun;
pragma(lib, "dranges");

template isExprType(T){
    static if(__traits(compiles, {
                            T a;
                            alias T.ValueType V;
                            alias T.ArgsType AT;
                            static assert(is(typeof(T.op) : string));
                            
                            T.ValueType v = a.evalExpr;
                        }))
        enum isExprType = true;
    else
        enum isExprType = false;
}

T evalExpr(T)(T arg){
    return arg;
}

auto expr(alias op = "", RT = E, E...)(E args){
    return Expr!(op, RT, E)(args);
}

struct Expr(alias Op, V, E...)
{
private:
    E _args;
    
public:
    alias Op op;
    alias V ValueType;
    alias E ArgsType;
    
    this(E src){
        _args = src;
    }
    
    auto opUnary(string s)()
    if(__traits(compiles, mixin(s ~ "ValueType.init")))
    {
        mixin("alias typeof(" ~ s ~ "this.evalExpr) RV;");
        return expr!(s, RV)(this);
    }
    
    auto opBinary(string s, T)(T rhs)
    if(isExprType!T && __traits(compiles, mixin("V.init" ~ s ~ "T.ValueType.init")))
    {
        mixin("alias typeof(V.init " ~ s ~" T.ValueType.init) RV;");
        return expr!(s, RV)(this, rhs);
    }
    
    auto opBinary(string s, T)(T rhs)
    if(!isExprType!T && __traits(compiles, mixin("V.init" ~ s ~ "T.init")))
    {
        mixin("alias typeof(V.init " ~ s ~" T.init) RV;");
        return expr!(s, RV)(this, rhs);
    }
    
    auto opIndex(T)(T idx)
    if(__traits(compiles, {T a; auto b = V.init[a];}))
    {
        alias typeof(ValueType.init[T.init]) RV;
        static if(isExprType!T)
            return expr!("a.evalExpr[b.evalExpr]", RV)(this, idx);
        else
            return expr!("a.evalExpr[b]", RV)(this, idx);
    }
    
    static if(__traits(compiles, {V a; auto b = a[];})){
        auto opSlice()
        {
            alias typeof(V.init[]) RV;
            return expr!("a.evalExpr[]", RV)(this);
        }
    }
    
    auto opSlice(T)(T idx1, T idx2)
    if(__traits(compiles, {V a; auto b = a[T.init .. T.init];}))
    {
        alias typeof(V.init[T.init .. T.init]) RV;
        
        return expr!("a.evalExpr[b..c]", RV)(this, idx1, idx2);
    }
    
    
    T opCast(T : V)(){
        return this.evalExpr;
    }
    
    T opCast(T)()
    if(__traits(compiles, cast(T)(V.init)))
    {
        return cast(T)this.evalExpr;
    }
    
    @property
    V evalExpr(){
        static if(is(typeof(Op) : string)){
            static if(is(typeof(naryFun!Op(E.init)))){
                return naryFun!Op(_args);
            }else{
                static if(E.length == 1)
                    return mixin(Op ~ "_args[0].evalExpr");
                else
                    return mixin("_args[0].evalExpr " ~ Op ~ "_args[1].evalExpr");
            }
        }else
            return Op(_args);
    }
    
    @property
    string toString(){
        static if(is(typeof(Op) : string)){
            static if(__traits(compiles, naryFun!(Op))){
                string dst = "naryFun!(\"" ~ Op ~"\")(";
                
                foreach(e; _args)
                    dst ~= e.to!string ~ ", ";
                
                return dst[0..$-2] ~ ")";
            }else{
                static if(E.length == 1)
                    return Op ~ _args[0].to!string;
                else
                    return "(" ~ to!string(_args[0]) ~ " " ~ Op ~ " " ~ to!string(_args[1]) ~ ")";
            }
        }else
            return __traits(identifier, Op) ~ "(" ~ _args.to!string ~")";
    }
    
}