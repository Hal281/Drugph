# Drugph Backend AI Proxy Reference

This proxy secures your Gemini API Key by keeping it server-side, preventing direct exposure in browser network inspection, and applying basic rate-limiting and payload validation.

## Deployment Options

### Option A: Cloudflare Workers (Recommended - Free Tier)
1. Install Wrangler CLI: `npm install -g wrangler`
2. Login to Cloudflare: `wrangler login`
3. Set your secret: `wrangler secret put GEMINI_API_KEY` (paste your Google AI Studio key)
4. Deploy: `wrangler deploy cloudflare_worker.js --name drugph-ai-proxy`
5. Copy your worker URL (e.g., `https://drugph-ai-proxy.your-subdomain.workers.dev`).

### Option B: Google Cloud Functions / Vercel Serverless
Store `GEMINI_API_KEY` in environment secrets and forward `{ message, history }` to `https://generativelanguage.googleapis.com`.

## Configuring Flutter Client

Build or run Flutter with `--dart-define=AI_PROXY_URL=...`:
```bash
flutter run -d chrome --dart-define=AI_PROXY_URL="https://drugph-ai-proxy.your-subdomain.workers.dev"
```
Or for web deploy:
```bash
flutter build web --dart-define=AI_PROXY_URL="https://drugph-ai-proxy.your-subdomain.workers.dev"
```
