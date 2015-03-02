package collaboRhythm.iHAART.model
{

	import core.Logger;

	import flash.utils.getQualifiedClassName;

	import mx.logging.ILogger;
	import mx.logging.*;
	import mx.logging.targets.TraceTarget;

	public class DebuggingTools
	{
		static public const TAG:String = "iHAART";

		static public const ALL:int = LogEventLevel.ALL;
		static public const DEBUG:int = 1;
		static public const INFO:int = 2;
		static public const WARN:int = 3;
		static public const ERROR:int = 4;
		static public const FATAL:int = 5;

		private var _logger:ILogger;
		
		public function DebuggingTools()
		{

		}

		public function initLogging():void
		{
			      // Create a target.
			var logTarget:TraceTarget = new TraceTarget();
			
			      // Log only messages for the classes in the mx.rpc. and 
			      // mx.messaging packages.
			 logTarget.filters = ["collaboRhythm.iHAART.*", "collaboRhythm.Tablet.*"];
			
			      // Log all log levels.
			
			logTarget.level = LogEventLevel.ALL;
			
			      // Add date, time, category, and log level to the output.
			
			logTarget.includeDate = true;
			
			logTarget.includeTime = true;
			
			logTarget.includeCategory = true;
			
			logTarget.includeLevel = true;
			
			      // Begin logging.
			
			Log.addTarget(logTarget);
			
		}

		public static function getMyStackTraceString():String
		{
			var tempError:Error = new Error();
			return tempError.getStackTrace();
		}

		public static function taggedTrace(traceText:String):void
		{
			trace("   bree in ", traceText);
		}

		public function taggedLog(logLevel:int, localTag:String, logText:String):void
		{
			if (logLevel == DEBUG)
			{
				logger.debug(TAG + "// (in " + localTag + "): " + logText)
			}
			if (logLevel == INFO) {
				logger.info(TAG + "// (in " + localTag + "): " + logText)
			}
			if (logLevel == WARN)
			{
				logger.warn(TAG + "// (in " + localTag + "): " + logText)
			}
			if (logLevel == ERROR)
			{
				logger.error(TAG + "// (in " + localTag + "): " + logText)
			}
			if (logLevel == FATAL)
			{
				logger.fatal(TAG + "// (in " + localTag + "): " + logText)
			}
		}

		public static function getFunctionName():String
		{
			var stackTrace:String = getMyStackTraceString();
			var startIndex:int = stackTrace.indexOf("at ");// start of first line
			var endIndex:int = stackTrace.indexOf("()");   // end of function name
			return stackTrace.substring(startIndex + 3, endIndex);
		}

		public function get logger():ILogger
		{
			if (!_logger)
			{
				_logger = Log.getLogger(getQualifiedClassName(this).replace("::", "."));
			}
			return _logger;
		}

		public function set logger(value:ILogger):void
		{
			_logger = value;
		}
	}
}
