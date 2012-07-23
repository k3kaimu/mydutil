module mydutil.mathfunction.rungekutta;

import std.functional;

/*******************************************************************************
 * 数学関数
 * 
 * 一変数関数。$(BR)
 * トリッキーな関数に応用が可能。$(BR)
 * たとえば
 * RungeKuttaMethoed4 などの複雑な要素の絡む関数、
 * Nonlinearly などを使った乱数の密度関数
 * などなどが挙げられます。
 */
interface INumericFunction
{
	/***************************************************************************
	 * 値を得る
	 * 
	 * y = f(x) でいうところの x を与え y の値を得るための関数。
	 * 
	 * Params:
	 *     x = y = f(x) でいうところの x
	 * Returns:
	 *     y = f(x) でいうところの y
	 */
	real opCall(real x);
}

/*******************************************************************************
 * 4次のルンゲクッタ法
 */
class RungeKuttaMethod4: INumericFunction
{
private:
	real[] _k1;
	real[] _k2;
	real[] _k3;
	real[] _k4;
	real[] _state;
	immutable(real)[] _prop;
	real[] _tmp;
	real _lastTime;
	real delegate(real) _fnInput;
	
	real func(real t, in real[] inputs)
	in
	{
		assert(_prop.length > 0);
		assert(_prop.length == inputs.length);
	}
	body
	{
		real x = _prop[0] * _fnInput(t);
		foreach (i; 0..inputs.length)
		{
			x -= _prop[i]*inputs[i];
		}
		return  x / _prop[$-1];
	}
	
public:
	/***************************************************************************
	 * 入力関数
	 * 
	 * property setter
	 * 
	 * Params:
	 *     dg = 入力関数
	 *     fn = 同上
	 */
	@property void input(real delegate(real) callable)
	{
		_fnInput = toDelegate(callable);
	}
	/// ditto
	@property void input(real function(real) callable)
	{
		_fnInput = toDelegate(callable);
	}
	/// ditto
	@property void input(INumericFunction callable)
	{
		_fnInput = toDelegate(callable);
	}
	
	/***************************************************************************
	 * 入出力の状態
	 * 
	 * property setter/getter$(BR)
	 * 入出力の状態を示します。　この値は calculate メソッドを実行することで更新
	 * されます。
	 * 
	 * Params:
	 *     state  = setter の場合入出力の状態を強制的に変更します。$(BR)
	 *             あまりお勧めできません。 initialize() を使用したほうがよい
	 *             でしょう。
	 * Returns:
	 *     getter の場合現在の状態を取得することが可能です。
	 */
	void state(in real[] initstate)
	in
	{
		assert(initstate.length == _state.length);
	}
	body
	{
		_state[] = initstate[];
	}
	
	/// ditto
	const(real)[] state()
	{
		return _state;
	}
	
	/***************************************************************************
	 * システムのプロパティ
	 * 
	 * 
	 * property setter/getter$(BR)
	 * システムの特性に関するプロパティです。システムは制御工学でいうところの
	 * 伝達関数によって表わされます。$(BR)
	 * 伝達関数の分子の数は1として、sの係数のリストを使用します。
	 * 
	 * Params:
	 *     prop = setter の場合、伝達関数のs^nの係数をsの次数の大きなものの
	 *            係数から順に設定してください。$(BR)
	 *            伝達関数が (1)/(2s + 1) であれば、 [2, 1]です。
	 * Returns:
	 *     getter の場合、既に設定されているシステムの特性を返します。
	 */
	void systemProperties(immutable(real)[] prop)
	{
		_prop         = prop;
		
		_state.length = prop.length;
		_k1.length    = prop.length;
		_k2.length    = prop.length;
		_k3.length    = prop.length;
		_k4.length    = prop.length;
		_tmp.length   = prop.length;
		
		_state[] = 0;
		_k1[] = 0;
		_k2[] = 0;
		_k3[] = 0;
		_k4[] = 0;
	}
	
	/// ditto
	immutable(real)[] systemProperties(bool aDoCopy = false)
	{
		return _prop;
	}
	
