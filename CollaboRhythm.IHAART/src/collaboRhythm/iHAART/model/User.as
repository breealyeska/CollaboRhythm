/**
 * Copyright 2014 Bree Alyeska
 *
 * This file is part of iHAART & CollaboRhythm.
 *
 * iHAART and CollaboRhythm are free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later  version.
 *
 * iHAART and CollaboRhythm are distributed in the hope that they will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with iHAART & CollaboRhythm. If not, see
 * <http://www.gnu.org/licenses/>.
 */

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
