import http from 'node:http';
import { execFile } from 'node:child_process';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, '..');
const WEB_DIR = path.join(ROOT, 'mobile', 'build', 'web');
const DATA_DIR = path.join(ROOT, 'server', 'data');
const DB_FILE = path.join(DATA_DIR, 'db.json');
const ACCOUNTS_FILE = path.join(DATA_DIR, 'accounts.json');
const UPLOADS_DIR = path.join(DATA_DIR, 'uploads');
const TTS_CACHE_DIR = path.join(DATA_DIR, 'tts_cache');
const HOST = process.env.HOST || '0.0.0.0';
const PORT = Number(process.env.FLUTTER_WEB_PORT || process.env.PORT || 8080);

const NEURAL_VOICE_MAP = {
  'amy-fluent-us': 'en-US-AvaMultilingualNeural',
  'amy-soft-uk': 'en-GB-LibbyNeural',
  'amy-clear-uk': 'en-GB-SoniaNeural',
  'amy-warm-us': 'en-US-EmmaMultilingualNeural',
  'en-gb': 'en-GB-LibbyNeural',
  'en-us': 'en-US-AvaMultilingualNeural',
};

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
  '.ogg': 'audio/ogg',
  '.webm': 'audio/webm',
  '.ico': 'image/x-icon',
};

function loadDotEnv() {
  const envPath = path.join(ROOT, '.env');
  const map = { ...process.env };
  if (fs.existsSync(envPath)) {
    for (const line of fs.readFileSync(envPath, 'utf8').split(/\r?\n/)) {
      const m = /^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/.exec(line);
      if (m && !line.trim().startsWith('#')) {
        map[m[1]] = m[2].replace(/^['"]|['"]$/g, '');
      }
    }
  }
  return map;
}

function readDb() {
  try {
    if (fs.existsSync(DB_FILE)) {
      return JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
    }
  } catch {
    // recover cleanly
  }
  return null;
}

function writeDb(payload) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  const tmp = `${DB_FILE}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(payload, null, 2), 'utf8');
  fs.renameSync(tmp, DB_FILE);
}

function readAccounts() {
  try {
    if (fs.existsSync(ACCOUNTS_FILE)) {
      const list = JSON.parse(fs.readFileSync(ACCOUNTS_FILE, 'utf8'));
      return Array.isArray(list) ? list : [];
    }
  } catch {
    // recover cleanly
  }
  return [];
}

function writeAccounts(accounts) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  const tmp = `${ACCOUNTS_FILE}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(accounts, null, 2), 'utf8');
  fs.renameSync(tmp, ACCOUNTS_FILE);
}

function hashPassword(password, saltHex) {
  const salt = saltHex || crypto.randomBytes(16).toString('hex');
  const hash = crypto.scryptSync(String(password), salt, 32).toString('hex');
  return { salt, hash };
}

const AUTHORIZED_GROUP_MEMBERS = [
  'Cheikh Mouhamadou Moustapha Lo',
  'Sokhna Diarra Lo',
  'Sokhna Amy Mountakha Thiam',
  'Serigne Khadim Seye',
  'Ahmadou Bamba Deme',
  'Sokhna Bintou Beye',
  'Sokhna Khady Sylla',
  'Sokhna Aida Thiam',
  'Sokhna Oumy Lo',
];

function normalizePersonName(raw) {
  return String(raw || '')
    .trim()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/\s+/g, ' ');
}

function matchOfficialGroupMember(rawName) {
  const target = normalizePersonName(rawName);
  if (!target) return null;
  const db = readDb();
  const extra = Array.isArray(db?.authorized_group_members) ? db.authorized_group_members : [];
  const pool = [...AUTHORIZED_GROUP_MEMBERS, ...extra];
  return pool.find((n) => normalizePersonName(n) === target) || null;
}

function toPublicMember(acc) {
  return {
    id: acc.id,
    full_name: acc.fullName,
    username: acc.username,
    email: acc.email,
    role_code: acc.role || 'member',
    is_group_member: acc.isGroupMember === true,
    joined_at: acc.createdAt,
  };
}

const sseClients = new Set();

function broadcastEvent(eventName, data) {
  const chunk = `event: ${eventName}\ndata: ${JSON.stringify(data)}\n\n`;
  for (const res of sseClients) {
    try {
      res.write(chunk);
    } catch {
      sseClients.delete(res);
    }
  }
}

function analyzeEnglishLocally(prompt) {
  const clean = String(prompt || '').replace(/^\([^)]*\)\s*/, '').trim();
  const sentences = clean.split(/(?<=[.!?])\s+/).filter(Boolean);
  const words = clean.split(/\s+/).filter(Boolean);
  const issues = [];
  let corrected = clean;

  if (/\ba\s+([aeiouAEIOU][a-zA-Z]+)/g.test(corrected)) {
    issues.push('Article indéfini : utilisez "an" devant un son vocalique.');
    corrected = corrected.replace(/\ba\s+([aeiouAEIOU][a-zA-Z]+)/g, 'an $1');
  }
  if (/\bdespite of\b/i.test(corrected)) {
    issues.push('"despite of" est incorrect : utilisez "despite" ou "in spite of".');
    corrected = corrected.replace(/\bdespite of\b/gi, 'despite');
  }
  if (/\bdiscuss about\b/i.test(corrected)) {
    issues.push('"discuss" est transitif direct : écrivez "discuss X" sans "about".');
    corrected = corrected.replace(/\bdiscuss about\b/gi, 'discuss');
  }
  if (/\b(informations|advices|equipments)\b/i.test(corrected)) {
    issues.push('Nom indénombrable en anglais : utilisez "information / advice / equipment" au singulier.');
    corrected = corrected
      .replace(/\binformations\b/gi, 'information')
      .replace(/\badvices\b/gi, 'advice')
      .replace(/\bequipments\b/gi, 'equipment');
  }
  if (/\bi\b/.test(corrected)) {
    issues.push('Le pronom "I" prend toujours une majuscule en anglais.');
    corrected = corrected.replace(/\bi\b/g, 'I');
  }

  const uniqueRatio = words.length ? Math.round((new Set(words.map((w) => w.toLowerCase())).size / words.length) * 100) : 0;
  return [
    `Analyse linguistique (${words.length} mots, ${sentences.length || 1} phrase(s), diversité lexicale ${uniqueRatio}%) :`,
    '',
    issues.length ? `Points de grammaire corrigés :\n- ${issues.join('\n- ')}` : 'Structure grammaticale de base cohérente sur votre énoncé.',
    '',
    `Version affinée : « ${corrected} »`,
    '',
    'Suggestion d’enrichissement : reliez vos idées avec des connecteurs de nuance ("Although...", "On balance...", "Consequently...") et illustrez par un exemple concret.',
  ].join('\n');
}

