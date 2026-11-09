import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/journey/controllers/journey_controller.dart';
import 'package:mind_forensics/features/journey/data/default_journey_curriculum.dart';
import 'package:mind_forensics/features/journey/data/local_journey_repository.dart';
import 'package:mind_forensics/features/journey/domain/journey_activity.dart';
import 'package:mind_forensics/features/journey/domain/journey_phase.dart';
import 'package:mind_forensics/features/journey/domain/journey_state_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Journey & Discovery Persistence Verification Tests', () {
    test('1. Custom discoveries survive serialization and deserialization intact', () {
      final defaultActs = DefaultJourneyCurriculum.getActivities();
      final now = DateTime.now();

      final customDiscovery = JourneyActivity(
        id: 'disc_999999',
        phase: JourneyPhase.phase3PsychologicalAwareness,
        title: 'Cognitive flexibility anchor',
        purpose: 'Perspective Reframe',
        shortExplanation: 'User reframing insight',
        guidedInstructions: const [],
        reflectionQuestions: const [],
        isCompleted: true,
        completedAt: now,
        personalNotes: 'Fact: silence. Reframe: busy schedule.',
      );

      final state = JourneyStateModel(
        activities: [customDiscovery, ...defaultActs],
        activePhase: JourneyPhase.phase3PsychologicalAwareness,
        updatedAt: now,
      );

      final json = state.toJson();
      final decodedState = JourneyStateModel.fromJson(json, defaultActs);

      expect(decodedState.activities.length, defaultActs.length + 1);
      final restored = decodedState.activities.firstWhere((a) => a.id == 'disc_999999');
      expect(restored.title, 'Cognitive flexibility anchor');
      expect(restored.purpose, 'Perspective Reframe');
      expect(restored.phase, JourneyPhase.phase3PsychologicalAwareness);
      expect(restored.isCompleted, isTrue);
      expect(restored.personalNotes, 'Fact: silence. Reframe: busy schedule.');
    });

    test('2. Custom discoveries and curriculum progress survive app restart (fresh repository instance)', () async {
      final repo1 = LocalJourneyRepository(userId: 'test_user_1');

      // 1. Mark a curriculum activity completed with reflection notes
      final initial = await repo1.getJourneyState();
      final updatedActs = initial.activities.map((a) {
        if (a.id == 'act_1_1') {
          return a.copyWith(
            isCompleted: true,
            completedAt: DateTime(2026, 11, 8),
            personalNotes: 'Separating thoughts from visceral panic.',
          );
        }
        return a;
      }).toList();

      // 2. Add a custom discovery
      final discovery = JourneyActivity(
        id: 'disc_user_persisted',
        phase: JourneyPhase.phase2UnderstandingPatterns,
        title: 'Emotional weather pattern',
        purpose: 'Body Wisdom',
        shortExplanation: 'Somatic tracking',
        guidedInstructions: const [],
        reflectionQuestions: const [],
        isCompleted: true,
        completedAt: DateTime(2026, 11, 8),
        personalNotes: 'Morning heaviness lifts by midday.',
      );

      final stateToSave = initial.copyWith(
        activities: [discovery, ...updatedActs],
        activePhase: JourneyPhase.phase2UnderstandingPatterns,
        updatedAt: DateTime(2026, 11, 8),
      );

      await repo1.saveJourneyState(stateToSave);

      // Simulate App Restart by creating a completely fresh repository instance
      final repoRestarted = LocalJourneyRepository(userId: 'test_user_1');
      final reloaded = await repoRestarted.getJourneyState();

      // Verify custom discovery is present
      expect(reloaded.activities.any((a) => a.id == 'disc_user_persisted'), isTrue);
      final reloadedDiscovery = reloaded.activities.firstWhere((a) => a.id == 'disc_user_persisted');
      expect(reloadedDiscovery.title, 'Emotional weather pattern');
      expect(reloadedDiscovery.personalNotes, 'Morning heaviness lifts by midday.');

      // Verify curriculum progress was never discarded or reset
      final reloadedAct1 = reloaded.activities.firstWhere((a) => a.id == 'act_1_1');
      expect(reloadedAct1.isCompleted, isTrue);
      expect(reloadedAct1.personalNotes, 'Separating thoughts from visceral panic.');
      expect(reloaded.activePhase, JourneyPhase.phase2UnderstandingPatterns);
    });

    test('3. Discovery phase assignment matches each active Journey phase correctly', () async {
      for (final phase in JourneyPhase.values) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(journeyControllerProvider.future);
        await container.read(journeyControllerProvider.notifier).setActivePhase(phase);

        await container.read(journeyControllerProvider.notifier).addCustomDiscovery(
          title: 'Discovery for ${phase.name}',
          notes: 'Notes for phase ${phase.phaseNumber}',
          category: 'Phase Verification',
        );

        final state = container.read(journeyControllerProvider).value!;
        final added = state.activities.first;
        expect(added.phase, equals(phase), reason: 'Discovery phase must equal active phase $phase');
        expect(added.title, 'Discovery for ${phase.name}');
      }
    });

    test('4. Anonymous data does not silently leak into newly authenticated accounts (strict partition isolation)', () async {
      final prefs = await SharedPreferences.getInstance();

      // Start unauthenticated (anonymous partition)
      final repoAnon = LocalJourneyRepository(userId: null);
      final anonInitial = await repoAnon.getJourneyState();

      final anonDiscovery = JourneyActivity(
        id: 'disc_anon_saved',
        phase: JourneyPhase.phase1SelfDiscovery,
        title: 'Anonymous Discovery',
        purpose: 'Thought Shift',
        shortExplanation: 'Pre-auth discovery',
        guidedInstructions: const [],
        reflectionQuestions: const [],
        isCompleted: true,
        completedAt: DateTime.now(),
        personalNotes: 'Captured before creating account.',
      );

      await repoAnon.saveJourneyState(anonInitial.copyWith(
        activities: [anonDiscovery, ...anonInitial.activities],
      ));

      // User creates/links a new authenticated account -> userId = 'user_vault_456'
      // Security Invariant: Anonymous data must NOT automatically transfer into newly authenticated accounts.
      final repoVault = LocalJourneyRepository(userId: 'user_vault_456');
      final vaultLoaded = await repoVault.getJourneyState();

      // Verify anonymous records do NOT silently appear in a newly created account
      expect(vaultLoaded.activities.any((a) => a.id == 'disc_anon_saved'), isFalse);

      // Authenticated account creates its own discovery
      final authDiscovery = JourneyActivity(
        id: 'disc_auth_saved',
        phase: JourneyPhase.phase2UnderstandingPatterns,
        title: 'Authenticated Discovery',
        purpose: 'Cognitive Restructuring',
        shortExplanation: 'Saved in user vault',
        guidedInstructions: const [],
        reflectionQuestions: const [],
        isCompleted: true,
        completedAt: DateTime.now(),
        personalNotes: 'Private notes in authenticated account.',
      );

      await repoVault.saveJourneyState(vaultLoaded.copyWith(
        activities: [authDiscovery, ...vaultLoaded.activities],
      ));

      // Verify journey persistence through repository API with correct decryption
      final freshRepoVault = LocalJourneyRepository(userId: 'user_vault_456');
      final reloadedVault = await freshRepoVault.getJourneyState();
      expect(reloadedVault.activities.any((a) => a.id == 'disc_auth_saved'), isTrue);
      final fetched = reloadedVault.activities.firstWhere((a) => a.id == 'disc_auth_saved');
      expect(fetched.title, equals('Authenticated Discovery'));
      expect(fetched.personalNotes, equals('Private notes in authenticated account.'));

      // Verify data is stored encrypted under AES-256-GCM and never as raw plaintext
      final rawVault = prefs.getString('mf_journey_progress_user_vault_456');
      expect(rawVault, isNotNull);
      expect(rawVault!.startsWith('enc:v1\$'), isTrue);
      expect(rawVault.contains('disc_auth_saved'), isFalse, reason: 'Plaintext entity ID must not appear in encrypted store');
    });

    test('5. Multi-user isolation prevents account cross-contamination and preserves anonymous partition', () async {
      // 1. Seed user_alpha journey
      final repoAlpha = LocalJourneyRepository(userId: 'user_alpha');
      final alphaInitial = await repoAlpha.getJourneyState();
      final alphaDiscovery = JourneyActivity(
        id: 'disc_alpha',
        phase: JourneyPhase.phase1SelfDiscovery,
        title: 'Alpha Discovery',
        purpose: 'Alpha Purpose',
        shortExplanation: 'Alpha Note',
        guidedInstructions: const [],
        reflectionQuestions: const [],
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      await repoAlpha.saveJourneyState(alphaInitial.copyWith(
        activities: [alphaDiscovery, ...alphaInitial.activities],
      ));

      // 2. Seed anonymous user journey
      final repoAnon = LocalJourneyRepository(userId: null);
      final anonInitial = await repoAnon.getJourneyState();
      final anonDiscovery = JourneyActivity(
        id: 'disc_anon',
        phase: JourneyPhase.phase1SelfDiscovery,
        title: 'Anon Discovery',
        purpose: 'Anon Purpose',
        shortExplanation: 'Anon Note',
        guidedInstructions: const [],
        reflectionQuestions: const [],
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      await repoAnon.saveJourneyState(anonInitial.copyWith(
        activities: [anonDiscovery, ...anonInitial.activities],
      ));

      // 3. User beta logs in: cannot see alpha or anon
      final repoBeta = LocalJourneyRepository(userId: 'user_beta');
      final betaLoaded = await repoBeta.getJourneyState();

      expect(betaLoaded.activities.any((a) => a.id == 'disc_alpha'), isFalse);
      expect(betaLoaded.activities.any((a) => a.id == 'disc_anon'), isFalse);

      // 4. Verify alpha still has only alpha
      final alphaLoaded = await repoAlpha.getJourneyState();
      expect(alphaLoaded.activities.any((a) => a.id == 'disc_alpha'), isTrue);
      expect(alphaLoaded.activities.any((a) => a.id == 'disc_anon'), isFalse);

      // 5. Verify anon still has only anon
      final anonState = await repoAnon.getJourneyState();
      expect(anonState.activities.any((a) => a.id == 'disc_anon'), isTrue);
      expect(anonState.activities.any((a) => a.id == 'disc_alpha'), isFalse);
    });
  });
}
