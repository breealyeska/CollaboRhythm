package collaboRhythm.plugins.schedule.shared.model
{
	import collaboRhythm.shared.model.Account;
	import collaboRhythm.shared.model.healthRecord.document.ScheduleItemOccurrence;
	import collaboRhythm.shared.model.services.IComponentContainer;

	import mx.collections.ArrayCollection;

	import spark.components.ViewNavigator;

	public class MasterHealthActionCreationControllerFactory
	{
		private var _factoryArray:Array;

		public function MasterHealthActionCreationControllerFactory(componentContainer:IComponentContainer)
		{
			_factoryArray = componentContainer.resolveAll(IHealthActionCreationControllerFactory);
		}

		public function createHealthActionCreationControllers(activeAccount:Account, activeRecordAccount:Account,
															  viewNavigator:ViewNavigator):ArrayCollection
		{
			var healthActionCreationControllers:ArrayCollection = new ArrayCollection();
			for each (var healthActionCreationControllerFactory:IHealthActionCreationControllerFactory in _factoryArray)
			{
				var healthActionCreationController:IHealthActionCreationController = healthActionCreationControllerFactory.createHealthActionCreationController(activeAccount,
						activeRecordAccount, viewNavigator);
				healthActionCreationControllers.addItem(healthActionCreationController);
			}

			return healthActionCreationControllers;
		}

		public function createHealthActionCreationControllerFromScheduleItemOccurrence(activeAccount:Account,
																					   activeRecordAccount:Account,
																					   scheduleItemOccurrence:ScheduleItemOccurrence,
																					   viewNavigator:ViewNavigator):IHealthActionCreationController
		{
			var currentHealthActionCreationController:IHealthActionCreationController = null;
			for each (var healthActionCreationControllerFactory:IHealthActionCreationControllerFactory in _factoryArray)
			{
				var healthActionCreationController:IHealthActionCreationController = healthActionCreationControllerFactory.createHealthActionCreationControllerFromScheduleItemOccurrence(activeAccount,
						activeRecordAccount, scheduleItemOccurrence, viewNavigator);
			}
			if (healthActionCreationController)
				currentHealthActionCreationController = healthActionCreationController;

			return currentHealthActionCreationController;
		}
	}
}
