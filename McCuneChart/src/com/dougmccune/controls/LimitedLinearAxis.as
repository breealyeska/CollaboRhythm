package com.dougmccune.controls
{
	import mx.charts.LinearAxis;

	public class LimitedLinearAxis extends LinearAxis
	{
		private var _maximumLimit:Number;
		private var _minimumLimit:Number;

		public function LimitedLinearAxis()
		{
		}

		override protected function adjustMinMax(minValue:Number, maxValue:Number):void
		{
			super.adjustMinMax(minValue, maxValue);
			
			if (!isNaN(maximumLimit))
				computedMaximum = Math.max(maximumLimit, computedMaximum);

			if (!isNaN(minimumLimit))
				computedMinimum = Math.min(minimumLimit, computedMinimum);
		}

		public function get maximumLimit():Number
		{
			return _maximumLimit;
		}

		public function set maximumLimit(value:Number):void
		{
			_maximumLimit = value;
		}

		public function get minimumLimit():Number
		{
			return _minimumLimit;
		}

		public function set minimumLimit(value:Number):void
		{
			_minimumLimit = value;
		}
	}
}
