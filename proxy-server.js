const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3333;
const HOST = '127.0.0.1';

// MIME types for static files
const mime = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
};

// Set CORS headers
function setCORS(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

// Simple Ollama proxy using native /api/chat endpoint
async function proxyOllamaChat(body) {
  const res = await fetch('https://ollama.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': 'Bearer ' + (process.env.OLLAMA_API_KEY || ''),
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(body)
  });
  return await res.json();
}

const server = http.createServer(async (req, res) => {
  const url = req.url;
  const method = req.method;

  // Handle CORS preflight
  if (method === 'OPTIONS') {
    setCORS(res);
    res.writeHead(204);
    res.end();
    return;
  }

  // API proxy: /api/generate
  if (url === '/api/generate' && method === 'POST') {
    setCORS(res);
    let bodyStr = '';
    req.on('data', chunk => bodyStr += chunk);
    req.on('end', async () => {
      try {
        const params = JSON.parse(bodyStr);
        console.log('[PROXY]', params.model, params.messages?.[0]?.content?.slice(0, 40));
        
        const result = await proxyOllamaChat(params);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(result));
      } catch (err) {
        console.error('[ERR]', err.message);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  // Static files
  let fp = url === '/' ? 'data-gen.html' : decodeURIComponent(url);
  fp = path.join(__dirname, fp);
  
  fs.readFile(fp, (err, data) => {
    if (err) {
      if (err.code === 'ENOENT') {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('Not found: ' + url);
      } else {
        res.writeHead(500);
        res.end('Server error');
      }
      return;
    }
    const ext = path.extname(fp);
    const ct = mime[ext] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': ct });
    res.end(data);
  });
});

server.listen(PORT, HOST, () => {
  console.log('Lingo Proxy running at http://' + HOST + ':' + PORT);
  console.log('API: http://' + HOST + ':' + PORT + '/api/generate');
  console.log('Set OLLAMA_API_KEY env var with your key');
});
