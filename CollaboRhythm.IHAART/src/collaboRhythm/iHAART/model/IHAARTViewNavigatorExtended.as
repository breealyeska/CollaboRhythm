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

package collaboRhythm.iHAART.model
{
	import collaboRhythm.shared.model.tablet.ViewNavigatorExtendedEvent;

	import spark.components.ViewNavigator;
	import spark.components.supportClasses.ViewNavigatorAction;
	import spark.transitions.ViewTransitionBase;
	import mx.core.mx_internal;

	/**
	 * Extends ViewNavigator to add dispatching of an event when a view is popped via the normal popView method.
	 * Exposes a method (popViewRemote) for preventing the dispatching of this event.
	 */
	public class IHAARTViewNavigatorExtended extends ViewNavigator
	{
		public function IHAARTViewNavigatorExtended()
		{
			super();
		}

		override public function pushView(viewClass:Class, data:Object = null, context:Object = null,
										  transition:ViewTransitionBase = null):void
		{
			super.pushView(viewClass, data, context, transition);

			if (!(viewClass == null || !mx_internal::canRemoveCurrentView()))
			{
				dispatchEvent(new ViewNavigatorExtendedEvent(ViewNavigatorExtendedEvent.VIEW_PUSHED));
			}
		}

		override public function popView(transition:ViewTransitionBase = null):void
		{
			super.popView(transition);

			if (!(mx_internal::navigationStack.length == 0 || !mx_internal::canRemoveCurrentView()))
			{
				dispatchEvent(new ViewNavigatorExtendedEvent(ViewNavigatorExtendedEvent.VIEW_POPPED));
			}
		}

		/**
		 * Pops a view without dispatching ViewNavigatorExtendedEvent.VIEW_POPPED. This is generally only called on
		 * the remote (slave) side of an collaboration so that the slave does not send a message back to the master
		 * to perform another (redundant) pop.
		 * @param transition The view transition to play while switching views.
		 */
		public function popViewRemote(transition:ViewTransitionBase = null):void
		{
			super.popView(transition);
		}

/*
		public function get expectedViewStackLength():int
		{
			var length:int = _navigationStack.length;

			for each (var parameters:Object in delayedNavigationActionsGetter)
			{
				switch (parameters.action)
				{
					case ViewNavigatorAction.PUSH:
						length++;
						break;
					case ViewNavigatorAction.POP:
						length--;
						break;
					case ViewNavigatorAction.POP_ALL:
						length = 0;
						break;
					case ViewNavigatorAction.POP_TO_FIRST:
						length = 1;
						break;
				}
			}

			return length;
		}

		private function get delayedNavigationActionsGetter():Vector.<Object>
		{
			return this["delayedNavigationActions"];
		}
*/
	}
}
