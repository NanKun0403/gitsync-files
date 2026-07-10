// Cloudflare Worker — 代理 GitHub raw content，加速国内访问
const GITHUB_USER = 'YOUR_USERNAME';
const GITHUB_REPO = 'gitsync-files';
const GITHUB_TOKEN = ''; // 可选，避免 rate limit

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  const url = new URL(request.url);
  const path = url.pathname; // /files/{uuid}/{filename}

  // 代理到 GitHub raw
  const githubUrl = `https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main${path}`;

  const headers = new Headers();
  if (GITHUB_TOKEN) {
    headers.set('Authorization', `Bearer ${GITHUB_TOKEN}`);
  }

  const response = await fetch(githubUrl, { headers });

  // 添加 CORS 头
  const newHeaders = new Headers(response.headers);
  newHeaders.set('Access-Control-Allow-Origin', '*');
  newHeaders.set('Cache-Control', 'public, max-age=3600');

  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers: newHeaders,
  });
}