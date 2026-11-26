// Accuracy check for withPhone() in iphone/ClaudeHistory.js: cuts the Mac's history early, adds a later
// phone reading, and compares today's total with the Mac's real one. Run from the project root:
//   node iphone/tests/history-phone-merge.test.mjs iphone/ClaudeHistory.js iphone/tests/fixtures/history-2026-11-25-2350.json iphone/tests/fixtures/phone-reading-2026-11-25-2354.json
import fs from 'fs';
const [,, scriptPath, dataPath, phonePath] = process.argv;
const src = fs.readFileSync(scriptPath, 'utf8');
const block = n => src.slice(src.indexOf('// BEGIN ' + n), src.indexOf('// END ' + n));
const withPhone = new Function(block('withPhone') + '; return withPhone;')();
const H = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
const day0 = new Date(H.day).getTime();
const at = m => new Date(day0 + m * 60000);
const hm = m => String(Math.floor(m / 60)).padStart(2, '0') + ':' + String(m % 60).padStart(2, '0');
const ok = (name, cond, extra='') => console.log((cond ? 'PASS ' : 'FAIL ') + name + (extra ? '  [' + extra + ']' : ''));

// Cut the Mac's history at minute `cut`, as if the Mac's last write was then. Gains after the cut
// are taken off today's total (rise between consecutive points, same as the Mac's rule in one session).
function cutAt(h, cut) {
  const o = JSON.parse(JSON.stringify(h));
  const before = o.line.filter(p => p.m <= cut), after = o.line.filter(p => p.m > cut);
  let prev = before[before.length - 1], removed = 0;
  for (const p of after) { if (p.p > prev.p) removed += p.p - prev.p; prev = p; }
  o.line = before; o.generatedAt = at(cut).toISOString();
  o.today.used -= removed; o.days[o.days.length - 1].used -= removed;
  return o;
}
const pointAt = m => H.line.filter(p => p.m <= m).pop();
const lastM = H.line[H.line.length - 1].m;
const curReset = new Date('2026-11-26T08:30:00Z');   // current session ends 3:30 am ET (from the Mac's snapshot)

console.log('Mac today: ' + H.today.used + '% used, last point ' + hm(lastM) + ' at ' + H.line[H.line.length - 1].p + '%');

// 1. Same session, Mac stuck 40 min behind: phone reading = the Mac's real later value.
for (const cut of [1370, 1390, lastM - 5]) {
  const old = cutAt(H, cut), real = pointAt(lastM);
  const m = withPhone(old, {at: at(lastM), percent: real.p, resetsAt: curReset});
  ok(`same session, Mac last at ${hm(cut)} (${old.today.used}%), phone at ${hm(lastM)} ${real.p}% -> ${m.today.used}% (Mac's real: ${H.today.used}%)`,
     Math.abs(m.today.used - H.today.used) < 0.01 && m.days[6].used === m.today.used);
}
// 2. A reset in between (session ended 5:30 pm ET, next one 5:30 pm → 10:30 pm): Mac last at 22:20 ET, phone at 22:45 ET.
{
  const old = cutAt(H, 1340), real = pointAt(1365);
  const m = withPhone(old, {at: at(1365), percent: real.p, resetsAt: curReset});
  const realUsedThen = cutAt(H, 1365).today.used;
  ok(`reset in between: Mac ${hm(1340)} -> phone ${hm(1365)} ${real.p}% -> ${m.today.used}% (Mac's real then: ${realUsedThen}%)`,
     m.today.used <= realUsedThen + 0.01 && realUsedThen - m.today.used < 5 && m.line[m.line.length - 1].s === old.line[old.line.length - 1].s + 1,
     'phone can only count the new session; the old session\'s last minutes are missed until the Mac catches up');
}
// 3. Phone older than Mac -> unchanged.
ok('phone older than Mac -> no change', withPhone(H, {at: at(lastM - 30), percent: 99, resetsAt: curReset}) === H);
// 4. Phone from tomorrow -> unchanged.
ok('phone from another day -> no change', withPhone(H, {at: new Date(day0 + 86400000 + 60000), percent: 5, resetsAt: curReset}) === H);
// 5. Session already over at the phone reading -> 0%, nothing added.
{ const m = withPhone(H, {at: at(lastM + 5), percent: 40, resetsAt: at(lastM + 2)});
  ok('phone reading after its session ended -> 0%, nothing added', m.today.used === H.today.used && m.line[m.line.length - 1].p === 0); }
// 6. Your real phone reading right now.
{ const r = JSON.parse(fs.readFileSync(phonePath, 'utf8')), s = r.limits.find(l => l.group === 'session');
  const m = withPhone(H, {at: new Date(r.fetchedAt), percent: s.percent, resetsAt: new Date(s.resetsAt)});
  console.log(`INFO real phone reading ${r.fetchedAt} ${s.percent}%: today ${H.today.used}% -> ${m.today.used}%` + (m === H ? ' (not newer than Mac, unchanged)' : '')); }
