/**
 * Copyright 2014 Bree Alyeska
 *
 * This file is part of iHAART & CollaboRhythm.
 *
 * iHAART and CollaboRhythm are free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later  version.
 *
 * iHAART and CollaboRhythm are distributed in the hope that they will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with iHAART & CollaboRhythm. If not, see
 * <http://www.gnu.org/licenses/>.
 */

package collaboRhythm.iHAART.model
{
	import collaboRhythm.iHAART.controller.IHAARTEventDispatcher;
	import collaboRhythm.iHAART.model.events.IHAARTEvent;
	import collaboRhythm.iHAART.sqlStore.controller.SQLStoreController;

	import flash.data.SQLResult;
	import flash.utils.getQualifiedClassName;

	import mx.collections.ArrayCollection;

	import mx.logging.ILogger;
	import mx.logging.Log;

	import collaboRhythm.iHAART.model.DebuggingTools;

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

			var dispatcher:IHAARTEventDispatcher = new IHAARTEventDispatcher();
			var result:SQLResult = dbController.getMedDataForUserAccount(gcmAccount);

			if (result != null)
			{
				this.nameDoseAndRoute = result.data[0]['med_name_dose_route'];
				this.startTime = result.data[0]['med_start_time'];
				this.endTime = result.data[0]['med_end_time'];
				this.instructions = result.data[0]['med_instructions'];

				dispatcher.dispatchEvent(new IHAARTEvent(IHAARTEvent.MEDICATION_LOADED, "success", false, false));
			}
			else
			{
				logger.info("  Cannot initialize medication, data not found...");
				dispatcher.dispatchEvent(new IHAARTEvent(IHAARTEvent.MEDICATION_LOADED, "failure", false, false));
			}
		}

		public function isDue():Boolean
		{
			var now:Date = new Date();
			DebuggingTools.myTraceFunction("medication.isDue now = " + now.toString());
			return true;

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
