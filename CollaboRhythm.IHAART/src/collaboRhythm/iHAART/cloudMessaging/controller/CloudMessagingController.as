/**
 * Copyright 2014 Bree Alyeska
 *
 * This file is part of CollaboRhythm.
 *
 * CollaboRhythm is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation, either version 2 of the License, or (at your option) any later
 * version.
 *
 * CollaboRhythm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with CollaboRhythm.  If not, see
 * <http://www.gnu.org/licenses/>.
 */

package collaboRhythm.iHAART.cloudMessaging.controller
{


	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequestHeader;
	import flash.text.TextField;
	import flash.utils.getQualifiedClassName;

	import mx.events.ResizeEvent;

	import com.afterisk.shared.ane.lib.GCMPushInterface;
	import com.afterisk.shared.ane.lib.GCMEvent;

	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.utils.ObjectUtil;
	import mx.utils.URLUtil;

	import collaboRhythm.shared.model.settings.Settings;
	import collaboRhythm.shared.model.services.WorkstationKernel;

	import collaboRhythm.iHAART.sqlStore.controller.SQLStoreController;

	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.EventDispatcher;
	import flash.events.InvokeEvent;
	import flash.net.URLRequest;

	import spark.skins.spark.StackedFormHeadingSkin;

	public class CloudMessagingController
	{
		public static var REGID_NONE:String = "NONE";
		public static var STATUS_OK:String = "200";
		private static const ACCOUNT_ID_SUFFIX:String = "@records.media.mit.edu";

		private var _statusText:String;
		private var _gcmi:GCMPushInterface;
		private var _registrationID:String;
		private var _payload:String;
		private var _isRegistered:Boolean;
		private var _dbController:SQLStoreController;
		private var _urlRequest:URLRequest;
		private var _httpStatusEvent:HTTPStatusEvent;
		private var _httpResponseStatusEvent:HTTPStatusEvent;

		private var STATUS_STR:String;

		private var _settings:Settings;
		private var _logger:ILogger;

		public function CloudMessagingController()
		{
			initialize();
		}

		public function initialize():void
		{
			statusText = "\n\nInitializing GCMPushInterface...\n";
			//create instance of extension interface and add appropriate listeners to it
			gcmi = new GCMPushInterface();
			gcmi.addEventListener(GCMEvent.REGISTERED, handleRegistered, false, 0, true);
			gcmi.addEventListener(GCMEvent.UNREGISTERED, handleUnregistered, false, 0, true);
			gcmi.addEventListener(GCMEvent.MESSAGE, handleMessage, false, 0, true);
			gcmi.addEventListener(GCMEvent.ERROR, handleError, false, 0, true);
			gcmi.addEventListener(GCMEvent.RECOVERABLE_ERROR, handleError, false, 0, true);

			logger.info("CloudMessaging initialized");
		}

		public function registerDevice():String
		{
			logger.info("Registering device with GCM SenderID: " + settings.gcmSenderID);
			statusText.concat("\n\nRegistering device with GCM...\n");
			//check if device is already registered otherwise start registration process and wait for REGISTERED event
			var response:String = gcmi.register(settings.gcmSenderID);
			logger.info("  GMC register response: " + response);

			if (response.indexOf("registrationID:") != -1)
			{
				logger.info(" Device already registered: " + response);
				statusText.concat("\n\nDevice was already registered.\n" + response);
				registrationID = response.substr(response.indexOf(":") + 1);
				isRegistered = true;

				return response;
			}

			return response;
		}

//		public function unregister(e:MouseEvent = null):void
//		{
//			statusText.concat("\n\nUnegistering device with GCM...");
//			gcmi.unregister();
//		}

		//on successful registration get GCM registration id for your device
		private function handleRegistered(event:GCMEvent):void
		{
			//todo bree add returned deviceRegistrationID to preferences for later use
			registrationID = event.deviceRegistrationID;
			isRegistered = true;
			dbController.saveRegistrationID(registrationID);
			logger.info("  Received device registrationID: " + registrationID);
			statusText.concat("\n\nreceived device registrationID: " + registrationID);
			updateLaunchPad();

		}

		private function updateLaunchPad():void {

			logger.info("  Updating GMC server with new registration ID: " + settings.gcmServerBaseURL);

			try
			{
				var nameValuePairs:Object = {};
				nameValuePairs["key"] = settings.gcmHTTPPostKey;
				nameValuePairs["account"] = settings.username + ACCOUNT_ID_SUFFIX;
				nameValuePairs["regid"] = registrationID;

				urlRequest.userAgent = settings.gcmUserAgent;
				urlRequest.contentType = "application/x-www-form-urlencoded";
				urlRequest.data = nameValuePairs;
				
				var urlLoader:URLLoader = new URLLoader();
				urlLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, handleHTTPResult);
				urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, handleHTTPStatus);
//			urlLoader.addEventListener(Event.COMPLETE, completeHandler);
//			urlLoader.addEventListener(Event.OPEN, openHandler);
//			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorEventHandler);
//			urlLoader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
//			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
				urlLoader.load(urlRequest);
			}
			catch (error:Error)
			{
				logger.info("    Error in CloudMessagingController.updateLaunchPad(): " +
				error.errorID +
				" ---- " +
				error.message);
			}


		}

		public function checkPendingFromLaunchPayload():String
		{
			logger.info("  Checking for pending GCM payload...");
			payload = gcmi.checkPendingPayload();
			trace("bree in check pending from launch payload pre if:  ", payload);
			if (payload != GCMPushInterface.NO_MESSAGE)
			{
				statusText.concat("\n\npending payload:" + payload);
				logger.info("  Pending GCM messages: " + payload);
				handlePayload();
				return payload;
			}
			return payload.toString();
		}

		//messages are received when app is in background therefore add event for when app is resumed from notification
		private function handleMessage(event:GCMEvent):void
		{
			//get payload
			payload = event.message;
			statusText.concat("\n\nGCM payload received:" + payload);
			trace("app is in the background: adding GCM app invoke listener  ", payload);
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke, false, 0, true);
		}

		private function onInvoke(event:InvokeEvent):void
		{
			trace("app was invoked by gcm notification");
			statusText.concat("\n\napp was invoked from GCM notification");
			NativeApplication.nativeApplication.removeEventListener(InvokeEvent.INVOKE, onInvoke);
			handlePayload();
		}

		public function handlePayload():void
		{
			trace("bree in handlePayload: payload = ", payload);
			//you can parse and treat gcm payload here
			//dispatch an event or open an appropriate view
		}

		//when device is unregistered on Google side, you might want to unregister it with your backend service
		private function handleUnregistered(event:GCMEvent):void
		{
			//
			//unregister with yours or public backend messaging service
			//...
		}

		//handle variety of gcm errors
		private function handleError(error:GCMEvent):void
		{
			logger.info("    Error in CloudMessagingController.handleError(): " +
					error.errorCode +
					" ---- " +
					error.message);
		}

		private function handleHTTPStatus(status:HTTPStatusEvent):void
		{
			logger.info("  Http status: " +
					status.status);
		}

		private function handleHTTPResult(result:HTTPStatusEvent):void
		{
			logger.info("  Http result: " +
					result.currentTarget.toString() +
					" ---- " +
					result.status +
					" ---- " +
					result.toString());
		}


		public function get statusText():String
		{
			return _statusText;
		}

		public function set statusText(value:String):void
		{
			_statusText = value;
		}

		public function get gcmi():GCMPushInterface
		{
			return _gcmi;
		}

		public function set gcmi(value:GCMPushInterface):void
		{
			_gcmi = value;
		}

		public function get registrationID():String
		{
			return _registrationID;
		}

		public function set registrationID(value:String):void
		{
			_registrationID = value;
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
	}
}
