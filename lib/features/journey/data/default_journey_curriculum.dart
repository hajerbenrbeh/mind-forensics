import '../domain/journey_activity.dart';
import '../domain/journey_phase.dart';

/// Pre-populated, clinically grounded curriculum across the 5 flexible journey phases.
class DefaultJourneyCurriculum {
  static List<JourneyActivity> getActivities() {
    return [
      // =========================================================================
      // PHASE 1 — SELF-DISCOVERY
      // =========================================================================
      const JourneyActivity(
        id: 'act_1_1',
        phase: JourneyPhase.phase1SelfDiscovery,
        title: 'The Triad: Thoughts, Emotions, and Actions',
        purpose: 'Distinguish between internal mental narratives, felt bodily emotions, and resulting behaviors.',
        shortExplanation:
            'A thought is not an emotion, and an emotion is not a directive to act. Untangling them provides immediate mental breathing room.',
        guidedInstructions: [
          'Recall a mildly stressful or unsettling event from the past few days.',
          'Identify what your mind immediately thought (the exact words or phrase).',
          'Notice what emotion you felt in that moment (e.g., fear, shame, frustration) and where you felt it in your body.',
          'Notice what action or impulse followed (e.g., checking, withdrawing, rushing).',
        ],
        reflectionQuestions: [
          'What did your mind tell you during that moment?',
          'How did that thought influence your emotional response and behavior?',
          'Can you see a clear separation between the thought and who you are as an observer?',
        ],
      ),
      const JourneyActivity(
        id: 'act_1_2',
        phase: JourneyPhase.phase1SelfDiscovery,
        title: 'Mapping Recurring Thought Themes',
        purpose: 'Recognize automatic thoughts that tend to recur across different situations.',
        shortExplanation:
            'Our minds often run familiar scripts (e.g., "I must not fail", "They think I am incompetent"). Spotting the theme reduces its power.',
        guidedInstructions: [
          'Review the past week and look for situations where tension or distress flared up.',
          'Write down the recurring internal message that seems to accompany that distress.',
          'Reflect on how long this particular theme or narrative has been present in your life.',
        ],
        reflectionQuestions: [
          'What recurring theme or sentence does your mind repeat when stressed?',
          'Does this thought arise in predictable contexts (work, relationships, solitude)?',
        ],
      ),
      const JourneyActivity(
        id: 'act_1_3',
        phase: JourneyPhase.phase1SelfDiscovery,
        title: 'The Somatic Anatomy of Distress',
        purpose: 'Connect cognitive tension with physical sensations to increase emotional self-attunement.',
        shortExplanation:
            'Distress almost always registers somatically—chest constriction, clenched jaw, stomach flutter—before conscious analysis begins.',
        guidedInstructions: [
          'Sit comfortably and take a gentle, neutral breath.',
          'Scan your body from scalp to toes: notice where tension is habitually stored.',
          'Acknowledge any tightness without attempting to force it away immediately.',
        ],
        reflectionQuestions: [
          'Where in your body do you first register stress or anxiety?',
          'What happens when you observe the physical sensation with curiosity rather than alarm?',
        ],
      ),
      const JourneyActivity(
        id: 'act_1_4',
        phase: JourneyPhase.phase1SelfDiscovery,
        title: 'Exploring Personal Strengths & Resilience',
        purpose: 'Identify existing coping mechanisms and personal strengths that have supported you through past adversity.',
        shortExplanation:
            'Self-discovery is not merely inventorying difficulties; it is recognizing the genuine endurance and insight you already possess.',
        guidedInstructions: [
          'Think of a significant challenge you endured in the past.',
          'Identify what personal quality, value, or decision helped you navigate it.',
          'Acknowledge that this inner resilience remains part of you today.',
        ],
        reflectionQuestions: [
          'What personal qualities have helped you navigate previous difficult chapters?',
          'How can you bring that same patience or strength to your current journey?',
        ],
      ),

      // =========================================================================
      // PHASE 2 — UNDERSTANDING PATTERNS
      // =========================================================================
      const JourneyActivity(
        id: 'act_2_1',
        phase: JourneyPhase.phase2UnderstandingPatterns,
        title: 'Decentering from Automatic Triggers',
        purpose: 'Identify specific environmental, relational, or internal cues that provoke distress.',
        shortExplanation:
            'A trigger is simply an activating event. Understanding the link between the trigger and the immediate interpretation breaks automatic reactions.',
        guidedInstructions: [
          'Choose a recent situation where you felt an abrupt spike in anxiety or frustration.',
          'Separate the raw, objective facts of what happened from your immediate interpretation.',
          'Ask: What was the exact moment the shift occurred?',
        ],
        reflectionQuestions: [
          'What was the specific observable trigger in that situation?',
          'What assumption or story did your mind instantaneously construct around it?',
        ],
      ),
      const JourneyActivity(
        id: 'act_2_2',
        phase: JourneyPhase.phase2UnderstandingPatterns,
        title: 'Unpacking Avoidance and Repetitive Behaviors',
        purpose: 'Examine how short-term relief can inadvertently maintain long-term distress.',
        shortExplanation:
            'Avoidance, procrastination, reassurance-seeking, or compulsive checking provide temporary calm, but reinforce the brain’s false alarm.',
        guidedInstructions: [
          'Identify a behavior you regularly engage in to ease immediate discomfort (e.g., avoiding a message, checking repeatedly).',
          'Notice what relief it provides in the first 5 minutes.',
          'Notice what happens to your anxiety or self-trust over the next 24 hours.',
        ],
        reflectionQuestions: [
          'What coping behavior gives quick relief but prolongs the underlying distress?',
          'What might happen if you gently sat with the discomfort for two minutes before reacting?',
        ],
      ),
      const JourneyActivity(
        id: 'act_2_3',
        phase: JourneyPhase.phase2UnderstandingPatterns,
        title: 'The Maintenance Cycle Exploration',
        purpose: 'Map how thoughts, physical reactions, and behavioral choices reinforce one another in a loop.',
        shortExplanation:
            'Distress is rarely linear. It operates as a feedback loop: Thought -> Arousal -> Behavior -> Reinforced Thought.',
        guidedInstructions: [
          'Trace a recent experience through each step of the loop.',
          'Notice where in the loop you have the greatest agency to introduce an intentional pause.',
        ],
        reflectionQuestions: [
          'How does your behavioral response feed back into what you believe about yourself or others?',
          'At what point in the cycle is it easiest for you to notice what is happening?',
        ],
      ),

      // =========================================================================
      // PHASE 3 — PSYCHOLOGICAL AWARENESS
      // =========================================================================
      const JourneyActivity(
        id: 'act_3_1',
        phase: JourneyPhase.phase3PsychologicalAwareness,
        title: 'Deconstructing Cognitive Distortions without Judgment',
        purpose: 'Learn to spot thinking traps (e.g., Mind Reading, Catastrophizing, All-or-Nothing) with analytical compassion.',
        shortExplanation:
            'Cognitive distortions are evolutionary shortcuts designed to protect us from perceived threats. They are not character flaws.',
        guidedInstructions: [
          'Review the common thinking traps: Mind Reading, Catastrophizing, All-or-Nothing, Emotional Reasoning, Mental Filtering.',
          'Identify which trap your mind visits most frequently.',
          'Re-frame the thought using exploratory hypothesis language: "My mind is running a catastrophizing scenario right now."',
        ],
        reflectionQuestions: [
          'Which cognitive distortion felt most familiar to you this week?',
          'How does your emotional intensity shift when you label the thought as an automatic pattern rather than a fact?',
        ],
      ),
      const JourneyActivity(
        id: 'act_3_2',
        phase: JourneyPhase.phase3PsychologicalAwareness,
        title: 'Demystifying Intrusive Thoughts',
        purpose: 'Understand that unwanted, alarming, or repetitive thoughts do not reflect your character, desire, or identity.',
        shortExplanation:
            'The brain produces thousands of random thoughts daily. Struggling to suppress an intrusive thought only amplifies its frequency.',
        guidedInstructions: [
          'Notice an unwanted intrusive thought when it arises.',
          'Mentally say: "I notice an intrusive thought has appeared. It is mental noise, not an intention or reality."',
          'Allow the thought to exist in awareness without trying to argue with it, verify it, or neutralize it.',
        ],
        reflectionQuestions: [
          'What happens when you treat an intrusive thought like a passerby on the street rather than an urgent crisis?',
          'Can you allow uncertainty to exist without demanding absolute proof right now?',
        ],
      ),
      const JourneyActivity(
        id: 'act_3_3',
        phase: JourneyPhase.phase3PsychologicalAwareness,
        title: 'Nervous System Arousal & The Window of Tolerance',
        purpose: 'Understand how physiological activation affects your perception of danger and cognitive clarity.',
        shortExplanation:
            'When autonomic arousal spikes, the prefrontal cortex temporarily takes a backseat to survival impulses. What feels like an emergency is often physiological arousal.',
        guidedInstructions: [
          'Reflect on the difference between being within your calm baseline vs hyperaroused (racing thoughts, tension) or hypoaroused (numbness, lethargy).',
          'Notice that during high arousal, all interpretations become more catastrophic and extreme.',
        ],
        reflectionQuestions: [
          'What signs tell you that your nervous system is in fight-or-flight mode?',
          'Why is it helpful to delay making major decisions or conclusions until physiological arousal has settled?',
        ],
      ),

      // =========================================================================
      // PHASE 4 — COPING AND DEVELOPMENT
      // =========================================================================
      const JourneyActivity(
        id: 'act_4_1',
        phase: JourneyPhase.phase4CopingAndDevelopment,
        title: 'Forensic CBT Thought Record',
        purpose: 'Systematically cross-examine an automatic thought with concrete, observable evidence for and against.',
        shortExplanation:
            'Put the thought on trial. Distinguish verifiable facts from emotional assumptions and arrive at a grounded, balanced reframe.',
        guidedInstructions: [
          'Write down the distressing automatic thought.',
          'List only facts that support it (what a video camera would record).',
          'List all observable facts and counter-evidence that contradict it.',
          'Synthesize a realistic, balanced perspective based on the full evidence.',
        ],
        reflectionQuestions: [
          'What was the balanced, grounded reframe you reached?',
          'How did your emotional intensity (1–10) change before and after this cross-examination?',
        ],
      ),
      const JourneyActivity(
        id: 'act_4_2',
        phase: JourneyPhase.phase4CopingAndDevelopment,
        title: 'Somatic Grounding: 5-4-3-2-1 Sensory Anchor',
        purpose: 'Use sensory engagement to interrupt rumination and re-orient attention to the present moment.',
        shortExplanation:
            'Directing attention intentionally toward external sensory data down-regulates amygdala activity and returns you to safety.',
        guidedInstructions: [
          'Look around and name 5 things you can visually observe.',
          'Notice 4 physical textures or contact points you can physically feel.',
          'Listen for 3 distinct sounds in your environment.',
          'Identify 2 scents or air qualities.',
          'Acknowledge 1 positive or neutral truth about this present second.',
        ],
        reflectionQuestions: [
          'How does your mental state shift when you anchor into the immediate physical environment?',
          'In what situations would this practice serve as a quick stabilizer for you?',
        ],
      ),
      const JourneyActivity(
        id: 'act_4_3',
        phase: JourneyPhase.phase4CopingAndDevelopment,
        title: 'Gradual Micro-Behavioral Activation',
        purpose: 'Take a small, manageable, values-aligned action even when motivation or mood is low.',
        shortExplanation:
            'Action often precedes motivation, not the other way around. Breaking tasks into micro-steps builds self-efficacy.',
        guidedInstructions: [
          'Choose an activity you have been putting off due to avoidance or fatigue.',
          'Reduce it to a 2-minute micro-action (e.g., opening a document, putting on shoes, stepping outside).',
          'Perform the micro-step with zero expectation of doing more.',
        ],
        reflectionQuestions: [
          'What micro-action did you accomplish?',
          'What did it feel like to act in alignment with your values regardless of temporary mood?',
        ],
      ),

      // =========================================================================
      // PHASE 5 — PERSONAL GROWTH AND MAINTENANCE
      // =========================================================================
      const JourneyActivity(
        id: 'act_5_1',
        phase: JourneyPhase.phase5PersonalGrowthAndMaintenance,
        title: 'Personalized Compassionate Coping Protocol',
        purpose: 'Synthesize your discoveries into a personal resilience guide for challenging days.',
        shortExplanation:
            'A clear plan created during calm moments acts as a lifeline when cognitive fog or intense distress takes over.',
        guidedInstructions: [
          'List 2 early warning signs that tell you distress is beginning to build.',
          'List 2 grounding techniques or practices that have genuinely helped you.',
          'Identify who you can contact or what boundaries you need to maintain.',
        ],
        reflectionQuestions: [
          'What are your primary early warning signs of escalating distress?',
          'What is the single most effective grounding step you can take when overwhelmed?',
        ],
      ),
      const JourneyActivity(
        id: 'act_5_2',
        phase: JourneyPhase.phase5PersonalGrowthAndMaintenance,
        title: 'Navigating Setbacks Without Self-Blame',
        purpose: 'Re-frame setbacks as natural information points rather than evidence of failure.',
        shortExplanation:
            'Progress in psychological development is nonlinear. Experiencing old thought patterns is not a relapse; it is an invitation to practice.',
        guidedInstructions: [
          'Think of a moment where you slipped back into an old coping mechanism or intense reaction.',
          'Treat yourself with the same gentle patience you would offer a dear friend.',
          'Ask: What can this experience teach me about what I needed in that moment?',
        ],
        reflectionQuestions: [
          'What compassion or understanding can you offer yourself regarding recent difficulties?',
          'How can you maintain your practices without perfectionism?',
        ],
      ),
      const JourneyActivity(
        id: 'act_5_3',
        phase: JourneyPhase.phase5PersonalGrowthAndMaintenance,
        title: 'Reflecting on Internal Shifts & Continuity',
        purpose: 'Review past reflections to observe subtle, meaningful shifts in self-awareness over time.',
        shortExplanation:
            'Because growth happens in small daily micro-adjustments, reviewing past reflections makes your expanding insight tangible.',
        guidedInstructions: [
          'Look back over your completed reflections, case files, or daily notes.',
          'Notice the difference in how you view automatic thoughts now compared to when you started.',
          'Acknowledge the quiet agency you have developed.',
        ],
        reflectionQuestions: [
          'What is the most significant realization you have discovered about your mind?',
          'How will you continue exploring with curiosity and self-compassion going forward?',
        ],
      ),
    ];
  }
}

