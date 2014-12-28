package collaboRhythm.iHAART.model
{
	import spark.skins.spark.PanelSkin;

	public class HeaderlessPanel extends PanelSkin
	{
		public function HeaderlessPanel()
		{
			super();

			topGroup.includeInLayout = false;
			border.includeInLayout = false;
		}
	}
}
