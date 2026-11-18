// YITTÉ ENGLISH CLUB — Accent-Fair AI Speaking Evaluator
// Evaluates intelligibility, grammar, vocabulary, fluency, and coherence out of 100
// across CEFR A1-C2 and en-GB / en-US preferences.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { handleOptions, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { requireAuth, enforceDailyAIQuota, logAIUsage } from "../_shared/auth.ts";
import { callAIProvider, extractJsonObject } from "../_shared/ai_providers.ts";
import { AGENT_SYSTEM_PROMPTS } from "../_shared/agent_prompts.ts";
import { normalizeEnglishRubric, type EnglishRubricResult } from "../_shared/rubric_logic.ts";

serve(async (req: Request) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const ctx = await requireAuth(req);
    await enforceDailyAIQuota(ctx.supabaseAdminClient, ctx.userId);

    const {
      lesson_id,
      recording_id,
      prompt_text,
      transcript_text,
      target_variant = "en-GB",
      cefr_level = "B1",
    } = await req.json();

    if (!prompt_text || !transcript_text) {
      return errorResponse("prompt_text and transcript_text are required.", 400);
    }

    const userPrompt = [
      `Target English Variant: ${target_variant}`,
      `Learner CEFR Level: ${cefr_level}`,
      `Speaking Prompt: ${prompt_text}`,
      `Learner Speech Transcript:\n"""\n${transcript_text}\n"""`,
      `Evaluate fairly for intelligibility and clarity; never penalize regional or non-native accents.`,
    ].join("\n\n");

    const aiRes = await callAIProvider({
      systemPrompt: AGENT_SYSTEM_PROMPTS.YITTE_ENGLISH_COACH,
      messages: [{ role: "user", content: userPrompt }],
      temperature: 0.25,
      expectJson: true,
    });

    const parsed = extractJsonObject<Partial<EnglishRubricResult>>(aiRes.text);
    const rubric = normalizeEnglishRubric(parsed);

    await logAIUsage(ctx.supabaseAdminClient, {
      userId: ctx.userId,
      agentName: "YITTE_ENGLISH_COACH",
      provider: aiRes.provider,
      model: aiRes.model,
      promptTokens: aiRes.promptTokens,
      completionTokens: aiRes.completionTokens,
      estimatedCostUsd: aiRes.estimatedCostUsd,
      latencyMs: aiRes.latencyMs,
      status: "success",
    });

    const { data: attempt, error } = await ctx.supabaseAdminClient
      .from("speaking_attempts")
      .insert({
        user_id: ctx.userId,
        lesson_id: lesson_id ?? null,
        recording_id: recording_id ?? null,
        prompt_text,
        target_variant,
        cefr_level,
        transcript_text,
        ...rubric,
      })
      .select()
      .single();

    if (error) return errorResponse(error.message, 500);
    return jsonResponse({ attempt, rubric });
  } catch (err) {
    const message = err instanceof Error ? err.message : "English evaluation error";
    return errorResponse(message, message.startsWith("UNAUTHORIZED") ? 401 : 500);
  }
});
