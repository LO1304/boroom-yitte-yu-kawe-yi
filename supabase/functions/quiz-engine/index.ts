// YITTÉ QUIZ ARENA Engine — Server-Side Answer Validation, Anti-Cheat,
// Tournament Bracket Seeding (8/16/32) & YITTE_QUIZ_MASTER question generation.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { handleOptions, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import {
  calculateQuizScore,
  generateTournamentBracket,
} from "../_shared/rubric_logic.ts";

serve(async (req: Request) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const ctx = await requireAuth(req);
    const body = await req.json();
    const action = body.action as string;

    if (action === "submit_answer") {
      const {
        match_id,
        question_id,
        selected_option_index,
        written_answer,
        client_response_time_ms,
        focus_lost_count = 0,
      } = body;

      const { data: question } = await ctx.supabaseAdminClient
        .from("quiz_questions")
        .select("*")
        .eq("id", question_id)
        .single();

      if (!question) return errorResponse("Question not found.", 404);

      const { data: match } = await ctx.supabaseAdminClient
        .from("quiz_matches")
        .select("*")
        .eq("id", match_id)
        .single();

      if (!match) return errorResponse("Match not found.", 404);

      // Server-side timing audit when question_started_at is recorded
      let effectiveMs = Number(client_response_time_ms ?? 5000);
      if (match.question_started_at) {
        const serverElapsed =
          Date.now() - new Date(match.question_started_at).getTime();
        effectiveMs = Math.max(effectiveMs, serverElapsed - 1500);
      }

      const isCorrect =
        question.question_type === "open"
          ? Boolean(
              written_answer &&
                question.correct_text_answer &&
                written_answer.trim().toLowerCase() ===
                  question.correct_text_answer.trim().toLowerCase(),
            )
          : Number(selected_option_index) === Number(question.correct_option_index);

      const scored = calculateQuizScore({
        isCorrect,
        basePoints: Number(question.points ?? 100),
        timeLimitSeconds: Number(question.time_limit_seconds ?? 25),
        responseTimeMs: effectiveMs,
        focusLostCount: Number(focus_lost_count),
      });

      const { data: saved, error } = await ctx.supabaseAdminClient
        .from("quiz_answers")
        .insert({
          match_id,
          question_id,
          user_id: ctx.userId,
          selected_option_index,
          written_answer,
          is_correct: isCorrect,
          response_time_ms: Math.max(0, Math.round(effectiveMs)),
          points_awarded: scored.pointsAwarded,
          focus_lost_count: Number(focus_lost_count),
          flagged_suspicious: scored.flaggedSuspicious,
        })
        .select()
        .single();

      if (error) return errorResponse(error.message, 400);

      return jsonResponse({
        answer: saved,
        explanation: question.explanation,
        verified_references: question.verified_references,
        correct_option_index: question.correct_option_index,
      });
    }

    if (action === "generate_bracket") {
      const { tournament_id } = body;
      const { data: tournament } = await ctx.supabaseAdminClient
        .from("tournaments")
        .select("*")
        .eq("id", tournament_id)
        .single();
      if (!tournament) return errorResponse("Tournament not found.", 404);

      const { data: participants } = await ctx.supabaseAdminClient
        .from("tournament_participants")
        .select("user_id")
        .eq("tournament_id", tournament_id)
        .order("joined_at", { ascending: true });

      const ids = (participants ?? []).map((p) => p.user_id as string);
      const size = ([2, 8, 16, 32].includes(tournament.max_participants)
        ? tournament.max_participants
        : 8) as 2 | 8 | 16 | 32;

      const bracket = generateTournamentBracket(ids, size);
      const { data: updated, error } = await ctx.supabaseAdminClient
        .from("tournaments")
        .update({
          bracket_state: bracket,
          status: "in_progress",
          current_round: 1,
        })
        .eq("id", tournament_id)
        .select()
        .single();

      if (error) return errorResponse(error.message, 500);
      return jsonResponse({ tournament: updated });
    }

    return errorResponse("Unsupported quiz action.", 400);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Quiz engine error";
    return errorResponse(message, message.startsWith("UNAUTHORIZED") ? 401 : 500);
  }
});
