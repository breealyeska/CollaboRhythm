package collaboRhythm.shared.model.medications
{
	import flash.display.Graphics;
	import flash.geom.Rectangle;

	import mx.charts.ChartItem;
	import mx.charts.chartClasses.GraphicsUtilities;
	import mx.charts.renderers.CircleItemRenderer;
	import mx.charts.series.items.PlotSeriesItem;
	import mx.graphics.IFill;
	import mx.graphics.IStroke;
	import mx.graphics.SolidColor;
	import mx.utils.ColorUtil;

	public class VitalSignForDecisionItemRenderer extends CircleItemRenderer
	{
		private static var rcFill:Rectangle = new Rectangle();

		public function VitalSignForDecisionItemRenderer()
		{
			super();
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var plotSeriesItem:PlotSeriesItem = data as PlotSeriesItem;
			var proxy:VitalSignForDecisionProxy = (plotSeriesItem).item as VitalSignForDecisionProxy;

			super.updateDisplayList(unscaledWidth, unscaledHeight);
			var fill:IFill;
			var state:String = "";
			
			if (data is ChartItem && data.hasOwnProperty('fill'))
			{
			 	fill = data.fill;
			 	state = data.currentState;
			}
			else
			 	fill = GraphicsUtilities.fillFromStyle(getStyle('fill'));
			 
	        
	        var color:uint;
			var adjustedRadius:Number = 0;
			
			switch (state)
			{
				case ChartItem.FOCUSED:
				case ChartItem.ROLLOVER:
					if (styleManager.isValidStyleValue(getStyle('itemRollOverColor')))
						color = getStyle('itemRollOverColor');
					else
						color = ColorUtil.adjustBrightness2(GraphicsUtilities.colorFromFill(fill),-20);
					fill = new SolidColor(color);
					adjustedRadius = getStyle('adjustedRadius');
					if (!adjustedRadius)
						adjustedRadius = 0;
					break;
				case ChartItem.DISABLED:
					if (styleManager.isValidStyleValue(getStyle('itemDisabledColor')))
						color = getStyle('itemDisabledColor');
					else
						color = ColorUtil.adjustBrightness2(GraphicsUtilities.colorFromFill(fill),20);
					fill = new SolidColor(GraphicsUtilities.colorFromFill(color));
					break;
				case ChartItem.FOCUSEDSELECTED:
				case ChartItem.SELECTED:
					if (styleManager.isValidStyleValue(getStyle('itemSelectionColor')))
						color = getStyle('itemSelectionColor');
					else
						color = ColorUtil.adjustBrightness2(GraphicsUtilities.colorFromFill(fill),-30);
					fill = new SolidColor(color);
					adjustedRadius = getStyle('adjustedRadius');
					if (!adjustedRadius)
						adjustedRadius = 0;
					break;
			}
			  
			var stroke:IStroke = getStyle("stroke");
					
			var w:Number = stroke ? stroke.weight / 2 : 0;
	
			rcFill.right = unscaledWidth;
			rcFill.bottom = unscaledHeight;

			if (proxy && proxy.isEligible)
			{
				adjustedRadius += 2;
				fill = new SolidColor(0xF7941E);
			}

			var g:Graphics = graphics;
			g.clear();		
			if (stroke)
				stroke.apply(g,null,null);
			if (fill)
				fill.begin(g, rcFill, null);

			var shape:String = getStyle("shape");
			if (shape == TitrationSupportChartModifierBase.WEDGE_SHAPE)
			{
                // center
                var cx:Number = unscaledWidth / 2;
                var cy:Number = unscaledHeight / 2;

				var directionScale:Number = -1;

				var deltaY:Number = 16 * directionScale;
				var deltaX:Number = 10;

                // left top corner
                g.moveTo(cx - deltaX, cy + deltaY);

                // center
                g.lineTo(cx, cy);

                // right top corner
                g.lineTo(cx + deltaX, cy + deltaY);
			}
			else
			{
				g.drawEllipse(w - adjustedRadius, w - adjustedRadius, unscaledWidth - 2 * w + adjustedRadius * 2,
						unscaledHeight - 2 * w + adjustedRadius * 2);
			}
	
			if (fill)
				fill.end(g);
		}
	}
}
