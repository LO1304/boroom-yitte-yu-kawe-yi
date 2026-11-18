// YITTÉ FACE-À-FACE Independent AI Debate Evaluation Engine
// Evaluates each participant independently on the exact same 100-pt rubric,
// updates debate_participants.final_score, and announces winner when both speeches are scored.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { handleOptions, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { requireAuth, enforceDailyAIQuota, logAIUsage } from "../_shared/auth.ts";
import { callAIProvider, extractJsonObject } from "../_shared/ai_providers.ts";
import { AGENT_SYSTEM_PROMPTS } from "../_shared/agent_prompts.ts";
import { normalizeDebateRubric, type DebateRubricResult } from "../_shared/rubric_logic.ts";

serve(async (req: Request) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const ctx = await requireAuth(req);
    await enforceDailyAIQuota(ctx.supabaseAdminClient, ctx.userId);

    const { match_id, participant_id, transcript_id, transcript_text } = await req.json();
    if (!match_id || !participant_id || !transcript_text) {
      return errorResponse("match_id, participant_id, and transcript_text are required.", 400);
    }

    const { data: match, error: mErr } = await ctx.supabaseAdminClient
      .from("debate_matches")
      .select("*")
      .eq("id", match_id)
      .single();
    if (mErr || !match) return errorResponse("Debate match not found.", 404);

    const { data: participant, error: pErr } = await ctx.supabaseAdminClient
      .from("debate_participants")
      .select("*")
      .eq("id", participant_id)
      .eq("match_id", match_id)
      .single();
    if (pErr || !participant) return errorResponse("Debate participant not found.", 404);

    // Blind evaluation prompt: omit username/religion/demographics to enforce impartiality
    const evaluationPrompt = [
      `Debate Topic: ${match.topic_title}`,
      `Question: ${match.topic_question}`,
      `Category: ${match.category}`,
      `Is Islamic Subject: ${match.is_islamic_subject}`,
      `Participant Position Taken: ${participant.selected_position ?? "nuanced"}`,
      `Speech Transcript (evaluate reasoning quality independently):`,
      `"""\n${String(transcript_text).trim()}\n"""`,
    ].join("\n\n");

    const aiRes = await callAIProvider({
      systemPrompt: AGENT_SYSTEM_PROMPTS.YITTE_DEBATE_AI,
      messages: [{ role: "user", content: evaluationPrompt }],
      temperature: 0.2,
      expectJson: true,
    });

    const parsed = extractJsonObject<Partial<DebateRubricResult>>(aiRes.text);
    const rubric = normalizeDebateRubric(parsed);

    await logAIUsage(ctx.supabaseAdminClient, {
      userId: ctx.userId,
      agentName: "YITTE_DEBATE_AI",
      provider: aiRes.provider,
      model: aiRes.model,
      promptTokens: aiRes.promptTokens,
      completionTokens: aiRes.completionTokens,
      estimatedCostUsd: aiRes.estimatedCostUsd,
      latencyMs: aiRes.latencyMs,
      status: "success",
    });

    const { data: savedEval, error: evalErr } = await ctx.supabaseAdminClient
      .from("ai_evaluations")
      .insert({
        agent_name: "YITTE_DEBATE_AI",
        subject_type: "debate_participant",
        subject_id: participant.id,
        user_id: participant.user_id,
        transcript_id: transcript_id ?? null,
        ai_provider: aiRes.provider,
        ai_model: aiRes.model,
        score_relevance: rubric.score_relevance,
        score_logical_reasoning: rubric.score_logical_reasoning,
        score_depth_analysis: rubric.score_depth_analysis,
        score_arguments_examples: rubric.score_arguments_examples,
        score_critical_nuance: rubric.score_critical_nuance,
        score_clarity: rubric.score_clarity,
        total_score: rubric.total_score,
        detected_contradictions: rubric.detected_contradictions,
        unsupported_claims: rubric.unsupported_claims,
        logical_fallacies: rubric.logical_fallacies,
        recognized_nuances: rubric.recognized_nuances,
        relevant_examples: rubric.relevant_examples,
        score_explanation: rubric.score_explanation,
        improvement_recommendations: rubric.improvement_recommendations,
        verified_references: rubric.verified_references,
        fairness_audit: {
          blind_to_identity_and_accent: true,
          same_rubric_applied: true,
          is_islamic_subject: match.is_islamic_subject,
          factual_vs_interpretive_notes: rubric.factual_vs_interpretive_notes ?? null,
        },
        raw_structured_output: rubric,
      })
      .select()
      .single();

    if (evalErr) return errorResponse(evalErr.message, 500);

    await ctx.supabaseAdminClient
      .from("debate_participants")
      .update({ final_score: rubric.total_score })
      .eq("id", participant.id);

    // Check if both participants now have scores; if so, resolve winner cleanly
    const { data: allParticipants } = await ctx.supabaseAdminClient
      .from("debate_participants")
      .select("user_id, final_score")
      .eq("match_id", match_id);

    if (
      allParticipants &&
      allParticipants.length === 2 &&
      allParticipants.every((p) => p.final_score !== null)
    ) {
      const [p1, p2] = allParticipants;
      const winnerId =
        Number(p1.final_score) > Number(p2.final_score)
          ? p1.user_id
          : Number(p2.final_score) > Number(p1.final_score)
            ? p2.user_id
            : null; // Exact tie allowed

      await ctx.supabaseAdminClient
        .from("debate_matches")
        .update({
          status: "completed",
          winner_id: winnerId,
          completed_at: new Date().toISOString(),
        })
        .eq("id", match_id);
    }

    return jsonResponse({ evaluation: savedEval, rubric });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Debate evaluation error";
    return errorResponse(message, message.startsWith("UNAUTHORIZED") ? 401 : 500);
  }
});
