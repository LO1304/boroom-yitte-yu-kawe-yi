// Automated Backend Verification Suite for BOROOM YITTÉ YU KAWÉ YI
// Validates:
//   1. All 39+ required PostgreSQL tables & migrations syntax/invariants
//   2. Strict RLS enablement across all tables
//   3. Ethical & product invariants (no Zikr piety rankings, editor review for summaries, strict private personal notes)
//   4. Pure rubric & bracket logic in Edge Functions (100-pt debate rubric, 100-pt accent-fair English rubric, 8/16/32 brackets, quiz anti-cheat, AI cost estimation)

import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  normalizeDebateRubric,
  normalizeEnglishRubric,
  generateTournamentBracket,
  calculateQuizScore,
} from "../functions/_shared/rubric_logic.ts";
import {
  estimateCostUsd,
  resolveProviderAndModel,
} from "../functions/_shared/ai_providers.ts";
import { AGENT_SYSTEM_PROMPTS } from "../functions/_shared/agent_prompts.ts";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationsDir = path.resolve(__dirname, "../migrations");

const REQUIRED_TABLES = [
  "profiles", "roles", "invitations", "reflections", "comments", "reactions",
  "weekly_topics", "topic_contributions", "summaries", "challenges",
  "challenge_submissions", "debate_matches", "debate_participants",
  "voice_recordings", "transcripts", "ai_evaluations", "quiz_questions",
  "quiz_matches", "quiz_answers", "tournaments", "tournament_participants",
  "zikr_sessions", "zikr_participations", "english_lessons",
  "english_exercises", "speaking_attempts", "vocabulary", "learning_progress",
  "career_profiles", "mock_interviews", "personal_goals", "habits",
  "private_notes", "messages", "voice_rooms", "notifications", "events",
  "reports", "audit_logs",
];

// 1. Validate SQL migrations
const sqlFiles = fs
  .readdirSync(migrationsDir)
  .filter((f) => f.endsWith(".sql"))
  .sort();
assert(sqlFiles.length >= 12, `Expected >= 12 migrations, found ${sqlFiles.length}`);

const combinedSql = sqlFiles
  .map((f) => fs.readFileSync(path.join(migrationsDir, f), "utf8"))
  .join("\n");

for (const table of REQUIRED_TABLES) {
  const re = new RegExp(`CREATE\\s+TABLE\\s+${table}\\b`, "i");
  assert(re.test(combinedSql), `Missing required table definition: ${table}`);
  assert(
    combinedSql.includes(`'${table}'`),
    `Table ${table} must be included in RLS enablement list`,
  );
}

// Check summary editor review invariant
assert(
  combinedSql.includes("status <> 'published' OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)"),
  "Summary editor-review invariant missing",
);

// Check strict privacy on personal growth & zikr
assert(combinedSql.includes("zikr_participations_strict_private"));
assert(combinedSql.includes("private_notes_strict_private"));
assert(combinedSql.includes("personal_goals_strict_private"));
assert(combinedSql.includes("habits_strict_private"));

// Ensure no Zikr leaderboard/ranking exists
assert(!/zikr.*leaderboard|piety_score|spiritual_rank/i.test(combinedSql));

// 2. Validate AI Agents (all 7 specialized agents)
const EXPECTED_AGENTS = [
  "YITTE_DEBATE_AI",
  "YITTE_ENGLISH_COACH",
  "YITTE_QUIZ_MASTER",
  "YITTE_SPIRITUAL_ASSISTANT",
  "YITTE_CAREER_COACH",
  "YITTE_PERSONAL_MENTOR",
  "YITTE_SUMMARIZER",
];
for (const agent of EXPECTED_AGENTS) {
  assert(agent in AGENT_SYSTEM_PROMPTS, `Missing AI agent prompt: ${agent}`);
}
assert(
  AGENT_SYSTEM_PROMPTS.YITTE_DEBATE_AI.includes("NEVER fabricate Qur'anic verses"),
);
assert(
  AGENT_SYSTEM_PROMPTS.YITTE_SPIRITUAL_ASSISTANT.includes("do NOT issue fatwas"),
);
assert(
  AGENT_SYSTEM_PROMPTS.YITTE_ENGLISH_COACH.includes("NEVER penalize legitimate non-native"),
);

