// UsageBarApp phase 0 test: can Scriptable read Claude usage through its own claude.ai login,
// both in the app and from inside a widget (where the Mac isn't needed)?
//
// 1. Run it in the Scriptable app. If you're not signed in, claude.ai opens: sign in, then tap Close.
// 2. Add it as a Scriptable widget (Home Screen, small) and check what it shows after a few minutes.
//
// It reads only percentages and reset times. It never stores your login or sends anything anywhere;
// results are logged to Scriptable's iCloud folder (UsageBarApp/login-test.log) so the Mac can read them.

const FETCH_JS = `
(async () => {
  const out = {};
  try {
    const o = await fetch('/api/organizations', {credentials: 'include'});
    out.orgStatus = o.status;
    const orgs = await o.json().catch(() => null);
    if (!Array.isArray(orgs)) { out.needLogin = true; return completion(JSON.stringify(out)); }
    const org = (orgs.find(g => (g.capabilities || []).includes('chat')) || orgs[0]).uuid;
    const r = await fetch('/api/organizations/' + org + '/usage', {credentials: 'include'});
    out.usageStatus = r.status;
    out.contentType = r.headers.get('content-type');
    const j = await r.json().catch(() => null);
    if (!j) return completion(JSON.stringify(out));
    const pick = k => j[k] ? {pct: j[k].utilization, resets: j[k].resets_at} : null;
    out.ok = r.ok;
    out.session = pick('five_hour');
    out.weekly = pick('seven_day');
    out.limits = (j.limits || []).map(l => ({kind: l.kind, pct: l.percent, resets: l.resets_at,
      model: l.scope && l.scope.model ? l.scope.model.display_name : null}));
    out.extra = j.spend ? {used: j.spend.used, limit: j.spend.limit, pct: j.spend.percent} : null;
    out.keys = Object.keys(j);
  } catch (e) { out.error = String(e); }
  completion(JSON.stringify(out));
})();
`;

async function readUsage() {
  const t0 = Date.now();
  const wv = new WebView();
  await wv.loadURL('https://claude.ai/');
  const res = JSON.parse(await wv.evaluateJavaScript(FETCH_JS, true));
  res.ms = Date.now() - t0;
  return res;
}

function log(mode, res) {
  try {
    const fm = FileManager.iCloud();
    const dir = fm.joinPath(fm.documentsDirectory(), 'UsageBarApp');
    if (!fm.fileExists(dir)) fm.createDirectory(dir, true);
    const path = fm.joinPath(dir, 'login-test.log');
    const prev = fm.fileExists(path) ? fm.readString(path) : '';
    fm.writeString(path, prev + JSON.stringify({at: new Date().toISOString(), mode, res}) + '\n');
  } catch (e) {}
}

function summary(res) {
  if (res.ok && res.session) {
    return 'Session ' + Math.round(res.session.pct) + '%  ·  Weekly ' + Math.round(res.weekly ? res.weekly.pct : 0) + '%';
  }
  if (res.needLogin) return 'Not signed in (run in app)';
  return 'Failed: ' + (res.error || ('HTTP ' + (res.usageStatus || res.orgStatus) + ' ' + (res.contentType || '')));
}

let res;
if (config.runsInWidget) {
  try { res = await readUsage(); } catch (e) { res = {error: String(e)}; }
  log('widget:' + config.widgetFamily, res);
  const w = new ListWidget();
  const title = w.addText('Claude usage test');
  title.font = Font.boldSystemFont(12);
  const line = w.addText(summary(res));
  line.font = Font.systemFont(12);
  line.minimumScaleFactor = 0.6;
  const when = w.addDate(new Date());
  when.applyTimeStyle();
  when.font = Font.systemFont(10);
  w.refreshAfterDate = new Date(Date.now() + 15 * 60 * 1000);
  Script.setWidget(w);
} else {
  res = await readUsage();
  if (res.needLogin) {
    const wv = new WebView();
    await wv.loadURL('https://claude.ai/login');
    await wv.present(true);   // sign in, then tap Close
    res = await readUsage();
  }
  log('app', res);
  const a = new Alert();
  a.title = 'Claude usage test';
  a.message = summary(res) + '\n\n' + JSON.stringify(res, null, 1).slice(0, 900);
  a.addAction('OK');
  await a.present();
}
Script.complete();
