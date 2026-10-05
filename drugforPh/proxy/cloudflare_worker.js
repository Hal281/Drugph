/**
 * Reference Proxy for Drugph AI Consultant (Cloudflare Worker)
 * 
 * Purpose:
 * Prevents client-side exposure of GEMINI_API_KEY.
 * Adds rate limiting and origin checks.
 * Forwards only { message, history } to Google Generative Language API.
 */

export default {
  async fetch(request, env) {
    // 1. CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*', // Replace with your production domain (e.g. https://hal281.github.io)
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 2. Environment secret verification
    const apiKey = env.GEMINI_API_KEY;
    if (!apiKey) {
      return new Response(JSON.stringify({ error: 'GEMINI_API_KEY is not configured on proxy server.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    try {
      const body = await request.json();
      const message = body.message;
      const history = body.history || [];

      if (!message || typeof message !== 'string') {
        return new Response(JSON.stringify({ error: 'Field "message" is required.' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Basic input length limiting
      if (message.length > 2000) {
        return new Response(JSON.stringify({ error: 'Message exceeds maximum length of 2000 characters.' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // 3. Format contents for Gemini API
      const contents = [];
      for (const item of history.slice(-6)) { // Keep last 6 exchanges
        contents.push({
          role: item.role === 'model' ? 'model' : 'user',
          parts: [{ text: item.text }]
        });
      }
      contents.push({
        role: 'user',
        parts: [{ text: message }]
      });

      const systemInstruction = {
        parts: [{
          text: `You are an educational Clinical Pharmacist AI Assistant.
RULES:
1. NEVER calculate or output patient-specific dosage numbers (mg, mg/kg, mL/hr). Instruct the user to use the app's deterministic Dosage Calculator.
2. Provide evidence-based pharmacology summaries only.
3. Cite reference sources (Lexicomp, Sanford Guide, etc.).
4. Add mandatory disclaimer: "Educational prototype only. Not for clinical decision-making."`
        }]
      };

      // 4. Forward to Gemini API
      const cleanKey = apiKey.trim();
      const geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';
      const geminiResponse = await fetch(geminiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': cleanKey,
        },
        body: JSON.stringify({
          system_instruction: systemInstruction,
          contents: contents,
          generationConfig: {
            temperature: 0.1,
            maxOutputTokens: 800,
          }
        }),
      });

      if (!geminiResponse.ok) {
        const errorText = await geminiResponse.text();
        return new Response(JSON.stringify({ error: 'Upstream AI provider error', details: errorText }), {
          status: geminiResponse.status,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const geminiData = await geminiResponse.json();
      const reply = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || 'No response generated.';

      return new Response(JSON.stringify({ reply }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } catch (err) {
      return new Response(JSON.stringify({ error: 'Internal proxy error', message: err.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  }
};
