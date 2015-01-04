/**
 * Copyright 2014 Bree Alyeska, John Moore, Scott Gilroy
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

package collaboRhythm.iHAART.view.skins
{

	import flash.events.Event;

	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;

	import spark.primitives.Ellipse;
	import spark.primitives.Graphic;

	import spark.skins.mobile.ViewNavigatorApplicationSkin;

	public class IHAARTTestApplicationSkin extends ViewNavigatorApplicationSkin
	{

		public function IHAARTTestApplicationSkin()
		{
			addEventListener(Event.RESIZE, resizeHandler);
			addEventListener(Event.COMPLETE, completeHandler);
		}

		override protected function createChildren():void
		{

		}

		private function resizeHandler(event:Event):void
		{

		}

		private function completeHandler(event:Event):void
		{

		}
	}
}
