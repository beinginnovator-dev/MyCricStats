/**
 * Cloudflare Pages Function — GET /api/news
 */
const FEEDS = [
  { name: 'ESPNcricinfo', url: 'https://www.espncricinfo.com/rss/content/story/feeds/0.xml' },
  { name: 'Google Cricket', url: 'https://news.google.com/rss/search?q=cricket+when:2d&hl=en-IN&gl=IN&ceid=IN:en' }
];

export async function onRequest() {
  const headers = new Headers({
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'application/json',
    'Cache-Control': 'public, max-age=300'
  });
  try {
    const results = await Promise.all(
      FEEDS.map(async (f) => {
        try {
          const res = await fetch(f.url, {
            headers: {
              'User-Agent': 'Mozilla/5.0 MyCricStatsNews/1.0',
              Accept: 'application/rss+xml, application/xml, text/xml, */*'
            }
          });
          if (!res.ok) return [];
          return parseRss(await res.text(), f.name);
        } catch (e) {
          return [];
        }
      })
    );
    let all = [].concat(...results);
    const seen = new Set();
    all = all.filter((n) => {
      const k = (n.title || '').toLowerCase().slice(0, 80);
      if (!k || seen.has(k)) return false;
      seen.add(k);
      return true;
    });
    all.sort((a, b) => (Date.parse(b.pub || 0) || 0) - (Date.parse(a.pub || 0) || 0));
    return new Response(JSON.stringify({ data: all.slice(0, 40) }), { status: 200, headers });
  } catch (e) {
    return new Response(JSON.stringify({ message: String(e.message || e), data: [] }), { status: 502, headers });
  }
}

function parseRss(xml, source) {
  const items = [];
  const parts = String(xml).split(/<item[\s>]/i);
  for (let i = 1; i < parts.length; i++) {
    const block = parts[i].split(/<\/item>/i)[0] || '';
    const title = textOf(block, 'title');
    let link = textOf(block, 'link');
    const pub = textOf(block, 'pubDate') || textOf(block, 'published');
    let desc = textOf(block, 'description') || '';
    desc = desc.replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/\s+/g, ' ').trim().slice(0, 220);
    let image = '';
    let m = block.match(/<enclosure[^>]+url=["']([^"']+)["']/i);
    if (m) image = m[1];
    if (!image) {
      m = block.match(/<media:content[^>]+url=["']([^"']+)["']/i);
      if (m) image = m[1];
    }
    if (!image) {
      m = block.match(/<media:thumbnail[^>]+url=["']([^"']+)["']/i);
      if (m) image = m[1];
    }
    if (!image) {
      m = block.match(/<img[^>]+src=["']([^"']+)["']/i);
      if (m) image = m[1];
    }
    if (!link || link.indexOf('http') !== 0) {
      const g = textOf(block, 'guid');
      if (g && g.indexOf('http') === 0) link = g;
    }
    if (title) items.push({ title: title, link: link, pub: pub, desc: desc, image: image, source: source });
  }
  return items;
}

function textOf(block, tag) {
  const cdata = block.match(new RegExp('<' + tag + '[^>]*>\\s*<!\\[CDATA\\[([\\s\\S]*?)\\]\\]>\\s*</' + tag + '>', 'i'));
  if (cdata) return cdata[1].trim();
  const plain = block.match(new RegExp('<' + tag + '[^>]*>([\\s\\S]*?)</' + tag + '>', 'i'));
  if (plain) return plain[1].replace(/<[^>]+>/g, '').trim();
  return '';
}
