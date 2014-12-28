package collaboRhythm.iHAART.controller
{
	import collaboRhythm.iHAART.model.events.IHAARTEvent;

	import com.alyeska.shared.ane.events.GCMEvent;

	import flash.events.IEventDispatcher;

//	import flash.events.IEventDispatcher;
	import flash.events.EventDispatcher;
	import flash.events.Event;

	public class IHAARTEventDispatcher extends EventDispatcher // implements IEventDispatcher
	{

		private var dispatcher:EventDispatcher;

		public function IHAARTEventDispatcher()
		{
			super();
//			dispatcher = new EventDispatcher(this);

		}

//		public function dispatchEvent(event:Event):Boolean
//		{
//			return dispatcher.dispatchEvent(event);
//		}
//
//		public function addEventListener(eventType:String,
//										 listener:Function,
//										 useCapture:Boolean = false,
//										 priority:int = 0,
//										 useWeakReference:Boolean = false):void
//		{
//			dispatcher.addEventListener(eventType, listener, useCapture, priority, useWeakReference);
//		}
//
//		public function removeEventListener(eventType:String, listener:Function, useCapture:Boolean = false):void
//		{
//			dispatcher.removeEventListener(eventType, listener, useCapture);
//		}
//
//		public function hasEventListener(eventType:String):Boolean
//		{
//			return dispatcher.hasEventListener(eventType);
//		}
//
//		public function willTrigger(eventType:String):Boolean
//		{
//			return dispatcher.willTrigger(eventType);
//		}
	}
}
