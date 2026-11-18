// Auth, RBAC, quota check, and AI usage audit logger for Supabase Edge Functions.
import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { getEnv } from "./ai_providers.ts";

export interface AuthenticatedContext {
  userId: string;
  role: string;
  supabaseUserClient: SupabaseClient;
  supabaseAdminClient: SupabaseClient;
}

export async function requireAuth(req: Request): Promise<AuthenticatedContext> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    throw new Error("UNAUTHORIZED: Missing Bearer token.");
  }

  const supabaseUrl = getEnv("SUPABASE_URL");
  const supabaseAnonKey = getEnv("SUPABASE_ANON_KEY");
  const supabaseServiceKey = getEnv("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceKey) {
    throw new Error("SERVER_MISCONFIGURED: Supabase environment keys missing.");
  }

  const supabaseUserClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const supabaseAdminClient = createClient(supabaseUrl, supabaseServiceKey);

  const { data: userData, error } = await supabaseUserClient.auth.getUser();
  if (error || !userData.user) {
    throw new Error("UNAUTHORIZED: Invalid or expired JWT.");
  }

  const { data: profile } = await supabaseAdminClient
    .from("profiles")
    .select("primary_role, is_suspended")
    .eq("id", userData.user.id)
    .single();

  if (profile?.is_suspended) {
    throw new Error("FORBIDDEN: User account is suspended.");
  }

  return {
    userId: userData.user.id,
    role: profile?.primary_role ?? "member",
    supabaseUserClient,
    supabaseAdminClient,
  };
}

export async function enforceDailyAIQuota(
  adminClient: SupabaseClient,
  userId: string,
): Promise<void> {
  const dailyQuota = Number(getEnv("AI_DAILY_USER_QUOTA_TOKENS", "50000"));
  const startOfDay = new Date();
  startOfDay.setUTCHours(0, 0, 0, 0);

  const { data, error } = await adminClient
    .from("ai_usage_logs")
    .select("prompt_tokens, completion_tokens")
    .eq("user_id", userId)
    .gte("created_at", startOfDay.toISOString());

  if (error || !data) return;

  const usedToday = data.reduce(
    (sum, row) =>
      sum + Number(row.prompt_tokens ?? 0) + Number(row.completion_tokens ?? 0),
    0,
  );
  if (usedToday >= dailyQuota) {
    throw new Error("RATE_LIMITED: Daily AI token quota exceeded.");
  }
}

export async function logAIUsage(
  adminClient: SupabaseClient,
  entry: {
    userId: string;
    agentName: string;
    provider: string;
    model: string;
    promptTokens: number;
    completionTokens: number;
    estimatedCostUsd: number;
    latencyMs: number;
    status: "success" | "rate_limited" | "error";
    errorMessage?: string;
  },
): Promise<void> {
  await adminClient.from("ai_usage_logs").insert({
    user_id: entry.userId,
    agent_name: entry.agentName,
    provider: entry.provider,
    model: entry.model,
    prompt_tokens: entry.promptTokens,
    completion_tokens: entry.completionTokens,
    estimated_cost_usd: entry.estimatedCostUsd,
    latency_ms: entry.latencyMs,
    status: entry.status,
    error_message: entry.errorMessage ?? null,
  });
}
