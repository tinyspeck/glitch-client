package locodeco.util
{
public final class MathUtil
{
	public static function roundForDisplayPercentages(n:Number):Number {
		return Math.round(n*10)/10;
	}
}
}