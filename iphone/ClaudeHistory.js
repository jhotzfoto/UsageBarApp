// Claude History for iPhone (Scriptable). A separate widget from Claude Usage: today's usage in
// half-hour slots (session running, idle = missed capacity, not recorded) and the last 7 days.
// Large shows both, medium shows today, small shows today's numbers; Lock Screen shows a summary.
//
// Data: the Mac app's history (UsageBarApp/history.json in Scriptable's iCloud folder), written
// every 10 minutes while the Mac is awake. Usage numbers and times only.
// The last good copy is also kept on the phone (outside iCloud), so the widget still shows the
// latest it had when iCloud is slow to hand over the new file in the background.
// "Right now" comes from the phone's own reading when that is newer: the Claude Usage script reads
// claude.ai itself and saves it (UsageBarApp/phone-reading.json), so today's line, its dot and the
// day's total stay current even while iCloud is slow to bring the Mac's update.
//
// "Sessions used" adds up how much of each 5-hour session was used today: 1.0 = one full session.
//
// Charts are lines by default. Type "bars" in the widget's Parameter field for bar charts.

const fm = FileManager.iCloud();
const dir = fm.joinPath(fm.documentsDirectory(), 'UsageBarApp');
const FILE = fm.joinPath(dir, 'history.json');
const PHONE = fm.joinPath(dir, 'phone-reading.json');   // written on this phone by Claude Usage
const local = FileManager.local();
const CACHE = local.joinPath(local.documentsDirectory(), 'claude-history-cache.json');
const REFRESH_MIN = 10;     // what the widget asks iOS for; iOS may wait longer
const STALE_MIN = 30;       // older than this gets a ⚠︎ in the age text

const BLUE = new Color('#0A84FF'), AMBER = new Color('#FF9F0A'), RED = new Color('#FF3B30');
const GREEN = new Color('#34C759'), DIM = new Color('#8E8E93');
const SHADE = {
  active: new Color('#34C759', 0.20),
  idle: new Color('#FF9F0A', 0.38),
  noData: new Color('#8E8E93', 0.16),
  future: new Color('#8E8E93', 0.05),
};

// BEGIN load (tested on the Mac with node and a fake Scriptable)
function parseHistory(text) {
  try {
    const h = JSON.parse(text);
    return h && h.today && Array.isArray(h.slots) && Array.isArray(h.days) && h.generatedAt ? h : null;
  } catch (e) { return null; }
}

// Resolves after ms, so a stuck iCloud download can't use up the widget's few seconds.
function wait(ms) { return new Promise(resolve => Timer.schedule(ms, false, resolve)); }

// Newest of: the iCloud copy (if iCloud hands it over in time) and the phone's own saved copy.
async function load() {
  let fresh = null;
  try {
    if (fm.fileExists(FILE)) {
      await Promise.race([fm.downloadFileFromiCloud(FILE).catch(() => {}), wait(config.runsInWidget ? 5000 : 20000)]);
      if (fm.isFileDownloaded(FILE)) fresh = parseHistory(fm.readString(FILE));
    }
  } catch (e) {}
  let saved = null;
  try { if (local.fileExists(CACHE)) saved = parseHistory(local.readString(CACHE)); } catch (e) {}
  if (fresh && (!saved || new Date(fresh.generatedAt) >= new Date(saved.generatedAt))) {
    try { local.writeString(CACHE, JSON.stringify(fresh)); } catch (e) {}
    return fresh;
  }
  return saved || fresh;
}

// The phone's own latest session reading, if Claude Usage has saved one here (no waiting on iCloud:
// this phone wrote it).
function loadPhone() {
  try {
    if (!fm.fileExists(PHONE) || !fm.isFileDownloaded(PHONE)) return null;
    const r = JSON.parse(fm.readString(PHONE));
    const s = r && r.source === 'phone' && Array.isArray(r.limits) && r.limits.find(l => l.group === 'session');
    return s && r.fetchedAt && s.resetsAt && typeof s.percent === 'number'
      ? {at: new Date(r.fetchedAt), percent: s.percent, resetsAt: new Date(s.resetsAt)} : null;
  } catch (e) { return null; }
}
// END load

