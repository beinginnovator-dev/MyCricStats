/**
 * MCS AI commentary voice.
 * Requires OPENAI_API_KEY in Cloudflare Pages → Settings → Variables and Secrets.
 * If the key is missing or the provider is unavailable, the viewer falls back
 * to its male-preferred device TTS voice.
 */
export async function onRequest(context) {
  const { request, env } = context;
  const headers = {
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff'
  };
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: {
      ...headers,
      'Access-Control-Allow-Origin': request.headers.get('Origin') || '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type'
    }});
  }
  if (request.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405, headers: { ...headers, 'Content-Type': 'application/json' }
    });
  }
  if (!env || !env.OPENAI_API_KEY) {
    return new Response(JSON.stringify({ error: 'AI voice is not configured; use device TTS fallback.' }), {
      status: 503, headers: { ...headers, 'Content-Type': 'application/json' }
    });
  }

  try {
    const body = await request.json();
    const text = String(body && body.text || '').replace(/\s+/g, ' ').trim();
    const language = body && body.language === 'hi' ? 'hi' : 'en';
    if (!text || text.length > 1200) {
      return new Response(JSON.stringify({ error: 'Commentary text must be between 1 and 1200 characters.' }), {
        status: 400, headers: { ...headers, 'Content-Type': 'application/json' }
      });
    }

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 18000);
    let upstream;
    try {
      upstream = await fetch('https://api.openai.com/v1/audio/speech', {
        method: 'POST',
        headers: {
          'Authorization': 'Bearer ' + env.OPENAI_API_KEY,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini-tts',
          voice: 'onyx',
          input: text,
          response_format: 'mp3',
          instructions: language === 'hi'
            ? 'Speak as an energetic male Indian cricket stadium commentator in natural Hindi. Sound like a live international sports broadcast: confident, lively, expressive, crisp diction, varied intonation, punchy delivery, and natural excitement on boundaries and wickets. Keep it clear and believable, never robotic or over-the-top. Preserve all player and team names exactly.'
            : 'Speak as an energetic male Indian cricket stadium commentator in natural Indian English. Sound like a live international sports broadcast: confident, lively, expressive, crisp diction, varied intonation, punchy delivery, and natural excitement on boundaries and wickets. Keep it clear and believable, never robotic or over-the-top. Preserve all player and team names exactly.'
        }),
        signal: controller.signal
      });
    } finally {
      clearTimeout(timer);
    }

    if (!upstream.ok) {
      const detail = await upstream.text().catch(() => '');
      console.error('MCS AI voice provider error', upstream.status, detail.slice(0, 500));
      return new Response(JSON.stringify({ error: 'AI voice provider unavailable.' }), {
        status: 502, headers: { ...headers, 'Content-Type': 'application/json' }
      });
    }

    return new Response(upstream.body, {
      status: 200,
      headers: { ...headers, 'Content-Type': 'audio/mpeg' }
    });
  } catch (error) {
    console.error('MCS AI voice route failed', error);
    return new Response(JSON.stringify({ error: 'AI voice request failed.' }), {
      status: 502, headers: { ...headers, 'Content-Type': 'application/json' }
    });
  }
}
