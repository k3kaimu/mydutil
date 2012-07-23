module mydutil.mathfunction.base;

import std.algorithm;
import std.range;
import std.traits;

template isArithmetic(T){
    static if(__traits(compiles, {
                            T a, b, c;
                            c = a + b;
                            c = a - b;
                            c = a * b;
                            c = a / b;
                        }))
        enum isArithmetic = true;
    else
        enum isArithmetic = false;
}


/*****************************************************************
 * 数学の関数を、関数オブジェクトとして表すためのインターフェース
 */
interface IMathFunction(X, Y)if(isArithmetic!X, isArithmetic!Y){
    /*************************************************************
     * 関数から値を取得します
     * 
     * Params:
     *      x = 関数 y = f(x) の x
     * Returns:
     *      y = f(x) の y を返す
     *
     */
    Y opCall(X x);
}

/*****************************************************************
 * IMathFunctionのなかでもreal→realな関数オブジェクトは数値計算でよく使うため別名定義しておく
 */
alias IMathFunction!(real, real) INumericalFunction;

/*****************************************************************
 * 関数や、Callableなオブジェクトや構造体をレンジ化します
 */
auto rangeApply(T, R)(T fun, R xrange)if(isCallable!T && is(ElementType!R : ParameterTypeTuple!T[0]))
{
    return xrange.map!(a => fun.opCall(a));
}