// BEGIN withPhone (pure; tested on the Mac with node)
// Brings the Mac's history up to the phone's newer reading, counting the way the Mac does:
// in the same 5-hour session, the % gained since the Mac's last reading; in a new session, all of
// its % (everything since it started). The gain goes to the half-hour of the phone's reading, the
// half-hours the current session covered become "session", and the line gets the phone's point
// (as a separate piece after a gap of over 20 minutes, as the Mac does, or after a reset whose
// exact time isn't known). Returns h unchanged if
// the phone reading isn't newer, or is from another day.
function withPhone(h, ph) {
  if (!h || !ph) return h;
  const day0 = new Date(h.day).getTime(), at = ph.at.getTime(), macAt = new Date(h.generatedAt).getTime();
  if (!(at > macAt) || at < day0 || at >= day0 + 86400000) return h;
  const out = JSON.parse(JSON.stringify(h));
  const SESSION = 5 * 3600000, GAP = 20 * 60000;
  const winStart = ph.resetsAt.getTime() - SESSION;
  const pNow = ph.resetsAt.getTime() > at ? ph.percent : 0;   // a session past its reset reads 0
  const last = out.line.length ? out.line[out.line.length - 1] : null;
  const lastAt = last ? day0 + last.m * 60000 : null;
  // Same session if it had already started at the Mac's last reading (1-minute leeway).
  const same = last && winStart <= lastAt + 60000;
  const gain = Math.max(0, same ? pNow - last.p : pNow);
  const slotMs = (out.slotMinutes || 30) * 60000;
  const slotOf = t => Math.min(out.slots.length - 1, Math.floor((t - day0) / slotMs));
  if (gain > 0) out.slots[slotOf(at)].used = Math.round((out.slots[slotOf(at)].used + gain) * 10) / 10;
  if (pNow > 0) {
    for (let i = slotOf(Math.max(winStart, day0)); i <= slotOf(at); i++)
      if (out.slots[i].state === 'future' || out.slots[i].state === 'noData') out.slots[i].state = 'active';
  }
  // A new piece after a gap, or when a reset came in between (its exact time isn't known here).
  const seg = last ? (at - lastAt > GAP || !same ? last.s + 1 : last.s) : 0;
  out.line.push({m: Math.round((at - day0) / 60000), p: pNow, s: seg});
  out.today = Object.assign({}, out.today, {used: out.today.used + gain});
  if (out.days.length) out.days[out.days.length - 1] = Object.assign({}, out.days[out.days.length - 1], {used: out.days[out.days.length - 1].used + gain});
  out.phoneAt = ph.at.toISOString();
  return out;
}
// END withPhone

const isToday = d => new Date(d).toDateString() === new Date().toDateString();
const hours = h => (h < 10 ? h.toFixed(1) : Math.round(h)) + ' h';
// Session % added up, shown as sessions: 156 -> "1.6", 1200 -> "12".
const sessions = pct => { const s = pct / 100; return s < 10 ? s.toFixed(1) : String(Math.round(s)); };

function summary(d) {
  const parts = [sessions(d.used) + ' sessions used'];
  if (d.unusedAtReset > 0) parts.push(sessions(d.unusedAtReset) + ' unused');
  parts.push(hours(d.idleHours) + ' idle');
  return parts.join(' · ');
}

function ageText(h) {
  const min = Math.round((Date.now() - new Date(h.phoneAt || h.generatedAt)) / 60000);
  return (min > STALE_MIN ? '⚠︎ ' : '') + (h.phoneAt ? 'Phone · ' : 'Mac · ')
    + (min < 1 ? 'now' : min < 120 ? min + 'm ago' : min < 2880 ? Math.round(min / 60) + 'h ago' : Math.round(min / 1440) + 'd ago');
}

const BARS = String(args.widgetParameter || '').trim().toLowerCase() === 'bars';

// Polylines through [x, y] points; a new segment starts a new line.
function strokeSegments(ctx, segments, color, width) {
  for (const pts of segments) {
    if (pts.length < 2) continue;
    const p = new Path();
    p.move(new Point(pts[0][0], pts[0][1]));
    for (const q of pts.slice(1)) p.addLine(new Point(q[0], q[1]));
    ctx.addPath(p); ctx.setStrokeColor(color); ctx.setLineWidth(width); ctx.strokePath();
  }
}

function dot(ctx, x, y, r, color) { ctx.setFillColor(color); ctx.fillEllipse(new Rect(x - r, y - r, r * 2, r * 2)); }

