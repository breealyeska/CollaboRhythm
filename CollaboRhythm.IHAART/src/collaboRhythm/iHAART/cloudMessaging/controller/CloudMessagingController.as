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

	import com.alyeska.shared.ane.alarm.libInterface.AlarmInterface;

	import flash.events.EventDispatcher;

	import collaboRhythm.iHAART.model.events.IHAARTEvent;

	import com.alyeska.shared.ane.gcm.libInterface.events.GCMEvent;
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
		public static var NO_IND_REGID:String="NONE";
		public static var INDIVO_UPDATED = GCMPushInterface.REGISTERED_INFO;

		public static var STATUS_OK:String = "200";

		private var _gcmi:GCMPushInterface;
		private var _alarmi:AlarmInterface;
		private var _gcmRegistrationID:String;
		private var _indivoRegistrationID:String;
		private var _payload:String;
		private var _parsedPayload:Object = {};
		private var _isRegistered:Boolean;
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
			initialize();
		}

		public function initialize():void
		{
			//create instance of extension interface and add appropriate listeners to it
			gcmi = new GCMPushInterface();
			gcmi.addEventListener(GCMEvent.REGISTERED, handleRegistered, false, 0, true);
			gcmi.addEventListener(GCMEvent.UNREGISTERED, handleUnregistered, false, 0, true);
			gcmi.addEventListener(GCMEvent.MESSAGE, handleMessage, false, 2, true);
			gcmi.addEventListener(GCMEvent.ERROR, handleError, false, 2, true);
			gcmi.addEventListener(GCMEvent.RECOVERABLE_ERROR, handleError, false, 2, true);
			gcmi.addEventListener(GCMEvent.FOREGROUND_MESSAGE, handleForegroundMessage, false, 2, true);

			alarmi = new AlarmInterface();
			alarmi.addEventListener(AlarmEvent.ADDED, handleAlarmAdded, false, 2, true);
			alarmi.addEventListener(AlarmEvent.TRIGGERED, handleAlarmTriggered, false, 2, true);
			alarmi.addEventListener(AlarmEvent.CANCELLED, handleAlarmCancelled, false, 2, true);

			var testing:Boolean = alarmi.initAlarm("testing");


			var dispatcher:IHAARTEventDispatcher = new IHAARTEventDispatcher();
			dispatcher.addEventListener(IHAARTEvent.REGISTERED, handleIHAARTRegistered, false, 0, false);

			//check gcm app server for device registration
			isRegistered = gcmi.checkRegistered(settings.gcmSenderID);
			if (isRegistered) {
				gcmRegistrationID = gcmi.registrationID;
			}
			else {
				gcmRegistrationID = GCMPushInterface.NO_REGID;
//				var response:String = gcmi.register(settings.gcmSenderID);
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
				gcmRegistrationID = response;
			}
			else {
				gcmRegistrationID = GCMPushInterface.NO_REGID;
			}
		}

		public function checkDeviceRegistration():Boolean
		{
			logger.info("  Checking for device registration with GCM service SenderID: " + settings.gcmSenderID);
			//calls ANE to 1. see if device is already registered and 2. if not start registration process (asynchronous)
//			ANE returns "registrationID:" + regId if already registered, "GCMRegistrar: registering sender " +  senderID otherwise

			isRegistered = gcmi.checkRegistered(settings.gcmSenderID);
			logger.info(isRegistered.toString());

			if (isRegistered)
			{
				gcmRegistrationID = gcmi.registrationID;
				return true;
			}
			else
			{ //not registered
				gcmRegistrationID = GCMPushInterface.NO_REGID;
				return false;
			}
		}

		public function checkPendingFromLaunchPayload():String
		{
			logger.info("  Checking for pending GCM payload...");
			payload = gcmi.checkPendingPayload();
			if (payload != GCMPushInterface.NO_MESSAGE)
			{
				logger.info("  Pending GCM messages: " + payload);
				handlePayload();
				return payload;
			}
			return payload.toString();
		}

		public function unregisterDevice():void
		{
			gcmi.unregister();
		}

		public function setAlarm():void
		{
			var now:Date = new Date();

			var dateFormatter:DateTimeFormatter = new DateTimeFormatter(flash.globalization.LocaleID.DEFAULT);
//			var timeFormatter:DateTimeFormatter = new DateTimeFormatter();
			var pattern:String = "yyyy-MM-dd HH:mm:ss.SSS";
			dateFormatter.setDateTimePattern(pattern);
			var formattedDate:String = dateFormatter.format(now);

			alarmi.newAlarm(formattedDate, "");
		}

		private function handleAlarmAdded(event:AlarmEvent):void
		{
			trace("  bree in handleAlarmAdded");
		}

		private function handleAlarmTriggered(event:AlarmEvent):void
		{
			trace("  bree in handleAlarmTriggered");
		}

		private function handleAlarmCancelled(event:AlarmEvent):void
		{
			trace("  bree in handleAlarmCancelled");
		}

		//on successful registration get GCM registration id for your device
		public function handleRegistered(event:GCMEvent):void
		{
			gcmRegistrationID = event.deviceRegistrationID;
			isRegistered = true;
//			isRegistered = true;
//			dbController.saveRegistrationID(gcmRegistrationID);
			logger.info("  Received device gcmRegistrationID: " + gcmRegistrationID);

			updateStoredIndivoRegistrationID();

			FlexGlobals.topLevelApplication.applicationController.handleGCMRegistered();

			var iHAARTEventDispatcher:IHAARTEventDispatcher = new IHAARTEventDispatcher();
			iHAARTEventDispatcher.dispatchEvent(new IHAARTEvent(IHAARTEvent.REGISTERED, gcmRegistrationID));

		}

		private function handleIHAARTRegistered(event:IHAARTEvent):void
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
			
			httpService.addEventListener(ResultEvent.RESULT, handleCurrentIndivoRequestResult);
			httpService.addEventListener(FaultEvent.FAULT, handleHTTPServiceFault);

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
				nameValuePairs["regid"] = gcmRegistrationID;
			}
			else
			{
				// Device not registered, need to register and then handle event can call updateStoredIndivoRegistrationID with new id
				nameValuePairs["regid"] = GCMPushInterface.NO_REGID;
			}

			if ((nameValuePairs["regid"]) && (nameValuePairs["regid"] != GCMPushInterface.NO_REGID))
			{
				httpService.addEventListener(ResultEvent.RESULT, handleUpdateIndivoRequestResult);
				httpService.addEventListener(FaultEvent.FAULT, handleHTTPServiceFault);

				httpService.method = "POST";
				try
				{

					httpService.send(nameValuePairs);
					logger.info("   Update stored Indivo reg ID request sent...");
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

		private function handleCurrentIndivoRequestResult(event:ResultEvent):void
		{
			try
			{
				var result:XMLList = new XMLList(event.result);
//				todo bree should validate this against schema at some point - maybe can use collaboRhythm core classes
				indivoRegistrationID = result.regid.toString();
			}
			catch (error:Error)
			{
				logger.info("    Error in CloudMessagingController.handleCurrentIndivoRequestResult(): " +
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

//			var iHAARTEventDispatcher:IHAARTEventDispatcher = new IHAARTEventDispatcher();
//			iHAARTEventDispatcher.dispatchEvent(new IHAARTEvent(IHAARTEvent.INDIVO_GET,
//					indivoRegistrationID,
//					false,
//					false));
		}

		private function handleUpdateIndivoRequestResult(event:ResultEvent):void
		{
			var result:Object = event.result;
			if (result == INDIVO_UPDATED) {
				indivoRegistrationID = gcmRegistrationID;
			}
			else {
				indivoRegistrationID = NO_IND_REGID;
			}

			logger.info("  Cloud Messaging: Indivo server updated with regID: " + indivoRegistrationID);

//			var strAlertBody:String = indivoRegistrationID;
//			strTitle = "ID Updated on Indivo";
//			SkinnableAlert.show(strAlertBody, strTitle, SkinnableAlert.OK);
//			var iHAARTEventDispatcher:IHAARTEventDispatcher = new IHAARTEventDispatcher();
//			iHAARTEventDispatcher.dispatchEvent(new IHAARTEvent(IHAARTEvent.INDIVO_UPDATE,
//					indivoRegistrationID,
//					false,
//					false));
			
		}

		public function handleHTTPServiceFault(fault:FaultEvent):void
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

		//messages are received when app is in background therefore add event for when app is resumed from notification
		public function handleMessage(event:GCMEvent):void
		{
			payload = event.message;
			logger.info("    GCM payload received:" + event + " event.message: " + event.message);
						NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke, false, 0, true);
		}

		//messages are received when app is in front therefore add event for handling message
		public function handleForegroundMessage(event:GCMEvent):void
		{
			payload = event.message;
			logger.info("    GCM foreground message received:" + event + " event.message: " + event.message);
//			//			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke, false, 0, true);

		}

		public function handlePayload():void
		{
			logger.info("  Handle Payload: " + payload);

			var pArray:Array = payload.split(",");

			for (var i = 0; i < pArray.length; i++)
			{
				var tmpPArray = pArray[i].split(": ");
				trace("   bree tmpPArray: ", tmpPArray[0], "   ", tmpPArray[1]);
				parsedPayload[tmpPArray[0]] = tmpPArray[1];
			}

			for (var key:String in parsedPayload)
			{
				trace("    bree looping through parsedPayload key=", key, "  value=", parsedPayload[key]);
			}

			var strAlertBody:String = parsedPayload.alert;
			var strTitle:String = parsedPayload.type;
			SkinnableAlert.show(strAlertBody, strTitle, SkinnableAlert.OK);
		}

		//when device is unregistered on Google side, you might want to unregister it with your backend service
		public function handleUnregistered(event:GCMEvent):void
		{
			//
			//unregister with yours or public backend messaging service
			//...
		}

		//handle variety of gcm errors
		public function handleError(error:GCMEvent):void
		{
			logger.info("    Error in CloudMessagingController.handleError(): " +
					error.errorCode +
					" ---- " +
					error.message);
		}

		public function get gcmi():GCMPushInterface
		{
			return _gcmi;
		}

		public function set gcmi(value:GCMPushInterface):void
		{
			_gcmi = value;
		}

		public function get gcmRegistrationID():String
		{
			return _gcmRegistrationID;
		}

		public function set gcmRegistrationID(value:String):void
		{
			if (value.indexOf(GCMPushInterface.NO_REGID) != -1) {
				isRegistered = false;
			}
			_gcmRegistrationID = value;
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

		public function get isRegistered():Boolean
		{
			return _isRegistered;
		}

		public function set isRegistered(value:Boolean):void
		{
			_isRegistered = value;
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
	}
}
