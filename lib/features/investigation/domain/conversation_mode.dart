/// The six dedicated conversational modes for the AI Psychological Companion.
///
/// Designed to offer clinically informed, paced, and supportive interaction
/// based on the user's immediate state.
enum ConversationMode {
  exploreThought,
  understandEmotion,
  psychologicalAnalysis,
  guidedReflection,
  justTalk,
  grounding;

  String get displayName {
    switch (this) {
      case ConversationMode.exploreThought:
        return 'Explore a Thought';
      case ConversationMode.understandEmotion:
        return 'Understand an Emotion';
      case ConversationMode.psychologicalAnalysis:
        return 'Psychological Analysis';
      case ConversationMode.guidedReflection:
        return 'Guided Reflection';
      case ConversationMode.justTalk:
        return 'Just Talk';
      case ConversationMode.grounding:
        return 'Grounding';
    }
  }

  String get localizedArabicName {
    switch (this) {
      case ConversationMode.exploreThought:
        return 'استكشاف فكرة';
      case ConversationMode.understandEmotion:
        return 'فهم شعور';
      case ConversationMode.psychologicalAnalysis:
        return 'تحليل نفسي واعي';
      case ConversationMode.guidedReflection:
        return 'تأمل موجّه';
      case ConversationMode.justTalk:
        return 'حديث حر وطبيعي';
      case ConversationMode.grounding:
        return 'تثبيت وتهدئة (Grounding)';
    }
  }

  String get localizedFrenchName {
    switch (this) {
      case ConversationMode.exploreThought:
        return 'Explorer une Pensée';
      case ConversationMode.understandEmotion:
        return 'Comprendre une Émotion';
      case ConversationMode.psychologicalAnalysis:
        return 'Analyse Psychologique';
      case ConversationMode.guidedReflection:
        return 'Réflexion Guidée';
      case ConversationMode.justTalk:
        return 'Conversation Libre';
      case ConversationMode.grounding:
        return 'Ancrage Somatique';
    }
  }

  String get description {
    switch (this) {
      case ConversationMode.exploreThought:
        return 'Examine a specific thought, what triggered it, and what you believe it means.';
      case ConversationMode.understandEmotion:
        return 'Identify what you feel, explore emotional intensity, and discover what your emotion is communicating.';
      case ConversationMode.psychologicalAnalysis:
        return 'Carefully explore possible connections across your experiences, themes, and behavioral patterns.';
      case ConversationMode.guidedReflection:
        return 'A structured, flexible step-by-step reflection through what happened, thoughts, and responses.';
      case ConversationMode.justTalk:
        return 'Unrestricted, natural conversation with no compulsory exercises or analysis.';
      case ConversationMode.grounding:
        return 'Gentle somatic anchoring and breath support when feeling overwhelmed or disconnected.';
    }
  }

  String get localizedArabicDescription {
    switch (this) {
      case ConversationMode.exploreThought:
        return 'فحص فكرة معينة، محفزاتها، وماذا تعني لك بدون حكم مسبق.';
      case ConversationMode.understandEmotion:
        return 'استكشاف مشاعرك، حدتها الجسدية، وما تحاول إيصاله إليك.';
      case ConversationMode.psychologicalAnalysis:
        return 'تحليل الروابط المحتملة بين التجارب، المحفزات، والأنماط المتكررة.';
      case ConversationMode.guidedReflection:
        return 'تأمل منظم ومرن خطوة بخطوة لما حدث، أفكارك، واستجاباتك.';
      case ConversationMode.justTalk:
        return 'حديث حر وتلقائي بدون تمارين أو أسئلة إجبارية.';
      case ConversationMode.grounding:
        return 'تثبيت حسي وتنفس واعٍ عند الشعور بالإرهاق أو التشتت.';
    }
  }

