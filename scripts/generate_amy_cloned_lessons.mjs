import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const ENV_FILE = path.join(ROOT, '.env');
const SAMPLE_FILE = path.join(ROOT, 'mobile', 'assets', 'audio', 'amy', 'amy_real_intro.ogg');
const OUT_DIR = path.join(ROOT, 'mobile', 'assets', 'audio', 'amy', 'cloned');

function loadEnv() {
  const out = {};
  if (!fs.existsSync(ENV_FILE)) return out;
  for (const line of fs.readFileSync(ENV_FILE, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Za-z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m) out[m[1]] = m[2].replace(/^['"]|['"]$/g, '').trim();
  }
  return out;
}

const PHRASES = [
  { id: 'topic_cafe', text: "Hey! Welcome in — it's quite busy this morning, isn't it? What can I get for you, and how has your day been so far?" },
  { id: 'topic_day', text: "Hey! How's your week going? Tell me one thing that went really well recently, or something you're looking forward to." },
  { id: 'topic_travel', text: "Hi there! Welcome to the hotel. Do you have a reservation under your name, and is this your first time visiting the city?" },
  { id: 'topic_interview', text: "Thanks for coming in today! Before we dive into technical questions, could you briefly walk me through your background and what motivates you?" },
  { id: 'topic_project', text: "Hey, glad we could catch up! How is your current project going, and is there anything blocking you right now?" },
  { id: 'topic_debate', text: "I'd love to hear your honest perspective: do you think artificial intelligence makes people more creative, or more dependent?" },
];

async function main() {
  const env = loadEnv();
  const hasEleven = Boolean(env.ELEVENLABS_API_KEY);
  const hasFish = Boolean(env.FISH_API_KEY);
  if (!hasEleven && !hasFish) {
    console.error('Ajoutez ELEVENLABS_API_KEY ou FISH_API_KEY dans .env avant de lancer ce script.');
    process.exit(1);
  }
  if (!fs.existsSync(SAMPLE_FILE)) {
    console.error(`Échantillon vocal introuvable : ${SAMPLE_FILE}`);
    process.exit(1);
  }
  fs.mkdirSync(OUT_DIR, { recursive: true });

  let voiceId = env.ELEVENLABS_VOICE_ID || '';
  if (hasEleven && !voiceId) {
    console.log('Clonage automatique de amy_real_intro.ogg sur ElevenLabs...');
    const form = new FormData();
    form.append('name', 'Amy BOROOM YITTE');
    form.append('files', new Blob([fs.readFileSync(SAMPLE_FILE)], { type: 'audio/ogg' }), 'amy_real_intro.ogg');
    const addRes = await fetch('https://api.elevenlabs.io/v1/voices/add', {
      method: 'POST',
      headers: { 'xi-api-key': env.ELEVENLABS_API_KEY },
      body: form,
    });
    if (!addRes.ok) throw new Error(`ElevenLabs add voice failed: ${addRes.status} ${await addRes.text()}`);
    const data = await addRes.json();
    voiceId = data.voice_id;
    console.log(`Voix clonée créée ! ELEVENLABS_VOICE_ID=${voiceId}`);
  }

  for (const item of PHRASES) {
    const dest = path.join(OUT_DIR, `${item.id}.mp3`);
    console.log(`Synthèse clonée : ${item.id}...`);
    let res;
    if (hasEleven) {
      res = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${encodeURIComponent(voiceId)}`, {
        method: 'POST',
        headers: {
          'xi-api-key': env.ELEVENLABS_API_KEY,
          'Content-Type': 'application/json',
          Accept: 'audio/mpeg',
        },
        body: JSON.stringify({
          text: item.text,
          model_id: 'eleven_multilingual_v2',
          voice_settings: { stability: 0.52, similarity_boost: 0.88, style: 0.25 },
        }),
      });
    } else {
      const sampleB64 = fs.readFileSync(SAMPLE_FILE).toString('base64');
      res = await fetch('https://api.fish.audio/v1/tts', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.FISH_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text: item.text,
          format: 'mp3',
          references: [{ audio: sampleB64, text: "Hello, my name is Amy. I'm twenty years old and I live in Villejuif." }],
        }),
      });
    }
    if (!res.ok) throw new Error(`TTS failed for ${item.id}: ${res.status}`);
    fs.writeFileSync(dest, Buffer.from(await res.arrayBuffer()));
  }
  console.log(`Terminé ! Fichiers clonés dans ${OUT_DIR}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
