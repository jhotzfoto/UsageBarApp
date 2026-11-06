// UsageBarApp for iPhone (Scriptable). Home Screen (small, medium) and Lock Screen (circular,
// rectangular, inline) widgets showing Claude session, weekly and extra usage.
//
// Data, newest of:
//   1. The phone's own reading: your claude.ai session key (pasted once, kept in the iOS Keychain)
//      sent with a plain request to claude.ai. Works with the Mac off. If claude.ai's bot check
//      blocks the request, this route stops; nothing tries to get around it.
//   2. The Mac app's shared reading in Scriptable's iCloud folder (UsageBarApp/snapshot.json).
// Only percentages, reset times and amounts are read. The key goes only to claude.ai.

const GREEN = new Color('#34C759'), AMBER = new Color('#FF9F0A'), RED = new Color('#FF3B30');
const DIM = new Color('#8E8E93');
const STALE_MIN = 20;
const fm = FileManager.iCloud();
const dir = fm.joinPath(fm.documentsDirectory(), 'UsageBarApp');
const CACHE = fm.joinPath(dir, 'phone-reading.json');
const MAC = fm.joinPath(dir, 'snapshot.json');

const KEY = 'claude_sessionKey', ORG = 'claude_org';

function color(p) { return p >= 90 ? RED : (p >= 70 ? AMBER : GREEN); }
function pct(l, now) { return l.resetsAt && new Date(l.resetsAt) <= now ? 0 : l.percent; }

// Same shape as the Mac snapshot: {fetchedAt, limits[{key,label,group,percent,resetsAt}], extra, source}
function parse(raw) {
  const limits = [];
  for (const l of (raw.limits || [])) {
    if (l.kind === 'session') limits.push({key: 'session', label: 'Session', group: 'session', percent: l.percent, resetsAt: l.resets_at});
    else if (l.kind === 'weekly_all') limits.push({key: 'weekly_all', label: 'Weekly', group: 'weekly', percent: l.percent, resetsAt: l.resets_at});
    else {
      const m = l.scope && l.scope.model ? l.scope.model.display_name : l.kind;
      limits.push({key: 'weekly_' + m, label: m, group: 'weekly', percent: l.percent, resetsAt: l.resets_at});
    }
  }
  if (!limits.length) {
    if (raw.five_hour) limits.push({key: 'session', label: 'Session', group: 'session', percent: raw.five_hour.utilization, resetsAt: raw.five_hour.resets_at});
    if (raw.seven_day) limits.push({key: 'weekly_all', label: 'Weekly', group: 'weekly', percent: raw.seven_day.utilization, resetsAt: raw.seven_day.resets_at});
  }
  let extra = null;
  const sp = raw.spend;
  if (sp && sp.enabled && sp.limit) {
    const money = m => (m ? m.amount_minor : 0) / Math.pow(10, m ? m.exponent : 2);
    const limit = money(sp.limit), used = money(sp.used);
    if (limit > 0) extra = {used, limit, currency: sp.limit.currency, percent: sp.percent != null ? sp.percent : used / limit * 100};
  }
  return {fetchedAt: new Date().toISOString(), limits, extra, source: 'phone'};
}

async function get(path, key) {
  const r = new Request('https://claude.ai' + path);
  r.headers = {Cookie: 'sessionKey=' + key, Accept: 'application/json'};
  r.timeoutInterval = 15;
  const text = await r.loadString();
  const status = r.response ? r.response.statusCode : 0;
  const type = (r.response && r.response.headers && (r.response.headers['Content-Type'] || r.response.headers['content-type'])) || '';
  if (/html/i.test(type) || /^\s*</.test(text)) throw new Error('blocked');
  let j = null;
  try { j = JSON.parse(text); } catch (e) {}
  if (status === 401 || status === 403) throw new Error('badKey');
  if (status !== 200 || !j) throw new Error('HTTP ' + status);
  return j;
}

async function readOwn() {
  if (!Keychain.contains(KEY)) throw new Error('noKey');
  const key = Keychain.get(KEY);
  let org = Keychain.contains(ORG) ? Keychain.get(ORG) : null;
  if (!org) {
    const orgs = await get('/api/organizations', key);
    const o = Array.isArray(orgs) ? (orgs.find(g => (g.capabilities || []).includes('chat')) || orgs[0]) : null;
    if (!o) throw new Error('badKey');
    org = o.uuid;
    Keychain.set(ORG, org);
  }
  const r = parse(await get('/api/organizations/' + org + '/usage', key));
  if (!r.limits.length) throw new Error('no data');
  return r;
}