  String get localizedFrenchDescription {
    switch (this) {
      case ConversationMode.exploreThought:
        return 'Examiner une pensée spécifique, son déclencheur et sa signification.';
      case ConversationMode.understandEmotion:
        return 'Identifier votre émotion, son intensité et ce qu’elle communique.';
      case ConversationMode.psychologicalAnalysis:
        return 'Explorer prudemment les liens entre vos expériences et schémas récurrents.';
      case ConversationMode.guidedReflection:
        return 'Une réflexion structurée et flexible : faits, pensées et réactions.';
      case ConversationMode.justTalk:
        return 'Échange libre et naturel, sans exercice obligatoire ni analyse imposée.';
      case ConversationMode.grounding:
        return 'Ancrage somatique doux et respiration pour apaiser le débordement.';
    }
  }

  String get openingQuestion {
    switch (this) {
      case ConversationMode.exploreThought:
        return 'Is there a thought that has been occupying your mind lately?';
      case ConversationMode.understandEmotion:
        return 'What are you feeling right now, and what does it feel like in your body?';
      case ConversationMode.psychologicalAnalysis:
        return 'What recurring patterns, themes, or reactions would you like to explore together?';
      case ConversationMode.guidedReflection:
        return 'Let us take a step back together. What happened recently that you would like to reflect on?';
      case ConversationMode.justTalk:
        return 'I am here with you. What would you like to talk about today?';
      case ConversationMode.grounding:
        return 'Let us take a quiet pause together. Would you like to try a simple, gentle grounding exercise?';
    }
  }

  List<String> get suggestedStarters {
    switch (this) {
      case ConversationMode.exploreThought:
        return [
          'There is something I cannot stop thinking about.',
          'I feel like I made a terrible mistake.',
          'I keep doubting myself even when things go well.',
          'Help me separate fact from assumption here.',
        ];
      case ConversationMode.understandEmotion:
        return [
          'I feel a heavy tightness in my chest today.',
          'I want to understand why I feel this way.',
          'My emotions shifted suddenly and I feel unsettled.',
          'I feel numb and disconnected from everything.',
        ];
      case ConversationMode.psychologicalAnalysis:
        return [
          'Can we explore a recurring pattern in my reactions?',
          'I noticed I always avoid situations when stressed.',
          'Help me understand the link between my mood and thoughts.',
          'Could there be a connection between my past and this habit?',
        ];
      case ConversationMode.guidedReflection:
        return [
          'Help me organize what is happening in my mind.',
          'A difficult conversation happened today.',
          'I want to review how I reacted to a challenge.',
          'Guide me through understanding this experience.',
        ];
      case ConversationMode.justTalk:
        return [
          'I need someone to listen without judging.',
          'Today felt long and exhausting.',
          'I have a lot on my mind but nowhere to start.',
          'Just checking in and exploring how I feel.',
        ];
      case ConversationMode.grounding:
        return [
          'Guide me through a 5-4-3-2-1 sensory grounding.',
          'I feel overwhelmed and need to slow down.',
          'Help me regulate my breathing.',
          'I feel disconnected from my surroundings.',
        ];
    }
  }

  String get shortGuidancePrompt {
    switch (this) {
      case ConversationMode.exploreThought:
        return 'ACTIVE MODE: Explore a Thought. Help the user gently examine a specific automatic thought. Separate narrative from tangible evidence without dismissing feelings.';
      case ConversationMode.understandEmotion:
        return 'ACTIVE MODE: Understand an Emotion. Help identify nuances in their emotional state, validate physiological activation, and explore its emotional context.';
      case ConversationMode.psychologicalAnalysis:
        return 'ACTIVE MODE: Psychological Analysis. Explore non-judgmental connections between triggers, automatic appraisals, and behavioral impulses. Never diagnose.';
      case ConversationMode.guidedReflection:
        return 'ACTIVE MODE: Guided Reflection. Lead the user step-by-step through a thoughtful, structured psychological reflection with paced open-ended inquiries.';
      case ConversationMode.justTalk:
        return 'ACTIVE MODE: Just Talk. Maintain natural, warm, empathetic dialogue without forcing formal exercises, homework, or structured interrogations.';
      case ConversationMode.grounding:
        return 'ACTIVE MODE: Grounding. Offer gentle sensory anchoring (5-4-3-2-1), somatic breath awareness, and present-moment safety to settle acute overwhelm.';
    }
  }
}

