package collaboRhythm.plugins.medications.model
{
	import collaboRhythm.iHAART.controller.IHAARTEventDispatcher;
	import collaboRhythm.iHAART.model.events.IHAARTEvent;
	import collaboRhythm.plugins.medications.view.MedicationImage;
	import collaboRhythm.plugins.schedule.shared.controller.HealthActionListViewControllerBase;
	import collaboRhythm.plugins.schedule.shared.model.HealthActionBase;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionListViewAdapter;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionListViewController;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionListViewModel;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionModelDetailsProvider;
	import collaboRhythm.plugins.schedule.shared.model.MedicationHealthAction;
	import collaboRhythm.shared.model.healthRecord.document.MedicationFillsModel;
	import collaboRhythm.shared.model.healthRecord.document.MedicationOrder;
	import collaboRhythm.shared.model.healthRecord.document.MedicationScheduleItem;
	import collaboRhythm.shared.model.healthRecord.document.ScheduleItemOccurrence;
	import collaboRhythm.shared.model.healthRecord.util.MedicationName;
	import collaboRhythm.shared.model.healthRecord.util.MedicationNameUtil;
	import collaboRhythm.shared.model.services.IImageCacheService;
	import collaboRhythm.shared.model.services.IMedicationColorSource;
	import collaboRhythm.shared.model.services.WorkstationKernel;
	import collaboRhythm.shared.model.settings.Settings;

	import mx.core.IVisualElement;

	import spark.components.Button;

	import spark.components.Image;

	public class MedicationHealthActionListViewAdapter implements IHealthActionListViewAdapter
	{
		private var _medicationScheduleItem:MedicationScheduleItem;
		private var _medicationOrder:MedicationOrder;
		private var _medicationName:MedicationName;
		private var _medicationColorSource:IMedicationColorSource;
		private var _medicationHealthAction:MedicationHealthAction;

		private var _model:MedicationHealthActionListViewModel;
		private var _controller:HealthActionListViewControllerBase;
		private var _instructionalVideo:String = "";

		private var _imageCacheService:IImageCacheService;
		private var _medicationCode:String;

		private var _settings:Settings;

		public function MedicationHealthActionListViewAdapter(scheduleItemOccurrence:ScheduleItemOccurrence,
															  healthActionModelDetailsProvider:IHealthActionModelDetailsProvider,
															  medicationOrder:MedicationOrder = null)
		{
			if (scheduleItemOccurrence)
			{
				_medicationScheduleItem = scheduleItemOccurrence.scheduleItem as MedicationScheduleItem;
				_medicationOrder = _medicationScheduleItem.scheduledMedicationOrder;
			}
			else if (medicationOrder)
			{
				_medicationOrder = medicationOrder;
			}

			if (_medicationOrder)
			{
				_medicationName = MedicationNameUtil.parseName(_medicationOrder.name.text);
				_medicationCode = _medicationOrder.name.value;
			}
			else if (_medicationScheduleItem)
			{
				_medicationName = MedicationNameUtil.parseName(_medicationScheduleItem.name.text);
				_medicationCode = _medicationScheduleItem.name.value;
			}

			_medicationColorSource = WorkstationKernel.instance.resolve(IMedicationColorSource) as IMedicationColorSource;

			_medicationHealthAction = new MedicationHealthAction(_medicationName.rawName, _medicationCode);

			_model = new MedicationHealthActionListViewModel(scheduleItemOccurrence, healthActionModelDetailsProvider, _medicationOrder);


			_imageCacheService = WorkstationKernel.instance.resolve(IImageCacheService) as IImageCacheService;
		}

		public function get healthAction():HealthActionBase
		{
			return _medicationHealthAction;
		}

		public function createImage():Image
		{
			var medicationImage:MedicationImage = new MedicationImage();
			if (_medicationOrder && _medicationOrder.medicationFill)
			{
				medicationImage.setStyle("loadingImageColor",
										 _medicationColorSource.getMedicationColor(_medicationOrder.medicationFill.ndc.text));
				medicationImage.source = _imageCacheService.getImage(medicationImage, MedicationFillsModel.MEDICATION_API_URL_BASE + _medicationOrder.medicationFill.ndc.text + "-front.png");
				if (settings.iHAARTOnly)
				{
					var dispatcher:IHAARTEventDispatcher = new IHAARTEventDispatcher();
					dispatcher.dispatchEvent(new IHAARTEvent(IHAARTEvent.MEDICATION_IMAGE_LOADED,
							medicationImage.source.toString(),
							null,
							false,
							false));
				}
			}
			return medicationImage;
		}

		public function get name():String
		{
			if (_medicationName.proprietaryName)
				return _medicationName.medicationName + " " + _medicationName.proprietaryName;
			else
				return _medicationName.medicationName;
		}

		public function get description():String
		{
			return _medicationName.strength + " " + _medicationName.form;
		}

		public function get indication():String
		{
			if (_medicationOrder)
				return _medicationOrder.indication;
			else
				return "";
		}

		public function get primaryInstructions():String
		{
			if (_medicationScheduleItem)
			{
				//TODO: Use the actual route from Indivo once it is modeled in the data
				var route:String = "";
				//TODO: Implement the totalDoseString so that it works with combination medications
				var totalDoseString:String = "";
				switch (_medicationName.form)
				{
					case "Oral Tablet":
						route = "by mouth";
//						var totalDose:Number = parseFloat(_medicationScheduleItem.dose.value) * parseFloat(_medicationName.strength);
						//TODO: Parse the dose value and the dose unit as separate strings from the _medicationName because the dose unit may not always be MG
//						totalDoseString = " (" + totalDose.toString() + " MG total dose)";
						break;
					case "Oral Capsule":
						route = "by mouth";
						break;
					case "Enteric Coated Capsule":
						route = "by mouth";
						break;
					case "Prefilled Syringe":
						route = "subcutaneous injection";
						break;
				}

				var plural:String = "";
				if (int(_medicationScheduleItem.dose.value) > 1)
				{
					plural = "s";
				}
				return _medicationScheduleItem.dose.value + " " + _medicationScheduleItem.dose.unit.text + plural + " " + route + totalDoseString;
			}
			else
				return "";
		}

		public function get secondaryInstructions():String
		{
			if (_medicationScheduleItem && _medicationScheduleItem.instructions)
				return _medicationScheduleItem.instructions;
			else if (_medicationOrder)
				return _medicationOrder.instructions;
			else
				return "";
		}

		public function get instructionalVideoPath():String
		{
			return _instructionalVideo;
		}

		public function set instructionalVideoPath(value:String):void
		{
			_instructionalVideo = value;
		}

		public function get additionalAdherenceInformation():String
		{
			return "";
		}

		public function get model():IHealthActionListViewModel
		{
			return _model;
		}

		public function get controller():IHealthActionListViewController
		{
			if (!_controller)
			{
				_controller = new HealthActionListViewControllerBase(_model);
			}
			return _controller;
		}

		public function createCustomView():IVisualElement
		{
			return null;
		}

		public function createCommandButtons():Vector.<Button>
		{
			return null;
		}

		public function get settings():Settings
		{
			if (!_settings)
			{
				_settings = WorkstationKernel.instance.resolve(Settings) as Settings;
			}
			return _settings;
		}
	}
}
