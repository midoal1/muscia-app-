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

// Stream Resolver
app.get('/api/stream', async (req, res) => {
  const { title, artist, id } = req.query;

  if (!title && !id) {
    return res.status(400).json({ success: false, error: 'Title or ID is required' });
  }

  const cacheKey = `${title || ''}_${artist || ''}_${id || ''}`.toLowerCase().trim();
  if (streamCache.has(cacheKey)) {
    return res.json({ success: true, streamUrl: streamCache.get(cacheKey), cached: true });
  }

  try {
    // Note: Do NOT return iTunes previewUrl because it is strictly limited to 30 seconds.
    // The mobile client uses direct native high-bitrate YouTube stream extraction for 100% full songs.
    res.status(404).json({ success: false, message: 'Use mobile native full audio extraction engine' });

    // 2. Fallback: Piped Audio Stream resolver if video ID exists
    if (id && id.length === 11 && !id.startsWith('itunes_')) {
      const pipedInstances = [
        'https://pipedapi.kavin.rocks',
        'https://api.piped.privacy.com.de',
        'https://piped-api.lunar.icu'
      ];

      for (const instance of pipedInstances) {
        try {
          const pRes = await axios.get(`${instance}/streams/${id}`, { timeout: 3500 });
          if (pRes.data && pRes.data.audioStreams && pRes.data.audioStreams.length > 0) {
            const bestAudio = pRes.data.audioStreams.sort((a, b) => (b.bitrate || 0) - (a.bitrate || 0))[0];
            if (bestAudio && bestAudio.url) {
              streamCache.set(cacheKey, bestAudio.url);
              return res.json({
                success: true,
                streamUrl: bestAudio.url,
                source: 'piped_proxy'
              });
            }
          }
        } catch (_) {
          continue;
        }
      }
    }

    res.status(404).json({ success: false, error: 'No stream available' });
  } catch (err) {
    console.error('Stream error:', err.message);
    res.status(500).json({ success: false, error: err.message });
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
