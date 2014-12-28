package collaboRhythm.iHAART.model
{
	import collaboRhythm.iHAART.controller.IHAARTEventDispatcher;
	import collaboRhythm.iHAART.model.events.IHAARTEvent;
	import collaboRhythm.iHAART.sqlStore.controller.SQLStoreController;

	import flash.data.SQLResult;
	import flash.utils.getQualifiedClassName;

	import mx.logging.ILogger;
	import mx.logging.Log;

	[Bindable]
	public class Medication
	{

		private var _nameDoseAndRoute:String;
		private var _startTime:String;
		private var _endTime:String;
		private var _instructions:String;

		private var _logger:ILogger;

		public function Medication()
		{

		}

		public function initialize(dbController:SQLStoreController, gcmAccount:String):void
		{

			var result:SQLResult = dbController.getMedDataForAccount(gcmAccount);

			var numResults:int = result.data.length;

			if (numResults == 1)
			{
				this.nameDoseAndRoute = result.data[0]['med_name_dose_route'];
				this.startTime = result.data[0]['med_start_time'];
				this.endTime = result.data[0]['med_end_time'];
				this.instructions = result.data[0]['med_instructions'];
			}
			else
			{
				logger.info("  Cannot initialize medication, data not found...");
			}

			var dispatcher:IHAARTEventDispatcher = new IHAARTEventDispatcher();
			dispatcher.dispatchEvent(new IHAARTEvent(IHAARTEvent.MEDICATION_LOADED, "", false, false));
		}

		public function get nameDoseAndRoute():String
		{
			return _nameDoseAndRoute;
		}

		public function set nameDoseAndRoute(value:String):void
		{
			_nameDoseAndRoute = value;
		}

		public function get startTime():String
		{
			return _startTime;
		}

		public function set startTime(value:String):void
		{
			_startTime = value;
		}

		public function get endTime():String
		{
			return _endTime;
		}

		public function set endTime(value:String):void
		{
			_endTime = value;
		}

		public function get instructions():String
		{
			return _instructions;
		}

		public function set instructions(value:String):void
		{
			_instructions = value;
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
