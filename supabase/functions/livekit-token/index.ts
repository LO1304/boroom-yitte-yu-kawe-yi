// LiveKit WebRTC Token Issuer with server-side mute/block & moderation claims.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";
import { handleOptions, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import { getEnv } from "../_shared/ai_providers.ts";

serve(async (req: Request) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const ctx = await requireAuth(req);
    const { room_id } = await req.json();
    if (!room_id) return errorResponse("room_id is required.", 400);

    const { data: room, error } = await ctx.supabaseAdminClient
      .from("voice_rooms")
      .select("*")
      .eq("id", room_id)
      .single();

    if (error || !room) return errorResponse("Voice room not found.", 404);
    if (!room.is_active) return errorResponse("Voice room has ended.", 410);
    if (room.is_locked && room.host_id !== ctx.userId && ctx.role === "member") {
      return errorResponse("Voice room is locked by host.", 403);
    }

    const lkUrl = getEnv("LIVEKIT_URL");
    const apiKey = getEnv("LIVEKIT_API_KEY");
    const apiSecret = getEnv("LIVEKIT_API_SECRET");
    if (!lkUrl || !apiKey || !apiSecret) {
      return errorResponse(
        "LiveKit credentials (LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET) are not configured.",
        503,
        "MISSING_LIVEKIT_CREDENTIALS",
      );
    }

    const isMuted = Array.isArray(room.muted_user_ids) &&
      room.muted_user_ids.includes(ctx.userId);
    const isHostOrMod =
      room.host_id === ctx.userId ||
      ["super_admin", "admin", "moderator"].includes(ctx.role);

    const key = await crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(apiSecret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"],
    );

    const token = await create(
      { alg: "HS256", typ: "JWT" },
      {
        iss: apiKey,
        sub: ctx.userId,
        nbf: getNumericDate(0),
        exp: getNumericDate(60 * 60 * 2),
        video: {
          room: room.livekit_room_name,
          roomJoin: true,
          canPublish: !isMuted,
          canSubscribe: true,
          canPublishData: true,
          roomAdmin: isHostOrMod,
        },
        metadata: JSON.stringify({ role: ctx.role }),
      },
      key,
    );

    return jsonResponse({
      livekit_url: lkUrl,
      room_name: room.livekit_room_name,
      token,
      can_publish: !isMuted,
      is_moderator: isHostOrMod,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "LiveKit token error";
    return errorResponse(message, message.startsWith("UNAUTHORIZED") ? 401 : 500);
  }
});