function readJSON(path) {
  try {
    if (!fm.fileExists(path)) return null;
    return JSON.parse(fm.readString(path));
  } catch (e) { return null; }
}

async function getReading() {
  if (!fm.fileExists(dir)) fm.createDirectory(dir, true);
  let own = null, err = null;
  try {
    own = await readOwn();
    fm.writeString(CACHE, JSON.stringify(own));
  } catch (e) { err = e.message; }
  // Newest of: fresh phone reading, cached phone reading, Mac snapshot.
  for (const p of [MAC, CACHE]) { try { await fm.downloadFileFromiCloud(p); } catch (e) {} }
  const candidates = [own, readJSON(CACHE), readJSON(MAC)].filter(r => r && r.limits && r.limits.length);
  candidates.sort((a, b) => new Date(b.fetchedAt) - new Date(a.fetchedAt));
  return {reading: candidates[0] || null, err};
}

function addCountdown(stack, resetsAt, size) {
  const d = stack.addDate(new Date(resetsAt));
  d.applyTimerStyle();
  d.font = Font.mediumMonospacedSystemFont(size);
  return d;
}

function ageText(r, now) {
  const min = Math.round((now - new Date(r.fetchedAt)) / 60000);
  const src = r.source === 'mac' ? 'Mac' : 'phone';
  return (min > STALE_MIN ? '⚠︎ ' : '') + (min < 1 ? 'now' : min + 'm ago') + ' · ' + src;
}

function bar(stack, p, c, width) {
  const ctx = new DrawContext();
  ctx.size = new Size(width, 6);
  ctx.opaque = false;
  ctx.respectScreenScale = true;
  const bg = new Path(); bg.addRoundedRect(new Rect(0, 0, width, 6), 3, 3);
  ctx.addPath(bg); ctx.setFillColor(new Color('#8E8E93', 0.25)); ctx.fillPath();
  const fg = new Path(); fg.addRoundedRect(new Rect(0, 0, Math.max(6, width * Math.min(1, p / 100)), 6), 3, 3);
  ctx.addPath(fg); ctx.setFillColor(c); ctx.fillPath();
  const img = stack.addImage(ctx.getImage());
  img.imageSize = new Size(width, 6);
}

function build(family, reading, err) {
  const now = new Date();
  const w = new ListWidget();
  w.refreshAfterDate = new Date(now.getTime() + 15 * 60000);
  w.url = 'https://claude.ai/settings/usage';
  if (!reading) {
    const t = w.addText(err === 'noKey' ? 'Open Scriptable to set up' : 'No Claude reading yet');
    t.font = Font.systemFont(12);
    return w;
  }
  const s = reading.limits.find(l => l.group === 'session');
  const wk = reading.limits.find(l => l.key === 'weekly_all') || reading.limits.find(l => l.group === 'weekly');
  const sp = s ? pct(s, now) : null, wp = wk ? pct(wk, now) : null;
  const live = s && s.resetsAt && new Date(s.resetsAt) > now && s.percent > 0;

  if (family === 'accessoryInline') {
    w.addText('S ' + Math.round(sp) + '% · W ' + Math.round(wp) + '%');
    return w;
  }
  if (family === 'accessoryCircular') {
    w.addAccessoryWidgetBackground = true;
    const t = w.addText(Math.round(sp) + '%');
    t.font = Font.boldRoundedSystemFont(16); t.centerAlignText();
    if (live) { const c = addCountdown(w, s.resetsAt, 9); c.centerAlignText(); }
    return w;
  }
  if (family === 'accessoryRectangular') {
    const t = w.addText('Claude  S ' + Math.round(sp) + '%  W ' + Math.round(wp) + '%');
    t.font = Font.boldSystemFont(13);
    const row = w.addStack();
    if (live) { const l = row.addText('resets in '); l.font = Font.systemFont(12); addCountdown(row, s.resetsAt, 12); }
    else { const l = row.addText('new session available'); l.font = Font.systemFont(12); }
    const a = w.addText(ageText(reading, now)); a.font = Font.systemFont(10);
    return w;
  }

  // Home Screen
  const title = w.addText('Claude');
  title.font = Font.boldSystemFont(12); title.textColor = DIM;
  w.addSpacer(4);
  const rows = family === 'small' ? [s] : reading.limits.slice(0, 3);
  for (const l of rows.filter(Boolean)) {
    const p = pct(l, now);
    const head = w.addStack();
    const name = head.addText(family === 'small' ? '' : l.label);
    name.font = Font.systemFont(11);
    head.addSpacer();
    const v = head.addText(Math.round(p) + '%');
    v.font = family === 'small' ? Font.boldRoundedSystemFont(30) : Font.boldSystemFont(12);
    v.textColor = color(p);
    w.addSpacer(2);
    bar(w, p, color(p), family === 'small' ? 130 : 290);
    w.addSpacer(4);
  }
  if (live) {
    const row = w.addStack();
    const l = row.addText('resets in '); l.font = Font.systemFont(11); l.textColor = DIM;
    addCountdown(row, s.resetsAt, 11);
  }
  if (family === 'small' && wk) { const t = w.addText('Weekly ' + Math.round(wp) + '%'); t.font = Font.systemFont(11); t.textColor = DIM; }
  if (family !== 'small' && reading.extra) {
    const e = reading.extra;
    const t = w.addText('Extra usage $' + e.used.toFixed(2) + ' / $' + e.limit.toFixed(2) + ' ' + e.currency + ' (' + Math.round(e.percent) + '%)');
    t.font = Font.systemFont(11); t.textColor = color(e.percent);
  }
  w.addSpacer();
  const a = w.addText(ageText(reading, now));
  a.font = Font.systemFont(9); a.textColor = DIM;
  return w;
}

