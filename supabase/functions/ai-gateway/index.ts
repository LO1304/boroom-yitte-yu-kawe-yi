// Unified AI Gateway Edge Function
// Routes requests to all 7 specialized AI agents while enforcing auth, quotas, and cost logging.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { handleOptions, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { requireAuth, enforceDailyAIQuota, logAIUsage } from "../_shared/auth.ts";
import {
  callAIProvider,
  extractJsonObject,
  type AIProviderName,
} from "../_shared/ai_providers.ts";
import { AGENT_SYSTEM_PROMPTS, type AgentName } from "../_shared/agent_prompts.ts";

serve(async (req: Request) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const ctx = await requireAuth(req);
    await enforceDailyAIQuota(ctx.supabaseAdminClient, ctx.userId);

    const body = await req.json();
    const agent = body.agent as AgentName;
    if (!agent || !(agent in AGENT_SYSTEM_PROMPTS)) {
      return errorResponse("Invalid or unsupported AI agent name.", 400, "INVALID_AGENT");
    }

    const prompt = String(body.prompt ?? "").trim();
    if (!prompt) {
      return errorResponse("Prompt is required.", 400, "EMPTY_PROMPT");
    }

    const expectJson = Boolean(body.expect_json ?? false);
    const provider = body.provider as AIProviderName | undefined;
    const model = typeof body.model === "string" ? body.model : undefined;
    const language = typeof body.language === "string" ? body.language : "fr";

    const systemPrompt = `${AGENT_SYSTEM_PROMPTS[agent]}\nPreferred response language: ${language}.`;

    const result = await callAIProvider({
      provider,
      model,
      systemPrompt,
      messages: [
        ...(Array.isArray(body.history) ? body.history : []),
        { role: "user", content: prompt },
      ],
      expectJson,
    });

    await logAIUsage(ctx.supabaseAdminClient, {
      userId: ctx.userId,
      agentName: agent,
      provider: result.provider,
      model: result.model,
      promptTokens: result.promptTokens,
      completionTokens: result.completionTokens,
      estimatedCostUsd: result.estimatedCostUsd,
      latencyMs: result.latencyMs,
      status: "success",
    });

    // Special handling: YITTE_SUMMARIZER creates a summary strictly in 'pending_review'
    if (agent === "YITTE_SUMMARIZER" && body.weekly_topic_id && expectJson) {
      const parsed = extractJsonObject<{
        title: string;
        summary_markdown: string;
        key_takeaways: string[];
        verified_references: string[];
      }>(result.text);

      const { data: savedSummary } = await ctx.supabaseAdminClient
        .from("summaries")
        .insert({
          weekly_topic_id: body.weekly_topic_id,
          title: parsed.title,
          summary_markdown: parsed.summary_markdown,
          key_takeaways: parsed.key_takeaways ?? [],
          verified_references: parsed.verified_references ?? [],
          generated_by_ai: true,
          ai_model: `${result.provider}:${result.model}`,
          status: "pending_review",
          created_by: ctx.userId,
        })
        .select()
        .single();

      return jsonResponse({
        agent,
        provider: result.provider,
        model: result.model,
        parsed,
        summary_record: savedSummary,
        usage: {
          prompt_tokens: result.promptTokens,
          completion_tokens: result.completionTokens,
          estimated_cost_usd: result.estimatedCostUsd,
        },
      });
    }

    return jsonResponse({
      agent,
      provider: result.provider,
      model: result.model,
      content: result.text,
      parsed: expectJson ? extractJsonObject(result.text) : null,
      usage: {
        prompt_tokens: result.promptTokens,
        completion_tokens: result.completionTokens,
        estimated_cost_usd: result.estimatedCostUsd,
      },
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    const status = message.startsWith("UNAUTHORIZED")
      ? 401
      : message.startsWith("FORBIDDEN")
        ? 403
        : message.startsWith("RATE_LIMITED")
          ? 429
          : 500;
    return errorResponse(message, status, "AI_GATEWAY_ERROR");
  }
});
