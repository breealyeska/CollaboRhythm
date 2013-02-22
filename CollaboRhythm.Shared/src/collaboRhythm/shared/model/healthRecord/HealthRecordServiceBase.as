package collaboRhythm.shared.model.healthRecord
{

	import collaboRhythm.shared.model.Account;
	import collaboRhythm.shared.model.StringUtils;
	import collaboRhythm.shared.model.services.HtmlParser;
	import collaboRhythm.shared.model.services.ICurrentDateSource;
	import collaboRhythm.shared.model.services.WorkstationKernel;

	import flash.events.EventDispatcher;
	import flash.utils.getQualifiedClassName;

	import mx.logging.ILogger;
	import mx.logging.Log;

	import org.indivo.client.IndivoClientEvent;

	public class HealthRecordServiceBase extends EventDispatcher
    {
		protected static var httpStatusCodeUtil:HttpStatusCodeUtil = new HttpStatusCodeUtil();

        protected var _logger:ILogger;
        protected var _activeAccount:Account;
        protected var _currentDateSource:ICurrentDateSource;

		protected const MAX_FAILED_ATTEMPTS:int = 3;

		private var _automaticRetryEnabled:Boolean = true;

		public function HealthRecordServiceBase(oauthConsumerKey:String, oauthConsumerSecret:String, indivoServerBaseURL:String, account:Account)
        {
            _logger = Log.getLogger(getQualifiedClassName(this).replace("::", "."));
            _activeAccount = account;
            _currentDateSource = WorkstationKernel.instance.resolve(ICurrentDateSource) as ICurrentDateSource;
        }

        public function indivoClientEventHandler(event:IndivoClientEvent):void
        {
            var healthRecordServiceRequestDetails:HealthRecordServiceRequestDetails = event.userData as HealthRecordServiceRequestDetails;
            if (event.type == IndivoClientEvent.COMPLETE)
            {
                var responseXml:XML = event.response;

                // TODO: what if responseXml is null
                if (responseXml != null)
                {
					_logger.info("Indivo response COMPLETE from {1} {2} ({0} bytes)", event.responseData.length, event.urlRequest.method, event.relativePath);
                    handleResponse(event, responseXml, healthRecordServiceRequestDetails);
                }
                else
                {
                    handleError(event, "Complete event has no response data", healthRecordServiceRequestDetails);
                }
            }
            else
            {
                var innerError:XMLList = event.response.InnerError;
                var errorStatus:String;

                if (innerError != null)
                {
                    errorStatus = innerError.text;
                }
                else
                {
                    errorStatus = "Undefined error occurred."
                }

                handleError(event, errorStatus, healthRecordServiceRequestDetails);
            }
        }

        /**
         * Virtual method which subclasses should override in order to handle the asynchronous response to a request.
         *
         * @param event
         * @param responseXml
         *
         */
        protected function handleResponse(event:IndivoClientEvent, responseXml:XML, healthRecordServiceRequestDetails:HealthRecordServiceRequestDetails):void
        {
            // Base class does nothing. Subclasses should override.
        }

        /**
         * Handles the asynchronous error response to a request by retrying (if automaticRetryEnabled).
         *
         * @param event
         * @param errorStatus
         * @returns true if the error handler is retrying the request (asynchronously); false otherwise. Subclasses should generally
		 * call super.handleError() and should ignore the error if the super class is retrying the request.
         */
        protected function handleError(event:IndivoClientEvent, errorStatus:String, healthRecordServiceRequestDetails:HealthRecordServiceRequestDetails):Boolean
        {
			return defaultHandleError(event, healthRecordServiceRequestDetails);
		}

		private static const DOCTYPE_TAG:String = '\<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">';
		private var _lastErrorDescription:String;

		protected function defaultHandleError(event:IndivoClientEvent,
											  healthRecordServiceRequestDetails:HealthRecordServiceRequestDetails):Boolean
		{
			var errorDescriptionParts:Array = new Array();

			if (event.httpStatusEvent && event.httpStatusEvent.status != 0)
			{
				errorDescriptionParts.push(event.httpStatusEvent.status);
				var shortDescription:String = httpStatusCodeUtil.getShortDescription(event.httpStatusEvent.status);
				errorDescriptionParts.push(shortDescription ? shortDescription : "(unknown status)");
			}

			if (event.errorEvent)
			{
				errorDescriptionParts.push("{" + event.errorEvent.type + "}");
				errorDescriptionParts.push(event.errorEvent.errorID);
				errorDescriptionParts.push(event.errorEvent.text);
			}

			_logger.warn("Indivo response ERROR {0} from {1} {2}", errorDescriptionParts.join(" "),
						 event.urlRequest.method, event.relativePath);
			if (event.responseData.indexOf(DOCTYPE_TAG) != -1)
			{
				// XPath: //*[@id="summary"]/h1  XPath: //*[@id="summary"]/pre
				var parser:HtmlParser = new HtmlParser();
				var parsed:String = parser.HTMLtoXML(StringUtils.trim(event.responseData).replace(DOCTYPE_TAG, ""));
				var parsedXml:XML = new XML(parsed);

				var summary:String = parsedXml.body.div.(@id=="summary").h1.toString();
				var exceptionValue:String = parsedXml.body.div.(@id=="summary").pre.(@["class"]=="exception_value").toString(); // .(@class=="exception_value")

				_logger.warn(summary);
				_logger.warn(exceptionValue);
				lastErrorDescription = summary + "\n" + exceptionValue;
			}
			else
			{
				_logger.warn(event.responseData);
				lastErrorDescription = event.responseData;
			}
			return handleErrorWithRetry(healthRecordServiceRequestDetails, event);
		}

		public function resetAndRetryFailedRequest(event:IndivoClientEvent):void
		{
			var healthRecordServiceRequestDetails:HealthRecordServiceRequestDetails = event.userData as HealthRecordServiceRequestDetails;
			if (healthRecordServiceRequestDetails == null)
				healthRecordServiceRequestDetails = new HealthRecordServiceRequestDetails();

			healthRecordServiceRequestDetails.failedAttempts = 0;

			retryFailedRequest(event, healthRecordServiceRequestDetails);
		}

		protected function handleErrorWithRetry(healthRecordServiceRequestDetails:HealthRecordServiceRequestDetails,
												event:IndivoClientEvent):Boolean
		{
			if (automaticRetryEnabled && shouldRetry(event))
			{
				if (healthRecordServiceRequestDetails == null)
					healthRecordServiceRequestDetails = new HealthRecordServiceRequestDetails();
				healthRecordServiceRequestDetails.failedAttempts++;
				if (healthRecordServiceRequestDetails.failedAttempts < MAX_FAILED_ATTEMPTS)
				{
					_logger.warn("Failed attempt(s): {0}. Retrying...",
								 healthRecordServiceRequestDetails.failedAttempts);
					retryFailedRequest(event, healthRecordServiceRequestDetails);
					return true;
				}
				else
				{
					_logger.warn("Failed attempt(s): {0}. Giving up.",
								 healthRecordServiceRequestDetails.failedAttempts);
					return false;
				}
			}
			return false;
		}

		private function shouldRetry(event:IndivoClientEvent):Boolean
		{
			return event.isConnectionError;
		}

		protected function retryFailedRequest(event:IndivoClientEvent,
											  healthRecordServiceRequestDetails:HealthRecordServiceRequestDetails):void
		{
			// subclasses must override to implement retry
		}

		/**
		 * If true, each failed request will automatically be retried multiple times. Otherwise, when a request fails
		 * it there will not be any additional automatic attempts to complete the request.
		 */
		public function get automaticRetryEnabled():Boolean
		{
			return _automaticRetryEnabled;
		}

		public function set automaticRetryEnabled(value:Boolean):void
		{
			_automaticRetryEnabled = value;
		}

		/**
		 * Assumes that there is only a single request being made by this service, so that if the request is not being
		 * retried, a failed event will be dispatched. This generally is not appropriate to use if the service makes multiple
		 * requests, some of which may be in progress or pending.
		 *
		 * @param event
		 * @param errorStatus
		 * @param healthRecordServiceRequestDetails
		 * @return
		 */
		protected function handleErrorForSingleRequest(event:IndivoClientEvent, errorStatus:String,
													   healthRecordServiceRequestDetails:HealthRecordServiceRequestDetails):Boolean
		{
			if (defaultHandleError(event, healthRecordServiceRequestDetails))
			{
				return true;
			}
			else
			{
				dispatchEvent(new HealthRecordServiceEvent(HealthRecordServiceEvent.FAILED, event, null, null, null,
						errorStatus));
				return false;
			}
		}

		public function get activeAccount():Account
		{
			return _activeAccount;
		}

		public function set activeAccount(value:Account):void
		{
			_activeAccount = value;
		}

		public function get lastErrorDescription():String
		{
			return _lastErrorDescription;
		}

		public function set lastErrorDescription(value:String):void
		{
			_lastErrorDescription = value;
		}
	}
}