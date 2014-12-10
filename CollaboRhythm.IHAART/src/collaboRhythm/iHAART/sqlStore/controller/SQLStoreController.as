/**
 * Copyright 2014 Bree Alyeska
 *
 * This file is part of CollaboRhythm.
 *
 * CollaboRhythm is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation, either version 2 of the License, or (at your option) any later
 * version.
 *
 * CollaboRhythm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with CollaboRhythm.  If not, see
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
	import flash.utils.getQualifiedClassName;

	import mx.logging.ILogger;
	import mx.logging.Log;

// todo bree need to encryptdb
// todo bree need to make store and read functions more generic
// todo bree needtocreate adherence data table along with user_settings

	public class SQLStoreController
	{
		private static const IHAART_DB_FILE = "iHAART.db";
		private static const SETTINGS_TABLE = "gcm_settings";
		private static const ADHERENCE_TABLE = "user_adherence";

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
				if (tableExists(SETTINGS_TABLE) && tableExists(ADHERENCE_TABLE))
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

			if (!tableExists(SETTINGS_TABLE))
			{
				create.text = "CREATE TABLE " + SETTINGS_TABLE + " (id INTEGER PRIMARY KEY AUTOINCREMENT, 'registration_id' VARCHAR(255))";

				create.sqlConnection = sqlConnectionSync;
				try
				{
					create.execute();
				}
				catch (error:SQLError)
				{
					logger.info("    SQLError in SQLStoreController.initialize(SETTINGS_TABLE): " +
					error.message +
					" ---- " +
					error.details);
				}
				logger.info("  Table " + SETTINGS_TABLE + " created: " + create.text);
			}

			if (!tableExists(ADHERENCE_TABLE))
			{
				// DateTime format in SQLLite is ("YYYY-MM-DD HH:MM:SS.SSS")
				create.text = "CREATE TABLE " + ADHERENCE_TABLE + " (id INTEGER PRIMARY KEY AUTOINCREMENT, 'factoid_id' INT, 'timeSent' VARCHAR(64), 'timeReceived' VARCHAR(64), 'timeReported' VARCHAR(64))";

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
		}

		public function saveRegistrationID(registrationID:String):Boolean
		{
			clearTableData(SETTINGS_TABLE);
			sqlResult = writeData("gcm_settings", "registration_id", registrationID.toString());
			logger.info("  GCM Registration ID saved: " + "  " + registrationID);
			return true;

		}

		public function getRegistrationID():String
		{
			try
			{
				var select:SQLStatement = new SQLStatement();
				select.sqlConnection = sqlConnectionSync;
				select.text = "SELECT registration_id FROM gcm_settings ORDER BY id";
				select.execute();
			}
			catch (error:SQLError)
			{
				logger.info("    SQLError in SQLStoreController.getRegistrationID(): " +
						error.message +
						" ---- " +
						error.details);
			}

			var output:String;
			try {
				sqlResult = select.getResult();

				if (sqlResult.data)
				{
					logger.info("  Getting GCM registrationID from store: " + sqlResult.data[0]["registration_id"]);
//					for (var columnName:String in sqlResult.data[0])
//					{
//						output += columnName + ": " + sqlResult.data[0][columnName] + "; ";
//					}
					return sqlResult.data[0]["registration_id"];
				}
				else
				{
					logger.info("No GCM registrationID found in store");
					return CloudMessagingController.REGID_NONE;
				}
			}
			catch (error:SQLError)
			{
				logger.info("    SQLError in SQLStoreController.getRegistrationID(): " +
						error.message +
						" ---- " +
						error.details);
			}
			return CloudMessagingController.REGID_NONE;
		}

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

//write the data
		private function writeData(table:String, parameter:String, value:String):SQLResult
		{
			try
			{
				var query:String = "INSERT INTO " + table + " ('" + parameter + "') VALUES (?)";
				var insert:SQLStatement = new SQLStatement(); //create the insert statement
				insert.sqlConnection = sqlConnectionSync; //set the connection
				insert.text = query;
				insert.parameters[0] = value;
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
			return insert.getResult();
		}

		private function readData():SQLResult
		{
			var read:SQLStatement = new SQLStatement(); //create the read statemen
			read.sqlConnection = sqlConnectionSync; //set the connection
//				todo bree this should be dynamic
			read.text = "SELECT id, registration_id FROM gcm_settings ORDER BY id";
			try
			{
				read.execute();
			}
			catch (error:SQLError)
			{
				logger.info("    SQLError in SQLStoreController.readData(): " +
						error.message +
						" ---- " +
						error.details);
			}
			return read.getResult();
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
