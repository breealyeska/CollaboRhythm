package collaboRhythm.plugins.bloodPressure.model.titration
{
	import collaboRhythm.shared.model.Account;
	import collaboRhythm.shared.model.StringUtils;
	import collaboRhythm.shared.model.healthRecord.CollaboRhythmCodedValue;
	import collaboRhythm.shared.model.healthRecord.CollaboRhythmValueAndUnit;
	import collaboRhythm.shared.model.healthRecord.DocumentBase;
	import collaboRhythm.shared.model.healthRecord.Relationship;
	import collaboRhythm.shared.model.healthRecord.document.HealthActionPlan;
	import collaboRhythm.shared.model.healthRecord.document.HealthActionResult;
	import collaboRhythm.shared.model.healthRecord.document.MedicationOrder;
	import collaboRhythm.shared.model.healthRecord.document.ScheduleItemOccurrence;
	import collaboRhythm.shared.model.healthRecord.document.healthActionResult.ActionResult;
	import collaboRhythm.shared.model.healthRecord.document.healthActionResult.ActionStepResult;
	import collaboRhythm.shared.model.healthRecord.document.healthActionResult.Measurement;
	import collaboRhythm.shared.model.healthRecord.document.healthActionResult.Occurrence;
	import collaboRhythm.shared.model.healthRecord.document.healthActionResult.StopCondition;
	import collaboRhythm.shared.model.settings.Settings;

	import com.theory9.data.types.OrderedMap;

	import mx.collections.ArrayCollection;

	/**
	 * Enhances HypertensionMedicationTitrationModel by adding support for saving decisions to the patient's health record.
	 */
	public class PersistableHypertensionMedicationTitrationModel extends HypertensionMedicationTitrationModel
	{
		private var _decisionScheduleItemOccurrence:ScheduleItemOccurrence;
		private var _settings:Settings;

		public function PersistableHypertensionMedicationTitrationModel(activeAccount:Account,
																		activeRecordAccount:Account,
																		settings:Settings)
		{
			super(activeAccount, activeRecordAccount);
			_settings = settings;
		}

		override public function evaluateForInitialize():void
		{
			reloadCurrentDoses();
			reloadSelections();
		}

		private function reloadCurrentDoses():void
		{
/*
			var medications:Vector.<HypertensionMedication> = getMedications();
			for each (var medication:HypertensionMedication in medications)
			{
				// look for a match in the patient's record
				var medicationOrder:MedicationOrder = record.medicationOrdersModel.medicationOrders.
			}
*/
			updateSystemRecommendedDoseSelections();
		}

		private function getMedications():Vector.<HypertensionMedication>
		{
			var medications:Vector.<HypertensionMedication> = new <HypertensionMedication>[];
			for each (var pair:HypertensionMedicationAlternatePair in _hypertensionMedicationAlternatePairsVector)
			{
				for each (var medication:HypertensionMedication in pair.medications)
				{
					medications.push(medication);
				}
			}
			return medications;
		}

		public function reloadSelections():void
		{
			clearSelections();

			var plan:DocumentBase = getParentForTitrationDecisionResult(false);

			if (plan)
			{
				var decisionsFromAccounts:OrderedMap = new OrderedMap();

				for (var i:int = plan.relatesTo.length - 1; i >= 0; i--)
				{
					var relationship:Relationship = plan.relatesTo[i];
					var decisionResult:HealthActionResult = relationship ? relationship.relatesTo as
							HealthActionResult : null;
					if (decisionResult && decisionResult.name.text == TITRATION_DECISION_HEALTH_ACTION_RESULT_NAME)
					{
						// only use latest titration decision from each account (each person's latest decision)
						if (decisionsFromAccounts.getValueByKey(decisionResult.reportedBy) != null)
						{
							continue;
						}
						decisionsFromAccounts.addKeyValue(decisionResult.reportedBy, decisionResult);
						restoreSelectionsFromDecisionResult(decisionResult);
					}
				}
			}
		}

		private function restoreSelectionsFromDecisionResult(decisionResult:HealthActionResult):void
		{
			if (decisionResult.actions && decisionResult.actions.length > 0)
			{
				for each (var actionResult:ActionResult in decisionResult.actions)
				{
					var actionStepResult:ActionStepResult = actionResult as ActionStepResult;

					if (actionStepResult)
					{
						var occurrence:Occurrence = actionStepResult.occurrences &&
								actionStepResult.occurrences.length > 0 ? actionStepResult.occurrences[0] as
								Occurrence : null;
						if (occurrence)
						{
							var measurementNewDose:Measurement;
							var measurementDoseSelected:Measurement;

							for each (var measurement:Measurement in occurrence.measurements)
							{
								if (measurement.name.text == "newDose")
								{
									measurementNewDose = measurement;
								}
								else if (measurement.name.text == "doseSelected")
								{
									measurementDoseSelected = measurement;
								}
							}

							if (measurementNewDose && measurementDoseSelected)
							{
								restoreMedicationDoseSelection(measurementNewDose, measurementDoseSelected, occurrence,
										decisionResult);
							}
						}
					}
				}
			}
		}

		private function restoreMedicationDoseSelection(measurementNewDose:Measurement,
														measurementDoseSelected:Measurement, occurrence:Occurrence,
														decisionResult:HealthActionResult):void
		{
			var newDose:int = parseInt(measurementNewDose.value.value);
			var doseSelected:int = parseInt(measurementDoseSelected.value.value);

			var medication:HypertensionMedication = getMedication(occurrence.additionalDetails);
			if (medication)
			{
				medication.restoreMedicationDoseSelection(doseSelected, newDose,
						getAccount(decisionResult.reportedBy),
						_activeRecordAccount.accountId, decisionResult.dateReported);
			}
		}

		private function clearSelections():void
		{
			for each (var pair:HypertensionMedicationAlternatePair in
					_hypertensionMedicationAlternatePairsVector)
			{
				for each (var medication:HypertensionMedication in pair.medications)
				{
					medication.clearSelections();
				}
			}
			isChangeSpecified = false;
		}

		private function getAccount(targetAccountId:String):Account
		{
			if (targetAccountId == _activeAccount.accountId)
			{
				return _activeAccount;
			}
			else if (targetAccountId == _activeRecordAccount.accountId)
			{
				return _activeRecordAccount;
			}
			else
			{
				// TODO: make this more robust; find the correct account
				_logger.warn("Creating fake Account for accountId " + targetAccountId);
				var account:Account = new Account();
				account.accountId = targetAccountId;
				return account;
			}
		}

		private function getMedication(medicationName:String):HypertensionMedication
		{
			for each (var pair:HypertensionMedicationAlternatePair in
					_hypertensionMedicationAlternatePairsVector)
			{
				for each (var medication:HypertensionMedication in pair.medications)
				{
					if (medication.medicationName == medicationName)
					{
						return medication;
					}
				}
			}
			return null;
		}

		public function save(persist:Boolean = true):Boolean
		{
			var saveSucceeded:Boolean = true;

			validateDecisionPreConditions();

//			var healthActionSchedule:HealthActionSchedule = decisionScheduleItemOccurrence.scheduleItem as HealthActionSchedule;
//			var plan:HealthActionPlan = healthActionSchedule.scheduledHealthAction as HealthActionPlan;

			// validate
			if (isChangeSpecified)
			{
				evaluateForSave();
				/*

				if (_scheduleDetails.currentSchedule == null || _scheduleDetails.occurrence == null)
				{
					// TODO: warn the user why the dose cannot be changed; possibly provide a means to fix the problem
					_logger.warn("User is attempting to change the dose but the current schedule/dose could not be determined.");
					return false;
				}
				else
				{
					var currentMedicationScheduleItem:MedicationScheduleItem = _scheduleDetails.currentSchedule as MedicationScheduleItem;
					if (isPatient)
						saveSucceeded = saveForPatient(currentMedicationScheduleItem, plan, saveSucceeded);
					else
						saveSucceeded = saveForClinician(currentMedicationScheduleItem, plan, saveSucceeded);

					saveTitrationResult(currentMedicationScheduleItem);
					evaluateForInitialize();
				}
*/
				var selections:Vector.<HypertensionMedicationDoseSelection> = getSelections();
				saveTitrationResult(selections);

				record.saveAllChanges();
				evaluateForInitialize();
			}

			return saveSucceeded;
		}

		override public function set isChangeSpecified(value:Boolean):void
		{
			super.isChangeSpecified = value;
			updateConfirmationMessage();
		}

		public function evaluateForSave():void
		{
			validateDecisionPreConditions();
			updateConfirmationMessage();
			/*
						_confirmationMessage = !isPatient ||
								!_clinicianLatestDecisionResult ? (algorithmPrerequisitesSatisfied ? (_dosageChangeValue ==
								algorithmSuggestedDoseChange ? "This change agrees with the 303 Protocol." : "This change does not agree with the 303 Protocol.") : "Prerequisites of the 303 Protocol not met.") : (_newDose ==
								_clinicianLatestDecisionDose ? "This change agrees with your coach’s advice." : "This change does not agree with your coach’s advice.")
			*/
		}

		private function updateConfirmationMessage():void
		{
			if (isChangeSpecified)
			{
				var selections:Vector.<HypertensionMedicationDoseSelection> = getSelections();
				var changeVerb:String = isPatient ? "make" : "suggest";
				var maintainVerb:String = isPatient ? "keep" : "suggest keeping";
				var medicationsOwner:String = isPatient ? "your" : "the patient's";
				if (selections.length > 0)
				{
					var parts:Array = getSelectionsSummary(selections);
					confirmationMessage = "You have chosen to " + changeVerb + " the following " +
							StringUtils.pluralize("change", parts.length) + " to " + medicationsOwner +
							" hypertension medications.\n\n" +
							parts.join("\n");
				}
				else
				{
					confirmationMessage = "You have chosen to " + maintainVerb + " all of " + medicationsOwner +
							" hypertension medications at current levels.";
				}
			}
			else
			{
				confirmationMessage = null;
			}
		}

		private function getSelectionsSummary(selections:Vector.<HypertensionMedicationDoseSelection>):Array
		{
			var parts:Array = [];
			for each (var selection:HypertensionMedicationDoseSelection in selections)
			{
				parts.push(selection.getSummary(false));
			}
			return parts;
		}

		private function getSelections():Vector.<HypertensionMedicationDoseSelection>
		{
			var selections:Vector.<HypertensionMedicationDoseSelection> = new <HypertensionMedicationDoseSelection>[];
			for each (var pair:HypertensionMedicationAlternatePair in _hypertensionMedicationAlternatePairsVector)
			{
				for each (var medication:HypertensionMedication in pair.medications)
				{
					for each (var selection:HypertensionMedicationDoseSelection in medication.doseSelections)
					{
						if (selection.selectionType != HypertensionMedicationDoseSelection.SYSTEM &&
							selection.selectionByAccount && selection.selectionByAccount.accountId == accountId)
						{
							selections.push(selection);
						}
					}
				}
			}
			return selections;
		}

		override protected function validateDecisionPreConditions():void
		{
/*
			if (decisionScheduleItemOccurrence == null)
				throw new Error("Failed to save. Decision data not available.");
*/
		}

		override protected function get decisionScheduleItemOccurrence():ScheduleItemOccurrence
		{
			return _decisionScheduleItemOccurrence;
		}

		private function saveTitrationResult(selections:Vector.<HypertensionMedicationDoseSelection>):void
		{
			var parentForTitrationDecisionResult:DocumentBase = getParentForTitrationDecisionResult();

			var titrationResult:HealthActionResult = new HealthActionResult();
			titrationResult.name = new CollaboRhythmCodedValue(null, null, null, TITRATION_DECISION_HEALTH_ACTION_RESULT_NAME);
			titrationResult.reportedBy = accountId;
			titrationResult.dateReported = currentDateSource.now();
			if (selections.length > 0)
			{
				titrationResult.actions = new ArrayCollection();
			}

			for each (var selection:HypertensionMedicationDoseSelection in selections)
			{
				selection.persisted = true;

				var actionStepResult:ActionStepResult = new ActionStepResult();
				actionStepResult.name = new CollaboRhythmCodedValue(null, null, null,
						isPatient ? PATIENT_DECISION_ACTION_STEP_RESULT_NAME : CLINICIAN_DECISION_ACTION_STEP_RESULT_NAME);
				actionStepResult.occurrences = new ArrayCollection();
				var occurrence:Occurrence = new Occurrence();
				occurrence.additionalDetails = selection.medication.medicationName;
				occurrence.stopCondition = new StopCondition();
				occurrence.stopCondition.name = new CollaboRhythmCodedValue(null, null, null, "agreement");
				occurrence.stopCondition.value = new CollaboRhythmValueAndUnit(null, null,
						selection.isInAgreement() ? AGREE_STOP_CONDITION_NAME : NEW_STOP_CONDITION_NAME);
				occurrence.measurements = new ArrayCollection();
				var measurementNewDose:Measurement = new Measurement();
				measurementNewDose.name = new CollaboRhythmCodedValue(null, null, null, "newDose");
				measurementNewDose.value = new CollaboRhythmValueAndUnit(selection.newDose.toString(),
						createDoseStrengthCodeCodedValue());
				occurrence.measurements.addItem(measurementNewDose);
				var measurementDoseSelected:Measurement = new Measurement();
				measurementDoseSelected.name = new CollaboRhythmCodedValue(null, null, null, "doseSelected");
				measurementDoseSelected.value = new CollaboRhythmValueAndUnit(selection.doseSelected.toString(),
						createDoseStrengthCodeCodedValue());
				occurrence.measurements.addItem(measurementDoseSelected);
				actionStepResult.occurrences.addItem(occurrence);
				titrationResult.actions.addItem(actionStepResult);
			}

			record.addDocument(titrationResult, true);

			record.addRelationship(HealthActionResult.RELATION_TYPE_TITRATION_DECISION, parentForTitrationDecisionResult, titrationResult, true);
		}

		private static const HYPERTENSION_MEDICATION_TITRATION_DECISION_PLAN_NAME:String = "Hypertension Medication Titration Decision";

		/**
		 * Finds the HealthActionPlan for hypertension medication titration decision, or create one if it does not exist.
		 * @return a document that can be used as the parent for titration decision result(s)
		 */
		private function getParentForTitrationDecisionResult(createIfNeeded:Boolean = true):DocumentBase
		{
			var titrationDecisionPlan:HealthActionPlan;

			// go in reverse order to start with most recent
			for (var i:int = record.healthActionPlansModel.documents.length - 1; i >= 0; i--)
			{
				var plan:HealthActionPlan = record.healthActionPlansModel.documents[i];
				if (plan.name.text == HYPERTENSION_MEDICATION_TITRATION_DECISION_PLAN_NAME)
				{
					titrationDecisionPlan = plan;
					break;
				}
			}

			if (createIfNeeded && titrationDecisionPlan == null)
			{
				titrationDecisionPlan = new HealthActionPlan();
				titrationDecisionPlan.name = new CollaboRhythmCodedValue(null, null, null, HYPERTENSION_MEDICATION_TITRATION_DECISION_PLAN_NAME);
				titrationDecisionPlan.planType = "Prescribed";
				titrationDecisionPlan.plannedBy = accountId;
				titrationDecisionPlan.datePlanned = _currentDateSource.now();
				titrationDecisionPlan.indication = "Essential Hypertension";
				titrationDecisionPlan.instructions = "Use CollaboRhythm to follow the algorithm for changing your dose of hypertension medications.";
				titrationDecisionPlan.system = new CollaboRhythmCodedValue(null, null, null, "CollaboRhythm Hypertension Titration Support");

				record.addDocument(titrationDecisionPlan, true);
			}

			return titrationDecisionPlan;
		}

		private static function createDoseStrengthCodeCodedValue():CollaboRhythmCodedValue
		{
			return new CollaboRhythmCodedValue("http://indivo.org/codes/units#", "DoseStrengthCode", "DSU", "DoseStrengthCode");
		}


		override protected function getAccountForSelectionAction(ctrlKey:Boolean):Account
		{
			return ctrlKey ? (isPatient ? getCoachAccount() : _activeRecordAccount) : _activeAccount;
		}

		private function getCoachAccount():Account
		{
			if (_settings.primaryClinicianTeamMember)
			{
				var account:Account = new Account();
				account.accountId = _settings.primaryClinicianTeamMember;
				return account;
			}
			return null;
		}
	}
}
