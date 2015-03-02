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

		private var _name:String;
		private var _doseAmount:Number;
		private var _doseUnit:String;
		private var _indication:String;
		private var _instructions:String;
		private var _startTime:String;
		private var _endTime:String;
		private var _imgSource:String;

		private var _nameAbbrevAttr:String;
		private var _nameTypeAttr:String;
		private var _nameValueAttr:String;
		private var _scheduledBy:String;
		private var _recurrenceFrequency:String;
		private var _recurrenceInterval:Number;
		private var _recurrenceCount:Number;
		private var _doseValue:Number;
		private var _doseUnitText:String;
		private var _doseUnitTypeAttr:String;
		private var _doseUnitValueAttr:String;
		private var _doseUnitAbbrevAttr:String;

		private var _xmlString:String;

		public function Medication(medData:Object)
		{

			var dTools = new DebuggingTools();

			var dispatcher:IHAARTEventDispatcher = new IHAARTEventDispatcher();

			if (medData['name'] != null) {
				_name = medData['name'];
			} else {
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", "  New medication: med name not found...");
			}

			if (medData['dose_amount'] != null)
			{
				_doseAmount = medData['dose_amount'];
			} else
			{
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", "  New medication: med dose amount not found...");
			}

			if (medData['dose_unit'] != null)
			{
				_doseUnit = medData['dose_unit'];
			} else
			{
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", "  New medication: med dose unit not found...");
			}

			if (medData['indication'] != null)
			{
				_indication = medData['indication'];
			} else
			{
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", "  New medication: med indication not found...");
			}

			if (medData['instructions'] != null)
			{
				_instructions = medData['instructions'];
			} else
			{
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", "  New medication: med instructions not found...");
			}

			if (medData['start_time'] != null)
			{
				_startTime = medData['start_time'];
			} else
			{
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", "  New medication: med start time not found...");
			}

			if (medData['end_time'] != null)
			{
				_endTime = medData['end_time'];
			} else
			{
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", "  New medication: med end time not found...");
			}

			if (medData['img_source'] != null)
			{
				_imgSource = medData['img_source'];
			} else
			{
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", "  New medication: med img source not found...");
			}

			if (medData['name_abbrev_attr'] != null)
			{
				_nameAbbrevAttr = medData['name_abbrev_attr'];
			} else
			{
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", " New medication: med nameAbbrev_attr not found...");
			}

			if (medData['name_type_attr'] != null)
			{
				_nameTypeAttr = medData['name_type_attr'];
			} else {
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", " New medication: med nameType_attr not found...");
			}

			if (medData['name_value_attr'] != null)
			{
				_nameValueAttr = medData['name_value_attr'];
			} else {
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", " New medication: med nameValue_attr not found...");
			}

			if (medData['scheduled_by'] != null)
			{
				_scheduledBy = medData['scheduled_by'];
			} else {
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", " New medication: med scheduledBy not found...");
			}

			if (medData['recurrence_frequency'] != null)
			{
				_recurrenceFrequency = medData['recurrence_frequency'];
			} else {
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", " New medication: med recurrenceFrequency not found...");
			}

			if (medData['recurrence_interval'] != null)
			{
			_recurrenceInterval = medData['recurrence_interval'];
			} else {
			dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", " New medication: med recurrenceInterval not found...");
			}

			if (medData['recurrence_count'] != null)
			{
				_recurrenceCount = medData['recurrence_count'];
			} else {
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", " New medication: med recurrenceCount not found...");
			}

			if (medData['dose_value'] != null)
			{
				_doseValue = medData['dose_value'];
			} else {
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", " New medication: med doseValue not found...");
			}

			if (medData['dose_unit_text'] != null)
			{
				_doseUnitText = medData['dose_unit_text'];
			} else {
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", " New medication: med doseUnit_text not found...");
			}

			if (medData['dose_unit_type_attr'] != null)
			{
				_doseUnitTypeAttr = medData['dose_unit_type_attr'];
			} else {
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", " New medication: med doseUnitTypeAttr not found...");
			}

			if (medData['dose_unit_value_attr'] != null)
			{
				_doseUnitValueAttr = medData['dose_unit_value_attr'];
			} else {
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", " New medication: med doseUnitValueAttr not found...");
			}

			if (medData['dose_unit_abbrev_attr'] != null)
			{
				_doseUnitAbbrevAttr = medData['dose_unit_abbrev_attr'];
			} else {
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", " New medication: med doseUnitAbbrevAttr not found...");
			}

			if (medData['xml_string'] != null)
			{
				_xmlString = medData['xml_string'];
			} else
			{
				dTools.taggedLog(DebuggingTools.INFO, "Medication constructor", "  New medication: med xml not found...");
			}

//			dispatcher.dispatchEvent(new IHAARTEvent(IHAARTEvent.MEDICATION_IMAGE_LOADED, "success", null, false, false));

		}

		public function setImgSource(imgSource:String) {
			_imgSource = imgSource;
			var dTools = new DebuggingTools();
			dTools.taggedLog(DebuggingTools.INFO, "Medication setImgSource", "  Medication image source: " + imgSource);
		}

