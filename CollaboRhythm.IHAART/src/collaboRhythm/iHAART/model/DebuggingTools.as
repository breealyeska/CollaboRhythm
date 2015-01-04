package collaboRhythm.iHAART.model
{
	public class DebuggingTools
	{
		public function DebuggingTools()
		{

		}

		public static function getMyStackTraceString():String
		{
			var tempError:Error = new Error();
			return tempError.getStackTrace();
		}

		public static function myTraceFunction(myString:String):void
		{
			trace("   bree in ", myString);
		}

		public static function getFunctionName():String
		{
			var stackTrace:String = getMyStackTraceString();
			var startIndex:int = stackTrace.indexOf("at ");// start of first line
			var endIndex:int = stackTrace.indexOf("()");   // end of function name
			return stackTrace.substring(startIndex + 3, endIndex);
		}
	}
}