// Today: half-hour shading by state, with the session % as a line (0–100%) or, with "bars",
// a blue bar per half hour for the session % used in it.
function timelineImage(h, width, height) {
  const ctx = new DrawContext();
  ctx.size = new Size(width, height); ctx.opaque = false; ctx.respectScreenScale = true;
  const n = h.slots.length, sw = width / n, chartH = height - 11;
  const useLine = !BARS && Array.isArray(h.line);
  const top = useLine ? 100 : Math.max(10, Math.max(...h.slots.map(s => s.used)) * 1.15);
  h.slots.forEach((s, i) => {
    ctx.setFillColor(SHADE[s.state] || SHADE.noData);
    ctx.fillRect(new Rect(i * sw, 0, sw + 0.5, chartH));
    if (!useLine && s.used > 0) {
      const bh = Math.max(1.5, s.used / top * chartH);
      ctx.setFillColor(BLUE);
      ctx.fillRect(new Rect(i * sw + 0.5, chartH - bh, Math.max(1, sw - 1), bh));
    }
  });
  if (useLine) {
    ctx.setFillColor(new Color('#8E8E93', 0.25));
    ctx.fillRect(new Rect(0, chartH / 2, width, 0.5));   // 50% guide
    const segs = {};
    for (const p of h.line) (segs[p.s] = segs[p.s] || []).push([p.m / 1440 * width, chartH - p.p / 100 * chartH]);
    strokeSegments(ctx, Object.values(segs), BLUE, 2);
    const last = h.line[h.line.length - 1];
    if (last && isToday(h.day)) dot(ctx, last.m / 1440 * width, chartH - last.p / 100 * chartH, 2.5, BLUE);
  }
  const x = t => (new Date(t) - new Date(h.day)) / 86400000 * width;
  for (const r of h.resets || []) { ctx.setFillColor(r.unused >= 20 ? AMBER : DIM); ctx.fillRect(new Rect(x(r.at) - 0.5, 0, 1, chartH)); }
  if (isToday(h.day)) { ctx.setFillColor(RED); ctx.fillRect(new Rect(x(Date.now()) - 0.5, 0, 1, chartH)); }
  ctx.setFont(Font.systemFont(8)); ctx.setTextColor(DIM);
  for (const hr of [0, 6, 12, 18]) ctx.drawText(hr === 0 ? '12a' : hr === 12 ? '12p' : (hr % 12) + (hr < 12 ? 'a' : 'p'), new Point(hr / 24 * width + 1, chartH + 1));
  return ctx.getImage();
}

// Last 7 days: per day, blue = session % used, amber = idle hours (out of 24).
function daysImage(h, width, height) {
  const ctx = new DrawContext();
  ctx.size = new Size(width, height); ctx.opaque = false; ctx.respectScreenScale = true;
  const n = h.days.length, cw = width / n, chartH = height - 11, bw = (cw - 8) / 2;
  const maxUsed = Math.max(100, ...h.days.map(d => d.used));
  const usedY = d => chartH - d.used / maxUsed * chartH;
  const idleY = d => chartH - Math.min(24, d.idleHours) / 24 * chartH;
  h.days.forEach((d, i) => {
    const x0 = i * cw + 3;
    ctx.setFillColor(new Color('#8E8E93', 0.10));
    ctx.fillRect(new Rect(x0, 0, cw - 6, chartH));
    if (BARS) {
      ctx.setFillColor(BLUE); ctx.fillRect(new Rect(x0, usedY(d), bw, chartH - usedY(d)));
      ctx.setFillColor(AMBER); ctx.fillRect(new Rect(x0 + bw + 2, idleY(d), bw, chartH - idleY(d)));
    }
    ctx.setFont(Font.systemFont(8)); ctx.setTextColor(i === n - 1 ? GREEN : DIM);
    ctx.drawText(new Date(d.date).toLocaleDateString(undefined, {weekday: 'short'}).slice(0, 3), new Point(x0, chartH + 1));
  });
  if (!BARS) {
    const cx = i => i * cw + cw / 2;
    strokeSegments(ctx, [h.days.map((d, i) => [cx(i), idleY(d)])], AMBER, 2);
    strokeSegments(ctx, [h.days.map((d, i) => [cx(i), usedY(d)])], BLUE, 2);
    h.days.forEach((d, i) => { dot(ctx, cx(i), idleY(d), 2.5, AMBER); dot(ctx, cx(i), usedY(d), 2.5, BLUE); });
  }
  return ctx.getImage();
}