//		public function initialize(dbController:SQLStoreController, gcmAccount:String):void
//		{
//
//			var dispatcher:IHAARTEventDispatcher = new IHAARTEventDispatcher();
//			var result:SQLResult = dbController.getMedDataForUserAccount(gcmAccount);
//
//			if (result != null)
//			{
//
//				_name = result.data[0]['med_name'];
//				_doseAmount = result.data[0]['med_dose_amount'];
//				_doseUnit = result.data[0]['med_dose_unit'];
//				_indication = result.data[0]['med_indication'];
//				_instructions = result.data[0]['med_instructions'];
//				_startTime = result.data[0]['med_start_time'];
//				_endTime = result.data[0]['med_end_time'];
//				_imgSource = result.data[0]['med_img_source'];
//
//				dispatcher.dispatchEvent(new IHAARTEvent(IHAARTEvent.MEDICATION_IMAGE_LOADED, "success", false, false));
//			}
//			else
//			{
//				logger.info("  Cannot initialize medication, data not found...");
//				dispatcher.dispatchEvent(new IHAARTEvent(IHAARTEvent.MEDICATION_IMAGE_LOADED, "failure", false, false));
//			}
//		}

		public function isDue():Boolean
		{
			var now:Date = new Date();
			DebuggingTools.taggedTrace("medication.isDue now = " + now.toString());
			return true;

		}

		public function get name():String
		{
			return _name;
		}

		public function set name(value:String):void
		{
			_name = value;
		}

		public function get doseAmount():Number
		{
			return _doseAmount;
		}

		public function set doseAmount(value:Number):void
		{
			_doseAmount = value;
		}

		public function get doseUnit():String
		{
			return _doseUnit;
		}

		public function set doseUnit(value:String):void
		{
			_doseUnit = value;
		}

		public function get indication():String
		{
			return _indication;
		}

		public function set indication(value:String):void
		{
			_indication = value;
		}

		public function get instructions():String
		{
			return _instructions;
		}

		public function set instructions(value:String):void
		{
			_instructions = value;
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

		public function get imgSource():String
		{
			return _imgSource;
		}

		public function set imgSource(value:String):void
		{
			_imgSource = value;
		}

		public function get xmlString():String
		{
			return _xmlString;
		}

		public function set xmlString(value:String):void
		{
			_xmlString = value;
		}

		public function get nameAbbrevAttr():String
		{
			return _nameAbbrevAttr;
		}

		public function get nameTypeAttr():String
		{
			return _nameTypeAttr;
		}

		public function get nameValueAttr():String
		{
			return _nameValueAttr;
		}

		public function get scheduledBy():String
		{
			return _scheduledBy;
		}

		public function get recurrenceFrequency():String
		{
			return _recurrenceFrequency;
		}

		public function get recurrenceInterval():Number
		{
			return _recurrenceInterval;
		}

		public function get recurrenceCount():Number
		{
			return _recurrenceCount;
		}

		public function get doseValue():Number
		{
			return _doseValue;
		}

		public function get doseUnitText():String
		{
			return _doseUnitText;
		}

		public function get doseUnitTypeAttr():String
		{
			return _doseUnitTypeAttr;
		}

		public function get doseUnitValueAttr():String
		{
			return _doseUnitValueAttr;
		}

		public function get doseUnitAbbrevAttr():String
		{
			return _doseUnitAbbrevAttr;
		}
	}
}
