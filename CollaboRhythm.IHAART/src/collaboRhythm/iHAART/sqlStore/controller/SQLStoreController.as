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
	import collaboRhythm.iHAART.model.DebuggingTools;

	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLStatement;
	import flash.data.SQLTableSchema;
	import flash.errors.SQLError;
	import flash.filesystem.File;
	import flash.globalization.DateTimeFormatter;
	import flash.globalization.DateTimeStyle;
	import flash.utils.getQualifiedClassName;

	import mx.collections.ArrayCollection;
	import mx.logging.ILogger;
	import mx.logging.Log;

// todo bree need to encryptdb
// todo bree need to make store and read functions more generic

	public class SQLStoreController
	{
		public static var IHAART_DB_FILE:String = "iHAART.db";
		public static var SETTINGS_TABLE:String = "user_settings";
		public static var USERS_TABLE:String = "users";
		public static var ADHERENCE_TABLE:String = "user_adherence";
		public static var NOTIFICATIONS_TABLE:String = "notifications";
		public static var MEDICATIONS_TABLE:String = "medications";

		private var LOG_QUERIES:Boolean = false;

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
			DebuggingTools.taggedTrace("dbFilePath");

			try {
				dbFile = new File(dbFilePath);
			}
			catch (error:Error) {
				logger.error("    Error in opening SQL Store: " +
				error.message +
				" ---- " +
				error.getStackTrace());
			}

			dbFile = new File(dbFilePath);

			if (dbFile.exists)
			{
				if (tableExists(USERS_TABLE) && tableExists(ADHERENCE_TABLE) && tableExists(MEDICATIONS_TABLE))
				{
					return;
				}
			}
			else
			{
				logger.error("    Error opening local SQLStore file: " + dbFilePath);
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
					logger.error("    SQLError in initialize(USERS_TABLE): " +
					error.message +
					" ---- " +
					error.details);
				}
				logger.debug("  Table " + USERS_TABLE + " created: " + create.text);
			}

			if (!tableExists(MEDICATIONS_TABLE))
			{
				create.text = "CREATE TABLE " + MEDICATIONS_TABLE + " (id INTEGER PRIMARY KEY AUTOINCREMENT, 'user_id' INTEGER, 'med_name' TEXT, 'med_dose_amount' INTEGER, 'med_dose_unit' TEXT, 'med_indication' TEXT, 'med_instructions' TEXT, 'med_start_time' TEXT, 'med_end_time' TEXT, 'med_img_source' TEXT)";

				create.sqlConnection = sqlConnectionSync;
				try
				{
					create.execute();
				}
				catch (error:SQLError)
				{
					logger.error("    SQLError in initialize(MEDICATIONS_TABLE): " +
					error.message +
					" ---- " +
					error.details);
				}
				logger.debug("  Table " + MEDICATIONS_TABLE + " created: " + create.text);
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
					logger.error("    SQLError in initialize(ADHERENCE_TABLE): " +
					error.message +
					" ---- " +
					error.details);
				}
				logger.debug("  Table " + ADHERENCE_TABLE + " created: " + create.text);
			}

			if (!tableExists(NOTIFICATIONS_TABLE))
			{
				// DateTime format in SQLLite is ("YYYY-MM-DD HH:MM:SS.SSS")
				create.text = "CREATE TABLE " + NOTIFICATIONS_TABLE + " (id INTEGER PRIMARY KEY AUTOINCREMENT, 'user_id' INT, 'notification_type' TEXT, 'indivo_id' TEXT, 'server_timestamp' TEXT, 'app_timestamp' TEXT)";

				create.sqlConnection = sqlConnectionSync;
				try
				{
					create.execute();
				}
				catch (error:SQLError)
				{
					logger.error("    SQLError in initialize(NOTIFICATIONS_TABLE): " +
					error.message +
					" ---- " +
					error.details);
				}
				logger.debug("  Table " + NOTIFICATIONS_TABLE + " created: " + create.text);
			}
		}

		public function syncMeds(accountString:String, medData:Object):Number
		{
			var userID:String = getFieldValue(SQLStoreController.USERS_TABLE, "account_string", accountString, "id");

			medData['user_id'] = userID;
			deleteData(SQLStoreController.MEDICATIONS_TABLE, "user_id", userID);
			var newID:Number = insertData(SQLStoreController.MEDICATIONS_TABLE, medData);
			DebuggingTools.taggedTrace("syncMeds with newID = " + newID);
			return newID;
		}

		public function dateTimeTest(inputString:String):void
		{
			var select:SQLStatement = new SQLStatement();
			var now:Date = new Date();

			var queryString:String = "SELECT datetime('" + inputString + "');";
//			var queryString:String = "SELECT datetime('" + inputString + "', 'utc');"; //goes from local time to utc
//			var queryString:String = "SELECT datetime('" + inputString + "', 'localtime');"; // utc to local time

			select.sqlConnection = sqlConnectionSync; //set the connection
			select.text = queryString;

			try
			{
				select.execute();
			}
			catch (error:SQLError)
			{
				logger.error("    SQLError in getMedDataForUserAccount: " +
				error.message +
				" ---- " +
				error.details);
			}

			if (LOG_QUERIES)
			{
				logger.debug("  Select from SQL Store query:  " + select.text);
			}

			var result:SQLResult = select.getResult();

			if (result)
			{
				for (var rowInd:int = 0; rowInd < result.data.length; rowInd++)
				{
					for (var key:String in result.data[rowInd])
					{
						DebuggingTools.taggedTrace(key);
						DebuggingTools.taggedTrace(result.data[rowInd][key].toString());
					}
				}
			}
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

		}

		public function newNotificationEvent(accountString:String, indivoID:String, notificationType:String, sentTimestamp:Date):void
		{
			var insert:SQLStatement = new SQLStatement();
			var userID:String = "";

			trace("   bree in newNotificationEvent:   ", accountString, "  ", indivoID, "   ", notificationType, "   ", sentTimestamp.toString());

//			var dateFormatter:DateTimeFormatter = new DateTimeFormatter(flash.globalization.LocaleID.DEFAULT);
//			var pattern:String = "yyyy-MM-dd HH:mm:ss.SSS";
//			dateFormatter.setDateTimePattern(pattern);
//			var formattedSentTimestamp:String = dateFormatter.format(sentTimestamp);
//			var formattedReceivedDate:String = dateFormatter.format(new Date());

			var formattedSentTimestamp:String = formatDateForSQLLite(sentTimestamp);
			var formattedReceivedDate:String = formatDateForSQLLite(new Date());
			
			trace("   bree in newNotification Event serverTimestamp & current time:   ",
					formattedSentTimestamp, "    ", formattedReceivedDate);
			userID = getFieldValue(SQLStoreController.USERS_TABLE, "account_string", accountString, "id");

			var notificationData:Object = new Object();
			notificationData['user_id'] = userID;
			notificationData['indivo_id'] = indivoID;
			notificationData['notification_type'] = notificationType;
			notificationData['server_timestamp'] = formattedSentTimestamp;
			notificationData['app_timestamp'] = formattedReceivedDate;

			var newID:Number = insertData(SQLStoreController.NOTIFICATIONS_TABLE, notificationData);
		}

