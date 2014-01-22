package locodeco.util
{
public final class TSIDGen
{
	private static var _counter:Number;
	{ // static init
		_counter = new Date().getTime();
	}
	
	public static function newTSID(prefix:String = 'T'):String {
		return prefix + '_' + _counter++;
	}
}
}