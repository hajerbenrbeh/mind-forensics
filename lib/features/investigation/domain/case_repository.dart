import 'case_model.dart';

/// Abstract contract for Case storage.
///
/// Following the Repository Pattern: The UI only interacts with this
/// interface. Whether data is stored in local SQLite/Hive/memory or synced to
/// Firebase, the application logic remains identical.
abstract class CaseRepository {
  /// Fetches all stored cases.
  Future<List<CaseModel>> getAllCases();

  /// Fetches a specific case by its ID.
  Future<CaseModel?> getCaseById(String id);

  /// Saves or updates a case.
  Future<void> saveCase(CaseModel caseModel);

  /// Deletes a specific case file.
  Future<void> deleteCase(String id);

  /// Renames an existing session/case title.
  Future<void> renameCase(String id, String newTitle);

  /// Completely wipes all user cases (Section 11: "delete everything").
  Future<void> deleteAllCases();

  /// Toggles the privacy shield flag ("Private, never shareable" - Section 12).
  Future<void> toggleCasePrivacy(String id);

  /// Returns the next sequential session ID (e.g., "SESSION 01", "SESSION 02").
  Future<String> getNextCaseNumber();
}

