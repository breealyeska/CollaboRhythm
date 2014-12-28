/**
 * Copyright 2014 Bree Alyeska
 *
 * This file is part of CollaboRhythm and based off of the Eskimo project by PeopleInAction found at: http://github.com/People-in-action/eskimo
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

package collaboRhythm.iHAART.model
{
	import collaboRhythm.iHAART.view.skins.NotificationSkin;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.StageOrientationEvent;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.ui.Keyboard;

	import mx.core.FlexGlobals;
	import mx.core.IFlexDisplayObject;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.managers.ISystemManager;
	import mx.managers.PopUpManager;

	import spark.components.Button;
	import spark.components.Group;
	import spark.components.Label;
	import spark.components.PopUpPosition;
	import spark.components.supportClasses.SkinnableComponent;

	import collaboRhythm.iHAART.view.skins.NotificationSkin;
	import collaboRhythm.iHAART.view.skins.ButtonSkin;
	import collaboRhythm.iHAART.model.ExtendedButton;

	/**
	 * Evant dispatched when the Alert is closed
	 * @eventType mx.events.CloseEvent.CLOSE
	 */
	[Event(name="close", type="mx.events.CloseEvent")]

	/**
	 * Define the chrome background color the Alert comtrol
	 * @defaults ios: 0x031037, android: 0x424242
	 */
	[Style(name="backgroundColor", inherit="no", type="uint")]

	/**
	 * Define the chrome background alpha the Alert comtrol
	 * @defaults 0.9
	 */
	[Style(name="backgroundAlpha", inherit="no", type="uint")]

	/**
	 * Style of the OK button
	 * @defaults "okButtonStyle"
	 */
	[Style(name="okButtonStyleName", inherit="no", type="String")]

	/**
	 * This component allow the user to display an Alert.
	 * It automatically uses iOS or Android 's style depending to the execution platform.
	 *
	 * It follows the mx.controls.Alert 's behavior.
	 */
	public class SkinnableNotification extends SkinnableComponent
	{
		/**
		 *  Value that enables a OK button on the Alert control
		 */
		public static const OK:uint = 0x0004;

		/**
		 *  Value that remove modal background
		 */
		public static const NONMODAL:uint = 0x8000;

		/**
		 *  A bitmask that contains <code>SkinnableNotification.OK</code>, <code>SkinnableNotification.CANCEL</code>,
		 *  <code>SkinnableNotification.YES</code>, and/or <code>SkinnableNotification.NO</code> indicating
		 *  the buttons available in the SkinnableNotification control.
		 */
		public var buttonFlags:uint = OK;

		/**
		 * @private
		 */
		public var buttonFlagsChanged:Boolean = true;

		/**
		 * @private
		 */
		protected var _text:String;
		/**
		 * @private
		 */
		protected var _title:String;

		/**
		 * Title skin part
		 */
		[SkinPart(required="false")]
		public var titleDisplay:Label;

		/**
		 * Text skin part
		 */
		[SkinPart(required="false")]
		public var textDisplay:Label;

		/**
		 * Control bar group skin part
		 */
		[SkinPart(required="false")]
		public var controlBarGroup:Group;

		/**
		 * @private
		 */
		protected var buttonOK:Button = new Button();


		/**
		 * @private
		 */
		protected static var _okLabel:String = "OK";

		/**
		 * @private
		 */
		protected static var _buttonHeight:Number = 70;

		protected var currentOS:String;

		protected var isIOS:Boolean;


		/**
		 * Constructor
		 */
		public function SkinnableNotification()
		{
			buttonOK = new Button();

			buttonOK.addEventListener(MouseEvent.CLICK, onOKClick);

			buttonOK.percentWidth = 100;

			buttonOK.percentHeight = 100;

			buttonOK.label = _okLabel;

			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, removeFromStage, false, 0, true);

			currentOS = Capabilities.version.toLocaleUpperCase();
			isIOS = currentOS.lastIndexOf("IOS") != -1;

		}

		protected function onAddedToStage(event:Event):void
		{
			systemManager.getSandboxRoot().addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 0, true);
			stage.addEventListener(StageOrientationEvent.ORIENTATION_CHANGE, onOrientationChange, false, 0, true);
		}

		/**
		 * @private
		 */
		protected function removeFromStage(event:Event):void
		{
			systemManager.getSandboxRoot().removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

			stage.removeEventListener(StageOrientationEvent.ORIENTATION_CHANGE, onOrientationChange);
		}

		/**
		 * @private
		 */
		protected function onOrientationChange(event:Event):void
		{
			invalidateDisplayList();
		}

		/**
		 * @private
		 */
		protected override function partAdded(partName:String, instance:Object):void
		{
			super.partAdded(partName, instance);
			if (instance == controlBarGroup)
			{
				controlBarGroup.height = _buttonHeight;
				controlBarGroup.removeAllElements();

				if (buttonFlags & SkinnableNotification.OK)
				{
					controlBarGroup.addElementAt(buttonOK, isIOS ? 0 : controlBarGroup.numChildren);
				}
			}
			if (instance == titleDisplay)
			{
				titleDisplay.text = _title;
			}
			if (instance == textDisplay)
			{
				textDisplay.text = _text;
			}
		}

		/**
		 * @private
		 */
		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (buttonFlagsChanged)
			{
				if (controlBarGroup)
				{
					controlBarGroup.removeAllElements();
					if (buttonFlags & SkinnableNotification.OK)
					{
						controlBarGroup.addElementAt(buttonOK, isIOS ? 0 : controlBarGroup.numChildren);
					}
				}

				buttonFlagsChanged = false;

				buttonOK.styleName = getStyle("okButtonStyleName");
			}

			PopUpManager.centerPopUp(this);
		}

		/**
		 * @private
		 */
		override protected function commitProperties():void
		{
			super.commitProperties();

			if (textDisplay)
			{
				textDisplay.text = _text;
			}
		}

		/**
		 * Create and show an Alert control
		 * @param text     Text showed in the Alert control
		 * @param title    Title of the Alert control
		 * @param flags    A bitmask that contains <code>SkinnableNotification.OK</code>, <code>SkinnableNotification.CANCEL</code>,
		 *                 <code>SkinnableNotification.YES</code>, and/or <code>SkinnableNotification.NO</code> indicating
		 *                 the buttons available in the SkinnableNotification control.
		 * @param closeHandler  Close function callback
		 *
		 */
		public static function show(text:String = "",
									title:String = "",
									flags:uint = 0x4,
									parent:Sprite = null,
									closeHandler:Function = null):SkinnableNotification
		{
			var modal:Boolean = (flags & SkinnableNotification.NONMODAL) ? false : true;

			if (!parent)
			{
				var sm:ISystemManager = ISystemManager(FlexGlobals.topLevelApplication.systemManager);
				// no types so no dependencies
				var mp:Object = sm.getImplementation("mx.managers.IMarshallPlanSystemManager");
				if (mp && mp.useSWFBridge())
				{
					parent = Sprite(sm.getSandboxRoot());
				}
				else
				{
					parent = Sprite(FlexGlobals.topLevelApplication);
				}
			}


			var alert:SkinnableNotification = new SkinnableNotification();


			if (flags &
					SkinnableNotification.OK)
			{
				alert.buttonFlags = flags;
			}

			alert.text = text;
			alert.title = title;

			if (closeHandler != null)
			{
				alert.addEventListener(CloseEvent.CLOSE, closeHandler);
			}

			alert.addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete, false, 0, true);


			PopUpManager.addPopUp(alert, parent, modal);

			return alert;
		}

		/**
		 * @private
		 */
		protected static function onCreationComplete(event:FlexEvent):void
		{
			PopUpManager.centerPopUp(event.target as IFlexDisplayObject);
		}

		/**
		 * Text of the SkinnableNotification control
		 */
		public function get text():String
		{
			return _text;
		}

		/**
		 * @private
		 */
		public function set text(value:String):void
		{
			_text = value;
		}

		/**
		 * Title of the SkinnableNotification control
		 */
		public function get title():String
		{
			return _title;
		}

		/**
		 * @private
		 */
		public function set title(value:String):void
		{
			_title = value;
		}

		/**
		 * Label of the OK button
		 */
		public static function get okLabel():String
		{
			return _okLabel;
		}

		/**
		 * @private
		 */
		public static function set okLabel(value:String):void
		{
			_okLabel = value;
		}

		/**
		 * Buttons height
		 */
		public static function get buttonHeight():Number
		{
			return _buttonHeight;
		}

		/**
		 * @private
		 */
		public static function set buttonHeight(value:Number):void
		{
			_buttonHeight = value;
		}

		/**
		 * @private
		 */
		protected function onOKClick(event:MouseEvent):void
		{
			dispatchEvent(new CloseEvent(CloseEvent.CLOSE, false, false, SkinnableNotification.OK));
			PopUpManager.removePopUp(this);
		}

		/**
		 * @private
		 */
		protected override function measure():void
		{
			super.measure();

			measuredMinWidth = 300;
			measuredMinHeight = 150;

			measuredWidth = 600;
		}

		/**
		 * @private
		 */
		protected function onKeyDown(event:KeyboardEvent):void
		{
			if (event.keyCode == Keyboard.BACK)
			{
				event.preventDefault();
			}
		}

	}
}
