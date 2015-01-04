/**
 * Copyright 2014 Bree Alyeska
 *
 * This file is part of iHAART & CollaboRhythm and is at least in part based off of the Eskimo project by PeopleInAction found at: http://github.com/People-in-action/eskimo
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
		import flash.display.InteractiveObject;

		import spark.components.IItemRenderer;
		import spark.events.ListEvent;

		/**
		 * Events dispatch by ContextableList Component
		 */
		public class ContextableListEvent extends ListEvent
		{
			/**
			 * Long press Event
			 */
			public static const ITEM_LONG_PRESS:String = "itemLongPress";

			/**
			 * Context Menu clicked
			 */
			public static const CONTEX_MENU_ITEM_CLICK:String = "contextMenuItemClick";

			/**
			 * Menu item clicked
			 */
			public var menuItem:Object;

			/**
			 * Constructor
			 */
			public function ContextableListEvent(type:String,
												 bubbles:Boolean = false,
												 cancelable:Boolean = false,
												 localX:Number = NaN,
												 localY:Number = NaN,
												 relatedObject:InteractiveObject = null,
												 ctrlKey:Boolean = false,
												 altKey:Boolean = false,
												 shiftKey:Boolean = false,
												 buttonDown:Boolean = false,
												 delta:int = 0,
												 itemIndex:int = -1,
												 item:Object = null,
												 itemRenderer:IItemRenderer = null,
												 menuItem:Object = null)
			{
				this.menuItem = menuItem;

				super(type,
						bubbles,
						cancelable,
						localX,
						localY,
						relatedObject,
						ctrlKey,
						altKey,
						shiftKey,
						buttonDown,
						delta,
						itemIndex,
						item,
						itemRenderer);
			}
		}
}
