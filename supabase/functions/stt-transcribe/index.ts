// Speech-to-Text Edge Function
// Downloads a consented voice recording from Supabase Storage and transcribes
// via Deepgram Nova-2 (default), OpenAI Whisper, or Google Cloud STT.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { handleOptions, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import { getEnv } from "../_shared/ai_providers.ts";

serve(async (req: Request) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const ctx = await requireAuth(req);
    const { recording_id, language = "fr", provider } = await req.json();

    if (!recording_id) {
      return errorResponse("recording_id is required.", 400);
    }

    const { data: rec, error: recErr } = await ctx.supabaseAdminClient
      .from("voice_recordings")
      .select("*")
      .eq("id", recording_id)
      .single();

    if (recErr || !rec) {
      return errorResponse("Voice recording not found.", 404);
    }
    if (rec.user_id !== ctx.userId && ctx.role !== "admin" && ctx.role !== "super_admin") {
      return errorResponse("Forbidden access to recording.", 403);
    }
    if (!rec.consent_granted) {
      return errorResponse("Audio transcription requires explicit user recording consent.", 403);
    }

    const { data: fileBlob, error: dlErr } = await ctx.supabaseAdminClient.storage
      .from("voice-recordings")
      .download(rec.storage_path);

    if (dlErr || !fileBlob) {
      return errorResponse(`Could not download audio file: ${dlErr?.message ?? "missing"}`, 500);
    }

    const sttProvider = provider ?? getEnv("STT_DEFAULT_PROVIDER", "deepgram");
    let transcriptText = "";
    let confidence = 0.95;

    if (sttProvider === "deepgram") {
      const dgKey = getEnv("DEEPGRAM_API_KEY");
      if (!dgKey) {
        return errorResponse("DEEPGRAM_API_KEY is not configured on the server.", 503, "MISSING_STT_KEY");
      }
      const dgRes = await fetch(
        `https://api.deepgram.com/v1/listen?model=nova-2&smart_format=true&language=${encodeURIComponent(language)}`,
        {
          method: "POST",
          headers: {
            Authorization: `Token ${dgKey}`,
            "Content-Type": rec.mime_type || "audio/m4a",
          },
          body: await fileBlob.arrayBuffer(),
        },
      );
      if (!dgRes.ok) {
        return errorResponse(`Deepgram error ${dgRes.status}: ${await dgRes.text()}`, 502);
      }
      const dgJson = await dgRes.json();
      const alt = dgJson?.results?.channels?.[0]?.alternatives?.[0];
      transcriptText = alt?.transcript ?? "";
      confidence = Number(alt?.confidence ?? 0.9);
    } else if (sttProvider === "whisper") {
      const oaiKey = getEnv("OPENAI_WHISPER_API_KEY") || getEnv("OPENAI_API_KEY");
      if (!oaiKey) {
        return errorResponse("OPENAI_WHISPER_API_KEY is not configured on the server.", 503, "MISSING_STT_KEY");
      }
      const form = new FormData();
      form.append("file", fileBlob, "speech.m4a");
      form.append("model", "whisper-1");
      form.append("language", language.slice(0, 2));
      const wRes = await fetch("https://api.openai.com/v1/audio/transcriptions", {
        method: "POST",
        headers: { Authorization: `Bearer ${oaiKey}` },
        body: form,
      });
      if (!wRes.ok) {
        return errorResponse(`Whisper error ${wRes.status}: ${await wRes.text()}`, 502);
      }
      const wJson = await wRes.json();
      transcriptText = wJson?.text ?? "";
    } else {
      return errorResponse(`Unsupported STT provider: ${sttProvider}`, 400);
    }

    const { data: savedTranscript, error: insErr } = await ctx.supabaseAdminClient
      .from("transcripts")
      .upsert(
        {
          recording_id: rec.id,
          user_id: rec.user_id,
          stt_provider: sttProvider,
          language_detected: language,
          raw_text: transcriptText,
          confidence,
        },
        { onConflict: "recording_id" },
      )
      .select()
      .single();

    if (insErr) {
      return errorResponse(insErr.message, 500);
    }

    return jsonResponse({ transcript: savedTranscript });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown STT error";
    return errorResponse(message, message.startsWith("UNAUTHORIZED") ? 401 : 500);
  }
});
