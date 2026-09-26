const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// In-memory cache for fast repeat requests
const streamCache = new Map();
const lyricsCache = new Map();

// Root & Health
app.get('/', (req, res) => {
  res.json({
    name: 'Muscia Streaming Backend',
    status: 'online',
    version: '1.0.0',
    endpoints: [
      '/health',
      '/api/stream?title=...&artist=...&id=...',
      '/api/lyrics?title=...&artist=...',
      '/api/search?q=...'
    ]
  });
});

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Dedicated Music Search API (Audius Music Protocol - 100% Full Unblocked Songs)
app.get('/api/music/search', async (req, res) => {
  const { q } = req.query;
  if (!q || !q.trim()) {
    return res.status(400).json({ success: false, tracks: [] });
  }

  const query = q.trim();
  const cacheKey = `music_search_${query.toLowerCase()}`;
  if (streamCache.has(cacheKey)) {
    return res.json({ success: true, tracks: streamCache.get(cacheKey) });
  }

  try {
    const aRes = await axios.get(`https://discoveryprovider.audius.co/v1/tracks/search`, {
      params: { query: query, app_name: 'muscia' },
      timeout: 5000
    });

    if (aRes.data && aRes.data.data) {
      const tracks = aRes.data.data.map(track => ({
        id: `audius_${track.id}`,
        title: track.title,
        artist: track.user ? track.user.name : 'Unknown Artist',
        album: 'Audius',
        durationMs: (track.duration || 180) * 1000,
        artworkUrl: track.artwork ? (track.artwork['480x480'] || track.artwork['150x150'] || '') : '',
        streamUrl: `https://discoveryprovider.audius.co/v1/tracks/${track.id}/stream?app_name=muscia`
      }));

      streamCache.set(cacheKey, tracks);
      return res.json({ success: true, tracks });
    }
  } catch (err) {
    console.error('Audius search error:', err.message);
  }

  res.json({ success: false, tracks: [] });
});

// Dedicated Music Stream API
app.get('/api/music/stream', async (req, res) => {
  const { id } = req.query;
  if (!id) {
    return res.status(400).json({ success: false, error: 'ID is required' });
  }

  const cleanId = id.replace('audius_', '');
  const directUrl = `https://discoveryprovider.audius.co/v1/tracks/${cleanId}/stream?app_name=muscia`;
  res.json({ success: true, streamUrl: directUrl });
});

// Legacy Stream Resolver
app.get('/api/stream', async (req, res) => {
  const { title, artist, id } = req.query;

  if (!title && !id) {
    return res.status(400).json({ success: false, error: 'Title or ID is required' });
  }

  if (id && id.startsWith('audius_')) {
    const cleanId = id.replace('audius_', '');
    return res.json({
      success: true,
      streamUrl: `https://discoveryprovider.audius.co/v1/tracks/${cleanId}/stream?app_name=muscia`
    });
  }

  res.status(404).json({ success: false, message: 'Use dedicated /api/music/search or client resolver' });
});

// Full Audio Streaming Proxy (Bypasses mobile ISP blocks and ExoPlayer 403)
app.get('/api/proxy', async (req, res) => {
  const { url } = req.query;
  if (!url) {
    return res.status(400).send('URL is required');
  }

  try {
    const targetUrl = decodeURIComponent(url);
    const headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      'Accept': '*/*',
      'Accept-Encoding': 'identity',
    };

    if (req.headers.range) {
      headers['Range'] = req.headers.range;
    }

    const response = await axios({
      method: 'GET',
      url: targetUrl,
      headers: headers,
      responseType: 'stream',
      validateStatus: (status) => status >= 200 && status < 400,
      timeout: 15000,
    });

    res.status(response.status);
    if (response.headers['content-type']) res.setHeader('Content-Type', response.headers['content-type']);
    if (response.headers['content-length']) res.setHeader('Content-Length', response.headers['content-length']);
    if (response.headers['content-range']) res.setHeader('Content-Range', response.headers['content-range']);
    if (response.headers['accept-ranges']) res.setHeader('Accept-Ranges', response.headers['accept-ranges']);

    response.data.pipe(res);
  } catch (err) {
    console.error('Proxy stream error:', err.message);
    if (!res.headersSent) {
      res.status(502).send('Proxy streaming failed: ' + err.message);
    }
  }
});

// Synchronized Lyrics Resolver (LrcLib API)
app.get('/api/lyrics', async (req, res) => {
  const { title, artist } = req.query;
  if (!title) {
    return res.status(400).json({ success: false, error: 'Title is required' });
  }

  const cacheKey = `${title}_${artist || ''}`.toLowerCase().trim();
  if (lyricsCache.has(cacheKey)) {
    return res.json({ success: true, lyrics: lyricsCache.get(cacheKey) });
  }

  try {
    const lRes = await axios.get('https://lrclib.net/api/get', {
      params: {
        track_name: title,
        artist_name: artist || ''
      },
      timeout: 4000
    });

    if (lRes.data) {
      const lyrics = lRes.data.syncedLyrics || lRes.data.plainLyrics;
      if (lyrics) {
        lyricsCache.set(cacheKey, lyrics);
        return res.json({ success: true, lyrics, synced: !!lRes.data.syncedLyrics });
      }
    }
  } catch (_) {}

  res.json({ success: false, lyrics: null });
});

app.listen(PORT, () => {
  console.log(`Muscia backend server running on port ${PORT}`);
});