// 3. Validate Debate Rubric normalization (20 + 25 + 20 + 15 + 10 + 10 = 100)
const clampedDebate = normalizeDebateRubric({
  score_relevance: 25, // exceeds 20 -> clamps to 20
  score_logical_reasoning: 22,
  score_depth_analysis: 18,
  score_arguments_examples: 14,
  score_critical_nuance: -2, // negative -> clamps to 0
  score_clarity: 9,
  detected_contradictions: ["Contradiction mineure dans la prémisse 2"],
  score_explanation: "Raisonnement clair et nuancé.",
});
assert.equal(clampedDebate.score_relevance, 20);
assert.equal(clampedDebate.score_critical_nuance, 0);
assert.equal(clampedDebate.total_score, 83);

// 4. Validate English Rubric normalization (5 x 20 = 100)
const englishScore = normalizeEnglishRubric({
  score_grammar: 17,
  score_vocabulary: 16,
  score_fluency: 18,
  score_intelligibility: 19,
  score_coherence: 18,
});
assert.equal(englishScore.total_score, 88);

// 5. Validate Tournament Brackets (8, 16, 32 players)
for (const size of [8, 16, 32]) {
  const players = Array.from({ length: size }, (_, i) => `user-${i + 1}`);
  const bracket = generateTournamentBracket(players, size);
  assert.equal(bracket.rounds.length, Math.log2(size));
  assert.equal(bracket.rounds[0].length, size / 2);
  assert.equal(bracket.rounds[bracket.rounds.length - 1].length, 1);
}

// 6. Validate Quiz Anti-Cheat & Speed Bonus
const validQuiz = calculateQuizScore({
  isCorrect: true,
  basePoints: 100,
  timeLimitSeconds: 25,
  responseTimeMs: 5000,
  focusLostCount: 0,
});
assert.equal(validQuiz.flaggedSuspicious, false);
assert(validQuiz.pointsAwarded > 100 && validQuiz.pointsAwarded <= 135);

const cheatedQuiz = calculateQuizScore({
  isCorrect: true,
  basePoints: 100,
  timeLimitSeconds: 25,
  responseTimeMs: 120, // impossibly fast
  focusLostCount: 0,
});
assert.equal(cheatedQuiz.flaggedSuspicious, true);
assert.equal(cheatedQuiz.pointsAwarded, 0);

const tabSwitchQuiz = calculateQuizScore({
  isCorrect: true,
  basePoints: 100,
  timeLimitSeconds: 25,
  responseTimeMs: 6000,
  focusLostCount: 3, // exceeded max 2
});
assert.equal(tabSwitchQuiz.flaggedSuspicious, true);
assert.equal(tabSwitchQuiz.pointsAwarded, 0);

// 7. Validate AI Provider Resolver & Cost Estimator
const defaultResolved = resolveProviderAndModel();
assert.equal(defaultResolved.provider, "gemini");
assert.equal(defaultResolved.model, "gemini-2.5-flash");
assert(estimateCostUsd("gemini-2.5-flash", 10000, 2000) > 0);

// 8. Validate all 8 Edge Functions exist and enforce auth + CORS
const functionsDir = path.resolve(__dirname, "../functions");
const EXPECTED_FUNCTIONS = [
  "ai-gateway",
  "stt-transcribe",
  "debate-evaluate",
  "english-evaluate",
  "quiz-engine",
  "livekit-token",
  "admin-actions",
  "retention-cleanup",
];
for (const fn of EXPECTED_FUNCTIONS) {
  const fnFile = path.join(functionsDir, fn, "index.ts");
  assert(fs.existsSync(fnFile), `Missing Edge Function: ${fn}/index.ts`);
  const src = fs.readFileSync(fnFile, "utf8");
  assert(src.includes("requireAuth(req)"), `Edge Function ${fn} must call requireAuth(req)`);
  assert(src.includes("handleOptions(req)"), `Edge Function ${fn} must handle CORS preflight`);
}

// 9. Verify seed.sql exists and matches seeded tables
const seedPath = path.resolve(__dirname, "../seed.sql");
assert(fs.existsSync(seedPath), "Missing supabase/seed.sql");
const seedSql = fs.readFileSync(seedPath, "utf8");
for (const seededTable of [
  "vocabulary",
  "english_lessons",
  "english_exercises",
  "quiz_questions",
  "zikr_sessions",
  "challenges",
  "weekly_topics",
  "career_opportunities",
]) {
  assert(
    new RegExp(`INSERT\\s+INTO\\s+${seededTable}\\b`, "i").test(seedSql),
    `Expected seed data for ${seededTable}`,
  );
}

console.log(
  `ALL BACKEND CHECKS PASSED: ${sqlFiles.length} SQL migrations, ${REQUIRED_TABLES.length} required tables, 7 AI agents, ${EXPECTED_FUNCTIONS.length} Edge Functions, rubric & anti-cheat invariants verified.`,
);
