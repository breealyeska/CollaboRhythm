package collaboRhythm.shared.model.healthRecord.document
{

	import collaboRhythm.shared.model.healthRecord.*;

	[Bindable]
	public class VitalSign extends DocumentBase
	{
		public static const DOCUMENT_TYPE:String = "http://indivo.org/vocab/xml/documents#CollaboRhythmVitalSign";

		private var _name:CollaboRhythmCodedValue;
		private var _measuredBy:String;
		private var _dateMeasuredStart:Date;
		private var _dateMeasuredEnd:Date;
		private var _result:CollaboRhythmValueAndUnit;
		private var _site:String;
		private var _position:String;
		private var _technique:String;
		private var _comments:String;
		private var _triggeredHealthActionResults:Vector.<HealthActionResult> = new Vector.<HealthActionResult>();

		public function VitalSign(name:CollaboRhythmCodedValue = null, measuredBy:String = null, dateMeasuredStart:Date = null, dateMeasuredEnd:Date = null, result:CollaboRhythmValueAndUnit = null, site:String = null, position:String = null, technique:String = null, comments:String = null)
		{
			meta.type = DOCUMENT_TYPE;
			_name = name;
			_measuredBy = measuredBy;
			_dateMeasuredStart = dateMeasuredStart;
			_dateMeasuredEnd = dateMeasuredEnd;
			_result = result;
			_site = site;
			_position = position;
			_technique = technique;
			_comments = comments;
		}

		public function get name():CollaboRhythmCodedValue
		{
			return _name;
		}

		public function set name(value:CollaboRhythmCodedValue):void
		{
			_name = value;
		}

		public function get measuredBy():String
		{
			return _measuredBy;
		}

		public function set measuredBy(value:String):void
		{
			_measuredBy = value;
		}

		public function get dateMeasuredStart():Date
		{
			return _dateMeasuredStart;
		}

		public function set dateMeasuredStart(value:Date):void
		{
			_dateMeasuredStart = value;
		}

		public function get dateMeasuredStartValue():Number
		{
			return _dateMeasuredStart.valueOf();
		}

		public function get dateMeasuredEnd():Date
		{
			return _dateMeasuredEnd;
		}

		public function set dateMeasuredEnd(value:Date):void
		{
			_dateMeasuredEnd = value;
		}

		public function get result():CollaboRhythmValueAndUnit
		{
			return _result;
		}

		public function set result(value:CollaboRhythmValueAndUnit):void
		{
			_result = value;
		}

		public function get resultAsNumber():Number
		{
			return Number(result.value);
		}

		public function get site():String
		{
			return _site;
		}

		public function set site(value:String):void
		{
			_site = value;
		}

		public function get position():String
		{
			return _position;
		}

		public function set position(value:String):void
		{
			_position = value;
		}

		public function get technique():String
		{
			return _technique;
		}

		public function set technique(value:String):void
		{
			_technique = value;
		}

		public function get comments():String
		{
			return _comments;
		}

		public function set comments(value:String):void
		{
			_comments = value;
		}

		public function get triggeredHealthActionResults():Vector.<HealthActionResult>
		{
			return _triggeredHealthActionResults;
		}

		public function set triggeredHealthActionResults(value:Vector.<HealthActionResult>):void
		{
			_triggeredHealthActionResults = value;
		}
	}
}
