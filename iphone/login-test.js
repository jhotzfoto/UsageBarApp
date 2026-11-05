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
// The async function returns a Promise, which Scriptable can't accept as the script's value;
// end on a plain string. The real result arrives through completion().
'started';
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
  while (res.needLogin && await signIn()) res = await readUsage();
  log('app', res);
  const a = new Alert();
  a.title = 'Claude usage test';
  a.message = summary(res) + '\n\n' + JSON.stringify(res, null, 1).slice(0, 900);
  a.addAction('OK');
  await a.present();
}
Script.complete();
