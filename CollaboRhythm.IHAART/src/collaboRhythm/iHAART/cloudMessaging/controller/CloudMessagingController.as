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

package collaboRhythm.iHAART.cloudMessaging.controller
{

	import collaboRhythm.iHAART.model.DebuggingTools;
	import collaboRhythm.shared.model.DebugUtils;

	import com.alyeska.shared.ane.alarm.libInterface.AlarmInterface;

	import flash.events.EventDispatcher;

	import collaboRhythm.iHAART.model.events.IHAARTEvent;
	import com.alyeska.shared.ane.alarm.libInterface.events.AlarmEvent;

	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.globalization.DateTimeFormatter;
	import flash.net.URLRequestHeader;
	import flash.text.TextField;
	import flash.utils.getQualifiedClassName;

	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;

	import mx.core.FlexGlobals;

	import mx.events.ResizeEvent;

	import com.alyeska.shared.ane.gcm.libInterface.GCMPushInterface;
	import com.alyeska.shared.ane.gcm.libInterface.events.GCMEvent;

	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.logging.targets.TraceTarget;
	import mx.rpc.Fault;
	import mx.utils.ObjectUtil;
	import mx.utils.URLUtil;
	import mx.events.FlexEvent;
	import mx.events.CloseEvent;
	import mx.rpc.http.HTTPService;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.events.FaultEvent;

	import collaboRhythm.shared.model.settings.Settings;
	import collaboRhythm.shared.model.services.WorkstationKernel;

	import collaboRhythm.iHAART.sqlStore.controller.SQLStoreController;
	import collaboRhythm.iHAART.model.SkinnableAlert;
	import collaboRhythm.iHAART.controller.IHAARTEventDispatcher;

	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.EventDispatcher;
	import flash.events.InvokeEvent;
	import flash.net.URLRequest;

	import spark.skins.spark.StackedFormHeadingSkin;

	public class CloudMessagingController
	{
		public static var NO_IND_REGID:String=GCMPushInterface.NO_REGID;
		public static var INDIVO_UPDATED:String = GCMPushInterface.IS_REGISTERED;

		public static var STATUS_OK:String = "200";
		public static var FACTOID:String = "factoid";

		private var _gcmi:GCMPushInterface;
		private var _alarmi:AlarmInterface;
		private var _indivoRegistrationID:String;
		private var _payload:String;
		private var _parsedPayload:Object = {};
		private var _dbController:SQLStoreController;
		private var _urlRequest:URLRequest;
		private var _httpStatusEvent:HTTPStatusEvent;
		private var _httpResponseStatusEvent:HTTPStatusEvent;
		private var _httpService:HTTPService;
		private var _eventDispatcher:IHAARTEventDispatcher;

		public var _medicationInformation:String = "test";

		private var STATUS_STR:String;

		private var _settings:Settings;
		private var _logger:ILogger;

		private var _strTitle:String;

		public function CloudMessagingController()
		{
//			initialize();
		}

		public function initialize():void
		{
			//create instance of extension interface and add appropriate listeners to it
			gcmi = new GCMPushInterface();
			gcmi.addEventListener(GCMEvent.REGISTERED, gcmEvent_registeredHandler, false, 0, true);
			gcmi.addEventListener(GCMEvent.UNREGISTERED, gcmEvent_unregisteredHandler, false, 0, true);
			gcmi.addEventListener(GCMEvent.MESSAGE, gcmEvent_messageHandler, false, 2, true);
			gcmi.addEventListener(GCMEvent.ERROR, gcmEvent_errorHandler, false, 2, true);
			gcmi.addEventListener(GCMEvent.RECOVERABLE_ERROR, gcmEvent_errorHandler, false, 2, true);
			gcmi.addEventListener(GCMEvent.FOREGROUND_MESSAGE, gcmEvent_foregroundMessageHandler, false, 2, true);

			alarmi = new AlarmInterface();
			alarmi.addEventListener(AlarmEvent.ADDED, alarmEvent_addedHandler, false, 2, true);
			alarmi.addEventListener(AlarmEvent.TRIGGERED, alarmEvent_triggeredHandler, false, 2, true);
			alarmi.addEventListener(AlarmEvent.CANCELLED, alarmEvent_cancelledHandler, false, 2, true);

			var testing:Boolean = alarmi.initAlarm("testing");

			var dispatcher:IHAARTEventDispatcher = new IHAARTEventDispatcher();
			dispatcher.addEventListener(IHAARTEvent.REGISTERED, iHAARTEvent_registeredHandler, false, 0, false);

			//check gcm app server for device registration
			if (!gcmi.checkRegistered(settings.gcmSenderID)) {
				registerDevice();
			}

			logger.info("CloudMessaging initialized");
		}

		public function registerDevice():void
		{
			logger.info("  Registering device with GCM SenderID: " + settings.gcmSenderID);
			//check if device is already registered otherwise start registration process and wait for REGISTERED event
			var response:String = gcmi.register(settings.gcmSenderID);
			if (gcmi.isRegistered) {
				logger.info("  GCMPushInterface.register() response: " + response);
			}
			else {
				logger.info("  GCMPushInterface.register() response: " + response + "    Will wait for gcm broadcastreceiver to be triggered...");
			}
		}

		public function unregisterDevice():void
		{
			gcmi.unregister();
		}

		public function syncDeviceIDBetweenServers():void
		{
//			logger.info("  GCM registrationID: " + gcmi.registrationID);
//			logger.info("  Ind registrationID: " + indivoRegistrationID);
			if (gcmi.checkRegistered(settings.gcmSenderID))
			{
				if (gcmi.registrationID == indivoRegistrationID) {
					logger.info("  in syncDeviceIDBetweenServers, servers are synchronized...");
				} else {
					logger.info("  in syncDeviceIDBetweenServers, servers are NOT synchronized...calling updateIndivo");
					updateStoredIndivoRegistrationID();
				}
			} else {
				logger.info("  in syncDeviceIDBetweenServers, device is not registered...calling registerDevice");
				registerDevice();
			}
		}

		public function checkPendingFromLaunchPayload():String
		{
			logger.info("  Checking for pending GCM payload...");
			payload = gcmi.checkPendingPayload();
			if (payload != GCMPushInterface.NO_PENDING_MESSAGES)
			{
				logger.info("  Pending GCM messages: " + payload);
				handlePayload();
				return payload;
			}
			return payload.toString();
		}

		public function setAlarm():void
		{
			var now:Date = new Date();

			now.seconds += 10;
			var dateFormatter:DateTimeFormatter = new DateTimeFormatter(flash.globalization.LocaleID.DEFAULT);
//			var timeFormatter:DateTimeFormatter = new DateTimeFormatter();
			var pattern:String = "yyyy-MM-dd HH:mm:ss.SSS";
			dateFormatter.setDateTimePattern(pattern);
			var formattedDate:String = dateFormatter.format(now);

			alarmi.newAlarm(formattedDate, "");
		}

		private function alarmEvent_addedHandler(event:AlarmEvent):void
		{
			trace("  bree in alarmEvent_addedHandler");
		}

		private function alarmEvent_triggeredHandler(event:AlarmEvent):void
		{
			trace("  bree in handleAlarmTriggered");
		}

		private function alarmEvent_cancelledHandler(event:AlarmEvent):void
		{
			trace("  bree in alarmEvent_cancelledHandler");
		}

		public function gcmEvent_registeredHandler(event:GCMEvent):void
		{
			logger.info("  Received device registered event && registrationID: " + event.deviceRegistrationID);
			updateStoredIndivoRegistrationID();

			var iHAARTEventDispatcher:IHAARTEventDispatcher = new IHAARTEventDispatcher();
			iHAARTEventDispatcher.dispatchEvent(new IHAARTEvent(IHAARTEvent.REGISTERED,
					event.deviceRegistrationID,
					null));

		}

		public function gcmEvent_notRegisteredHandler(event:GCMEvent):void
		{
			//  This function allows silent registeration and server sync if the device is not currently registered
			logger.info("  Device is not registered...");

			registerDevice();
//			todo bree should delete registrationID from indivo either through updateStoredIndivoRegistrationID or a lone function

//			FlexGlobals.topLevelApplication.applicationController.handleGCMNotRegistered(); //Show or hide Registered Icon

			var iHAARTEventDispatcher:IHAARTEventDispatcher = new IHAARTEventDispatcher();
			iHAARTEventDispatcher.dispatchEvent(new IHAARTEvent(IHAARTEvent.REGISTERED,
					event.deviceRegistrationID,
					null));

		}

		public function gcmEvent_messageHandler(event:GCMEvent):void
		{
			payload = event.message;
			logger.info("    GCM background message received:" + event + " event.message: " + event.message);
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke, false, 0, true);
		}

		public function gcmEvent_foregroundMessageHandler(event:GCMEvent):void
		{
			payload = event.message;
			logger.info("    GCM foreground message received:" + event + " event.message: " + event.message);
//			//			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke, false, 0, true);

		}

		private function iHAARTEvent_registeredHandler(event:IHAARTEvent):void
		{
			trace("   bree in testing registered handler again");
		}

		public function requestCurrentIndivoRegistrationID():void
		{

			var nameValuePairs:Object = {};
			nameValuePairs["key"] = settings.gcmHTTPPostKey;
			nameValuePairs["getregid"] = settings.gcmAccount;

			httpService.method = "GET";
			httpService.resultFormat = "e4x";
			
			httpService.addEventListener(ResultEvent.RESULT, httpEvent_getIndivoIDHandler);
			httpService.addEventListener(FaultEvent.FAULT, httpEvent_FaultHandler);

			try
			{
				httpService.send(nameValuePairs);
				logger.info("   Get stored Indivo reg ID request sent...");
			}
			catch (error:Error)
			{
				logger.info("    Error in CloudMessagingController.updateStoredIndivoRegistrationID(): " +
				error.errorID +
				" ---- " +
				error.message);
			}
		}

		public function updateStoredIndivoRegistrationID():void
		{

			var nameValuePairs:Object = {};
			nameValuePairs["key"] = settings.gcmHTTPPostKey;
			nameValuePairs["account"] = settings.gcmAccount;

			if (gcmi.isRegistered) {
				nameValuePairs["regid"] = gcmi.registrationID;
			}
			else
			{
				// Device not registered, need to register and then handle event can call updateStoredIndivoRegistrationID with new id
				logger.info("    Error in CloudMessagingController.updateStoredIndivoRegistrationID(): Device not yet registered with GCM Server");
//				todo bree ideally this would silently handle not registered state by calling register function and then proceeding to update indivo server
//				todo bree maybe have event called silent sync or some such, that would be called by GCM returning a not registered status.
			}

			if ((nameValuePairs["regid"]) && (nameValuePairs["regid"] != GCMPushInterface.NO_REGID))
			{
				httpService.addEventListener(ResultEvent.RESULT, httpEvent_updateIndivoIDHandler);
				httpService.addEventListener(FaultEvent.FAULT, httpEvent_FaultHandler);

				httpService.method = "POST";
				try
				{

					httpService.send(nameValuePairs);
					logger.info("   Update stored Indivo reg ID request sent with regID: " + gcmi.registrationID);
				}
				catch (error:Error)
				{
					logger.info("    Error in CloudMessagingController.updateStoredIndivoRegistrationID(): " +
						error.errorID +
						" ---- " +
						error.message);
				}
			}
			else
			{
				logger.info("   updateStoredIndivoRegistrationID has no regID to pass, waiting for registration event to return, request not sent ");
			}
		}

		private function httpEvent_getIndivoIDHandler(event:ResultEvent):void
		{
			try
			{
				var result:XMLList = new XMLList(event.result);
//				todo bree should validate this against schema at some point - maybe can use collaboRhythm core classes
				indivoRegistrationID = result.regid.toString();
			}
			catch (error:Error)
			{
				logger.info("    Error in CloudMessagingController.httpEvent_getIndivoIDHandler(): " +
						error.errorID +
						" ---- " +
						error.message);
			}

			if (indivoRegistrationID.length > 0) {
				logger.info("  Cloud Messaging: Current registrationID on Indivo server: " + indivoRegistrationID);
				var strAlertBody:String = indivoRegistrationID;
				strTitle = "Current ID in Indivo";
				SkinnableAlert.show(strAlertBody, strTitle, SkinnableAlert.OK);
			}
			else {
				logger.info("  CloudMessaging: No reg ID on Indivo server for user: " + settings.gcmAccount);
			}
		}

		private function httpEvent_updateIndivoIDHandler(event:ResultEvent):void
		{
			var result:Object = event.result;

			logger.info("  httpEvent_updateIndivoIDHandler result: " + result);

			indivoRegistrationID = gcmi.registrationID;

			logger.info("  Cloud Messaging: Indivo server updated with regID: " + indivoRegistrationID);
		}

		public function httpEvent_FaultHandler(fault:FaultEvent):void
		{
			var faultString:String = fault.fault.faultString;
			logger.info("    Error in CloudMessagingController HTTPServiceFault(): " +
						"Status Code: " + fault.statusCode +
						"     " +
						"Type: " + fault.type +
						"     " +
						faultString);
//			var strAlertBody:String = faultString;
//			strTitle = "HTTP Service Error in CloudMessagingController";
//			SkinnableAlert.show(strAlertBody, strTitle, SkinnableAlert.OK);
		}

		public function onInvoke(event:InvokeEvent):void
		{
			logger.info("    App was invoked from GCM notification");
			NativeApplication.nativeApplication.removeEventListener(InvokeEvent.INVOKE, onInvoke);
			handlePayload();
		}

		public function gcmEvent_unregisteredHandler(event:GCMEvent):void
		{
			//
			//unregister with yours or public backend messaging service
			//...
		}

		//handle variety of gcm errors
		public function gcmEvent_errorHandler(error:GCMEvent):void
		{
			logger.info("    Error in CloudMessagingController.gcmEvent_errorHandler(): " +
					error.message);
		}

		private function parsePayload(payload):Array
		{
			// Expected payload format: comma delimited string consisting of 4 substrings
			//		"title: <title>"
			//		"alert: <alert text>"
			//		"type: <type>"
			//		"id: <id and timestamp>"
			// 			Expected payload id field format = serverAlertID_YYYY-MM-DD_HH:MM:SS

			var pArray:Array = payload.split(GCMPushInterface.PAYLOAD_SEPARATOR);

			var parsedPayloadArray:Array;

			for (var i = 0; i < pArray.length; i++)
			{
				DebuggingTools.taggedTrace(" pArray[" + i + "] = " + pArray[i]);
				var tmpPArray = pArray[i].split(GCMPushInterface.PARAMETER_SEPARATOR);
				parsedPayloadArray[tmpPArray[0]] = tmpPArray[1];
			}
			// At this point will have array 	parsedPayload["title"]=<title>
			//									parsedPayload["alert"]=<alert text>
			//									parsedPayload["type"]=<type>
			//									parsedPayload["id"]=<serverAlertID_YYYY-MM-DD_HH:MM:SS>
			return parsedPayloadArray;
		}

		private function parsePayloadTimestamp(dateString:String, timeString:String):Date
		{
			var parsedDate:Array = dateString.split("-");
			var parsedTime:Array = timeString.split(":");

//			for (var i = 0; i < parsedDate.length; i++)
//			{
//				trace("   bree in more of this...parsedDate[", i, "]: ", parsedDate[i]);
//			}
//
//			for (var i = 0; i < parsedTime.length; i++)
//			{
//				trace("   bree in more of this...parsedTime[", i, "]: ", parsedTime[i]);
//			}

			var year:int = int(parsedDate[0]);
			var month:int = int(parsedDate[1]);
			var day:int = int(parsedDate[2]);

			var hour:int = int(parsedTime[0]);
			var minute:int = int(parsedTime[1]);
			var second:int = int(parsedTime[2]);

			var serverDate:Date = new Date(year, month, day, hour, minute, second, 0);
			serverDate.hours -= 5;  //Stupid timezone correction
			return serverDate;
		}

		public function handlePayload():void
		{
			logger.info("  Handle Payload: " + payload);

			var parsedPayloadArray = parsePayload(payload);

			var idTimestampArray:Array = parsedPayloadArray.id.split("_");
			var msgID:String = idTimestampArray[0];
			var serverDate:Date = parsePayloadTimestamp(idTimestampArray[1], idTimestampArray[2]);


			switch (parsedPayload.type)
			{
				case FACTOID :
					dbController.newNotificationEvent(settings.gcmAccount, msgID, parsedPayload.type, serverDate);

					var strAlertBody:String = parsedPayload.alert;
					var strTitle:String = parsedPayload.type;
					SkinnableAlert.show(strAlertBody, strTitle.toUpperCase(), SkinnableAlert.OK | SkinnableAlert.TAKE);

					break;
				default:
					trace("  bree in not a factoid");
					break;
			}
		}

		public function get gcmi():GCMPushInterface
		{
			return _gcmi;
		}

		public function set gcmi(value:GCMPushInterface):void
		{
			_gcmi = value;
		}

		public function get payload():String
		{
			return _payload;
		}

		public function set payload(value:String):void
		{
			_payload = value;
		}

		public function get logger():ILogger
		{
			if (!_logger) {
				var myTools:DebuggingTools = new DebuggingTools();
				myTools.initLogging();
				_logger = Log.getLogger(getQualifiedClassName(this).replace("::", "."));
			}
			return _logger;
		}

		public function set logger(value:ILogger):void
		{
			_logger = value;
		}

		public function get settings():Settings
		{
			if (!_settings) {
				_settings = WorkstationKernel.instance.resolve(Settings) as Settings;
			}
			return _settings;
		}

		public function set settings(value:Settings):void
		{
			_settings = value;
		}

		public function get dbController():SQLStoreController
		{
			if (!_dbController)
			{
				_dbController = new SQLStoreController();
				return _dbController;
			}
			else
			{
				return _dbController;
			}
		}

		public function set dbController(value:SQLStoreController):void
		{
			_dbController = value;
		}

		public function get urlRequest():URLRequest
		{
			if (!_urlRequest)
			{
				_urlRequest = new URLRequest();
				_urlRequest.url = settings.gcmServerBaseURL;
				_urlRequest.method = "POST";
			}
			return _urlRequest;
		}

		public function set urlRequest(value:URLRequest):void
		{
			
			_urlRequest = value;
		}

		public function get httpService():HTTPService
		{
			if (!_httpService)
			{
				_httpService = new HTTPService();
				_httpService.url = settings.gcmServerBaseURL;
			}
			return _httpService;
		}

		public function set httpService(value:HTTPService):void
		{
			_httpService = value;
		}

		public function get strTitle():String
		{
			return _strTitle;
		}

		public function set strTitle(value:String):void
		{
			_strTitle = value;
		}

		public function get parsedPayload():Object
		{
			return _parsedPayload;
		}

		public function set parsedPayload(value:Object):void
		{
			_parsedPayload = value;
		}

		public function get indivoRegistrationID():String
		{
			if (!_indivoRegistrationID) {
				_indivoRegistrationID = GCMPushInterface.NO_REGID;
			}
			return _indivoRegistrationID;
		}

		public function set indivoRegistrationID(value:String):void
		{
			_indivoRegistrationID = value;
		}

		public function get eventDispatcher():IHAARTEventDispatcher
		{
			if (!_eventDispatcher) {
				_eventDispatcher = new IHAARTEventDispatcher;
			}
			return _eventDispatcher;
		}

		public function set eventDispatcher(value:IHAARTEventDispatcher):void
		{
			_eventDispatcher = value;
		}

		public function get alarmi():AlarmInterface
		{
			if (!_alarmi) {
				_alarmi = new AlarmInterface();
			}
			return _alarmi;
		}

		public function set alarmi(value:AlarmInterface):void
		{
			_alarmi = value;
		}

//		public function get gcmRegistrationID():String
//		{
//			return _gcmRegistrationID;
//		}
//
//		public function set gcmRegistrationID(value:String):void
//		{
//			if (value.indexOf(GCMPushInterface.NO_REGID) != -1) {
//				isRegistered = false;
//			}
//			_gcmRegistrationID = value;
//		}
//
//		public function get isRegistered():Boolean
//		{
//			return _isRegistered;
//		}
//
//		public function set isRegistered(value:Boolean):void
//		{
//			_isRegistered = value;
//		}
	}
}
