package collaboRhythm.tablet.view.skins
{
	import spark.skins.spark.PanelSkin;

	public class HeaderlessPanelSkin extends PanelSkin
	{
		public function HeaderlessPanelSkin()
		{
			super();

			topGroup.includeInLayout = false;
			border.includeInLayout = false;
		}
	}
}
