// UsageBarApp for iPhone (Scriptable). Home Screen (small, medium) and Lock Screen (circular,
// rectangular, inline) widgets showing Claude session, weekly and extra usage.
//
// Data, in order:
//   1. The iPhone's own claude.ai login (run this script once in the Scriptable app to sign in).
//      Works with the Mac off.
//   2. The Mac app's shared reading in Scriptable's iCloud folder (UsageBarApp/snapshot.json), with
//      its age shown.
// Only percentages, reset times and amounts are read. Nothing is sent anywhere.
//
// Status: written 2026-11-04, NOT yet tested on a phone (run iphone/login-test.js first).

const GREEN = new Color('#34C759'), AMBER = new Color('#FF9F0A'), RED = new Color('#FF3B30');
const DIM = new Color('#8E8E93');
const STALE_MIN = 20;
const fm = FileManager.iCloud();
const dir = fm.joinPath(fm.documentsDirectory(), 'UsageBarApp');
const CACHE = fm.joinPath(dir, 'phone-reading.json');
const MAC = fm.joinPath(dir, 'snapshot.json');

const FETCH_JS = `
(async () => {
  try {
    const o = await fetch('/api/organizations', {credentials: 'include'});
    const orgs = await o.json().catch(() => null);
    if (!Array.isArray(orgs)) return completion(JSON.stringify({needLogin: true}));
    const org = (orgs.find(g => (g.capabilities || []).includes('chat')) || orgs[0]).uuid;
    const r = await fetch('/api/organizations/' + org + '/usage', {credentials: 'include'});
    const j = await r.json().catch(() => null);
    if (!r.ok || !j) return completion(JSON.stringify({error: 'HTTP ' + r.status}));
    completion(JSON.stringify({raw: j}));
  } catch (e) { completion(JSON.stringify({error: String(e)})); }
})();
// The async function returns a Promise, which Scriptable can't accept as the script's value;
// end on a plain string. The real result arrives through completion().
'started';
`;

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

async function readOwn() {
  const wv = new WebView();
  await wv.loadURL('https://claude.ai/');
  const res = JSON.parse(await wv.evaluateJavaScript(FETCH_JS, true));
  if (res.raw) {
    const r = parse(res.raw);
    if (r.limits.length) return r;
  }
  throw new Error(res.needLogin ? 'needLogin' : (res.error || 'no data'));
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
    const t = w.addText(err === 'needLogin' ? 'Open Scriptable to sign in' : 'No Claude reading yet');
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

// "Sign in with Google" doesn't work in Scriptable's built-in browser (Google blocks embedded
// browsers), so offer email sign-in, with a way to paste the emailed login link into this browser.
// Only claude.ai links are accepted.
async function signIn() {
  const pick = new Alert();
  pick.title = 'Sign in to claude.ai';
  pick.message = 'Google sign-in is blocked inside Scriptable. Use email instead:\n\n'
    + '1. Tap "Open claude.ai", type your email, tap Continue with email, then tap Close.\n'
    + '2. In the email from Anthropic, DON\'T tap the button. Press and hold it, tap Copy Link.\n'
    + '3. Run this again and tap "Paste login link".\n\n'
    + 'If the email gives you a code instead, type it on the claude.ai page.';
  pick.addAction('Open claude.ai');
  pick.addAction('Paste login link');
  pick.addCancelAction('Cancel');
  const i = await pick.present();
  if (i === -1) return false;
  let url = 'https://claude.ai/login';
  if (i === 1) {
    const p = new Alert();
    p.title = 'Paste the login link';
    p.message = 'From the Anthropic email (press and hold the button, Copy Link).';
    p.addTextField('https://claude.ai/...', Pasteboard.paste() || '');
    p.addAction('Sign in');
    p.addCancelAction('Cancel');
    if (await p.present() === -1) return false;
    url = (p.textFieldValue(0) || '').trim();
    if (!/^https:\/\/([a-z0-9-]+\.)?claude\.ai\//i.test(url)) {
      const bad = new Alert();
      bad.title = 'Not a claude.ai link';
      bad.message = 'The link should start with https://claude.ai/';
      bad.addAction('OK');
      await bad.present();
      return false;
    }
  }
  const wv = new WebView();
  await wv.loadURL(url);
  await wv.present(true);   // finish signing in, then tap Close
  return true;
}

const {reading, err} = await getReading();
if (config.runsInWidget) {
  Script.setWidget(build(config.widgetFamily, reading, err));
} else if (err === 'needLogin') {
  let again = {reading, err};
  while (again.err === 'needLogin' && await signIn()) again = await getReading();
  await build('medium', again.reading, again.err).presentMedium();
} else {
  await build('medium', reading, err).presentMedium();
}
Script.complete();
