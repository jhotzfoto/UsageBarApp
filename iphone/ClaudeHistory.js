// Claude History for iPhone (Scriptable). A separate widget from Claude Usage: today's usage in
// half-hour slots (session running, idle = missed capacity, not recorded) and the last 7 days.
// Large shows both, medium shows today, small shows today's numbers; Lock Screen shows a summary.
//
// Data: the Mac app's history (UsageBarApp/history.json in Scriptable's iCloud folder), written
// every 10 minutes while the Mac is awake. Usage numbers and times only.

const fm = FileManager.iCloud();
const dir = fm.joinPath(fm.documentsDirectory(), 'UsageBarApp');
const FILE = fm.joinPath(dir, 'history.json');

const BLUE = new Color('#0A84FF'), AMBER = new Color('#FF9F0A'), RED = new Color('#FF3B30');
const GREEN = new Color('#34C759'), DIM = new Color('#8E8E93');
const SHADE = {
  active: new Color('#34C759', 0.20),
  idle: new Color('#FF9F0A', 0.38),
  noData: new Color('#8E8E93', 0.16),
  future: new Color('#8E8E93', 0.05),
};

async function load() {
  try { await fm.downloadFileFromiCloud(FILE); } catch (e) {}
  try { return fm.fileExists(FILE) ? JSON.parse(fm.readString(FILE)) : null; } catch (e) { return null; }
}

const isToday = d => new Date(d).toDateString() === new Date().toDateString();
const hours = h => (h < 10 ? h.toFixed(1) : Math.round(h)) + ' h';

function summary(d) {
  const parts = ['Used ' + Math.round(d.used) + '%'];
  if (d.unusedAtReset > 0) parts.push(Math.round(d.unusedAtReset) + '% unused');
  parts.push(hours(d.idleHours) + ' idle');
  return parts.join(' · ');
}

function ageText(h) {
  const min = Math.round((Date.now() - new Date(h.generatedAt)) / 60000);
  return 'Mac · ' + (min < 1 ? 'now' : min < 120 ? min + 'm ago' : Math.round(min / 60) + 'h ago');
}

// Today: one column per half hour, shaded by state, with a blue bar for session % used.
function timelineImage(h, width, height) {
  const ctx = new DrawContext();
  ctx.size = new Size(width, height); ctx.opaque = false; ctx.respectScreenScale = true;
  const n = h.slots.length, sw = width / n, chartH = height - 11;
  const top = Math.max(10, Math.max(...h.slots.map(s => s.used)) * 1.15);
  h.slots.forEach((s, i) => {
    ctx.setFillColor(SHADE[s.state] || SHADE.noData);
    ctx.fillRect(new Rect(i * sw, 0, sw + 0.5, chartH));
    if (s.used > 0) {
      const bh = Math.max(1.5, s.used / top * chartH);
      ctx.setFillColor(BLUE);
      ctx.fillRect(new Rect(i * sw + 0.5, chartH - bh, Math.max(1, sw - 1), bh));
    }
  });
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
  h.days.forEach((d, i) => {
    const x0 = i * cw + 3;
    ctx.setFillColor(new Color('#8E8E93', 0.10));
    ctx.fillRect(new Rect(x0, 0, cw - 6, chartH));
    const uh = d.used / maxUsed * chartH;
    ctx.setFillColor(BLUE); ctx.fillRect(new Rect(x0, chartH - uh, bw, uh));
    const ih = Math.min(24, d.idleHours) / 24 * chartH;
    ctx.setFillColor(AMBER); ctx.fillRect(new Rect(x0 + bw + 2, chartH - ih, bw, ih));
    ctx.setFont(Font.systemFont(8)); ctx.setTextColor(i === n - 1 ? GREEN : DIM);
    ctx.drawText(new Date(d.date).toLocaleDateString(undefined, {weekday: 'short'}).slice(0, 3), new Point(x0, chartH + 1));
  });
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
  w.refreshAfterDate = new Date(Date.now() + 30 * 60000);
  if (!h) {
    const t = w.addText('No Claude history yet. The Mac app shares it every 10 minutes.');
    t.font = Font.systemFont(11);
    return w;
  }
  const day = isToday(h.day) ? 'Today' : new Date(h.day).toLocaleDateString(undefined, {weekday: 'short', month: 'short', day: 'numeric'});
  const d = h.today;

  if (family === 'accessoryInline') { w.addText(day + ': ' + Math.round(d.used) + '% · ' + hours(d.idleHours) + ' idle'); return w; }
  if (family === 'accessoryCircular') {
    w.addAccessoryWidgetBackground = true;
    const t = w.addText(Math.round(d.used) + '%'); t.font = Font.boldRoundedSystemFont(15); t.centerAlignText();
    const s = w.addText(hours(d.idleHours)); s.font = Font.systemFont(9); s.centerAlignText();
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
    const big = w.addText(Math.round(d.used) + '%'); big.font = Font.boldRoundedSystemFont(28);
    const l1 = w.addText('used · ' + hours(d.idleHours) + ' idle'); l1.font = Font.systemFont(10); l1.textColor = DIM;
    if (d.unusedAtReset > 0) { const l2 = w.addText(Math.round(d.unusedAtReset) + '% unused at reset'); l2.font = Font.systemFont(10); l2.textColor = AMBER; }
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
  legend(w, [['used', BLUE], ['session', GREEN], ['idle', AMBER], ['no data', DIM]]);

  if (family === 'large') {
    w.addSpacer(10);
    const t = w.addText('Last 7 days'); t.font = Font.boldSystemFont(12); t.textColor = DIM;
    w.addSpacer(4);
    const di = w.addImage(daysImage(h, 310, 96)); di.imageSize = new Size(310, 96);
    w.addSpacer(3);
    legend(w, [['session % used', BLUE], ['idle hours', AMBER]]);
    const sum = (k) => h.days.reduce((a, x) => a + x[k], 0);
    const st = w.addText('7 days: ' + Math.round(sum('used')) + '% used · ' + Math.round(sum('unusedAtReset')) + '% unused at resets · '
      + hours(sum('idleHours')) + ' idle (room for ~' + (sum('idleHours') / 5).toFixed(1) + ' more sessions)');
    st.font = Font.systemFont(10); st.textColor = DIM;
  }
  w.addSpacer();
  return w;
}

const history = await load();
if (config.runsInWidget) {
  Script.setWidget(build(config.widgetFamily, history));
} else {
  await build('large', history).presentLarge();
}
Script.complete();