	/***************************************************************************
	 * 最後に更新した際の時間
	 * 
	 * property setter/getter
	 * 
	 * Params:
	 *     newtime = setter の場合、最後の試行の際の時間を手動で切り替えます。
	 *               重要なのは、 lastTime プロパティの時間と、試行時の時間の
	 *               差異となります。これを微少時間として計算を行います。
	 * Returns:
	 *     getter の場合、前回試行時の時間を取得することが可能です。
	 */
	void lastTime(real newtime)
	{
		_lastTime = newtime;
	}
	/// ditto
	real lastTime()
	{
		return _lastTime;
	}
	
	
	/***************************************************************************
	 * 初期化する
	 * 
	 * 各プロパティを一斉に設定する。$(BR)
	 * 各プロパティは以下の通り
	 * $(UL
	 *     $(LI systemProperties)
	 *     $(LI state)
	 *     $(LI input)
	 *     $(LI lastTime)
	 * )
	 * 
	 * Params:
	 *     dg        = 入力関数 inputプロパティの値
	 *     fn        = 入力関数 inputプロパティの値
	 *     initstate = 初期の状態 stateプロパティの値
	 *     prop      = システムの状態 systemProperties プロパティの値
	 *     startTime = 開始時間
	 */
	void initialize(
		real delegate(real) dg,
		in real[] initstate,
		immutable(real)[] prop,
		real startTime=0.0L)
	in
	{
		assert(initstate.length == prop.length);
	}
	body
	{
		_state       = initstate.dup;
		_k1.length   = _state.length;
		_k2.length   = _state.length;
		_k3.length   = _state.length;
		_k4.length   = _state.length;
		_tmp.length  = _state.length;
		_prop        = prop;
		input        = dg;
		_lastTime    = startTime;
	}
	
	/// ditto
	void initialize(
		real function(real) fn,
		in real[] initstate,
		immutable(real)[] prop,
		real startTime=0.0L)
	in
	{
		assert(initstate.length == prop.length);
	}
	body
	{
		_state       = initstate.dup;
		_k1.length   = _state.length;
		_k2.length   = _state.length;
		_k3.length   = _state.length;
		_k4.length   = _state.length;
		_tmp.length  = _state.length;
		_prop        = prop;
		input        = fn;
		_lastTime    = startTime;
	}
	
	/***************************************************************************
	 * コンストラクタ
	 * 
	 * 基本的に initialize() と同じ。$(BR)
	 * 引数を指定しないでインスタンスを生成する場合、必ずすべてのプロパティを
	 * 設定しなければならない。
	 * 
	 * See_Also:
	 *     initialize()
	 */
	this(real startTime=0.0L)
	{
		_lastTime = startTime;
	}
	
	/// ditto
	this(
		real delegate(real) dg,
		in real[] initstate,
		immutable(real)[] prop,
		real startTime=0.0L)
	{
		initialize(dg, initstate, prop, startTime);
	}
	
	/// ditto
	this(
		real function(real) fn,
		in real[] initstate,
		immutable(real)[] prop,
		real startTime=0.0L)
	{
		initialize(fn, initstate, prop, startTime);
	}
	
	/***************************************************************************
	 * 計算する
	 * 
	 * 計算を行い、内部状態を更新する。$(BR)
	 * 
	 * Params:
	 *     t = 計算する際の時間。現在時刻など、今回計算する際の時間を指定する。
	 *         細かい周期で呼び出すほど精度が高くなる。
	 *         ただし、処理時間もかかるため、ほどほどの間隔で呼び出すのがいい。
	 */
	void calculate(real t)
	in
	{
		assert(_state.length > 0);
	}
	body
	{
		real dt = t - _lastTime;
		immutable idxMax = _state.length-1;
		
		foreach (i; 0..idxMax)
		{
			_k1[i] = dt*_state[i];
		}
		_k1[idxMax] = dt*func(t, _state);
		
		foreach (i; 0..idxMax)
		{
			_k2[i] = dt*(_state[i+1] + _k1[i+1]/2);
			_tmp[i] = _state[i] + _k1[i]/2;
		}
		_tmp[idxMax] = _state[idxMax] + _k1[idxMax]/2;
		_k2[idxMax] = dt*func(t + dt/2, _tmp);
		
		foreach (i; 0..idxMax)
		{
			_k3[i] = dt*(_state[i+1] + _k2[i+1]/2);
			_tmp[i] = _state[i] + _k2[i]/2;
		}
		_tmp[idxMax] = _state[idxMax] + _k2[idxMax]/2;
		_k3[idxMax] = dt*func(t + dt/2, _tmp);
		
		foreach (i; 0..idxMax)
		{
			_k4[i] = dt*(_state[i+1] + _k3[i+1]);
			_tmp[i] = _state[i] + _k3[i];
		}
		_tmp[idxMax] = _state[idxMax] + _k3[idxMax];
		_k4[idxMax] = dt*func(t + dt, _tmp);
		
		foreach (i; 0..idxMax)
		{
			_state[i] = _state[i]
			+(_k1[i] + 2*_k2[i] + 2*_k3[i] + _k4[i])/6.0L;
		}
		
		_lastTime = t;
	}
	
	/***************************************************************************
	 * 値を得る
	 * 
	 * See_Also:
	 *     INumericFunction
	 */
	override real opCall(real t)
	{
		calculate(t);
		return state()[0];
	}
	
}