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

package collaboRhythm.shared.cloudMessaging.controller
{

	import flash.desktop.NativeApplication;
	import flash.text.TextField;
	import flash.utils.getQualifiedClassName;

	import mx.events.ResizeEvent;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.InvokeEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;

	import com.afterisk.shared.ane.lib.GCMPushInterface;
	import com.afterisk.shared.ane.lib.GCMEvent;


	import flash.events.EventDispatcher;
	import flash.net.URLRequest;

	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.utils.ObjectUtil;
	import mx.utils.URLUtil;

	import collaboRhythm.shared.model.settings.Settings;
	import collaboRhythm.shared.model.services.WorkstationKernel;

	public class CloudMessagingController
	{

		public static const SENDER_ID:String = "57214367303";// collaboRhythm Application GCMSenderID (defined through google apps dashboard);

		private var _statusText:String;
		private var _gcmi:GCMPushInterface;
		private var _gcmDeviceID:String;
		private var _payload:String;

		private var STATUS_CODE:int;
		private var STATUS_STR:String;
		private var USER_AGENT:String = "CollaboRhythm";
		/**
		 * Tag used on log messages.
		 */
		private var TAG:String = "GCMDemo";
		private var PROPERTY_REG_ID:String = "gcm_4_ihaart_reg_id";
		// connection key required to submit the Google Cloud Messaging (GCM) registration ID
		private var HTTP_POST_KEY:String = "iyeH@@rthTtPp05tkeeee";
		// the server to connect to when posting the GCM registration ID
		//todo bree make this dynamic based on settings file
		private var UMASS_IHAART_SERVER:String = "https://www.umassartstudy.org:8080/launchpad";

		private var _settings:Settings;
		private var _logger:ILogger;

		public function CloudMessagingController()
		{
			logger = Log.getLogger(getQualifiedClassName(this).replace("::", "."));
			initialize();
		}

		public function initialize():void
		{
			trace("bree in initialize ");
			statusText = "\n\nInitializing GCMPushInterface...\n";
			//create instance of extension interface and add appropriate listeners to it
			gcmi = new GCMPushInterface();
			gcmi.addEventListener(GCMEvent.REGISTERED, handleRegistered, false, 0, true);
			gcmi.addEventListener(GCMEvent.UNREGISTERED, handleUnregistered, false, 0, true);
			gcmi.addEventListener(GCMEvent.MESSAGE, handleMessage, false, 0, true);
			gcmi.addEventListener(GCMEvent.ERROR, handleError, false, 0, true);
			gcmi.addEventListener(GCMEvent.RECOVERABLE_ERROR, handleError, false, 0, true);

			settings = WorkstationKernel.instance.resolve(Settings) as Settings;
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
				//extract GCM registration id for your device from response, you will need that to send messages to the device
				//create your own backend service or use public services
				gcmDeviceID = response.substr(response.indexOf(":") + 1);
				//handleRegistrationIDReceived();
				//if device was already registered check if there is any pending payload from GCM
				//this can be true when android shut down your app and its restarted instead of being resumed
				//checkPendingFromLaunchPayload();
				return gcmDeviceID;
			}

			return response;
		}

//		public function unregister(e:MouseEvent = null):void
//		{
//			statusText.concat("\n\nUnegistering device with GCM...");
//			gcmi.unregister();
//		}

		//on successful registration get GCM registration id for your device
		private function handleRegistered(e:GCMEvent):void
		{
			//todo bree add returned deviceRegistrationID to preferences for later use
			gcmDeviceID = e.deviceRegistrationID;
			logger.info(" Received device registrationID: " + gcmDeviceID);
			statusText.concat("\n\nreceived device registrationID: " + gcmDeviceID);
			handleRegistrationIDReceived();
		}

		private function handleRegistrationIDReceived():void
		{
			trace("bree in handleRegistrationIDReceived");
			//send device id to backend service that will broadcast messages
		}

		public function checkPendingFromLaunchPayload():void
		{
			_payload = gcmi.checkPendingPayload();
			if (_payload != GCMPushInterface.NO_MESSAGE)
			{
				statusText.concat("\n\npending payload:" + _payload);
				handlePayload();
			}
		}

		//messages are received when app is in background therefore add event for when app is resumed from notification
		private function handleMessage(e:GCMEvent):void
		{
			//get payload
			_payload = e.message;
			statusText.concat("\n\nGCM payload received:" + _payload);
			trace("app is in the background: adding GCM app invoke listener");
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke, false, 0, true);
		}

		private function onInvoke(e:InvokeEvent):void
		{
			trace("app was invoked by gcm notification");
			statusText.concat("\n\napp was invoked from GCM notification");
			NativeApplication.nativeApplication.removeEventListener(InvokeEvent.INVOKE, onInvoke);
			handlePayload();
		}

		public function handlePayload():void
		{
			//you can parse and treat gcm payload here
			//dispatch an event or open an appropriate view
		}

		//when device is unregistered on Google side, you might want to unregister it with your backend service
		private function handleUnregistered(e:GCMEvent):void
		{
			//
			//unregister with yours or public backend messaging service
			//...
		}

		//handle variety of gcm errors
		private function handleError(e:GCMEvent):void
		{
			trace("bree in error");
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

		public function get gcmDeviceID():String
		{
			return _gcmDeviceID;
		}

		public function set gcmDeviceID(value:String):void
		{
			_gcmDeviceID = value;
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
			return _logger;
		}

		public function set logger(value:ILogger):void
		{
			_logger = value;
		}

		public function get settings():Settings
		{
			return _settings;
		}

		public function set settings(value:Settings):void
		{
			_settings = value;
		}
	}
}