const ERRORS = {
  noKey: 'No session key yet',
  badKey: 'Session key expired or wrong. Paste a new one.',
  blocked: "claude.ai's bot check blocked the phone's request. Showing the Mac's reading instead.",
};

// One-time setup: paste the claude.ai session key (copied on the Mac; see README).
async function setKey() {
  const clip = (Pasteboard.paste() || '').trim();
  const a = new Alert();
  a.title = 'Paste your claude.ai session key';
  a.message = 'On the Mac, copy the "sessionKey" value from Chrome (see the steps you were given). It starts with sk-ant-sid. It stays in this iPhone\'s Keychain and is sent only to claude.ai.';
  a.addSecureTextField('sk-ant-sid…', clip.startsWith('sk-ant-sid') ? clip : '');
  a.addAction('Save');
  a.addCancelAction('Cancel');
  if (await a.present() === -1) return false;
  const v = (a.textFieldValue(0) || '').trim().replace(/^sessionKey=/, '');
  if (!v.startsWith('sk-ant-sid')) {
    const bad = new Alert(); bad.title = "That doesn't look like a session key"; bad.message = 'It should start with sk-ant-sid.'; bad.addAction('OK'); await bad.present();
    return false;
  }
  Keychain.set(KEY, v);
  if (Keychain.contains(ORG)) Keychain.remove(ORG);
  return true;
}

async function showResult(reading, err) {
  const a = new Alert();
  a.title = 'Claude usage';
  const s = reading && reading.limits.find(l => l.group === 'session');
  const w = reading && reading.limits.find(l => l.key === 'weekly_all');
  a.message = (reading ? 'Session ' + Math.round(s ? s.percent : 0) + '% · Weekly ' + Math.round(w ? w.percent : 0) + '%\nFrom: ' + (reading.source === 'phone' ? 'this iPhone ✓' : 'the Mac') + '\n' : 'No reading.\n')
    + (err ? '\nPhone: ' + (ERRORS[err] || err) : '');
  a.addAction('OK');
  if (err !== 'noKey') a.addAction('Change session key');
  else a.addAction('Paste session key');
  return await a.present();
}

let {reading, err} = await getReading();
if (config.runsInWidget) {
  Script.setWidget(build(config.widgetFamily, reading, err));
} else {
  if (err === 'noKey' && await setKey()) ({reading, err} = await getReading());
  while ((await showResult(reading, err)) === 1 && await setKey()) ({reading, err} = await getReading());
  await build('medium', reading, err).presentMedium();
}
Script.complete();
