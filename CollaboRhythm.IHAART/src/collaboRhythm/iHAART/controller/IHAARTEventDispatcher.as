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

package collaboRhythm.iHAART.controller
{
	import collaboRhythm.iHAART.model.events.IHAARTEvent;

	import com.alyeska.shared.ane.gcm.libInterface.events.GCMEvent;

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
