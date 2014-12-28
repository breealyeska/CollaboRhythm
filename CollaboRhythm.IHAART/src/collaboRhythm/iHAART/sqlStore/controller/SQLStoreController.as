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

package collaboRhythm.iHAART.sqlStore.controller
{
	import collaboRhythm.iHAART.cloudMessaging.controller.CloudMessagingController;

	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLStatement;
	import flash.data.SQLTableSchema;
	import flash.errors.SQLError;
	import flash.filesystem.File;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;


	import flash.globalization.DateTimeFormatter;
	import flash.globalization.DateTimeStyle;
	import flash.utils.getQualifiedClassName;

	import mx.logging.ILogger;
	import mx.logging.Log;

// todo bree need to encryptdb
// todo bree need to make store and read functions more generic
// todo bree needtocreate adherence data table along with user_settings

	public class SQLStoreController
	{
		public static var IHAART_DB_FILE = "iHAART.db";
		public static var SETTINGS_TABLE = "user_settings";
		public static var USERS_TABLE = "users";
		public static var ADHERENCE_TABLE = "user_adherence";
		public static var NOTIFICATIONS_TABLE = "notifications";
		public static var MEDICATIONS_TABLE = "medications";

		protected var _sqlConnectionSync:SQLConnection;
		private var _sqlResult:SQLResult;
		private var _sqlError:SQLError;
		private var _dbFile:File;

		private var _logger:ILogger;

		public function SQLStoreController()
		{

			//create the database file in the application storage folder
			var dbFilePath:String = File.applicationStorageDirectory.resolvePath(IHAART_DB_FILE).nativePath;
			dbFilePath = dbFilePath.replace("/data/data", "/storage/sdcard0");
			dbFile = new File(dbFilePath);

			if (dbFile.exists)
			{
				if (tableExists(USERS_TABLE) && tableExists(ADHERENCE_TABLE) && tableExists(MEDICATIONS_TABLE))
				{
					return;
				}
			}

			initialize();

//			todo bree if want to make asynchronous then use event listeners
// 			register listeners for the result and error events
//			selectStmt.addEventListener(SQLEvent.RESULT, selectResult);
//			selectStmt.addEventListener(SQLErrorEvent.ERROR, selectError);

		}

		private function initialize()
		{
			logger.info("Initializing sqlStoreController...");

			var create:SQLStatement = new SQLStatement();

			if (!tableExists(USERS_TABLE))
			{
				create.text = "CREATE TABLE " + USERS_TABLE + " (id INTEGER PRIMARY KEY AUTOINCREMENT, 'account_string' TEXT, 'registration_id' TEXT)";

				create.sqlConnection = sqlConnectionSync;
				try
				{
					create.execute();
				}
				catch (error:SQLError)
				{
					logger.info("    SQLError in SQLStoreController.initialize(USERS_TABLE): " +
					error.message +
					" ---- " +
					error.details);
				}
				logger.info("  Table " + USERS_TABLE + " created: " + create.text);
			}

			if (!tableExists(MEDICATIONS_TABLE))
			{
				create.text = "CREATE TABLE " + MEDICATIONS_TABLE + " (id INTEGER PRIMARY KEY AUTOINCREMENT, 'user_id' INTEGER, 'med_name_dose_route' TEXT, 'med_start_time' TEXT, 'med_end_time' TEXT, 'med_instructions' TEXT)";

				create.sqlConnection = sqlConnectionSync;
				try
				{
					create.execute();
				}
				catch (error:SQLError)
				{
					logger.info("    SQLError in SQLStoreController.initialize(MEDICATIONS_TABLE): " +
					error.message +
					" ---- " +
					error.details);
				}
				logger.info("  Table " + MEDICATIONS_TABLE + " created: " + create.text);
			}

			if (!tableExists(ADHERENCE_TABLE))
			{
				// DateTime format in SQLLite is ("YYYY-MM-DD HH:MM:SS.SSS")
				create.text = "CREATE TABLE " +
				ADHERENCE_TABLE +
				" (id INTEGER PRIMARY KEY AUTOINCREMENT, 'user_id' INTEGER, 'med_id' INTEGER, 'time_reported' TEXT)";

				create.sqlConnection = sqlConnectionSync;
				try
				{
					create.execute();
				}
				catch (error:SQLError)
				{
					logger.info("    SQLError in SQLStoreController.initialize(ADHERENCE_TABLE): " +
					error.message +
					" ---- " +
					error.details);
				}
				logger.info("  Table " + ADHERENCE_TABLE + " created: " + create.text);
			}

			if (!tableExists(NOTIFICATIONS_TABLE))
			{
				// DateTime format in SQLLite is ("YYYY-MM-DD HH:MM:SS.SSS")
				create.text = "CREATE TABLE " + NOTIFICATIONS_TABLE + " (id INTEGER PRIMARY KEY AUTOINCREMENT, 'factoid_id' INT, 'time_sent' TEXT, 'time_received' TEXT)";

				create.sqlConnection = sqlConnectionSync;
				try
				{
					create.execute();
				}
				catch (error:SQLError)
				{
					logger.info("    SQLError in SQLStoreController.initialize(NOTIFICATIONS_TABLE): " +
					error.message +
					" ---- " +
					error.details);
				}
				logger.info("  Table " + NOTIFICATIONS_TABLE + " created: " + create.text);
			}
		}

//		public function saveRegistrationID(registrationID:String):Boolean
//		{
////			clearTableData(USERS_TABLE);
//			sqlResult = writeData("user_settings", "registration_id", registrationID.toString());
//			logger.info("  GCM Registration ID saved: " + "  " + registrationID);
//			return true;
//		}

//		public function getLocalRegistrationID():String
//		{
//			try
//			{
//				var select:SQLStatement = new SQLStatement();
//				select.sqlConnection = sqlConnectionSync;
//				select.text = "SELECT registration_id FROM gcm_settings ORDER BY id";
//				select.execute();
//			}
//			catch (error:SQLError)
//			{
//				logger.info("    SQLError in SQLStoreController.getLocalRegistrationID(): " +
//						error.message +
//						" ---- " +
//						error.details);
//			}
//
//			var output:String;
//			try {
//				sqlResult = select.getResult();
//
//				if (sqlResult.data)
//				{
//					logger.info("  Getting GCM registrationID from store: " + sqlResult.data[0]["registration_id"]);
////					for (var columnName:String in sqlResult.data[0])
////					{
////						output += columnName + ": " + sqlResult.data[0][columnName] + "; ";
////					}
//					return sqlResult.data[0]["registration_id"];
//				}
//				else
//				{
//					logger.info("No GCM registrationID found in store");
//					return GCMPushInterface.NO_REGID;
//				}
//			}
//			catch (error:SQLError)
//			{
//				logger.info("    SQLError in SQLStoreController.getLocalRegistrationID(): " +
//						error.message +
//						" ---- " +
//						error.details);
//			}
//			return GCMPushInterface.NO_REGID;
//		}

		public function clearTableData(tableName:String):void
		{
			var select:SQLStatement = new SQLStatement();
			select.sqlConnection = sqlConnectionSync;
			select.text = "DELETE FROM '" + tableName + "'";
			try
			{
				select.execute();
			}
			catch (error:SQLError)
			{
				logger.info("    SQLError in SQLStoreController.clearTableData(" + tableName + "): " +
				error.message +
				" ---- " +
				error.details);
			}
			logger.info("  Table " + tableName + " deleted");
		}


		private function getFieldValue(tableName:String, parameterColumn:String, parameterValue:String, fieldColumn:String):String
		{
			var queryString:String = "SELECT " + fieldColumn + " FROM " + tableName + " WHERE " + parameterColumn + " = '" + parameterValue + "'";
			var select:SQLStatement = new SQLStatement();

			select.text = queryString;

			try
			{
				select.sqlConnection = sqlConnectionSync;
				select.execute();
			}
			catch (error:SQLError)
			{
				logger.info("    SQLError in SQLStoreController.getField(): " +
				error.message +
				" ---- " +
				error.details);
			}

			var result = select.getResult();
			if (result.data.length > 0) {
				return result.data[0][fieldColumn];
			}
			else {
				return "";
			}
		}
		
//		private function writeData(tableName:String, parameter:String, value:String):SQLResult
//		{
//			try
//			{
//				var query:String = "INSERT INTO " + tableName + " ('" + parameter + "') VALUES (?)";
//				var insert:SQLStatement = new SQLStatement(); //create the insert statement
//				insert.sqlConnection = sqlConnectionSync; //set the connection
//				insert.text = query;
//				insert.parameters[0] = value;
//				insert.execute();
//			}
//			catch (error:SQLError)
//			{
//				logger.info("    SQLError in SQLStoreController.writeData(): " +
//						error.message +
//						" ---- " +
//						error.details);
//			}
//
//			logger.info("  Insert into SQL Store query:  " + insert.text);
//			return insert.getResult();
//		}

		public function updateData(tableName:String, whereColumn:String, whereValue:String, dataObject:Object):Number
		{
			var colNamesStr:String = "";
			var colValuesStr:String = "";
			try
			{
				var update:SQLStatement = new SQLStatement(); //create the insert statement

				var i:int = 0;

				var queryString:String = "UPDATE " + tableName + " SET ";

				for (var key:String in dataObject)
				{
					update.parameters[i] = dataObject[key].toString();
					queryString = queryString + key + " = ?, ";
					i++;
				}

				queryString = queryString.slice(0, -2);
				queryString = queryString + " WHERE " + whereColumn + " = " + whereValue;

				update.sqlConnection = sqlConnectionSync; //set the connection
				update.text = queryString;
				update.execute();
			}
			catch (error:SQLError)
			{
				logger.info("    SQLError in SQLStoreController.writeData(): " +
				error.message +
				" ---- " +
				error.details);
			}

			logger.info("  Update SQL Store query:  " + update.text);

			// get the primary key
			var result:SQLResult = update.getResult();
			return result.rowsAffected;
			// do something with the primary key
			//return update.getResult();
		}
		
		public function insertData(tableName:String, queryData:Object):Number
		{
			var colNamesStr:String = "";
			var colValuesStr:String = "";
			try
			{
				var insert:SQLStatement = new SQLStatement(); //create the insert statement

				var i:int = 0;

				for (var key:String in queryData)
				{
					insert.parameters[i] = queryData[key].toString();
					colNamesStr = colNamesStr + "'" + key + "', ";
					colValuesStr = colValuesStr + "?, ";
					i++;
				}

				colNamesStr = colNamesStr.slice(0, -2);
				colValuesStr = colValuesStr.slice(0, -2);

				var queryString:String = "INSERT INTO " + tableName + " ( " + colNamesStr + " ) VALUES ( " + colValuesStr + " )";

				insert.sqlConnection = sqlConnectionSync; //set the connection
				insert.text = queryString;
				insert.execute();
			}
			catch (error:SQLError)
			{
				logger.info("    SQLError in SQLStoreController.writeData(): " +
				error.message +
				" ---- " +
				error.details);
			}

			logger.info("  Insert into SQL Store query:  " + insert.text);

			// get the primary key
			var result:SQLResult = insert.getResult();
			return result.lastInsertRowID;
			// do something with the primary key
			//return insert.getResult();
		}

		public function newAdherenceEvent(accountString:String):void
		{
			var insert:SQLStatement = new SQLStatement();
			var userID:String = "";
			var medID:String = "";
			var now:Date = new Date();

			var dateFormatter:DateTimeFormatter = new DateTimeFormatter(flash.globalization.LocaleID.DEFAULT);
//			var timeFormatter:DateTimeFormatter = new DateTimeFormatter();
			var pattern:String = "yyyy-MM-dd HH:mm:ss.SSS";
			dateFormatter.setDateTimePattern(pattern);
			var formattedDate:String = dateFormatter.format(now);
			userID = getFieldValue(SQLStoreController.USERS_TABLE, "account_string", accountString, "id");
			medID = getFieldValue(SQLStoreController.MEDICATIONS_TABLE, "user_id", userID, "id");

			var adherenceData:Object = new Object();
			adherenceData['user_id'] = userID;
			adherenceData['med_id'] = medID;
			adherenceData['time_reported'] = formattedDate;
			
			var newID:Number = insertData(SQLStoreController.ADHERENCE_TABLE, adherenceData);
			trace("    bree newID = ", newID);
		}

		public function getMedDataForAccount(accountString:String):SQLResult
		{

			var select:SQLStatement = new SQLStatement();
			var userID:String = "";

			userID = getFieldValue(SQLStoreController.USERS_TABLE, "account_string", accountString, "id");

			if (userID.length > 0) {
				var queryString:String = "select * from " +
						SQLStoreController.MEDICATIONS_TABLE +
						" WHERE user_id = " +
						userID;

				select.sqlConnection = sqlConnectionSync; //set the connection
				select.text = queryString;

				try
				{
					select.execute();
				}
				catch (error:SQLError)
				{
					logger.info("    SQLError in SQLStoreController.getAccountData(): " +
					error.message +
					" ---- " +
					error.details);
				}
			}

			logger.info("  Select from SQL Store query:  " + select.text);

			return select.getResult();
		}

//		private function readData():SQLResult
//		{
//			var read:SQLStatement = new SQLStatement(); //create the read statemen
//			read.sqlConnection = sqlConnectionSync; //set the connection
////				todo bree this should be dynamic
//			read.text = "SELECT id, registration_id FROM gcm_settings ORDER BY id";
//			try
//			{
//				read.execute();
//			}
//			catch (error:SQLError)
//			{
//				logger.info("    SQLError in SQLStoreController.readData(): " +
//						error.message +
//						" ---- " +
//						error.details);
//			}
//			return read.getResult();
//		}

		private function tableExists(tableName:String):Boolean
		{
			try
			{
				sqlConnectionSync.loadSchema();
				var schema:SQLSchemaResult = sqlConnectionSync.getSchemaResult();

				if (schema.tables)
				{
					for each (var table:SQLTableSchema in schema.tables)
					{
						if (table.name.toLowerCase() == tableName.toLowerCase())
						{
							logger.info("  Table " + tableName + " exists");
							return true;
						}
					}
				}
			}
			catch (error:SQLError)
			{
				logger.info("    SQLError in SQLStoreController.tableExists(): " +
						error.message +
						" ---- " +
						error.details);
			}

			logger.info("  Table " + tableName + " does not exist");
			return false;

		}

		public function get sqlConnectionSync():SQLConnection
		{
			var dbFilePath:String = File.applicationStorageDirectory.resolvePath("iHAART.db").nativePath;
			dbFilePath = dbFilePath.replace("/data/data", "/storage/sdcard0");

			if (!_sqlConnectionSync) {

				_sqlConnectionSync = new SQLConnection();

				try
				{
					//create the database file in the application storage folder
					dbFile = new File(dbFilePath);
					if (!dbFile.exists) {
						logger.info("  Creating SQL Store: " + dbFilePath);
					}
					else {
						logger.info("  Opening SQL Store: " + dbFilePath);
					}
					_sqlConnectionSync.open(dbFile, SQLMode.CREATE);


				}
				catch (error:Error)
				{
					logger.info("    SQLError in SQLStoreController.getSQLConnectionSync(): " +
							error.message);
				}
				return _sqlConnectionSync;
			}
			else
			{
				if (!_sqlConnectionSync.connected) {
					try {
						dbFile = new File(dbFilePath);
						_sqlConnectionSync.open(dbFile, SQLMode.UPDATE);
					}
					catch (error:Error)
					{
						logger.info("    SQLError in SQLStoreController.getSQLConnectionSync(): " +
								error.message);
					}
					logger.info("  Opening SQL Store: " + dbFilePath);
				}
				return _sqlConnectionSync;
			}
		}

		public function set sqlConnectionSync(value:SQLConnection):void
		{
			_sqlConnectionSync = value;
		}

		public function get sqlResult():SQLResult
		{
			if (!_sqlResult)
			{
				_sqlResult = new SQLResult();
				return _sqlResult;
			}
			else
			{
				return _sqlResult;
			}
		}

		public function set sqlResult(value:SQLResult):void
		{
			_sqlResult = value;
		}

		public function get sqlError():SQLError
		{
			return _sqlError;
		}

		public function set sqlError(value:SQLError):void
		{
			_sqlError = value;
		}

		public function get dbFile():File
		{
			return _dbFile;
		}

		public function set dbFile(value:File):void
		{
			_dbFile = value;
		}

		public function get logger():ILogger
		{
			if (!_logger) {
				logger = Log.getLogger(getQualifiedClassName(this).replace("::", "."));
			}
			return _logger;
		}

		public function set logger(value:ILogger):void
		{
			_logger = value;
		}
	}
}