function analyzeCareerLocally(prompt) {
  const clean = String(prompt || '').trim();
  const hasSituation = /(?:contexte|situation|projet|équipe|mission|client|entreprise|stage|poste)/i.test(clean);
  const hasAction = /(?:j['’]ai|nous avons|conçu|développ|gér|dirig|pilot|optimis|résolu|mis en place|construit|automatis)/i.test(clean);
  const hasResult = /(?:résultat|impact|réduit|augment|gagn|livr|amélior|utilisateur|%|\d+)/i.test(clean);
  const hasMetrics = /\d+/.test(clean);

  const starScore =
    (hasSituation ? 25 : 10) +
    (hasAction ? 30 : 12) +
    (hasResult ? 25 : 10) +
    (hasMetrics ? 20 : 5);

  const missing = [];
  if (!hasSituation) missing.push('Situation : précisez le contexte, la taille d’équipe ou l’enjeu initial.');
  if (!hasAction) missing.push('Action : utilisez des verbes d’action directs à la 1ʳᵉ personne ("J’ai conçu / arbitré / automatisé...").');
  if (!hasResult) missing.push('Résultat : expliquez l’impact final observé après votre intervention.');
  if (!hasMetrics) missing.push('Indicateur chiffré : ajoutez au moins un chiffre concret (délai réduit de X%, N utilisateurs, budget).');

  return [
    `Évaluation STAR & Impact Professionnel — Score structurel : ${starScore}/100`,
    '',
    `Critères détectés dans votre texte (${clean.split(/\s+/).filter(Boolean).length} mots) :`,
    `- Contexte / Situation : ${hasSituation ? 'Présent' : 'À préciser'}`,
    `- Actions concrètes : ${hasAction ? 'Présentes' : 'À renforcer'}`,
    `- Résultat & Preuves chiffrées : ${hasMetrics ? 'Quantifié' : hasResult ? 'Qualitatif (chiffres manquants)' : 'Manquant'}`,
    '',
    missing.length
      ? `Recommandations ciblées :\n- ${missing.join('\n- ')}`
      : 'Excellente structuration STAR ! Préparez maintenant une réponse de 30s sur les compromis techniques ou humains arbitrés.',
  ].join('\n');
}

function analyzeMentorLocally(prompt) {
  const clean = String(prompt || '').trim();
  const words = clean.split(/\s+/).filter(Boolean);
  const procrastination = /\b(procrastin|retard|remettre|difficile|commencer|motivation|distraction|téléphone)\b/i.test(clean);
  const overload = /\b(trop|surcharg|temps|fatigue|organisation|priorit|tout faire|épuis)\b/i.test(clean);

  return [
    `Plan d’action personnalisé (basé sur votre note de ${words.length} mots) :`,
    '',
    overload
      ? '1. Tri immédiat : sélectionnez UNE seule priorité non négociable pour les prochaines 24h et reportez le secondaire.'
      : '1. Ancrage du premier pas : découpez l’objectif en un bloc fixe de 25 minutes sans notification (téléphone hors de portée).',
    procrastination
      ? '2. Règle d’amorçage (2 minutes) : engagez-vous uniquement sur les 2 premières minutes sans exiger la perfection immédiate.'
      : '2. Mesure vérifiable : notez l’heure exacte de début et de fin dans votre suivi d’habitudes.',
    '3. Questions de bilan pour ce soir :',
    `   • Quel obstacle concret a failli freiner « ${words.slice(0, 7).join(' ')}${words.length > 7 ? '...' : ''} » ?`,
    '   • Quelle condition environnementale pouvez-vous ajuster dès demain matin pour réussir avec régularité ?',
  ].join('\n');
}

function analyzeDebateLocally(prompt) {
  const clean = String(prompt || '').trim();
  const words = clean.split(/\s+/).filter(Boolean);
  const absolutes = clean.match(/\b(toujours|jamais|tout le monde|personne|forcément|évidemment|prouve)\b/gi) || [];
  const connectors = clean.match(/\b(car|parce que|donc|cependant|toutefois|en effet|ainsi|néanmoins|d'une part|d’autre part)\b/gi) || [];
  const examples = clean.match(/\b(exemple|notamment|histoire|science|étude|expérience|statistique|cas)\b/gi) || [];

  return [
    `Analyse rhétorique & logique (${words.length} mots) :`,
    `- Connecteurs argumentatifs identifiés : ${connectors.length} (${[...new Set(connectors.map((c) => c.toLowerCase()))].slice(0, 5).join(', ') || 'aucun'})`,
    `- Illustrations / preuves : ${examples.length ? `${examples.length} repère(s) concret(s)` : 'aucun exemple explicite repéré'}`,
    absolutes.length
      ? `- Alerte nuance : termes absolus détectés (${[...new Set(absolutes)].join(', ')}). Pensez à qualifier votre thèse.`
      : '- Ton équilibré : aucune généralisation absolue détectée.',
    '',
    'Contre-objection à anticiper : « Comment votre thèse tient-elle face à un cas limite où deux principes légitimes entrent en tension ? »',
  ].join('\n');
}

function runConcreteAiEngine(agent, prompt) {
  switch (agent) {
    case 'YITTE_ENGLISH_COACH':
      return analyzeEnglishLocally(prompt);
    case 'YITTE_CAREER_COACH':
      return analyzeCareerLocally(prompt);
    case 'YITTE_PERSONAL_MENTOR':
      return analyzeMentorLocally(prompt);
    case 'YITTE_DEBATE_AI':
      return analyzeDebateLocally(prompt);
    case 'YITTE_SUMMARIZER': {
      const lines = String(prompt || '').split(/\n+/).map((l) => l.trim()).filter((l) => l.length > 10);
      const unique = [...new Set(lines)].slice(0, 5);
      return `Synthèse structurée à partir de ${lines.length} élément(s) :\n${unique.map((l) => `• ${l}`).join('\n')}`;
    }
    case 'YITTE_SPIRITUAL_ASSISTANT':
      return 'Rappel méthodologique : privilégiez les sources coraniques et recensements authentiques vérifiés (al-Bukhari, Muslim) ; cet assistant fournit uniquement des repères éducatifs et n’émet aucune fatwa.';
    default:
      return analyzeDebateLocally(prompt);
  }
}

async function callCloudLlmIfConfigured(agent, prompt, env) {
  const systemPrompt = `Tu es ${agent} pour la plateforme éducative BOROOM YITTÉ YU KAWÉ YI. Sois concret, rigoureux, bienveillant et nuancé. Ne fabrique jamais de verset coranique ni de hadith.`;
  if (env.GEMINI_API_KEY && env.GEMINI_API_KEY.trim()) {
    const model = env.GEMINI_MODEL || 'gemini-2.5-flash';
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(env.GEMINI_API_KEY.trim())}`;
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: systemPrompt }] },
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.4, maxOutputTokens: 900 },
      }),
    });
    if (res.ok) {
      const json = await res.json();
      const text = json?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (text) return { content: text, provider: 'gemini' };
    }
  }
  if (env.OPENAI_API_KEY && env.OPENAI_API_KEY.trim()) {
    const res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${env.OPENAI_API_KEY.trim()}`,
      },
      body: JSON.stringify({
        model: env.OPENAI_MODEL || 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: prompt },
        ],
        temperature: 0.4,
      }),
    });
    if (res.ok) {
      const json = await res.json();
      const text = json?.choices?.[0]?.message?.content;
      if (text) return { content: text, provider: 'openai' };
    }
  }
  return null;
}

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => {
      try {
        const raw = Buffer.concat(chunks).toString('utf8');
        resolve(raw ? JSON.parse(raw) : {});
      } catch (e) {
        reject(e);
      }
    });
    req.on('error', reject);
  });
}

