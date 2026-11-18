// Pure deterministic business logic for Debate Rubric, English Rubric & Quiz Tournaments.
// Shared between Supabase Edge Functions and automated Node/Deno test suites.

export interface DebateRubricResult {
  score_relevance: number;
  score_logical_reasoning: number;
  score_depth_analysis: number;
  score_arguments_examples: number;
  score_critical_nuance: number;
  score_clarity: number;
  total_score: number;
  detected_contradictions: string[];
  unsupported_claims: string[];
  logical_fallacies: string[];
  recognized_nuances: string[];
  relevant_examples: string[];
  score_explanation: string;
  improvement_recommendations: string[];
  verified_references: string[];
  factual_vs_interpretive_notes?: string;
}

export interface EnglishRubricResult {
  score_grammar: number;
  score_vocabulary: number;
  score_fluency: number;
  score_intelligibility: number;
  score_coherence: number;
  total_score: number;
  identified_errors: Array<{ original: string; correction: string; explanation: string }>;
  corrected_sentences: string[];
  natural_expressions: string[];
  suggested_vocabulary: Array<{ word: string; cefr: string; example: string }>;
  personalized_exercises: Array<{ prompt: string; answer: string }>;
}

function clamp(val: unknown, min: number, max: number): number {
  const num = typeof val === "number" && Number.isFinite(val) ? val : 0;
  return Number(Math.max(min, Math.min(max, num)).toFixed(2));
}

function asStringArray(val: unknown): string[] {
  return Array.isArray(val) ? val.map((v) => String(v)).filter(Boolean) : [];
}

/**
 * Validates and normalizes AI-returned debate evaluation scores so the 100-pt
 * rubric invariants always hold:
 *   Relevance (20) + Logic (25) + Depth (20) + Examples (15) + Nuance (10) + Clarity (10) = 100
 */
export function normalizeDebateRubric(
  raw: Partial<DebateRubricResult>,
): DebateRubricResult {
  const score_relevance = clamp(raw.score_relevance, 0, 20);
  const score_logical_reasoning = clamp(raw.score_logical_reasoning, 0, 25);
  const score_depth_analysis = clamp(raw.score_depth_analysis, 0, 20);
  const score_arguments_examples = clamp(raw.score_arguments_examples, 0, 15);
  const score_critical_nuance = clamp(raw.score_critical_nuance, 0, 10);
  const score_clarity = clamp(raw.score_clarity, 0, 10);

  const total_score = Number(
    (
      score_relevance +
      score_logical_reasoning +
      score_depth_analysis +
      score_arguments_examples +
      score_critical_nuance +
      score_clarity
    ).toFixed(2),
  );

  return {
    score_relevance,
    score_logical_reasoning,
    score_depth_analysis,
    score_arguments_examples,
    score_critical_nuance,
    score_clarity,
    total_score,
    detected_contradictions: asStringArray(raw.detected_contradictions),
    unsupported_claims: asStringArray(raw.unsupported_claims),
    logical_fallacies: asStringArray(raw.logical_fallacies),
    recognized_nuances: asStringArray(raw.recognized_nuances),
    relevant_examples: asStringArray(raw.relevant_examples),
    score_explanation:
      typeof raw.score_explanation === "string" && raw.score_explanation.trim()
        ? raw.score_explanation.trim()
        : "Évaluation structurée selon la grille à 100 points.",
    improvement_recommendations: asStringArray(raw.improvement_recommendations),
    verified_references: asStringArray(raw.verified_references),
    factual_vs_interpretive_notes:
      typeof raw.factual_vs_interpretive_notes === "string"
        ? raw.factual_vs_interpretive_notes
        : undefined,
  };
}

/**
 * Normalizes AI English speaking evaluation (100-pt accent-fair rubric: 5 x 20).
 */
