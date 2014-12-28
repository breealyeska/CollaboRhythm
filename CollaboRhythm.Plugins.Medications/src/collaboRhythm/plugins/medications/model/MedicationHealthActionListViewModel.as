package collaboRhythm.plugins.medications.model
{
	import collaboRhythm.plugins.schedule.shared.model.HealthActionListViewModelBase;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionModelDetailsProvider;
	import collaboRhythm.shared.model.healthRecord.DocumentBase;
	import collaboRhythm.shared.model.healthRecord.document.MedicationAdministration;
	import collaboRhythm.shared.model.healthRecord.document.MedicationOrder;
	import collaboRhythm.shared.model.healthRecord.document.MedicationScheduleItem;
	import collaboRhythm.shared.model.healthRecord.document.ScheduleItemOccurrence;
	import collaboRhythm.shared.model.services.ICurrentDateSource;
	import collaboRhythm.shared.model.services.WorkstationKernel;
	import collaboRhythm.iHAART.cloudMessaging.controller.CloudMessagingController;
	import collaboRhythm.iHAART.sqlStore.controller.SQLStoreController;
	import collaboRhythm.shared.model.settings.Settings;

	public class MedicationHealthActionListViewModel extends HealthActionListViewModelBase
	{
		private var _medicationScheduleItem:MedicationScheduleItem;
		private var _medicationOrder:MedicationOrder;

		private var _currentDateSource:ICurrentDateSource;

		public function MedicationHealthActionListViewModel(scheduleItemOccurrence:ScheduleItemOccurrence,
															healthActionModelDetailsProvider:IHealthActionModelDetailsProvider,
															medicationOrder:MedicationOrder = null)
		{
			super(scheduleItemOccurrence, healthActionModelDetailsProvider);

			if (scheduleItemOccurrence)
			{
				_medicationScheduleItem = scheduleItemOccurrence.scheduleItem as MedicationScheduleItem;
				_medicationOrder = _medicationScheduleItem.scheduledMedicationOrder;
				
				var settings:Settings = WorkstationKernel.instance.resolve(Settings) as Settings;
				var sqlStore = new SQLStoreController();
				var userData:Object = new Object();
				userData['registration_id'] = CloudMessagingController.NO_IND_REGID;
				userData['account_string'] = settings.gcmAccount.toString();
				var insertedRowID:Number = sqlStore.insertData(SQLStoreController.USERS_TABLE, userData);

				var medData:Object = new Object();
				medData['user_id'] = insertedRowID;
				medData['med_name_dose_route'] = _medicationOrder.name.text;
				medData['med_start_time'] = scheduleItemOccurrence.dateStart;
				medData['med_end_time'] = scheduleItemOccurrence.dateEnd;
				medData['med_instructions'] = _medicationOrder.instructions;
				sqlStore.insertData(SQLStoreController.MEDICATIONS_TABLE, medData);
			}
			else
			{
				_medicationOrder = medicationOrder;
			}

			_currentDateSource = WorkstationKernel.instance.resolve(ICurrentDateSource) as ICurrentDateSource;
		}

		override public function createHealthActionResult(persist:Boolean):void
		{
			if (_medicationScheduleItem)
			{
				var medicationAdministration:MedicationAdministration = new MedicationAdministration();
				medicationAdministration.init(_medicationOrder ? _medicationOrder.name : _medicationScheduleItem.name, healthActionInputModelDetailsProvider.accountId,
						_currentDateSource.now(), _currentDateSource.now(),
						_medicationScheduleItem.dose);

				var adherenceResults:Vector.<DocumentBase> = new Vector.<DocumentBase>();
				adherenceResults.push(medicationAdministration);
				scheduleItemOccurrence.createAdherenceItem(adherenceResults,
						healthActionInputModelDetailsProvider.record, healthActionInputModelDetailsProvider.accountId,
						persist);
			}
		}
	}
}