function resolveNeuralVoice(voiceKey, locale) {
  const k = String(voiceKey || '').trim().toLowerCase();
  if (NEURAL_VOICE_MAP[k]) return NEURAL_VOICE_MAP[k];
  const loc = String(locale || 'en-US').trim().toLowerCase();
  if (NEURAL_VOICE_MAP[loc]) return NEURAL_VOICE_MAP[loc];
  return 'en-US-AvaMultilingualNeural';
}

const AMY_REAL_SAMPLE_FILE = path.resolve(
  ROOT,
  'mobile',
  'assets',
  'audio',
  'amy',
  'amy_real_intro.ogg',
);
const AMY_CLONE_META_FILE = path.join(DATA_DIR, 'amy_cloned_voice.json');

function readAmyCloneMeta() {
  try {
    if (!fs.existsSync(AMY_CLONE_META_FILE)) return {};
    return JSON.parse(fs.readFileSync(AMY_CLONE_META_FILE, 'utf8'));
  } catch {
    return {};
  }
}

function writeAmyCloneMeta(meta) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  fs.writeFileSync(AMY_CLONE_META_FILE, JSON.stringify(meta, null, 2), 'utf8');
}

async function ensureElevenLabsAmyVoiceId(env) {
  const explicit = (env.ELEVENLABS_VOICE_ID || '').trim();
  if (explicit) return explicit;
  const cached = readAmyCloneMeta();
  if (cached.elevenlabsVoiceId) return cached.elevenlabsVoiceId;
  if (!env.ELEVENLABS_API_KEY || !env.ELEVENLABS_API_KEY.trim()) return null;
  if (!fs.existsSync(AMY_REAL_SAMPLE_FILE)) return null;

  const sampleBuf = fs.readFileSync(AMY_REAL_SAMPLE_FILE);
  const form = new FormData();
  form.append('name', 'Amy BOROOM YITTE');
  form.append('description', 'Voix réelle clonée d’Amy pour BOROOM YITTÉ YU KAWÉ YI');
  form.append(
    'files',
    new Blob([sampleBuf], { type: 'audio/ogg' }),
    'amy_real_intro.ogg',
  );
  const res = await fetch('https://api.elevenlabs.io/v1/voices/add', {
    method: 'POST',
    headers: { 'xi-api-key': env.ELEVENLABS_API_KEY.trim() },
    body: form,
  });
  if (!res.ok) {
    const errText = await res.text().catch(() => '');
    throw new Error(`ElevenLabs clone error (${res.status}): ${errText.slice(0, 180)}`);
  }
  const json = await res.json();
  const voiceId = String(json?.voice_id || '').trim();
  if (!voiceId) throw new Error('ElevenLabs voice_id non retourné.');
  writeAmyCloneMeta({
    ...cached,
    elevenlabsVoiceId: voiceId,
    clonedAt: new Date().toISOString(),
  });
  return voiceId;
}

let cachedChatterboxSamplePath = null;

async function ensureChatterboxAmySamplePath() {
  if (cachedChatterboxSamplePath) return cachedChatterboxSamplePath;
  if (!fs.existsSync(AMY_REAL_SAMPLE_FILE)) return null;
  const base = 'https://resembleai-chatterbox.hf.space';
  const buf = fs.readFileSync(AMY_REAL_SAMPLE_FILE);
  const form = new FormData();
  form.append(
    'files',
    new Blob([buf], { type: 'audio/ogg' }),
    'amy_real_intro.ogg',
  );
  const upRes = await fetch(`${base}/gradio_api/upload`, {
    method: 'POST',
    body: form,
    signal: AbortSignal.timeout(20000),
  });
  if (!upRes.ok) throw new Error(`Chatterbox upload failed (${upRes.status})`);
  const upJson = await upRes.json();
  const remotePath = Array.isArray(upJson) ? upJson[0] : null;
  if (!remotePath) throw new Error('Chatterbox upload path missing');
  cachedChatterboxSamplePath = remotePath;
  return remotePath;
}

