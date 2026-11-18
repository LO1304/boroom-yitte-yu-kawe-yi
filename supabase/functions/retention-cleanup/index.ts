// Scheduled Consent & Audio Retention Policy Enforcement Job
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { handleOptions, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";

serve(async (req: Request) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const ctx = await requireAuth(req);
    if (!["super_admin", "admin"].includes(ctx.role)) {
      return errorResponse("Forbidden: admin role required.", 403);
    }

    const nowIso = new Date().toISOString();
    const { data: expired } = await ctx.supabaseAdminClient
      .from("voice_recordings")
      .select("id, storage_path")
      .is("deleted_at", null)
      .neq("retention_policy", "permanent_with_consent")
      .lte("retain_until", nowIso);

    let purgedCount = 0;
    for (const rec of expired ?? []) {
      await ctx.supabaseAdminClient.storage
        .from("voice-recordings")
        .remove([rec.storage_path]);
      await ctx.supabaseAdminClient
        .from("voice_recordings")
        .update({ deleted_at: nowIso })
        .eq("id", rec.id);
      purgedCount++;
    }

    await ctx.supabaseAdminClient.from("audit_logs").insert({
      actor_id: ctx.userId,
      action: "audio_retention_cleanup",
      metadata: { purged_count: purgedCount },
    });

    return jsonResponse({ purged_count: purgedCount });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Cleanup error";
    return errorResponse(message, 500);
  }
});
