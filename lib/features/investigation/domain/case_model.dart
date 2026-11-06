import 'case_stage.dart';
import 'conversation_mode.dart';
import 'forensic_chain.dart';
import 'hypothesis.dart';
import 'statement.dart';

/// The central entity of the Mind Forensics application: The Case / AI Companion Conversation.
///
/// Section 3 & 7: "Everything revolves around a Case, one investigation
/// of a thought, reaction, or recurring pattern."
class CaseModel {
  const CaseModel({
    required this.id,
    this.userId = 'local_user',
    required this.caseNumber,
    required this.title,
    this.conversationMode = ConversationMode.exploreThought,
    required this.createdAt,
    required this.updatedAt,
    required this.currentStage,
    required this.incidentDescription,
    this.chain,
    this.statements = const [],
    this.hypotheses = const [],
    this.findingsSummary,
    this.userConclusion,
    this.emotionTags = const [],
    this.isCompleted = false,
    this.isPausedForSafety = false,
    this.isPrivate = false,
  });

  /// Internal unique ID (UUID).
  final String id;

  /// User identifier for multi-user local isolation.
  final String userId;

  /// Human-readable session identifier (e.g., "SESSION 01", "SESSION 02").
  final String caseNumber;

  /// User-defined or auto-generated concise title.
  final String title;

  /// Active conversational mode for this dialogue.
  final ConversationMode conversationMode;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// The active stage of this investigation.
  final CaseStage currentStage;

  /// Initial incident description in the user's own words.
  final String incidentDescription;

  /// The underlying chain: Trigger -> Thought -> Emotion -> Behavior.
  final ForensicChain? chain;

  /// All recorded statements with their forensic labels (Fact, Assumption, Interpretation).
  final List<Statement> statements;

  /// Alternative explanations proposed during the case.
  final List<Hypothesis> hypotheses;

  /// Structured summary sorting what is observed, assumed, and uncertain.
  final String? findingsSummary;

  /// The user's own final takeaway. Section 2: "The user has the final word."
  final String? userConclusion;

  /// Emotion tags attached to this case.
  final List<String> emotionTags;

  /// Whether the case has completed all stages.
  final bool isCompleted;

  /// Whether this case was paused by the safety interceptor.
  final bool isPausedForSafety;

  /// Whether this case is marked "Private, never shareable" (Section 12 Principle 2).
  /// Private cases are shielded and strictly excluded from Session Brief exports.
  final bool isPrivate;

  CaseModel copyWith({
    String? id,
    String? userId,
    String? caseNumber,
    String? title,
    ConversationMode? conversationMode,
    DateTime? createdAt,
    DateTime? updatedAt,
    CaseStage? currentStage,
    String? incidentDescription,
    ForensicChain? chain,
    List<Statement>? statements,
    List<Hypothesis>? hypotheses,
    String? findingsSummary,
    String? userConclusion,
    List<String>? emotionTags,
    bool? isCompleted,
    bool? isPausedForSafety,
    bool? isPrivate,
  }) {
    return CaseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      caseNumber: caseNumber ?? this.caseNumber,
      title: title ?? this.title,
      conversationMode: conversationMode ?? this.conversationMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentStage: currentStage ?? this.currentStage,
      incidentDescription: incidentDescription ?? this.incidentDescription,
      chain: chain ?? this.chain,
      statements: statements ?? this.statements,
      hypotheses: hypotheses ?? this.hypotheses,
      findingsSummary: findingsSummary ?? this.findingsSummary,
      userConclusion: userConclusion ?? this.userConclusion,
      emotionTags: emotionTags ?? this.emotionTags,
      isCompleted: isCompleted ?? this.isCompleted,
      isPausedForSafety: isPausedForSafety ?? this.isPausedForSafety,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'caseNumber': caseNumber,
        'title': title,
        'conversationMode': conversationMode.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'currentStage': currentStage.name,
        'incidentDescription': incidentDescription,
        'chain': chain?.toJson(),
        'statements': statements.map((s) => s.toJson()).toList(),
        'hypotheses': hypotheses.map((h) => h.toJson()).toList(),
        'findingsSummary': findingsSummary,
        'userConclusion': userConclusion,
        'emotionTags': emotionTags,
        'isCompleted': isCompleted,
        'isPausedForSafety': isPausedForSafety,
        'isPrivate': isPrivate,
      };

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    final rawNumber = json['caseNumber'] as String? ?? 'SESSION 01';
    final digitsMatch = RegExp(r'\d+').firstMatch(rawNumber);
    final num = digitsMatch != null ? int.tryParse(digitsMatch.group(0) ?? '') : null;
    final normalizedNumber = num != null
        ? 'SESSION ${num.toString().padLeft(2, '0')}'
        : (rawNumber.startsWith('CASE ') ? rawNumber.replaceFirst('CASE ', 'SESSION ') : rawNumber);

    ConversationMode parsedMode = ConversationMode.exploreThought;
    final rawMode = json['conversationMode'] as String?;
    if (rawMode != null) {
      parsedMode = ConversationMode.values.firstWhere(
        (m) => m.name == rawMode,
        orElse: () => ConversationMode.exploreThought,
      );
    }

    return CaseModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? 'local_user',
      caseNumber: normalizedNumber,
      title: json['title'] as String? ?? 'Untitled Session',
      conversationMode: parsedMode,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      currentStage: CaseStage.values.firstWhere(
        (s) => s.name == json['currentStage'],
        orElse: () => CaseStage.incident,
      ),
      incidentDescription: json['incidentDescription'] as String? ?? '',
      chain: json['chain'] != null
          ? ForensicChain.fromJson(json['chain'] as Map<String, dynamic>)
          : null,
      statements: (json['statements'] as List<dynamic>?)
              ?.map((e) => Statement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      hypotheses: (json['hypotheses'] as List<dynamic>?)
              ?.map((e) => Hypothesis.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      findingsSummary: json['findingsSummary'] as String?,
      userConclusion: json['userConclusion'] as String?,
      emotionTags: (json['emotionTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      isPausedForSafety: json['isPausedForSafety'] as bool? ?? false,
      isPrivate: json['isPrivate'] as bool? ?? false,
    );
  }
}