function legend(stack, items) {
  const row = stack.addStack(); row.centerAlignContent();
  for (const [label, color] of items) {
    const sq = row.addText('■ '); sq.font = Font.systemFont(9); sq.textColor = color;
    const t = row.addText(label + '   '); t.font = Font.systemFont(9); t.textColor = DIM;
  }
}

function header(w, h, title) {
  const row = w.addStack(); row.centerAlignContent();
  const t = row.addText(title); t.font = Font.boldSystemFont(12); t.textColor = DIM;
  row.addSpacer();
  const a = row.addText(ageText(h)); a.font = Font.systemFont(9); a.textColor = DIM;
}

function build(family, h) {
  const w = new ListWidget();
  w.refreshAfterDate = new Date(Date.now() + REFRESH_MIN * 60000);
  if (!h) {
    const t = w.addText('No Claude history on this phone yet. Open this script once in Scriptable to fetch it.');
    t.font = Font.systemFont(11);
    return w;
  }
  const day = isToday(h.day) ? 'Today' : new Date(h.day).toLocaleDateString(undefined, {weekday: 'short', month: 'short', day: 'numeric'});
  const d = h.today;

  if (family === 'accessoryInline') { w.addText(day + ': ' + sessions(d.used) + ' sessions · ' + hours(d.idleHours) + ' idle'); return w; }
  if (family === 'accessoryCircular') {
    w.addAccessoryWidgetBackground = true;
    const t = w.addText(sessions(d.used)); t.font = Font.boldRoundedSystemFont(15); t.centerAlignText();
    const s = w.addText('sessions'); s.font = Font.systemFont(8); s.centerAlignText();
    return w;
  }
  if (family === 'accessoryRectangular') {
    const t = w.addText('Claude ' + day.toLowerCase()); t.font = Font.boldSystemFont(12);
    const s = w.addText(summary(d)); s.font = Font.systemFont(11);
    const a = w.addText(ageText(h)); a.font = Font.systemFont(9);
    return w;
  }
  if (family === 'small') {
    header(w, h, day);
    w.addSpacer(2);
    const big = w.addText(sessions(d.used)); big.font = Font.boldRoundedSystemFont(28);
    const l1 = w.addText('sessions used · ' + hours(d.idleHours) + ' idle'); l1.font = Font.systemFont(10); l1.textColor = DIM;
    if (d.unusedAtReset > 0) { const l2 = w.addText(sessions(d.unusedAtReset) + ' unused at resets'); l2.font = Font.systemFont(10); l2.textColor = AMBER; }
    w.addSpacer();
    const img = w.addImage(timelineImage(h, 130, 36)); img.imageSize = new Size(130, 36);
    return w;
  }

  // Medium and large: today's timeline.
  header(w, h, 'Claude · ' + day);
  w.addSpacer(3);
  const s = w.addText(summary(d)); s.font = Font.systemFont(11);
  w.addSpacer(5);
  const th = family === 'large' ? 96 : 70;
  const img = w.addImage(timelineImage(h, 310, th)); img.imageSize = new Size(310, th);
  w.addSpacer(3);
  legend(w, [[BARS ? 'used' : 'session %', BLUE], ['session', GREEN], ['idle', AMBER], ['no data', DIM]]);

  if (family === 'large') {
    w.addSpacer(10);
    const t = w.addText('Last 7 days'); t.font = Font.boldSystemFont(12); t.textColor = DIM;
    w.addSpacer(4);
    const di = w.addImage(daysImage(h, 310, 96)); di.imageSize = new Size(310, 96);
    w.addSpacer(3);
    legend(w, [['sessions used', BLUE], ['idle hours', AMBER]]);
    const sum = (k) => h.days.reduce((a, x) => a + x[k], 0);
    const st = w.addText('7 days: ' + sessions(sum('used')) + ' sessions used · ' + sessions(sum('unusedAtReset')) + ' unused at resets · '
      + hours(sum('idleHours')) + ' idle (room for ~' + (sum('idleHours') / 5).toFixed(1) + ' more sessions)');
    st.font = Font.systemFont(10); st.textColor = DIM;
  }
  w.addSpacer();
  return w;
}

const history = withPhone(await load(), loadPhone());
if (config.runsInWidget) {
  Script.setWidget(build(config.widgetFamily, history));
} else {
  await build('large', history).presentLarge();
}
Script.complete();
