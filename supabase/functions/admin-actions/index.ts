// Server-enforced RBAC Administration & Notification Broadcast Edge Function
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { handleOptions, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";

serve(async (req: Request) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const ctx = await requireAuth(req);
    const body = await req.json();
    const action = String(body.action ?? "");

    const isAdmin = ["super_admin", "admin"].includes(ctx.role);
    const isMod = ["super_admin", "admin", "moderator"].includes(ctx.role);
    const isEditor = ["super_admin", "admin", "content_editor"].includes(ctx.role);

    if (action === "assign_role") {
      if (ctx.role !== "super_admin") {
        return errorResponse("Forbidden: super_admin role required.", 403);
      }
      const { target_user_id, new_role } = body;
      const { data: roleRow } = await ctx.supabaseAdminClient
        .from("roles")
        .select("id")
        .eq("code", new_role)
        .single();
      if (!roleRow) return errorResponse("Unknown role.", 400);

      await ctx.supabaseAdminClient
        .from("profiles")
        .update({ primary_role: new_role })
        .eq("id", target_user_id);

      await ctx.supabaseAdminClient
        .from("user_roles")
        .upsert(
          { user_id: target_user_id, role_id: roleRow.id, assigned_by: ctx.userId },
          { onConflict: "user_id,role_id" },
        );

      await ctx.supabaseAdminClient.from("audit_logs").insert({
        actor_id: ctx.userId,
        action: "role_assigned",
        target_table: "profiles",
        target_id: target_user_id,
        metadata: { new_role },
      });
      return jsonResponse({ ok: true, target_user_id, new_role });
    }

    if (action === "broadcast_notification") {
      if (!isAdmin) return errorResponse("Forbidden: admin required.", 403);
      const { title, message, notification_type = "announcement", deep_link } = body;
      const { data: users } = await ctx.supabaseAdminClient
        .from("profiles")
        .select("id")
        .eq("is_suspended", false);

      const rows = (users ?? []).map((u) => ({
        user_id: u.id,
        title,
        body: message,
        notification_type,
        deep_link: deep_link ?? null,
      }));
      if (rows.length > 0) {
        await ctx.supabaseAdminClient.from("notifications").insert(rows);
      }

      await ctx.supabaseAdminClient.from("audit_logs").insert({
        actor_id: ctx.userId,
        action: "notification_broadcast",
        metadata: { recipients_count: rows.length, title },
      });
      return jsonResponse({ ok: true, delivered_in_app: rows.length });
    }

    if (action === "approve_summary") {
      if (!isEditor) return errorResponse("Forbidden: editor or admin required.", 403);
      const { summary_id, review_notes } = body;
      const { data, error } = await ctx.supabaseAdminClient
        .from("summaries")
        .update({
          status: "published",
          reviewed_by: ctx.userId,
          review_notes: review_notes ?? null,
          reviewed_at: new Date().toISOString(),
          published_at: new Date().toISOString(),
        })
        .eq("id", summary_id)
        .select()
        .single();
      if (error) return errorResponse(error.message, 400);
      await ctx.supabaseAdminClient.from("audit_logs").insert({
        actor_id: ctx.userId,
        action: "summary_approved_published",
        target_table: "summaries",
        target_id: summary_id,
      });
      return jsonResponse({ summary: data });
    }

    if (action === "resolve_report") {
      if (!isMod) return errorResponse("Forbidden: moderator or above required.", 403);
      const { report_id, status = "resolved", resolution_notes } = body;
      const { data, error } = await ctx.supabaseAdminClient
        .from("reports")
        .update({
          status,
          assigned_to: ctx.userId,
          resolution_notes,
          resolved_at: new Date().toISOString(),
        })
        .eq("id", report_id)
        .select()
        .single();
      if (error) return errorResponse(error.message, 400);
      await ctx.supabaseAdminClient.from("audit_logs").insert({
        actor_id: ctx.userId,
        action: "report_resolved",
        target_table: "reports",
        target_id: report_id,
        metadata: { status },
      });
      return jsonResponse({ report: data });
    }

    if (action === "platform_stats") {
      if (!isAdmin && !isMod) return errorResponse("Forbidden.", 403);
      const [profiles, reflections, debates, quizzes, zikr, usage, reports] =
        await Promise.all([
          ctx.supabaseAdminClient.from("profiles").select("*", { count: "exact", head: true }),
          ctx.supabaseAdminClient.from("reflections").select("*", { count: "exact", head: true }),
          ctx.supabaseAdminClient.from("debate_matches").select("*", { count: "exact", head: true }),
          ctx.supabaseAdminClient.from("quiz_matches").select("*", { count: "exact", head: true }),
          ctx.supabaseAdminClient.from("zikr_sessions").select("*", { count: "exact", head: true }),
          ctx.supabaseAdminClient.from("ai_usage_logs").select("estimated_cost_usd, prompt_tokens, completion_tokens"),
          ctx.supabaseAdminClient.from("reports").select("*", { count: "exact", head: true }).eq("status", "open"),
        ]);

      const totalAiCost = (usage.data ?? []).reduce(
        (s, r) => s + Number(r.estimated_cost_usd ?? 0),
        0,
      );
      const totalTokens = (usage.data ?? []).reduce(
        (s, r) => s + Number(r.prompt_tokens ?? 0) + Number(r.completion_tokens ?? 0),
        0,
      );

      return jsonResponse({
        members_count: profiles.count ?? 0,
        reflections_count: reflections.count ?? 0,
        debates_count: debates.count ?? 0,
        quizzes_count: quizzes.count ?? 0,
        zikr_sessions_count: zikr.count ?? 0,
        open_reports_count: reports.count ?? 0,
        ai_total_tokens: totalTokens,
        ai_total_cost_usd: Number(totalAiCost.toFixed(4)),
      });
    }

    return errorResponse("Unknown admin action.", 400);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Admin action error";
    return errorResponse(message, message.startsWith("UNAUTHORIZED") ? 401 : 500);
  }
});
