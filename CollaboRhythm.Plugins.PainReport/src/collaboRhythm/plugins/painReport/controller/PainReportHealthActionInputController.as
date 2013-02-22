package collaboRhythm.plugins.painReport.controller
{
	import collaboRhythm.plugins.painReport.model.PainReportHealthActionInputModel;
	import collaboRhythm.plugins.painReport.view.PainReportHealthActionInputView;
	import collaboRhythm.plugins.schedule.shared.controller.HealthActionInputControllerBase;
	import collaboRhythm.plugins.schedule.shared.model.HealthActionInputModelAndController;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionInputController;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionModelDetailsProvider;
	import collaboRhythm.shared.model.healthRecord.document.ScheduleItemOccurrence;

	import flash.events.MouseEvent;
	import flash.net.URLVariables;

	import spark.components.ViewNavigator;
	import spark.transitions.SlideViewTransition;

	public class PainReportHealthActionInputController extends HealthActionInputControllerBase implements IHealthActionInputController
	{
		private const HEALTH_ACTION_INPUT_VIEW_CLASS:Class = PainReportHealthActionInputView;

		private var _dataInputModel:PainReportHealthActionInputModel;
		private var _viewNavigator:ViewNavigator;

		public function PainReportHealthActionInputController(scheduleItemOccurrence:ScheduleItemOccurrence,
															  healthActionModelDetailsProvider:IHealthActionModelDetailsProvider, viewNavigator:ViewNavigator)
		{
			_dataInputModel = new PainReportHealthActionInputModel(scheduleItemOccurrence, healthActionModelDetailsProvider);
			_viewNavigator = viewNavigator;
		}

		public function handleHealthActionResult(initiatedLocally:Boolean):void
		{
			var dataInputModelAndController:HealthActionInputModelAndController = new HealthActionInputModelAndController(_dataInputModel,
					this);

			_viewNavigator.pushView(HEALTH_ACTION_INPUT_VIEW_CLASS, dataInputModelAndController, null,
					new SlideViewTransition());
		}

		public function handleHealthActionSelected():void
		{
		}

		public function handleUrlVariables(urlVariables:URLVariables):void
		{

		}

		public function get healthActionInputViewClass():Class
		{
			return HEALTH_ACTION_INPUT_VIEW_CLASS;
		}

		public function useDefaultHandleHealthActionResult():Boolean
		{
			return false;
		}

		public function updateDateMeasuredStart(date:Date):void
		{
		}

		public function handleHealthActionCommandButtonClick(event:MouseEvent):void
		{
		}
	}
}
