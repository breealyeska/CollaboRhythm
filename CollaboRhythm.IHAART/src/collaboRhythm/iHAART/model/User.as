package collaboRhythm.iHAART.model
{
	[Bindable]
	public class User
	{

		private var _givenName:String;
		private var _familyName:String;
		private var _gcmAccount:String;
		private var _fullName:String;

		public function User()
		{
		}

		public function initialize(given:String, family:String, account:String):void
		{
			this.givenName = given;
			this.familyName = family;
			this.gcmAccount = account;
		}

		public function get givenName():String
		{
			return _givenName;
		}

		public function set givenName(value:String):void
		{
			_givenName = value;
		}

		public function get familyName():String
		{
			return _familyName;
		}

		public function set familyName(value:String):void
		{
			_familyName = value;
		}

		public function get gcmAccount():String
		{
			return _gcmAccount;
		}

		public function set gcmAccount(value:String):void
		{
			_gcmAccount = value;
		}

		public function get fullName():String
		{
			return givenName + " " + familyName;
		}
	}
}
