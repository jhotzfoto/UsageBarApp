// Fake-Scriptable checks for iphone/ClaudeHistory.js (loading, saved copy, iCloud time limit, labels, phone merge).
// Run from the project root:
//   node iphone/tests/history-widget.test.mjs iphone/ClaudeHistory.js iphone/tests/fixtures/history-2026-11-25-2350.json iphone/tests/fixtures/phone-reading-2026-11-25-2354.json
// Every line should say PASS. The expected numbers (1.6 sessions, 2.0 h idle) come from these fixtures.
import fs from 'fs';
const [,, scriptPath, dataPath] = process.argv;
const src = fs.readFileSync(scriptPath, 'utf8');
const real = fs.readFileSync(dataPath, 'utf8');

async function run({family, icloud, cache, inWidget = true}) {
  const texts = []; const store = {cache};
  const W = class { addText(t){ texts.push(t); return new Proxy({}, {get: (o,k) => k in o ? o[k] : () => {}, set: (o,k,v) => (o[k]=v, true)}); } addStack(){ return this; } addSpacer(){} addImage(){ return {}; } centerAlignContent(){} };
  class DC { set size(v){} fillRect(){} setFillColor(){} addPath(){} setStrokeColor(){} setLineWidth(){} strokePath(){} fillEllipse(){} setFont(){} setTextColor(){} drawText(){} getImage(){ return {}; } }
  const g = {
    FileManager: {
      iCloud: () => ({ documentsDirectory: () => '/ic', joinPath: (a,b) => a+'/'+b,
        fileExists: p => p.endsWith('phone-reading.json') ? !!icloud.phone : icloud.exists, isFileDownloaded: p => p.endsWith('phone-reading.json') ? !!icloud.phone : icloud.downloaded,
        downloadFileFromiCloud: () => icloud.hang ? new Promise(()=>{}) : (icloud.downloaded = true, Promise.resolve()),
        readString: p => p.endsWith('phone-reading.json') ? icloud.phone : icloud.text }),
      local: () => ({ documentsDirectory: () => '/loc', joinPath: (a,b) => a+'/'+b,
        fileExists: () => store.cache != null, readString: () => store.cache, writeString: (p, s) => { store.cache = s; } }),
    },
    Timer: { schedule: (ms, rep, cb) => setTimeout(cb, ms / 100) },   // 100x faster
    config: { runsInWidget: inWidget, widgetFamily: family }, args: { widgetParameter: '' },
    ListWidget: W, DrawContext: DC, Color: class {}, Size: class {}, Rect: class {}, Point: class {}, Path: class { move(){} addLine(){} },
    Font: new Proxy({}, { get: () => () => ({}) }),
    Script: { setWidget: () => {}, complete: () => {} },
  };
  const t0 = Date.now();
  const fn = new Function(...Object.keys(g), `return (async () => { ${src} })();`);
  await fn(...Object.values(g));
  return { texts, cacheWritten: store.cache !== cache, ms: Date.now() - t0, cache: store.cache };
}

const older = JSON.stringify(Object.assign(JSON.parse(real), {generatedAt: '2026-11-25T20:00:00Z'}));
const ok = (name, cond, extra='') => console.log((cond ? 'PASS ' : 'FAIL ') + name + (extra ? '  [' + extra + ']' : ''));
let r;
r = await run({family: 'small', icloud: {exists: true, downloaded: false, text: real}, cache: null});
ok('A fresh iCloud copy, no saved copy -> shows it and saves it', r.texts.includes('sessions used · 2.0 h idle') && r.cacheWritten, r.texts.join(' | '));
r = await run({family: 'small', icloud: {exists: true, downloaded: false, hang: true, text: real}, cache: older});
ok('B iCloud stuck -> gives up and shows saved copy', r.texts.length > 0 && !r.cacheWritten && r.ms < 200, r.ms + 'ms (=' + r.ms/10 + 's real) ' + r.texts[0]);
r = await run({family: 'small', icloud: {exists: true, downloaded: false, hang: true, text: real}, cache: null});
ok('C iCloud stuck, nothing saved -> clear message, no hang', r.texts[0].startsWith('No Claude history on this phone'), r.texts[0]);
r = await run({family: 'small', icloud: {exists: true, downloaded: true, text: older}, cache: real});
ok('D iCloud copy older than saved -> keeps the newer saved one', r.texts.join('|').includes('sessions used') && r.cache === real);
r = await run({family: 'small', icloud: {exists: true, downloaded: true, text: '{bad json'}, cache: older});
ok('E broken iCloud file -> saved copy used', r.texts.length > 1 && r.cache === older);
for (const f of ['accessoryInline', 'accessoryCircular', 'accessoryRectangular', 'medium', 'large']) {
  r = await run({family: f, icloud: {exists: true, downloaded: true, text: real}, cache: null});
  ok('F ' + f + ' renders', r.texts.length > 0 && !r.texts.some(t => /\d%/.test(t)), r.texts.join(' | '));
}

const phone = fs.readFileSync(process.argv[4], 'utf8');
r = await run({family: 'medium', icloud: {exists: true, downloaded: true, text: real, phone}, cache: null});
ok('G newer phone reading -> header says Phone, total updated', r.texts.some(t => t.startsWith('Phone · ')) && r.texts.some(t => t.startsWith('1.6 sessions used')), r.texts.slice(0,3).join(' | '));
r = await run({family: 'medium', icloud: {exists: true, downloaded: false, hang: true, text: real, phone}, cache: older});
ok('H iCloud stuck + saved copy + phone reading -> merged, not blank', r.texts.some(t => t.startsWith('Phone · ')), r.texts.slice(0,3).join(' | '));
r = await run({family: 'medium', icloud: {exists: true, downloaded: true, text: real, phone: '{oops'}, cache: null});
ok('I broken phone file -> ignored, Mac data shown', r.texts.some(t => t.startsWith('Mac · ')));