async function synthesizeChatterboxFreeClone(text, cacheFile) {
  const base = 'https://resembleai-chatterbox.hf.space';
  const snippet = String(text || '').replace(/\s+/g, ' ').trim().slice(0, 290);
  if (!snippet) throw new Error('Empty text');

  let samplePath = await ensureChatterboxAmySamplePath();
  if (!samplePath) throw new Error('amy_real_intro.ogg introuvable');

  const invoke = async (remotePath) => {
    const callRes = await fetch(`${base}/gradio_api/call/generate_tts_audio`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        data: [
          snippet,
          { path: remotePath, meta: { _type: 'gradio.FileData' } },
          0.5,
          0.75,
          0,
          0.5,
          false,
        ],
      }),
      signal: AbortSignal.timeout(20000),
    });
    if (!callRes.ok) throw new Error(`Chatterbox call failed (${callRes.status})`);
    const { event_id: eventId } = await callRes.json();
    if (!eventId) throw new Error('Chatterbox event_id missing');
    const sseRes = await fetch(
      `${base}/gradio_api/call/generate_tts_audio/${encodeURIComponent(eventId)}`,
      { signal: AbortSignal.timeout(60000) },
    );
    if (!sseRes.ok) throw new Error(`Chatterbox SSE failed (${sseRes.status})`);
    const sseText = await sseRes.text();
    const lines = sseText.split(/\r?\n/);
    const dataLine = [...lines].reverse().find((l) => l.startsWith('data:'));
    if (!dataLine) throw new Error('Chatterbox SSE data missing');
    const parsed = JSON.parse(dataLine.slice(5).trim());
    const audioUrl = parsed?.[0]?.url;
    if (!audioUrl) throw new Error('Chatterbox output audio URL missing');
    const audioRes = await fetch(audioUrl, { signal: AbortSignal.timeout(25000) });
    if (!audioRes.ok) throw new Error(`Chatterbox audio download failed (${audioRes.status})`);
    return Buffer.from(await audioRes.arrayBuffer());
  };

  let audioBuf;
  try {
    audioBuf = await invoke(samplePath);
  } catch {
    // Re-upload sample once in case Space restarted /tmp
    cachedChatterboxSamplePath = null;
    samplePath = await ensureChatterboxAmySamplePath();
    audioBuf = await invoke(samplePath);
  }
  fs.writeFileSync(cacheFile, audioBuf);
  return { filePath: cacheFile, engine: 'chatterbox-free-amy-clone', mime: 'audio/wav' };
}

