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

package collaboRhythm.iHAART.model.events
{

	import collaboRhythm.iHAART.cloudMessaging.controller.CloudMessagingController;
	import collaboRhythm.iHAART.sqlStore.controller.SQLStoreController;

	import com.alyeska.shared.ane.gcm.libInterface.GCMPushInterface;

	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.utils.getQualifiedClassName;

	import mx.core.FlexGlobals;

	import mx.logging.ILogger;
	import mx.logging.Log;

	public class IHAARTEvent extends Event
	{

		public var indivoRegistrationID:String;
		public var gcmServerRegistrationID:String;
		public var message:String;
		public var errorCode:String;
		public var statusCode:String;
		private var _logger:ILogger;

		static public const REGISTERED:String = "IHAARTEvent.REGISTERED";
		static public const UNREGISTERED:String = "IHAARTEvent.UNREGISTERED";
		static public const INDIVO_UPDATE:String = "IHAARTEvent.INDIVO_UPDATE";
		static public const INDIVO_GET:String = "IHAARTEvent.INDIVO_GET";
		static public const MESSAGE:String = "IHAARTEvent.MESSAGE";
		static public const FOREGROUND_MESSAGE:String = "IHAARTEvent.FOREGROUND_MESSAGE";
		static public const ERROR:String = "IHAARTEvent.ERROR";
		static public const SCHEDULE_LOADED:String = "IHAARTEvent.SCHEDULE_LOADED";
		static public const MEDICATION_LOADED:String = "IHAARTEvent.MEDICATION_LOADED";
		static public const ACTIVE_ACCOUNT_LOADED:String = "IHAARTEvent.ACTIVE_ACCOUNT_LOADED";

		/**
		 * Constructor.
		 *
		 * @param type Event type.
		 * @param volume The system volume.
		 * @param bubbles Whether or not the event bubbles.
		 * @param cancelable Whether or not the event is cancelable.
		 */

		public function IHAARTEvent(eventType:String,
									message:String,
									bubbles:Boolean = false,
									cancelable:Boolean = false)
		{
			super(eventType, bubbles, cancelable);
			logger.info("  CM Event: " + eventType + "  " + message);

			switch (eventType)
			{
				case REGISTERED :
					this.gcmServerRegistrationID = message;
					break;
				case UNREGISTERED :
					this.gcmServerRegistrationID = GCMPushInterface.NO_REGID;
					break;
				case INDIVO_UPDATE :
					this.statusCode = message;
					break;
				case INDIVO_GET :
					this.indivoRegistrationID = message;
					break;
				case MESSAGE :
					this.message = message;
					break;
				case FOREGROUND_MESSAGE :
					this.message = message;
					break;
				case ACTIVE_ACCOUNT_LOADED :
					this.message = message;
					FlexGlobals.topLevelApplication.applicationController.activeAccount_loadedHandler(this.message);
					break;
				case SCHEDULE_LOADED :
					this.message = message;
					FlexGlobals.topLevelApplication.applicationController.schedule_loadedHandler(this.message);
					break;
				case MEDICATION_LOADED :   //message = 'success' or 'failure' based on whether object was initialized
					this.message = message;
					break;
				default :
					this.statusCode = "-1";
					break;
			}
		}

		/**
		 * Creates and returns a copy of the current instance.
		 * @return A copy of the current instance.
		 */
		public override function clone():Event
		{
			return new IHAARTEvent(this.type, this.message, this.bubbles, this.cancelable);
		}

		public function get logger():ILogger
		{
			if (!_logger)
			{
				logger = Log.getLogger(getQualifiedClassName(this).replace("::", "."));
			}
			return _logger;
		}

		public function set logger(value:ILogger):void
		{
			_logger = value;
		}
	}
}
