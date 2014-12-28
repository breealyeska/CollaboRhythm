package collaboRhythm.iHAART.model.events
{
	import collaboRhythm.iHAART.cloudMessaging.controller.CloudMessagingController;
	import collaboRhythm.iHAART.sqlStore.controller.SQLStoreController;

	import com.alyeska.shared.ane.GCMPushInterface;

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
		public function IHAARTEvent(eventType:String, message:String, bubbles:Boolean = false, cancelable:Boolean = false)
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
					FlexGlobals.topLevelApplication.applicationController.activeAccountLoadedHandler(this.message);
					break;
				case SCHEDULE_LOADED :
					this.message = message;
					FlexGlobals.topLevelApplication.applicationController.scheduleLoadedHandler(this.message);
					break;
				case MEDICATION_LOADED :
					this.message = message;
//					FlexGlobals.topLevelApplication.applicationController.medicationLoadedHandler();
					break;
				default :
					this.statusCode = "-1";
					break;
			}
		}

//		public override function clone():Event
//		{
//
//		}
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