export function normalizeEnglishRubric(
  raw: Partial<EnglishRubricResult>,
): EnglishRubricResult {
  const score_grammar = clamp(raw.score_grammar, 0, 20);
  const score_vocabulary = clamp(raw.score_vocabulary, 0, 20);
  const score_fluency = clamp(raw.score_fluency, 0, 20);
  const score_intelligibility = clamp(raw.score_intelligibility, 0, 20);
  const score_coherence = clamp(raw.score_coherence, 0, 20);
  const total_score = Number(
    (
      score_grammar +
      score_vocabulary +
      score_fluency +
      score_intelligibility +
      score_coherence
    ).toFixed(2),
  );

  return {
    score_grammar,
    score_vocabulary,
    score_fluency,
    score_intelligibility,
    score_coherence,
    total_score,
    identified_errors: Array.isArray(raw.identified_errors)
      ? raw.identified_errors
      : [],
    corrected_sentences: asStringArray(raw.corrected_sentences),
    natural_expressions: asStringArray(raw.natural_expressions),
    suggested_vocabulary: Array.isArray(raw.suggested_vocabulary)
      ? raw.suggested_vocabulary
      : [],
    personalized_exercises: Array.isArray(raw.personalized_exercises)
      ? raw.personalized_exercises
      : [],
  };
}

export interface BracketMatch {
  matchIndex: number;
  round: number;
  playerA: string | null;
  playerB: string | null;
  winnerId: string | null;
}

/**
 * Generates deterministic single-elimination tournament bracket for 2, 8, 16, or 32 players.
 */
export function generateTournamentBracket(
  participantIds: string[],
  bracketSize: 2 | 8 | 16 | 32,
): { rounds: BracketMatch[][] } {
  const padded: Array<string | null> = [...participantIds.slice(0, bracketSize)];
  while (padded.length < bracketSize) {
    padded.push(null); // Bye slot if bracket isn't full yet
  }

  const totalRounds = Math.log2(bracketSize);
  const rounds: BracketMatch[][] = [];

  // Round 1 pairing: standard high-vs-low seeding (1 vs N, 2 vs N-1...)
  const round1: BracketMatch[] = [];
  for (let i = 0; i < bracketSize / 2; i++) {
    const playerA = padded[i];
    const playerB = padded[bracketSize - 1 - i];
    const autoWinner =
      playerA && !playerB ? playerA : !playerA && playerB ? playerB : null;
    round1.push({
      matchIndex: i,
      round: 1,
      playerA,
      playerB,
      winnerId: autoWinner,
    });
  }
  rounds.push(round1);

  for (let r = 2; r <= totalRounds; r++) {
    const prevRound = rounds[r - 2];
    const currentRound: BracketMatch[] = [];
    for (let i = 0; i < prevRound.length / 2; i++) {
      const m1 = prevRound[i * 2];
      const m2 = prevRound[i * 2 + 1];
      currentRound.push({
        matchIndex: i,
        round: r,
        playerA: m1.winnerId,
        playerB: m2.winnerId,
        winnerId: null,
      });
    }
    rounds.push(currentRound);
  }

  return { rounds };
}

/**
 * Server-side quiz answer scoring with speed bonus & anti-cheat verification.
 */
export function calculateQuizScore(params: {
  isCorrect: boolean;
  basePoints: number;
  timeLimitSeconds: number;
  responseTimeMs: number;
  focusLostCount: number;
  maxFocusLosses?: number;
}): { pointsAwarded: number; flaggedSuspicious: boolean } {
  const maxFocus = params.maxFocusLosses ?? 2;
  const maxMs = params.timeLimitSeconds * 1000;
  // Detect impossible human speed (< 250ms) or excessive tab switching
  const flaggedSuspicious =
    params.focusLostCount > maxFocus ||
    params.responseTimeMs < 250 ||
    params.responseTimeMs > maxMs + 1500;

  if (!params.isCorrect || flaggedSuspicious) {
    return { pointsAwarded: 0, flaggedSuspicious };
  }

  const clampedTime = Math.min(Math.max(params.responseTimeMs, 250), maxMs);
  const speedRatio = 1 - clampedTime / maxMs;
  const speedBonus = Math.round(params.basePoints * 0.35 * speedRatio);
  return {
    pointsAwarded: params.basePoints + speedBonus,
    flaggedSuspicious: false,
  };
}
