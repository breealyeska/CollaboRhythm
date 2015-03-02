/**
 * Copyright 2014 John Moore, Scott Gilroy, Bree Alyeska
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
package collaboRhythm.tablet.controller
{

	import collaboRhythm.core.controller.ApplicationControllerBase;
	import collaboRhythm.core.controller.HealthRecordTreeController;
	import collaboRhythm.core.controller.apps.AppControllersMediatorBase;
	import collaboRhythm.core.model.HealthRecordTreeModel;
	import collaboRhythm.iHAART.cloudMessaging.controller.CloudMessagingController;
	import collaboRhythm.iHAART.controller.IHAARTEventDispatcher;
	import collaboRhythm.iHAART.model.DebuggingTools;
	import collaboRhythm.iHAART.model.IHAARTViewNavigatorExtended;
	import collaboRhythm.iHAART.model.Medication;
	import collaboRhythm.iHAART.model.SkinnableAlert;
	import collaboRhythm.iHAART.model.User;
	import collaboRhythm.iHAART.model.events.IHAARTEvent;
	import collaboRhythm.iHAART.sqlStore.controller.SQLStoreController;

	import collaboRhythm.shared.collaboration.model.CollaborationModel;
	import collaboRhythm.shared.collaboration.model.SynchronizationService;
	import collaboRhythm.shared.collaboration.view.CollaborationInvitationPopUp;
	import collaboRhythm.shared.collaboration.view.CollaborationInvitationPopUpEvent;
	import collaboRhythm.shared.collaboration.view.CollaborationVideoView;
	import collaboRhythm.shared.controller.apps.AppControllerBase;
	import collaboRhythm.shared.controller.apps.AppControllerConstructorParams;
	import collaboRhythm.shared.model.Account;
	import collaboRhythm.shared.model.services.IViewModifier;
	import collaboRhythm.shared.model.services.WorkstationKernel;
	import collaboRhythm.shared.model.settings.Settings;
	import collaboRhythm.shared.model.tablet.ViewNavigatorExtendedEvent;
	import collaboRhythm.shared.view.tablet.TabletViewBase;

	import collaboRhythm.tablet.view.HealthRecordTreeView;
	import collaboRhythm.tablet.view.IHAARTHomeView;
	import collaboRhythm.tablet.view.SelectRecordView;
	import collaboRhythm.tablet.view.TabletFullViewContainer;

	import com.alyeska.shared.ane.iHAART.libInterface.IHAARTInterface;

	import flash.display.Bitmap;

	import mx.collections.ArrayCollection;
	import mx.controls.Label;
	import mx.core.FlexGlobals;

	import spark.components.Image;
	import spark.components.Label;
	import spark.components.SkinnableContainer;
	import spark.components.VGroup;
	import spark.primitives.BitmapImage;

	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	import mx.binding.utils.BindingUtils;
	import mx.core.IVisualElementContainer;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	import mx.events.CloseEvent;

	import spark.components.ViewNavigator;
	import spark.transitions.SlideViewTransition;

	public class IHAARTApplicationController extends ApplicationControllerBase
	{
		private static const SESSION_IDLE_TIMEOUT:int = 60 * 5;
		private static const ACCOUNT_ID_SUFFIX:String = "@records.media.mit.edu";

		private var _iHAARTApplication:IHAARTApplication;
		private var _appControllersMediator:IHAARTAppControllersMediator;
		private var _fullContainer:IVisualElementContainer;

		[Embed("/../../CollaboRhythm.Tablet/src/resources/settings.xml", mimeType="application/octet-stream")]
		private var _applicationSettingsEmbeddedFile:Class;
		private var _openingRecordAccount:Boolean = false;

		private var _collaborationInvitationPopUp:CollaborationInvitationPopUp;
		private var _synchronizationService:SynchronizationService;

		private var _sessionIdleTimer:Timer;

		private var _scheduleItemsArray:ArrayCollection;

		[Bindable]
		private var _medication:Medication;

		[Bindable]
		private var _user:User;

		[Bindable]
		private var _userLabel:spark.components.Label;

		[Bindable]
		private var _registeredIcon:BitmapImage;
		private var _registeredGroup:VGroup;

		private var _userInfoContainer:SkinnableContainer;
		private var _mainContainer:SkinnableContainer;

		private var _gcmController:CloudMessagingController;
		private var _dbController:SQLStoreController;

		public function IHAARTApplicationController(iHAARTApplication:IHAARTApplication)
		{
			super(iHAARTApplication);

			_iHAARTApplication = iHAARTApplication;
			_connectivityView = iHAARTApplication.connectivityView;
			_busyView = iHAARTApplication.busyView;
			_aboutApplicationView = iHAARTApplication.aboutApplicationView;
			_inAppPassCodeView = iHAARTApplication.inAppPassCodeView;

			_userLabel = iHAARTApplication.iHAARTHomeView.userLabel;
//			_registeredIcon = iHAARTApplication.registeredIcon;
//			_registeredGroup = iHAARTApplication.registeredGroup;

			_userInfoContainer = iHAARTApplication.iHAARTHomeView.userInfoContainer;
			_mainContainer = iHAARTApplication.iHAARTHomeView.mainContainer;

			initializeConnectivityView();
			initializeInAppPassCodeView();
		}

		override public function main():void
		{
			super.main();

			gcmController.initialize();

			settings.modality = Settings.MODALITY_TABLET;

			initCollaborationController();
			_collaborationController.viewNavigator = navigator;
			_synchronizationService = new SynchronizationService(this, _collaborationLobbyNetConnectionServiceProxy);

			BindingUtils.bindSetter(collaborationState_changeHandler, _collaborationController.collaborationModel,
					"collaborationState");

			_iHAARTApplication.addEventListener(MouseEvent.MOUSE_DOWN, application_mouseDownHandler);

			navigator.addEventListener(Event.COMPLETE, viewNavigator_transitionCompleteHandler);
			navigator.addEventListener("viewChangeComplete",
					viewNavigator_transitionCompleteHandler);
			navigator.addEventListener(ViewNavigatorExtendedEvent.VIEW_POPPED, viewNavigator_viewPopped);
			navigator.addEventListener(Event.ADDED, viewNavigator_addedHandler);

//			BindingUtils.bindSetter(user_changeHandler, user, "givenName");
			initializeActiveView();

			createSession();

//			createGoogleAnalyticsSessionIdleTimer();
		}

		public function gcmState_registeredHandler():void
		{
			registeredIcon.visible = true;
		}

		public function gcmState_unregisteredHandler():void
		{
			registeredIcon.visible = false;
		}

		public function user_changeHandler(value:String):void
		{
//			trace("    bree in testing binding  ", value);
		}

		public function activeAccount_loadedHandler(givenName:String, familyName:String, account:String):void
		{

			var userData:Object = new Object();
			userData['registration_id'] = CloudMessagingController.NO_IND_REGID;
			userData['account_string'] = settings.gcmAccount.toString();
			var insertedRowID:Number = dbController.insertData(SQLStoreController.USERS_TABLE, userData);

			trace("   bree in activeAccount_loadedHandler, new ID:", insertedRowID);

			user = new User();
			user.initialize(givenName, familyName, account);
			userInfoContainer.visible = true;
			userLabel.text = user.fullName;
			userLabel.visible = true;

			mainContainer.visible = true;
		}

		public function schedule_loadedHandler(medData:Object):void
		{
			medication = new Medication(medData);
		}

		public function medicationImage_loadedHandler(medSource:String):void
		{
			medication.setImgSource(medSource);

//			var jsonString:String = {"nameText":medication.nameText, "doseAmount":medication.doseAmount, "doseUnit":medication.doseUnit, "indication":medication.indication, "instructions":medication.instructions, "startTime":medication.startTime, "endTime": medication.endTime, "imgSource":medication.imgSource};
			var jsonString = JSON.stringify(medication);
			DebuggingTools.taggedTrace("  entering startClockActivity function: " + jsonString);
			var utili:IHAARTInterface = new IHAARTInterface();
			utili.startClockActivity(jsonString);
		}

		public function settings_loadedHandler(message:String):void
		{
			gcmController.initialize();
		}

		private function collaborationState_changeHandler(collaborationState:String):void
		{
			if (collaborationState == CollaborationModel.COLLABORATION_INVITATION_SENT ||
					collaborationState == CollaborationModel.COLLABORATION_INVITATION_RECEIVED)
			{
				_collaborationInvitationPopUp = new CollaborationInvitationPopUp();
				_collaborationInvitationPopUp.init(_collaborationController, activeRecordAccount);
				_collaborationInvitationPopUp.addEventListener(CollaborationInvitationPopUpEvent.ACCEPT,
						collaborationInvitationPopUp_acceptHandler);
				_collaborationInvitationPopUp.addEventListener(CollaborationInvitationPopUpEvent.REJECT,
						collaborationInvitationPopUp_rejectHandler);
				_collaborationInvitationPopUp.addEventListener(CollaborationInvitationPopUpEvent.CANCEL,
						collaborationInvitationPopUp_cancelHandler);
				_collaborationInvitationPopUp.open(navigator.activeView as TabletViewBase, true);
				PopUpManager.centerPopUp(_collaborationInvitationPopUp);
			}
			else
			{
				if (_collaborationInvitationPopUp && _collaborationInvitationPopUp.isOpen)
				{
					_collaborationInvitationPopUp.close(false);
				}

				if (collaborationState == CollaborationModel.COLLABORATION_ACTIVE)
				{
					navigator.popToFirstView();
					navigator.pushView(CollaborationVideoView);
				}

				if (collaborationState == CollaborationModel.COLLABORATION_INACTIVE &&
						navigator.activeView as CollaborationVideoView)
				{
					navigator.popView();
				}
			}

			trackActiveView();
		}

		private function collaborationInvitationPopUp_acceptHandler(event:CollaborationInvitationPopUpEvent):void
		{
			_collaborationController.acceptCollaborationInvitation();
		}

		private function collaborationInvitationPopUp_rejectHandler(event:CollaborationInvitationPopUpEvent):void
		{
			_collaborationController.rejectCollaborationInvitation();
		}

		private function collaborationInvitationPopUp_cancelHandler(event:CollaborationInvitationPopUpEvent):void
		{
			_collaborationController.cancelCollaborationInvitation();
		}

		private function popCollaborationVideoView():void
		{
			var collaborationVideoView:CollaborationVideoView = navigator.activeView as CollaborationVideoView;
			if (collaborationVideoView)
			{
				navigator.popView();
			}
		}

		private function viewNavigator_transitionCompleteHandler(event:Event):void
		{
			if (iHAARTHomeView)
			{
				if (_openingRecordAccount)
				{
					showWidgets(activeRecordAccount);
					_openingRecordAccount = false;
				}
			}
			else if (_appControllersMediator)
			{
				_appControllersMediator.destroyWidgetViews();
			}

			if (_reloadWithFullView)
			{
				appControllersMediator.showFullView(_reloadWithFullView);
				_reloadWithFullView = null;
			}

			trackActiveView();
		}

		private function viewNavigator_addedHandler(event:Event):void
		{
			var view:TabletViewBase = event.target as TabletViewBase;
			if (view)
			{
				initializeView(view);
			}
		}

		public function initializeActiveView():void
		{
			var view:TabletViewBase = _iHAARTApplication.navigator.activeView as TabletViewBase;
			if (view)
			{
				initializeView(view);
			}
		}

		private function initializeView(view:TabletViewBase):void
		{
			view.activeAccount = activeAccount;
			view.activeRecordAccount = activeRecordAccount;
			view.tabletApplicationController = this;

			var viewModifiers:Array = WorkstationKernel.instance.resolveAll(IViewModifier);
			for each (var viewModifier:IViewModifier in viewModifiers)
			{
				viewModifier.modify(view);
			}
		}

		private function application_mouseDownHandler(event:MouseEvent):void
		{
			if (settings.useGoogleAnalytics)
			{
				if (_sessionIdleTimer.running)
				{
					_sessionIdleTimer.reset();
					_sessionIdleTimer.start();
				}
				else
				{
					_sessionIdleTimer.start();
					trackActiveView();
				}

				if (collaborationLobbyNetConnectionServiceProxy.collaborationModel.collaborationState ==
						CollaborationModel.COLLABORATION_ACTIVE)
				{
					_analyticsTracker.trackEvent("collaborationActivity", "click",
							getCollaborationActivityEventLabel());
				}
			}
		}

		override protected function activateTracking():void
		{
//			if (settings.useGoogleAnalytics)
//			{
//				_sessionIdleTimer.start();
//				trackActiveView();
//			}
		}

		override protected function showInAppPassCodeView():void
		{
			if (settings.requireInAppPassCode)
			{
				_inAppPassCodeView.visible = true;
			}
		}

		override protected function deactivateTracking():void
		{
//			if (settings.useGoogleAnalytics)
//			{
//				_sessionIdleTimer.reset();
//				trackActiveView("deactivated");
//				_analyticsTracker.resetSession();
//			}
		}

		override protected function exitTracking():void
		{
//			if (settings.useGoogleAnalytics)
//			{
//				trackActiveView("exited");
//				_analyticsTracker.resetSession();
//			}
		}

		private function trackActiveView(applicationState:String = null):void
		{
			if (settings.useGoogleAnalytics)
			{
				var recordAccountId:String;
				if (settings.mode == Settings.MODE_CLINICIAN)
				{
					if (activeRecordAccount && activeRecordAccount.accountId)
						recordAccountId = activeRecordAccount.accountId;
				}
				else
				{
					recordAccountId = settings.username + ACCOUNT_ID_SUFFIX;
				}

				var collaborationState:String = collaborationLobbyNetConnectionServiceProxy.collaborationModel.collaborationState;
				var peerId:String;
				if (collaborationLobbyNetConnectionServiceProxy.collaborationModel.peerAccount)
				{
					peerId = collaborationLobbyNetConnectionServiceProxy.collaborationModel.peerAccount.accountId;
				}

				var pageName:String;
				if (navigator.activeView as TabletFullViewContainer)
				{
					pageName = navigator.activeView.title;
				}
				else
				{
					pageName = navigator.activeView.className;
				}

				if (!applicationState)
				{
					applicationState = "activated";
				}

				var completePageName:String = "/applicationState=" + applicationState + "/recordAccountId=" +
						recordAccountId + "/collaborationState=" + collaborationState;
				if (peerId)
				{
					completePageName = completePageName + "/peerId=" + peerId;
				}
				completePageName = completePageName + "/pageName=" + pageName;

				_analyticsTracker.trackPageview(completePageName);
			}
		}

		override public function showSelectRecordView():void
		{
			_iHAARTApplication.navigator.pushView(SelectRecordView);
		}

		override public function openRecordAccount(recordAccount:Account):void
		{
			if (activeRecordAccount)
			{
				// End the collaboration before closing the record so that the automated message regarding the session can be sent
				_collaborationController.endCollaboration();
				closeRecordAccount(activeRecordAccount);
			}
			super.openRecordAccount(recordAccount);
			if (iHAARTHomeView)
			{
				initializeActiveView();
				iHAARTHomeView.init();
				showWidgets(recordAccount);
			}
			else
			{
				_openingRecordAccount = true;
				navigator.popToFirstView();
			}

			trackActiveView();
		}

		override public function sendCollaborationInvitation():void
		{
			super.sendCollaborationInvitation();
		}

		override public function navigateHome():void
		{
			if (_synchronizationService.synchronize("navigateHome"))
			{
				return;
			}

			navigator.popToFirstView()
		}

		override public function synchronizeBack():void
		{
			if (_synchronizationService.synchronize("synchronizeBack", null, false))
			{
				return;
			}

			(navigator as IHAARTViewNavigatorExtended).popViewRemote();
		}

		//		the apps are not actually loaded immediately when a record is opened
//		only after the active record view has been made visible are they loaded, this makes the UI more responsive
		public function showWidgets(recordAccount:Account):void
		{
			if (_appControllersMediator == null)
			{
				var appControllerConstructorParams:AppControllerConstructorParams = new AppControllerConstructorParams();
				appControllerConstructorParams.collaborationLobbyNetConnectionServiceProxy = _collaborationLobbyNetConnectionServiceProxy;
				appControllerConstructorParams.navigationProxy = _navigationProxy;
				_appControllersMediator = new IHAARTAppControllersMediator(iHAARTHomeView.widgetContainers,
						_fullContainer, _componentContainer, settings, appControllerConstructorParams, this);
			}
			_appControllersMediator.createAndStartApps(activeAccount, recordAccount);
		}

		private function get iHAARTHomeView():IHAARTHomeView
		{
			return _iHAARTApplication.iHAARTHomeView;
		}

		public override function get fullContainer():IVisualElementContainer
		{
			return _fullContainer;
		}

		public override function get applicationSettingsEmbeddedFile():Class
		{
			return _applicationSettingsEmbeddedFile;
		}

		public override function get appControllersMediator():AppControllersMediatorBase
		{
			return _appControllersMediator;
		}

		public override function get currentFullView():String
		{
			return _appControllersMediator.currentFullView;
		}

		// when a record is closed, all of the apps need to be closed and the documents cleared from the record
		public override function closeRecordAccount(recordAccount:Account):void
		{
			super.closeRecordAccount(recordAccount);
			_appControllersMediator.closeApps();
			if (recordAccount)
				recordAccount.primaryRecord.clearDocuments();
			activeRecordAccount = null;
			if (iHAARTHomeView)
				iHAARTHomeView.visible = false;
		}

		protected override function changeDemoDate():void
		{
			reloadData();

			if (activeRecordAccount && activeRecordAccount.primaryRecord &&
					activeRecordAccount.primaryRecord.demographics)
				activeRecordAccount.primaryRecord.demographics.dispatchAgeChangeEvent();
		}

		protected override function restoreFocus():void
		{
			if (iHAARTHomeView)
				iHAARTHomeView.setFocus();
		}

		public function pushFullView(appController:AppControllerBase):void
		{
			if (appController.fullView)
			{
				backgroundProcessModel.updateProcess("fullViewUpdate", "Updating...", true);
				appController.fullView.addEventListener(FlexEvent.UPDATE_COMPLETE, fullView_updateCompleteHandler,
						false, 0, true);
			}
			_iHAARTApplication.navigator.pushView(TabletFullViewContainer, appController, new SlideViewTransition());
		}

		private function fullView_updateCompleteHandler(event:FlexEvent):void
		{
			event.target.removeEventListener(FlexEvent.UPDATE_COMPLETE, fullView_updateCompleteHandler);
			backgroundProcessModel.updateProcess("fullViewUpdate", "Updating...", false);
		}

		public function useWidgetContainers():void
		{
			if (_appControllersMediator)
			{
				_appControllersMediator.widgetContainers = iHAARTHomeView.widgetContainers;
				_appControllersMediator.showWidgetsInNewContainers();
			}
		}

		override public function get navigator():ViewNavigator
		{
			return _iHAARTApplication ? _iHAARTApplication.navigator : null;
		}

		public function get tabletAppControllersMediator():IHAARTAppControllersMediator
		{
			return _appControllersMediator;
		}

		public function showCollaborationVideoView():void
		{
			if (_synchronizationService.synchronize("showCollaborationVideoView"))
			{
				return;
			}

			navigator.pushView(CollaborationVideoView);
		}

		override protected function prepareToExit():void
		{
			_collaborationController.prepareToExit();
		}

		public function setCollaborationLobbyConnectionStatus():void
		{
			if (activeRecordAccount.collaborationLobbyConnectionStatus == Account.COLLABORATION_LOBBY_AVAILABLE)
			{
				activeRecordAccount.collaborationLobbyConnectionStatus = Account.COLLABORATION_LOBBY_AWAY;
				_collaborationController.collaborationModel.collaborationLobbyNetConnectionService.updateCollaborationLobbyConnectionStatus(Account.COLLABORATION_LOBBY_AWAY);
			}
			else if (activeRecordAccount.collaborationLobbyConnectionStatus == Account.COLLABORATION_LOBBY_AWAY)
			{
				activeRecordAccount.collaborationLobbyConnectionStatus = Account.COLLABORATION_LOBBY_AVAILABLE;
				_collaborationController.collaborationModel.collaborationLobbyNetConnectionService.updateCollaborationLobbyConnectionStatus(Account.COLLABORATION_LOBBY_AVAILABLE);
			}
		}

		private function viewNavigator_viewPopped(event:ViewNavigatorExtendedEvent):void
		{
			synchronizeBack();
		}

		override public function showHealthRecordTreeView():void
		{
			var controller:HealthRecordTreeController = new HealthRecordTreeController(new HealthRecordTreeModel(activeRecordAccount.primaryRecord, _healthRecordServiceFacade), navigator);
			navigator.pushView(HealthRecordTreeView, controller);
		}

		public function get scheduleItemsArray():ArrayCollection
		{
			return _scheduleItemsArray;
		}

		public function get gcmController():CloudMessagingController
		{
			if (!_gcmController)
			{
				_gcmController = new CloudMessagingController();
			}
			return _gcmController;
		}

		public function set gcmController(value:CloudMessagingController):void
		{
			_gcmController = value;
		}

		public function get dbController():SQLStoreController
		{
			if (!_dbController)
			{
				_dbController = new SQLStoreController();
			}
			return _dbController;
		}

		public function set dbController(value:SQLStoreController):void
		{
			_dbController = value;
		}

		public function get medication():Medication
		{
			return _medication;
		}

		public function set medication(value:Medication):void
		{
			_medication = value;
		}

		public function get user():User
		{
			return _user;
		}

		public function set user(value:User):void
		{
			_user = value;
		}

		public function get userLabel():spark.components.Label
		{
			return _userLabel;
		}

		public function set userLabel(value:spark.components.Label):void
		{
			_userLabel = value;
		}

		public function get registeredIcon():BitmapImage
		{
			return _registeredIcon;
		}

		public function set registeredIcon(value:BitmapImage):void
		{
			_registeredIcon = value;
		}

		public function get userInfoContainer():SkinnableContainer
		{
			return _userInfoContainer;
		}

		public function set userInfoContainer(value:SkinnableContainer):void
		{
			_userInfoContainer = value;
		}

		public function get mainContainer():SkinnableContainer
		{
			return _mainContainer;
		}

		public function set mainContainer(value:SkinnableContainer):void
		{
			_mainContainer = value;
		}
	}
}
