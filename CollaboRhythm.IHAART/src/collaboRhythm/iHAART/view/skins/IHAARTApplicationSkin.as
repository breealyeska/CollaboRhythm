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

package collaboRhythm.iHAART.view.skins
{
	import collaboRhythm.core.view.AboutApplicationView;
	import collaboRhythm.core.view.BusyView;
	import collaboRhythm.core.view.ConnectivityView;
	import collaboRhythm.core.view.InAppPassCodeView;
	import collaboRhythm.iHAART.model.IHAARTViewNavigatorExtended;

	import flash.events.Event;

	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;

	import spark.primitives.Ellipse;
	import spark.primitives.Graphic;

	import spark.skins.mobile.ViewNavigatorApplicationSkin;

	public class IHAARTApplicationSkin extends ViewNavigatorApplicationSkin
	{
		public var connectivityView:ConnectivityView;
		public var busyView:BusyView;
		public var aboutApplicationView:AboutApplicationView;
		public var inAppPassCodeView:InAppPassCodeView;

		public var scheduleItemArray:ArrayCollection;

		public function IHAARTApplicationSkin()
		{
			addEventListener(Event.RESIZE, resizeHandler);
			addEventListener(Event.COMPLETE, completeHandler);
		}

		override protected function createChildren():void
		{
			navigator = new IHAARTViewNavigatorExtended();
			navigator.id = "navigator";

			addChild(navigator);

			connectivityView = new ConnectivityView();
			connectivityView.width = 600;
			connectivityView.height = 400;
			connectivityView.visible = false;
			connectivityView.horizontalCenter = 0;
			connectivityView.verticalCenter = 0;
			addChild(connectivityView);

			busyView = new BusyView();
			busyView.width = 800;
			busyView.height = 600;

			aboutApplicationView = new AboutApplicationView();
			aboutApplicationView.width = 800;
			aboutApplicationView.height = 600;
			aboutApplicationView.visible = false;
			addChild(aboutApplicationView);

			inAppPassCodeView = new InAppPassCodeView();
			inAppPassCodeView.width = 800;
			inAppPassCodeView.height = 600;
			inAppPassCodeView.visible = false;
			addChild(inAppPassCodeView);
		}

		private function resizeHandler(event:Event):void
		{
			connectivityView.width = width;
			connectivityView.height = height;
//			busyView.width = width;
//			busyView.height = height;
//			aboutApplicationView.width = width;
//			aboutApplicationView.height = height;
//			inAppPassCodeView.width = width;
//			inAppPassCodeView.height = height;
		}

		private function completeHandler(event:Event):void
		{
//			connectivityView.width = width;
//			connectivityView.height = height;
//			busyView.width = width;
//			busyView.height = height;
//			aboutApplicationView.width = width;
//			aboutApplicationView.height = height;
//			inAppPassCodeView.width = width;
//			inAppPassCodeView.height = height;
		}
	}
}
