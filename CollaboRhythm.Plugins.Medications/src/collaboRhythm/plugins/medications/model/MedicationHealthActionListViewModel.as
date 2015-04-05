package collaboRhythm.plugins.medications.model
{
	import collaboRhythm.iHAART.controller.IHAARTEventDispatcher;
	import collaboRhythm.iHAART.model.Medication;
	import collaboRhythm.iHAART.model.events.IHAARTEvent;
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

	import mx.core.FlexGlobals;

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

				if (settings.iHAARTOnly)
				{
					var medData:Object = {};
					medData['name'] = _medicationOrder.name.text;
					medData['dose_amount'] = _medicationScheduleItem.dose.value;
					medData['dose_unit'] = _medicationScheduleItem.dose.unit.text;
					medData['indication'] = _medicationOrder.indication;
					medData['instructions'] = _medicationScheduleItem.instructions;
					medData['start_time'] = _medicationScheduleItem.dateStart;
					medData['end_time'] = _medicationScheduleItem.dateEnd;
					medData['name_abbrev_attr'] = _medicationScheduleItem.name.abbrev;
					medData['name_type_attr'] = _medicationScheduleItem.name.type;
					medData['name_value_attr'] = _medicationScheduleItem.name.value;
					medData['scheduled_by'] = _medicationScheduleItem.scheduledBy;
					medData['recurrence_frequency'] = _medicationScheduleItem.recurrenceRule.frequency;
					medData['recurrence_interval'] = _medicationScheduleItem.recurrenceRule.interval;
					medData['recurrence_count'] = _medicationScheduleItem.recurrenceRule.count;
					medData['dose_value'] = _medicationScheduleItem.dose.value;
					medData['dose_unit_text'] = _medicationScheduleItem.dose.unit.text;
					medData['dose_unit_type_attr'] = _medicationScheduleItem.dose.unit.type;
					medData['dose_unit_value_attr'] = _medicationScheduleItem.dose.unit.value;
					medData['dose_unit_abbrev_attr'] = _medicationScheduleItem.dose.unit.abbrev;
					medData['xml_string'] = _medicationScheduleItem.convertToXML().toString();

					var dispatcher:IHAARTEventDispatcher = new IHAARTEventDispatcher();
					dispatcher.dispatchEvent(new IHAARTEvent(IHAARTEvent.SCHEDULE_LOADED,
							settings.gcmAccount,
							medData,
							false,
							false));
				}
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