//		todo bree would be better if returned an arraycollection for event handling or an object
		public function getMedDataForUserAccount(accountString:String):SQLResult
		{
			var resultArray:Array;

			var select:SQLStatement = new SQLStatement();
			var userID:String = "";

			userID = getFieldValue(SQLStoreController.USERS_TABLE, "account_string", accountString, "id");

			if (userID.length > 0)
			{
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
					logger.error("    SQLError in getMedDataForUserAccount: " +
					error.message +
					" ---- " +
					error.details);
				}

				if (LOG_QUERIES)
				{
					logger.debug("  Select from SQL Store query:  " + select.text);
				}

				var result:SQLResult = select.getResult();

			}
			else {
				logger.error("    Error in getMedDataForUserAccount: no user found for account " + accountString);
			}

			return result;
		}

		public function resultToArrayCollection(result:SQLResult):ArrayCollection
		{
			var resultArray:ArrayCollection;
			for (var rowInd:int = 0; rowInd < result.data.length; rowInd++)
			{
				var row:Object;
				for (var key:String in result.data[rowInd])
				{
					row[key] = result.data[rowInd][key].toString();
					resultArray.addItem(row);
				}
			}
			return resultArray;
		}

		public function clearAllDataFromTable(tableName:String):void
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
				logger.error("    SQLError in clearAllDataFromTable(" + tableName + "): " +
				error.message +
				" ---- " +
				error.details);
			}
			logger.debug("  Table " + tableName + " deleted");
		}

		private function getFieldValue(tableName:String,
									   parameterColumn:String,
									   parameterValue:String,
									   fieldColumn:String):String
		{
			var queryString:String = "SELECT " +
					fieldColumn +
					" FROM " +
					tableName +
					" WHERE " +
					parameterColumn +
					" = '" +
					parameterValue +
					"'";
			var select:SQLStatement = new SQLStatement();

			select.text = queryString;

			trace("   bree in getFieldValue: ", queryString);
			try
			{
				select.sqlConnection = sqlConnectionSync;
				select.execute();
			}
			catch (error:SQLError)
			{
				logger.error("    SQLError in getField(): " +
				error.message +
				" ---- " +
				error.details);
			}

			var result = select.getResult();
			if (result != null && result.data != null)
			{
				return result.data[0][fieldColumn];
			}
			else
			{
				return "";
			}
		}

		public function updateData(tableName:String, whereColumn:String, whereValue:String, dataObject:Object):Number
		{
			var colNamesStr:String = "";
			var colValuesStr:String = "";

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

			try
			{
				update.sqlConnection = sqlConnectionSync; //set the connection
				update.text = queryString;
				update.execute();
			}
			catch (error:SQLError)
			{
				logger.error("    SQLError in updateData(): " +
				error.message +
				" ---- " +
				error.details);
			}

			// get the primary key
			var result:SQLResult = update.getResult();
			if (LOG_QUERIES)
			{
				logger.debug("  Update SQL Store query:  " + update.text + "\n  Rows affected: " + result.rowsAffected);
			}
			return result.rowsAffected;
		}

		public function insertData(tableName:String, queryData:Object):Number
		{
			var colNamesStr:String = "";
			var colValuesStr:String = "";
			var colRealValues:String = "";
			try
			{
				var insert:SQLStatement = new SQLStatement(); //create the insert statement

				var i:int = 0;

				for (var key:String in queryData)
				{
					insert.parameters[i] = queryData[key].toString();
					colNamesStr = colNamesStr + "'" + key + "', ";
					colValuesStr = colValuesStr + "?, ";
					colRealValues = colRealValues + "'" + queryData[key].toString() + "' ";
					i++;
				}

				colNamesStr = colNamesStr.slice(0, -2);
				colValuesStr = colValuesStr.slice(0, -2);

				var queryString:String = "INSERT INTO " +
						tableName +
						" ( " +
						colNamesStr +
						" ) VALUES ( " +
						colValuesStr +
						" )";

				insert.sqlConnection = sqlConnectionSync; //set the connection
				insert.text = queryString;
				insert.execute();
			}
			catch (error:SQLError)
			{
				logger.error("    SQLError in insertData(): " +
				error.message +
				" ---- " +
				error.details);
			}

			// get the primary key
			var result:SQLResult = insert.getResult();
			if (LOG_QUERIES)
			{
				logger.debug("  Insert into SQL Store query:  " + insert.text + "\n  Rows affected: " + result.rowsAffected);
			}
			return result.lastInsertRowID;
		}

		public function deleteData(tableName:String, columnName:String, columnValue:String):void
		{
			if (tableExists(tableName))
			{
				var deleteStmt:SQLStatement = new SQLStatement();
				var result:SQLResult = new SQLResult();

				deleteStmt.parameters[0] = columnValue;

				var queryString:String = "DELETE FROM " +
						tableName +
						" WHERE " +
						columnName +
						" = ?";

				try
				{
					deleteStmt.sqlConnection = sqlConnectionSync; //set the connection
					deleteStmt.text = queryString;
					deleteStmt.execute();
					result = deleteStmt.getResult();
				}
				catch (error:SQLError)
				{
					logger.error("    SQLError in deleteData(): " +
					error.message +
					" ---- " +
					error.details);
				}
				if (LOG_QUERIES)
				{
					logger.debug("  Delete SQL Store query: " + deleteStmt.text + "\n  Rows affected: " + result.rowsAffected);
				}
			}
		}

		private function formatDateForSQLLite(dateObj:Date):String
		{
			var dateFormatter:DateTimeFormatter = new DateTimeFormatter(flash.globalization.LocaleID.DEFAULT);
			var pattern:String = "yyyy-MM-dd HH:mm:ss.SSS"; //sqlite datetime stored in strings with this format
			dateFormatter.setDateTimePattern(pattern);

			return dateFormatter.format(dateObj);
		}

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
							logger.debug("  Table " + tableName + " exists");
							return true;
						}
					}
				}
			}
			catch (error:SQLError)
			{
				logger.error("    SQLError in tableExists(): " +
						error.message +
						" ---- " +
						error.details);
			}

			logger.debug("  Table " + tableName + " does not exist");
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
						logger.debug("  Creating SQL Store: " + dbFilePath);
					}
					else {
						logger.debug("  Opening SQL Store: " + dbFilePath);
					}
					_sqlConnectionSync.open(dbFile, SQLMode.CREATE);


				}
				catch (error:Error)
				{
					logger.error("    SQLError in getSQLConnectionSync(): " +
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
						logger.error("    SQLError in getSQLConnectionSync(): " +
								error.message);
					}
					logger.debug("  Opening SQL Store: " + dbFilePath);
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
