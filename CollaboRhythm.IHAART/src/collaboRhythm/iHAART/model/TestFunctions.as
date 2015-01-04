package collaboRhythm.iHAART.model
{
	import collaboRhythm.shared.model.services.DateUtil;

	import flash.globalization.DateTimeFormatter;

	import mx.collections.ArrayCollection;

	public class TestFunctions
	{
		public function TestFunctions()
		{


		}

		public static function generateMedicationList()
		{
			var medicationArray:ArrayCollection;

			var med1:Medication = new Medication();
			med1.nameDoseAndRoute = "efavirenz 600 MG Oral Tablet [Sustiva]";
			var now:Date = new Date();
		}

		public static function isoTimestampToDate(inputString:String):Date
		{
			return DateUtil.parseW3CDTF(inputString);
		}

		public static function indivoTimestampToDate(inputString:String):Date
		{

//			var d:Date = DateUtil.parseW3CDTF(inputString);
//			trace(d);
//			var s:String = DateUtil.format()   .toW3CDTF(d);
//			trace(s);
			//xs:date in format 2015-01-02T21:17:15.298Z YYYY-MM-DDTHH:MM:SS.mmmZ

			var str:String = inputString; //"2015-01-03T04:04:34.298Z";
//          test.setTime(Date.parse("2015-01-02T21:17:15.298Z"));
			var now:Date = new Date();

			var strArray:Array = str.split("T");
			var parsedDate:Array = strArray[0].split("-");
			var zoneFlag:String = strArray[1];
			var zoneFlag = zoneFlag.substring(zoneFlag.length - 1, zoneFlag.length);
			var trimTime:String = strArray[1];
			trimTime = trimTime.substring(0, trimTime.length - 1);
			var parsedTime:Array = trimTime.split(":");
			DebuggingTools.myTraceFunction("  parsedDate: " +
			parsedDate[0] +
			"-" +
			parsedDate[1] +
			"-" +
			parsedDate[2]);
			DebuggingTools.myTraceFunction("  zoneFlag: " + zoneFlag);
			DebuggingTools.myTraceFunction("  parsedTime: " +
			parsedTime[0] +
			":" +
			parsedTime[1] +
			":" +
			parsedTime[2]);

			return new Date(Date.UTC(parsedDate[0], parsedDate[1], parsedDate[2], parsedTime[0],
					parsedTime[1], parsedTime[2].split(".")[0],
					parsedTime[2].split(".")[1]));
		}

		public static function dateToIndivoString(dateObj:Date):String
		{
			var dateFormatter:DateTimeFormatter = new DateTimeFormatter(flash.globalization.LocaleID.DEFAULT);
//			var timeFormatter:DateTimeFormatter = new DateTimeFormatter();
			var pattern:String = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
			dateFormatter.setDateTimePattern(pattern);
			return dateFormatter.format(dateObj);
		}

		public static function dateToSQLiteString(dateObj:Date):String
		{
			var dateFormatter:DateTimeFormatter = new DateTimeFormatter(flash.globalization.LocaleID.DEFAULT);
//			var timeFormatter:DateTimeFormatter = new DateTimeFormatter();
			var pattern:String = "yyyy-MM-dd HH:mm:ss.SSS";
			dateFormatter.setDateTimePattern(pattern);
			return dateFormatter.format(dateObj);
		}
	}
}