async function synthesizeNeuralTts({
  text,
  voiceKey,
  locale,
  rate,
  env,
  strictClone = false,
}) {
  const cleanText = String(text || '').replace(/\s+/g, ' ').trim().slice(0, 900);
  if (!cleanText) throw new Error('Texte vide pour la synthèse vocale.');

  const numRate = Math.min(1.25, Math.max(0.7, Number(rate) || 0.96));
  const ratePct = Math.round((numRate - 1.0) * 100);
  const rateArg = `${ratePct >= 0 ? '+' : ''}${ratePct}%`;
  const neuralVoice = resolveNeuralVoice(voiceKey, locale);

  fs.mkdirSync(TTS_CACHE_DIR, { recursive: true });

  const hasEleven = Boolean(env.ELEVENLABS_API_KEY && env.ELEVENLABS_API_KEY.trim());
  const hasFish = Boolean(env.FISH_API_KEY && env.FISH_API_KEY.trim());
  const hasAmySample = fs.existsSync(AMY_REAL_SAMPLE_FILE);
  const clonedVoiceId = hasEleven ? await ensureElevenLabsAmyVoiceId(env).catch(() => null) : null;

  const providerTag = clonedVoiceId
    ? `el_amy_${clonedVoiceId}`
    : hasFish
      ? 'fish_amy_clone'
      : hasAmySample
        ? 'chatterbox_amy_free'
        : env.OPENAI_API_KEY
          ? 'oai_shimmer'
          : `edge_${neuralVoice}`;
  const isWavProvider = providerTag === 'chatterbox_amy_free';
  const hash = crypto
    .createHash('sha256')
    .update(`${providerTag}|${rateArg}|${cleanText}`)
    .digest('hex')
    .slice(0, 24);
  const cacheFile = path.join(TTS_CACHE_DIR, `${hash}.${isWavProvider ? 'wav' : 'mp3'}`);

  if (fs.existsSync(cacheFile) && fs.statSync(cacheFile).size > 256) {
    return {
      filePath: cacheFile,
      engine: `${providerTag}:cached`,
      mime: isWavProvider ? 'audio/wav' : 'audio/mpeg',
    };
  }

  // Tier 1A: ElevenLabs Cloned Voice (auto-cloné depuis amy_real_intro.ogg)
  if (hasEleven && clonedVoiceId) {
    const elRes = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${encodeURIComponent(clonedVoiceId)}`,
      {
        method: 'POST',
        headers: {
          'xi-api-key': env.ELEVENLABS_API_KEY.trim(),
          'Content-Type': 'application/json',
          Accept: 'audio/mpeg',
        },
        body: JSON.stringify({
          text: cleanText,
          model_id: 'eleven_multilingual_v2',
          voice_settings: { stability: 0.52, similarity_boost: 0.88, style: 0.25 },
        }),
      },
    );
    if (elRes.ok) {
      const buf = Buffer.from(await elRes.arrayBuffer());
      fs.writeFileSync(cacheFile, buf);
      return { filePath: cacheFile, engine: 'elevenlabs-amy-clone', mime: 'audio/mpeg' };
    }
  }

  // Tier 1B: Fish Audio Zero-Shot Clone directement depuis amy_real_intro.ogg
  if (hasFish && hasAmySample) {
    const sampleB64 = fs.readFileSync(AMY_REAL_SAMPLE_FILE).toString('base64');
    const fishRes = await fetch('https://api.fish.audio/v1/tts', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.FISH_API_KEY.trim()}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        text: cleanText,
        format: 'mp3',
        references: [
          {
            audio: sampleB64,
            text: "Hello, my name is Amy. I'm twenty years old and I live in Villejuif.",
          },
        ],
      }),
    });
    if (fishRes.ok) {
      const buf = Buffer.from(await fishRes.arrayBuffer());
      fs.writeFileSync(cacheFile, buf);
      return { filePath: cacheFile, engine: 'fish-amy-clone', mime: 'audio/mpeg' };
    }
  }

  // Tier 1C (100% GRATUIT, zéro clé API) : ResembleAI Chatterbox Zero-Shot Clone depuis amy_real_intro.ogg
  if (hasAmySample) {
    try {
      return await synthesizeChatterboxFreeClone(cleanText, cacheFile);
    } catch (e) {
      if (strictClone) {
        const err = new Error(`Chatterbox free clone indisponible temporairement : ${e.message}`);
        err.statusCode = 503;
        throw err;
      }
    }
  }

  if (strictClone) {
    const err = new Error(
      'CLONE_NOT_CONFIGURED: Échantillon amy_real_intro.ogg introuvable.',
    );
    err.statusCode = 503;
    throw err;
  }

  // Tier 2: OpenAI HD Female Neural Voice if configured in .env
  if (env.OPENAI_API_KEY && env.OPENAI_API_KEY.trim()) {
    const oaiRes = await fetch('https://api.openai.com/v1/audio/speech', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.OPENAI_API_KEY.trim()}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'tts-1-hd',
        voice: 'shimmer',
        speed: numRate,
        input: cleanText,
      }),
    });
    if (oaiRes.ok) {
      const buf = Buffer.from(await oaiRes.arrayBuffer());
      fs.writeFileSync(cacheFile, buf);
      return { filePath: cacheFile, engine: 'openai-hd' };
    }
  }

  // Tier 3 (Default, Free & Studio Quality): Microsoft Edge Neural Voice via python -m edge_tts
  const tmpFile = `${cacheFile}.${Date.now()}.tmp.mp3`;
  await new Promise((resolve, reject) => {
    execFile(
      'python',
      [
        '-m',
        'edge_tts',
        '--voice',
        neuralVoice,
        `--rate=${rateArg}`,
        '--text',
        cleanText,
        '--write-media',
        tmpFile,
      ],
      { timeout: 20000, windowsHide: true },
      (err) => {
        if (err) reject(err);
        else resolve();
      },
    );
  });
  if (!fs.existsSync(tmpFile) || fs.statSync(tmpFile).size < 128) {
    throw new Error('Fichier audio neural non généré.');
  }
  fs.renameSync(tmpFile, cacheFile);
  return { filePath: cacheFile, engine: 'edge-neural' };
}

if (!fs.existsSync(path.join(WEB_DIR, 'index.html'))) {
  console.error(`Missing Flutter web build at ${WEB_DIR}. Run 'flutter build web' first.`);
  process.exit(1);
}

const server = http.createServer(async (req, res) => {
  const urlObj = new URL(req.url || '/', `http://127.0.0.1:${PORT}`);
  const cleanPath = decodeURIComponent(urlObj.pathname);

  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (cleanPath === '/api/health' && req.method === 'GET') {
    const env = loadDotEnv();
    const db = readDb();
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(
      JSON.stringify({
        ok: true,
        backend: 'local_node_sqlite_json',
        dbFile: DB_FILE,
        hasPersistedState: Boolean(db),
        cloudAiConfigured: Boolean(env.GEMINI_API_KEY || env.OPENAI_API_KEY),
      }),
    );
    return;
  }

  if (cleanPath === '/api/events' && req.method === 'GET') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream; charset=utf-8',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    });
    res.write('event: connected\ndata: {"ok":true}\n\n');
    sseClients.add(res);
    req.on('close', () => sseClients.delete(res));
    return;
  }

  if (cleanPath === '/api/snapshot' && req.method === 'GET') {
    const db = readDb();
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ exists: Boolean(db), snapshot: db }));
    return;
  }

  if (cleanPath === '/api/snapshot' && req.method === 'PUT') {
    try {
      const body = await readJsonBody(req);
      const saved = { ...body, updatedAt: new Date().toISOString() };
      writeDb(saved);
      broadcastEvent('snapshot_updated', { updatedAt: saved.updatedAt });
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: true, updatedAt: saved.updatedAt }));
    } catch (e) {
      res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: false, error: String(e) }));
    }
    return;
  }

  if (cleanPath === '/api/ai' && req.method === 'POST') {
    try {
      const { agent = 'YITTE_PERSONAL_MENTOR', prompt = '' } = await readJsonBody(req);
      const env = loadDotEnv();
      const cloud = await callCloudLlmIfConfigured(agent, prompt, env);
      const content = cloud?.content || runConcreteAiEngine(agent, prompt);
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(
        JSON.stringify({
          ok: true,
          agent,
          provider: cloud?.provider || 'local_nlp_engine',
          content,
        }),
      );
    } catch (e) {
      res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: false, error: String(e) }));
    }
    return;
  }

  if (cleanPath === '/api/auth/register' && req.method === 'POST') {
    try {
      const body = await readJsonBody(req);
      const email = String(body.email || '').trim().toLowerCase();
      const password = String(body.password || '');
      const fullName = String(body.fullName || '').trim();
      const username = String(body.username || '').trim();
      const inviteCode = String(body.inviteCode || '').trim().toUpperCase();
      if (!email || !password || !fullName || !username) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ ok: false, error: 'Champs requis incomplets.' }));
        return;
      }
      const accounts = readAccounts();
      if (accounts.some((a) => a.email === email || a.username.toLowerCase() === username.toLowerCase())) {
        res.writeHead(409, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ ok: false, error: 'Cet email ou identifiant existe déjà.' }));
        return;
      }
      const isFirst = accounts.length === 0;
      const role = isFirst || inviteCode.startsWith('YITTE-SUP')
        ? 'super_admin'
        : inviteCode.startsWith('YITTE-ADM') || inviteCode.startsWith('ADMIN')
          ? 'admin'
          : 'member';
      const { salt, hash } = hashPassword(password);
      const isGroup = Boolean(matchOfficialGroupMember(fullName)) || inviteCode.startsWith('YITTE-SUP');
      const account = {
        id: crypto.randomUUID(),
        email,
        fullName,
        username,
        role,
        isGroupMember: isGroup,
        salt,
        hash,
        onboardingCompleted: false,
        createdAt: new Date().toISOString(),
      };
      accounts.push(account);
      writeAccounts(accounts);
      broadcastEvent('snapshot_updated', { memberJoined: username });
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: true, user: toPublicMember(account) }));
    } catch (e) {
      res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: false, error: String(e) }));
    }
    return;
  }

  if (cleanPath === '/api/auth/login' && req.method === 'POST') {
    try {
      const body = await readJsonBody(req);
      const email = String(body.email || '').trim().toLowerCase();
      const password = String(body.password || '');
      const displayName = String(body.displayName || '').trim();
      const accounts = readAccounts();
      let existing = accounts.find((a) => a.email === email);
      if (existing) {
        const { hash } = hashPassword(password, existing.salt);
        if (hash !== existing.hash) {
          res.writeHead(401, { 'Content-Type': 'application/json; charset=utf-8' });
          res.end(JSON.stringify({ ok: false, error: 'Mot de passe incorrect pour ce compte.' }));
          return;
        }
      } else {
        // First-time local login registers the account cleanly with a real user name (never a generic bot label)
        const baseName = displayName || email.split('@')[0].replace(/[._-]+/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
        const baseUser = email.split('@')[0].replace(/[^a-zA-Z0-9_]/g, '_') || 'membre';
        const { salt, hash } = hashPassword(password);
        existing = {
          id: crypto.randomUUID(),
          email,
          fullName: baseName,
          username: baseUser,
          role: accounts.length === 0 ? 'super_admin' : 'member',
          salt,
          hash,
          onboardingCompleted: true,
          createdAt: new Date().toISOString(),
        };
        accounts.push(existing);
        writeAccounts(accounts);
        broadcastEvent('snapshot_updated', { memberJoined: existing.username });
      }
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: true, user: toPublicMember(existing) }));
    } catch (e) {
      res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: false, error: String(e) }));
    }
    return;
  }

  if (cleanPath === '/api/auth/name-login' && req.method === 'POST') {
    try {
      const body = await readJsonBody(req);
      const rawName = String(body.fullName || '').trim().replace(/\s+/g, ' ');
      const inviteCode = String(body.inviteCode || '').trim().toUpperCase();
      if (rawName.length < 2) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ ok: false, error: 'Veuillez saisir votre nom complet (minimum 2 caractères).' }));
        return;
      }
      const canonicalName = matchOfficialGroupMember(rawName);
      if (!canonicalName) {
        res.writeHead(403, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({
          ok: false,
          error: 'Ce nom ne figure pas dans la liste officielle des membres du groupe. Les autres personnes doivent utiliser l’onglet « Connexion Standard » avec email.',
        }));
        return;
      }
      const accounts = readAccounts();
      const normKey = normalizePersonName(canonicalName);
      let existing = accounts.find(
        (a) => normalizePersonName(a.fullName || '') === normKey ||
          normalizePersonName(a.username || '') === normKey,
      );
      if (!existing) {
        const isFirst = accounts.length === 0;
        const role = isFirst || inviteCode.startsWith('YITTE-SUP')
          ? 'super_admin'
          : inviteCode.startsWith('YITTE-ADM') || inviteCode.startsWith('ADMIN')
            ? 'admin'
            : 'member';
        const slug = canonicalName
          .normalize('NFD')
          .replace(/[\u0300-\u036f]/g, '')
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, '_')
          .replace(/^_+|_+$/g, '') || 'membre';
        const { salt, hash } = hashPassword(crypto.randomUUID());
        existing = {
          id: crypto.randomUUID(),
          email: `${slug}@membre.boroomyitte.local`,
          fullName: canonicalName,
          username: slug,
          role,
          isGroupMember: true,
          salt,
          hash,
          onboardingCompleted: true,
          createdAt: new Date().toISOString(),
        };
        accounts.push(existing);
        writeAccounts(accounts);
        broadcastEvent('snapshot_updated', { memberJoined: existing.username });
      }
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: true, user: toPublicMember(existing) }));
    } catch (e) {
      res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: false, error: String(e) }));
    }
    return;
  }

  if (cleanPath === '/api/members' && req.method === 'GET') {
    const accounts = readAccounts();
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ members: accounts.map(toPublicMember) }));
    return;
  }

  if (cleanPath === '/api/auth/reset-password' && req.method === 'POST') {
    try {
      const { email = '', newPassword = '' } = await readJsonBody(req);
      const norm = String(email).trim().toLowerCase();
      if (!norm || String(newPassword).length < 6) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ ok: false, error: 'Email et nouveau mot de passe (min 6 car.) requis.' }));
        return;
      }
      const accounts = readAccounts();
      const idx = accounts.findIndex((a) => a.email === norm);
      if (idx < 0) {
        res.writeHead(404, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ ok: false, error: 'Aucun compte enregistré avec cet email.' }));
        return;
      }
      const { salt, hash } = hashPassword(newPassword);
      accounts[idx] = { ...accounts[idx], salt, hash };
      writeAccounts(accounts);
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: true }));
    } catch (e) {
      res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: false, error: String(e) }));
    }
    return;
  }

  if (cleanPath === '/api/upload' && req.method === 'POST') {
    try {
      const body = await readJsonBody(req);
      const rawName = path.basename(String(body.fileName || 'document.txt'));
      const safeName = rawName.replace(/[^a-zA-Z0-9._-]/g, '_');
      const storedName = `${Date.now()}_${safeName}`;
      const ext = path.extname(safeName).toLowerCase().replace('.', '') || 'txt';
      const buf = body.base64Data
        ? Buffer.from(String(body.base64Data), 'base64')
        : Buffer.from(String(body.providedText || ''), 'utf8');

      fs.mkdirSync(UPLOADS_DIR, { recursive: true });
      fs.writeFileSync(path.join(UPLOADS_DIR, storedName), buf);

      let extractedText = typeof body.providedText === 'string' && body.providedText.trim()
        ? body.providedText.trim()
        : '';
      let unreadableWarning = null;

      if (!extractedText) {
        if (['txt', 'md', 'csv'].includes(ext)) {
          extractedText = buf.toString('utf8').trim();
        } else if (['webm', 'ogg', 'oga', 'm4a', 'mp4', 'mp3', 'wav', 'aac'].includes(ext)) {
          unreadableWarning = null;
        } else if (ext === 'pdf') {
          const latin = buf.toString('latin1');
          const chunks = [];
          const regex = /\(([^()]{3,200})\)/g;
          let m;
          while ((m = regex.exec(latin)) !== null && chunks.length < 180) {
            const clean = m[1].replace(/[^\x20-\x7E\xA0-\xFF]/g, ' ').trim();
            if (clean.length > 3 && !/^[0-9.\s]+$/.test(clean)) chunks.push(clean);
          }
          if (chunks.length >= 3) {
            extractedText = chunks.join(' ').replace(/\s+/g, ' ').slice(0, 12000);
          } else {
            unreadableWarning = 'PDF compressé ou numérisé sans couche texte lisible localement. Collez un extrait source pour générer un résumé fidèle sans invention.';
          }
        } else {
          unreadableWarning = `Format .${ext} enregistré (fichier original téléchargeable). L’extraction automatique complète nécessite un lecteur serveur/OCR ; ajoutez un extrait textuel source pour produire un résumé vérifiable.`;
        }
      }

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({
        ok: true,
        storageUrl: `/api/files/${encodeURIComponent(storedName)}`,
        fileSizeBytes: buf.length,
        extractedText: extractedText || null,
        unreadableWarning,
      }));
    } catch (e) {
      res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: false, error: String(e) }));
    }
    return;
  }

  if (cleanPath.startsWith('/api/files/') && req.method === 'DELETE') {
    const fileName = path.basename(decodeURIComponent(cleanPath.slice('/api/files/'.length)));
    const filePath = path.resolve(UPLOADS_DIR, fileName);
    if (filePath.startsWith(UPLOADS_DIR) && fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ ok: true }));
    return;
  }

  if (cleanPath.startsWith('/api/files/') && req.method === 'GET') {
    let rawSlug = cleanPath.slice('/api/files/'.length);
    try {
      rawSlug = decodeURIComponent(rawSlug);
    } catch {}
    const fileName = path.basename(rawSlug);
    const filePath = path.resolve(UPLOADS_DIR, fileName);
    if (!filePath.startsWith(UPLOADS_DIR) || !fs.existsSync(filePath)) {
      res.writeHead(404);
      res.end('File not found');
      return;
    }
    const ext = path.extname(fileName).toLowerCase();
    const audioMime = {
      '.webm': 'audio/webm',
      '.ogg': 'audio/ogg',
      '.oga': 'audio/ogg',
      '.m4a': 'audio/mp4',
      '.mp4': 'audio/mp4',
      '.mp3': 'audio/mpeg',
      '.wav': 'audio/wav',
      '.aac': 'audio/aac',
    }[ext];
    const stat = fs.statSync(filePath);
    const total = stat.size;

    if (audioMime) {
      const rangeHeader = req.headers.range;
      if (rangeHeader && /^bytes=\d*-\d*$/.test(rangeHeader)) {
        const [startStr, endStr] = rangeHeader.replace('bytes=', '').split('-');
        const start = startStr ? Math.min(Number(startStr), total - 1) : 0;
        const end = endStr ? Math.min(Number(endStr), total - 1) : Math.max(total - 1, 0);
        const chunkSize = Math.max(0, end - start + 1);
        res.writeHead(206, {
          'Content-Type': audioMime,
          'Content-Range': `bytes ${start}-${end}/${total}`,
          'Accept-Ranges': 'bytes',
          'Content-Length': chunkSize,
          'Cache-Control': 'no-cache',
        });
        fs.createReadStream(filePath, { start, end }).pipe(res);
      } else {
        res.writeHead(200, {
          'Content-Type': audioMime,
          'Accept-Ranges': 'bytes',
          'Content-Length': total,
          'Cache-Control': 'no-cache',
        });
        fs.createReadStream(filePath).pipe(res);
      }
      return;
    }

    const mime =
      ext === '.pdf'
        ? 'application/pdf'
        : ['.txt', '.md', '.csv'].includes(ext)
          ? 'text/plain; charset=utf-8'
          : 'application/octet-stream';
    res.writeHead(200, {
      'Content-Type': mime,
      'Content-Length': total,
      'Content-Disposition': `attachment; filename="${fileName}"`,
    });
    fs.createReadStream(filePath).pipe(res);
    return;
  }

  if (cleanPath === '/api/summarize-document' && req.method === 'POST') {
    try {
      const { documentId = '', title = '', sourceText = '' } = await readJsonBody(req);
      const clean = String(sourceText || '').trim();
      if (clean.length < 20) {
        res.writeHead(422, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({
          ok: false,
          error: 'Texte source insuffisant ou illisible : aucun résumé ne sera fabriqué sans contenu source vérifiable.',
        }));
        return;
      }

      const sentences = clean
        .split(/(?<=[.!?])\s+|\n+/)
        .map((s) => s.trim())
        .filter((s) => s.length > 15);
      const stopWords = new Set(['dans', 'pour', 'avec', 'cette', 'sont', 'être', 'nous', 'vous', 'mais', 'donc', 'plus', 'tout', 'elle', 'comme', 'leur', 'aussi', 'entre', 'that', 'this', 'with', 'from', 'have']);
      const freq = new Map();
      for (const word of clean.toLowerCase().split(/[^a-zàâçéèêëîïôûùüÿñæœ0-9'-]+/)) {
        if (word.length >= 5 && !stopWords.has(word)) {
          freq.set(word, (freq.get(word) || 0) + 1);
        }
      }
      const concepts = [...freq.entries()]
        .sort((a, b) => b[1] - a[1])
        .slice(0, 6)
        .map(([w, count]) => `${w} (${count} occurrence${count > 1 ? 's' : ''})`);

      const definitions = sentences.filter((s) => /(?:signifie|est un|est une|désigne|consiste|définit)/i.test(s)).slice(0, 4);
      const argumentsList = sentences.filter((s) => /(?:car|parce que|donc|ainsi|cependant|toutefois|montre|prouve)/i.test(s)).slice(0, 4);
      const citations = sentences.filter((s) => /(?:sourate|hadith|selon|référence|chapitre|article|http|page|\d{4})/i.test(s)).slice(0, 4);
      const conclusions = sentences.length >= 3 ? [sentences[sentences.length - 1]] : [];

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({
        ok: true,
        source_document_id: documentId,
        general_summary: sentences.slice(0, 3).join(' ') || clean.slice(0, 360),
        main_ideas: sentences.slice(0, 4),
        important_concepts: concepts,
        definitions: definitions.length ? definitions : ['Aucune définition explicite extraite dans ce passage.'],
        developed_arguments: argumentsList.length ? argumentsList : sentences.slice(0, 2),
        author_conclusions: conclusions.length ? conclusions : ['Voir les derniers paragraphes du document original.'],
        cited_references: citations.length ? citations : ['Aucune référence bibliographique explicite extraite.'],
        comprehension_questions: [
          `Quelle thèse centrale est soutenue dans « ${title || 'ce document'} » ?`,
          concepts.length ? `Comment l’auteur articule-t-il la notion clé de « ${concepts[0].split(' ')[0]} » ?` : 'Quels arguments appuient la conclusion du texte ?',
        ],
        unreadable_notices: clean.length < 120 ? ['Source courte : ce résumé ne couvre qu’un extrait limité fourni par l’utilisateur.'] : [],
        is_ai_assisted: true,
        status: 'draft',
      }));
    } catch (e) {
      res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: false, error: String(e) }));
    }
    return;
  }

  if (cleanPath === '/api/transcribe' && req.method === 'POST') {
    try {
      const { audioBase64 = '', mimeType = 'audio/webm', language = 'en' } =
        await readJsonBody(req);
      const env = loadDotEnv();
      if (!audioBase64) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ ok: false, error: 'Audio manquant.' }));
        return;
      }
      const audioBuf = Buffer.from(String(audioBase64), 'base64');
      const ext = mimeType.includes('mp4')
        ? 'm4a'
        : mimeType.includes('ogg')
          ? 'ogg'
          : 'webm';
      const langCode = String(language).split('-')[0].toLowerCase() || 'en';

      // Tier 1: Groq Whisper (ultra-rapide) ou OpenAI Whisper si clé présente dans .env
      const apiKey = (env.GROQ_API_KEY || env.OPENAI_API_KEY || '').trim();
      if (apiKey) {
        const isGroq = Boolean(env.GROQ_API_KEY && env.GROQ_API_KEY.trim());
        const endpoint = isGroq
          ? 'https://api.groq.com/openai/v1/audio/transcriptions'
          : 'https://api.openai.com/v1/audio/transcriptions';
        const form = new FormData();
        form.append(
          'file',
          new Blob([audioBuf], { type: mimeType }),
          `recording.${ext}`,
        );
        form.append('model', isGroq ? 'whisper-large-v3-turbo' : 'whisper-1');
        form.append('language', langCode);

        const wRes = await fetch(endpoint, {
          method: 'POST',
          headers: { Authorization: `Bearer ${apiKey}` },
          body: form,
        });
        if (wRes.ok) {
          const wJson = await wRes.json();
          const transcript = String(wJson?.text || '').trim();
          res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
          res.end(JSON.stringify({ ok: true, transcript, engine: isGroq ? 'groq-whisper' : 'openai-whisper' }));
          return;
        }
      }

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(
        JSON.stringify({
          ok: false,
          fallback: true,
          message:
            'Audio enregistré avec succès. Configurez GROQ_API_KEY ou OPENAI_API_KEY dans .env pour la transcription serveur automatique.',
        }),
      );
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: false, error: String(e) }));
    }
    return;
  }

  if (cleanPath === '/api/voice/amy-status' && req.method === 'GET') {
    const env = loadDotEnv();
    const meta = readAmyCloneMeta();
    const hasEleven = Boolean(env.ELEVENLABS_API_KEY && env.ELEVENLABS_API_KEY.trim());
    const hasFish = Boolean(env.FISH_API_KEY && env.FISH_API_KEY.trim());
    const sampleExists = fs.existsSync(AMY_REAL_SAMPLE_FILE);
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(
      JSON.stringify({
        ok: true,
        sampleExists,
        clonedReady: hasEleven || hasFish || sampleExists,
        provider: hasEleven
          ? 'elevenlabs'
          : hasFish
            ? 'fish_audio'
            : sampleExists
              ? 'chatterbox_free'
              : 'none',
        voiceId: (env.ELEVENLABS_VOICE_ID || meta.elevenlabsVoiceId || '').trim() || null,
      }),
    );
    return;
  }

  if (cleanPath === '/api/tts' && (req.method === 'GET' || req.method === 'POST')) {
    try {
      const body = req.method === 'POST' ? await readJsonBody(req) : {};
      const text = req.method === 'POST'
        ? body.text
        : urlObj.searchParams.get('text');
      const voiceKey = req.method === 'POST'
        ? body.voice
        : urlObj.searchParams.get('voice');
      const locale = req.method === 'POST'
        ? body.locale
        : urlObj.searchParams.get('locale');
      const rate = req.method === 'POST'
        ? body.rate
        : urlObj.searchParams.get('rate');
      const strictClone = req.method === 'POST'
        ? Boolean(body.strictClone)
        : urlObj.searchParams.get('strictClone') === '1';

      const env = loadDotEnv();
      const { filePath, engine, mime } = await synthesizeNeuralTts({
        text,
        voiceKey,
        locale,
        rate,
        env,
        strictClone,
      });
      const stat = fs.statSync(filePath);
      res.writeHead(200, {
        'Content-Type': mime || 'audio/mpeg',
        'Content-Length': stat.size,
        'Cache-Control': 'public, max-age=86400',
        'X-TTS-Engine': engine,
      });
      fs.createReadStream(filePath).pipe(res);
    } catch (e) {
      const status = Number(e?.statusCode) || 502;
      res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ ok: false, error: String(e) }));
    }
    return;
  }

  // Static Flutter Web assets
  const rel = cleanPath === '/' ? 'index.html' : cleanPath.replace(/^\/+/, '');
  let target = path.resolve(WEB_DIR, rel);
  if (!target.startsWith(WEB_DIR) || !fs.existsSync(target) || fs.statSync(target).isDirectory()) {
    target = path.join(WEB_DIR, 'index.html');
  }
  if (!fs.existsSync(target)) {
    res.writeHead(503, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({
      ok: false,
      error: 'Flutter Web build absent (mobile/build/web/index.html manquant). Exécutez `cd mobile && flutter build web --no-tree-shake-icons`.',
    }));
    return;
  }
  const ext = path.extname(target).toLowerCase();
  res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
  const stream = fs.createReadStream(target);
  stream.on('error', (err) => {
    if (!res.headersSent) res.writeHead(500);
    res.end(String(err));
  });
  stream.pipe(res);
});

server.listen(PORT, HOST, () => {
  console.log(`BOROOM YITTE Full-Stack Web Server ready at: http://127.0.0.1:${PORT}/`);
  const nets = os.networkInterfaces();
  for (const entries of Object.values(nets)) {
    for (const info of entries || []) {
      if (info.family === 'IPv4' && !info.internal) {
        console.log(`LAN Network Link (same Wi-Fi): http://${info.address}:${PORT}/#/auth`);
      }
    }
  }
  console.log(`Persistent DB file: ${DB_FILE}`);
});
