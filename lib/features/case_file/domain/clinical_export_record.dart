/// A recorded entry of an exported Clinical Session Brief (Section 12 Principle 5).
///
/// Ensures a visible history of what was exported, with whom (or what note),
/// and when, without any automatic data transmission.
class ClinicalExportRecord {
  const ClinicalExportRecord({
    required this.id,
    required this.exportedAt,
    required this.sessionNumbers,
    this.recipientOrNote = '',
  });

  final String id;
  final DateTime exportedAt;
  final List<String> sessionNumbers;
  final String recipientOrNote;

  Map<String, dynamic> toJson() => {
        'id': id,
        'exportedAt': exportedAt.toIso8601String(),
        'sessionNumbers': sessionNumbers,
        'recipientOrNote': recipientOrNote,
      };

  factory ClinicalExportRecord.fromJson(Map<String, dynamic> json) {
    return ClinicalExportRecord(
      id: json['id'] as String,
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ?? DateTime.now(),
      sessionNumbers: (json['sessionNumbers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      recipientOrNote: json['recipientOrNote'] as String? ?? '',
    );
  }
}

