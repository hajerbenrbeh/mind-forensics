import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../profile/domain/condition_type.dart';
import '../data/local_symptom_repository.dart';
import '../data/observatory_ai_service.dart';
import '../domain/symptom_entry.dart';
import '../domain/symptom_report.dart';

// -----------------------------------------------------------------------------
// AI Service Provider
// -----------------------------------------------------------------------------
final observatoryAiServiceProvider = Provider<ObservatoryAiService>((ref) {
  final aiConfig = ref.watch(aiConfigProvider);
  return ObservatoryAiService(
    apiKey: aiConfig.apiKey,
    modelName: 'gemini-3.1-flash-lite',
  );
});

// -----------------------------------------------------------------------------
// Symptom Library State & Controller
// -----------------------------------------------------------------------------
class SymptomListNotifier extends AsyncNotifier<List<SymptomEntry>> {
  @override
  Future<List<SymptomEntry>> build() async {
    final repo = ref.watch(symptomRepositoryProvider);
    return repo.getAllSymptoms();
  }

  Future<void> addCustomSymptom(SymptomEntry symptom) async {
    final repo = ref.read(symptomRepositoryProvider);
    await repo.saveCustomSymptom(symptom);
    ref.invalidateSelf();
  }

  Future<void> removeCustomSymptom(String id) async {
    final repo = ref.read(symptomRepositoryProvider);
    await repo.deleteCustomSymptom(id);
    ref.invalidateSelf();
  }
}

final symptomListControllerProvider =
    AsyncNotifierProvider<SymptomListNotifier, List<SymptomEntry>>(
  SymptomListNotifier.new,
);

// -----------------------------------------------------------------------------
// Filters & Search
// -----------------------------------------------------------------------------
class SymptomSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String q) => state = q;
}

final symptomSearchQueryProvider =
    NotifierProvider<SymptomSearchQueryNotifier, String>(
  SymptomSearchQueryNotifier.new,
);

class SelectedDomainNotifier extends Notifier<SymptomDomain?> {
  @override
  SymptomDomain? build() => null;
  void select(SymptomDomain? domain) => state = domain;
}

final selectedDomainFilterProvider =
    NotifierProvider<SelectedDomainNotifier, SymptomDomain?>(
  SelectedDomainNotifier.new,
);

class SelectedConditionNotifier extends Notifier<ConditionType?> {
  @override
  ConditionType? build() => null;
  void select(ConditionType? condition) => state = condition;
}

final selectedConditionFilterProvider =
    NotifierProvider<SelectedConditionNotifier, ConditionType?>(
  SelectedConditionNotifier.new,
);

final filteredSymptomsProvider = Provider<List<SymptomEntry>>((ref) {
  final symptomsAsync = ref.watch(symptomListControllerProvider);
  final symptoms = symptomsAsync.value ?? [];
  final query = ref.watch(symptomSearchQueryProvider).trim().toLowerCase();
  final domainFilter = ref.watch(selectedDomainFilterProvider);
  final conditionFilter = ref.watch(selectedConditionFilterProvider);

  return symptoms.where((s) {
    if (domainFilter != null && s.domain != domainFilter) {
      return false;
    }
    if (conditionFilter != null && s.relatedCondition != conditionFilter) {
      return false;
    }
    if (query.isNotEmpty) {
      final matchesEn = s.titleEn.toLowerCase().contains(query) ||
          s.descriptionEn.toLowerCase().contains(query);
      final matchesFr = s.titleFr.toLowerCase().contains(query) ||
          s.descriptionFr.toLowerCase().contains(query);
      final matchesAr = s.titleAr.contains(query) || s.descriptionAr.contains(query);
      return matchesEn || matchesFr || matchesAr;
    }
    return true;
  }).toList();
});

// -----------------------------------------------------------------------------
// Multiple Symptom Selection
// -----------------------------------------------------------------------------
class SelectedSymptomIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String id) {
    final next = Set<String>.from(state);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
  }

  void clear() => state = {};

  void setSelection(Set<String> ids) => state = ids;
}

final selectedSymptomIdsProvider =
    NotifierProvider<SelectedSymptomIdsNotifier, Set<String>>(
  SelectedSymptomIdsNotifier.new,
);

// -----------------------------------------------------------------------------
// Symptom Reports (Longitudinal & Assessment History)
// -----------------------------------------------------------------------------
class SymptomReportsNotifier extends AsyncNotifier<List<SymptomReport>> {
  @override
  Future<List<SymptomReport>> build() async {
    final repo = ref.watch(symptomRepositoryProvider);
    return repo.getAllReports();
  }

  Future<void> recordReport(SymptomReport report) async {
    final repo = ref.read(symptomRepositoryProvider);
    await repo.saveReport(report);
    ref.invalidateSelf();
  }

  Future<void> deleteReport(String id) async {
    final repo = ref.read(symptomRepositoryProvider);
    await repo.deleteReport(id);
    ref.invalidateSelf();
  }
}

final symptomReportsControllerProvider =
    AsyncNotifierProvider<SymptomReportsNotifier, List<SymptomReport>>(
  SymptomReportsNotifier.new,
);

final symptomFrequenciesProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(symptomRepositoryProvider);
  return repo.getSymptomFrequencies(days: 14);
});
