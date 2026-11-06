import XCTest
@testable import UsageCore

/// All tests use temporary folders and synthetic data. They never touch the real data files
/// (see UsageBar 1.2.1's incident).
final class UsageCoreTests: XCTestCase {
    var tmp: URL!
    let t0 = Date(timeIntervalSince1970: 1_793_570_000)   // 2026-11-01 ~17:13 local

    override func setUp() {
        tmp = FileManager.default.temporaryDirectory.appendingPathComponent("usagecore-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    }
    override func tearDown() { try? FileManager.default.removeItem(at: tmp) }

    func iso(_ d: Date) -> String { ISO8601DateFormatter().string(from: d) }

    func raw(session: Double, sessionReset: Date, weekly: Double = 30, weeklyReset: Date? = nil, spend: Bool = false) -> [String: Any] {
        var r: [String: Any] = [
            "limits": [
                ["kind": "session", "percent": session, "resets_at": iso(sessionReset).replacingOccurrences(of: "Z", with: ".316268+00:00")],
                ["kind": "weekly_all", "percent": weekly, "resets_at": iso(weeklyReset ?? sessionReset.addingTimeInterval(5 * 86400))],
                ["kind": "weekly_scoped", "percent": 20, "resets_at": iso(weeklyReset ?? sessionReset.addingTimeInterval(5 * 86400)),
                 "scope": ["model": ["display_name": "Fable"]]],
            ],
            "seven_day_breakdown": ["rows": [["display_name": "Chats", "percent": 16], ["display_name": "Cowork", "percent": 81]]],
        ]
        if spend {
            r["spend"] = ["enabled": true, "percent": 94, "used": ["amount_minor": 468, "currency": "CAD", "exponent": 2],
                          "limit": ["amount_minor": 500, "currency": "CAD", "exponent": 2]]
        }
        return r
    }

    // MARK: parser

    func testParserReadsEveryLimitExtraAndBreakdown() throws {
        let reset = t0.addingTimeInterval(3600)
        let s = try UsageParser.snapshot(from: raw(session: 64, sessionReset: reset, spend: true), at: t0)
        XCTAssertEqual(s.limits.map(\.key), ["session", "weekly_all", "weekly_fable"])
        XCTAssertEqual(s.limits[2].label, "Weekly · Fable")
        XCTAssertEqual(s.session?.resetsAt?.timeIntervalSince1970 ?? 0, reset.timeIntervalSince1970, accuracy: 1)
        XCTAssertEqual(s.extra?.used ?? 0, 4.68, accuracy: 0.001)
        XCTAssertEqual(s.extra?.limit, 5)
        XCTAssertEqual(s.breakdown.first?.name, "Cowork")
    }

    func testLegacyFallbackAndEmpty() throws {
        let s = try UsageParser.snapshot(from: ["five_hour": ["utilization": 12, "resets_at": "2026-11-05T01:30:00+00:00"],
                                               "seven_day": ["utilization": 65, "resets_at": "2026-11-08T09:00:00.3+00:00"]])
        XCTAssertEqual(s.limits.map(\.key), ["session", "weekly_all"])
        XCTAssertNotNil(s.weekly?.resetsAt)
        XCTAssertThrowsError(try UsageParser.snapshot(from: [:]))
    }

    func testEffectivePercentAfterReset() {
        let l = UsageLimit(key: "session", label: "S", group: "session", percent: 80, resetsAt: t0)
        XCTAssertEqual(l.effectivePercent(at: t0.addingTimeInterval(-1)), 80)
        XCTAssertEqual(l.effectivePercent(at: t0.addingTimeInterval(1)), 0)
    }

    // MARK: log + history

    func snap(_ pct: Double, at ts: Date, reset: Date, weekly: Double = 30) -> Snapshot {
        Snapshot(fetchedAt: ts, limits: [
            UsageLimit(key: "session", label: "Session (5h)", group: "session", percent: pct, resetsAt: reset),
            UsageLimit(key: "weekly_all", label: "Weekly · all models", group: "weekly", percent: weekly, resetsAt: reset.addingTimeInterval(5 * 86400)),
        ], extra: nil, breakdown: [])
    }

    func testLogRoundTripAndRollup() throws {
        let log = ReadingsLog(directory: tmp)
        let now = t0.addingTimeInterval(40 * 86400)
        // 2 old windows (rolled up) + 1 recent
        try log.append(snap(30, at: t0, reset: t0.addingTimeInterval(3600)))
        try log.append(snap(55, at: t0.addingTimeInterval(1800), reset: t0.addingTimeInterval(3600)))
        try log.append(snap(10, at: t0.addingTimeInterval(86400), reset: t0.addingTimeInterval(86400 + 3600)))
        try log.append(snap(20, at: now.addingTimeInterval(-60), reset: now.addingTimeInterval(3600)))
        XCTAssertEqual(log.load().count, 8)
        XCTAssertEqual(log.rollup(now: now), 6)
        XCTAssertEqual(log.load().count, 2)
        XCTAssertEqual(log.rollup(now: now), 0, "second rollup is a no-op")
        let daily = log.loadDaily()
        XCTAssertEqual(daily.filter { $0.key == "session" }.map(\.maxPercent).sorted(), [10, 55])
        let wins = History.windows(readings: log.load(), daily: daily, now: now)
        XCTAssertEqual(wins.map(\.peak), [55, 10, 20])
        XCTAssertEqual(wins.last?.done, false)
        XCTAssertEqual(wins.first?.unused, 45)
    }

    func testCSVQuotesTitlesWithCommas() {
        let rows = CSV.rows("a,\"b, c\",\"say \"\"hi\"\"\"\n1,2,3\n")
        XCTAssertEqual(rows[0], ["a", "b, c", "say \"hi\""])
        XCTAssertEqual(rows.count, 2)
    }

    func testDaysIdleHours() throws {
        let log = ReadingsLog(directory: tmp)
        let cal = Calendar.current
        let day = cal.startOfDay(for: t0)
        let reset = day.addingTimeInterval(14 * 3600)        // window 09:00–14:00
        try log.append(snap(1, at: day.addingTimeInterval(1), reset: reset))
        try log.append(snap(40, at: day.addingTimeInterval(13 * 3600), reset: reset))
        let now = day.addingTimeInterval(20 * 3600)
        let days = History.days(readings: log.load(), daily: [], now: now)
        XCTAssertEqual(days.count, 1)
        XCTAssertEqual(days[0].windows, 1)
        XCTAssertEqual(days[0].idleHours, 15, accuracy: 0.01)   // 20 tracked - 5 active
        XCTAssertEqual(days[0].weeklyEnd, 30)
    }

    // MARK: pace

    func testPaceRecentAndAverage() {
        let reset = t0.addingTimeInterval(2.5 * 3600)        // window started 2.5 h ago
        let lim = UsageLimit(key: "session", label: "S", group: "session", percent: 60, resetsAt: reset)
        let readings = [Reading(ts: t0.addingTimeInterval(-3600), key: "session", label: "S", percent: 40, resetsAt: reset)]
        let p = Forecast.pace(for: lim, readings: readings, now: t0)!
        XCTAssertEqual(p.percentPerHour, 20, accuracy: 0.01)
        XCTAssertEqual(p.hitsLimitAt!.timeIntervalSince(t0), 2 * 3600, accuracy: 1)
        // No readings: average since the window started (60% in 2.5 h = 24%/h).
        let a = Forecast.pace(for: lim, readings: [], now: t0)!
        XCTAssertEqual(a.basis, "since the window started")
        XCTAssertEqual(a.percentPerHour, 24, accuracy: 0.01)
        // Idle: nothing used recently.
        let idle = [Reading(ts: t0.addingTimeInterval(-3600), key: "session", label: "S", percent: 60, resetsAt: reset)]
        let i = Forecast.pace(for: lim, readings: idle, now: t0)!
        XCTAssertNil(i.hitsLimitAt)
        XCTAssertEqual(i.projectedUnused, 40, accuracy: 0.01)
    }

    func testWeeklyPlan() {
        let w = UsageLimit(key: "weekly_all", label: "W", group: "weekly", percent: 40, resetsAt: t0.addingTimeInterval(3 * 86400))
        XCTAssertEqual(Forecast.weeklyPlan(w, now: t0), "60% left · about 20% per day for 3 days")
    }

    // MARK: alerts

    func testAlertsHighestThresholdOnceAndNewSession() {
        var st = AlertState()
        let c = AlertConfig()
        let reset = t0.addingTimeInterval(3 * 3600)
        let a1 = AlertEngine.evaluate(snap(96, at: t0, reset: reset), config: c, state: &st, now: t0)
        XCTAssertEqual(a1.map(\.title), ["Claude session at 96%"])
        XCTAssertTrue(a1[0].body.contains("95%"))
        XCTAssertTrue(AlertEngine.evaluate(snap(97, at: t0, reset: reset), config: c, state: &st, now: t0).isEmpty)
        let after = reset.addingTimeInterval(60)
        let a2 = AlertEngine.evaluate(snap(97, at: t0, reset: reset), config: c, state: &st, now: after)
        XCTAssertTrue(a2.contains { $0.title == "New Claude session available" })
        XCTAssertFalse(AlertEngine.evaluate(snap(97, at: t0, reset: reset), config: c, state: &st, now: after.addingTimeInterval(60))
            .contains { $0.title == "New Claude session available" })
    }

    func testEditableThresholdsAndDisabled() {
        var c = AlertConfig()
        c.sessionThresholds = AlertConfig.parseList("50, 70 ,x, 200")!
        XCTAssertEqual(c.sessionThresholds, [50, 70])
        var st = AlertState()
        let reset = t0.addingTimeInterval(3 * 3600)
        XCTAssertEqual(AlertEngine.evaluate(snap(55, at: t0, reset: reset), config: c, state: &st, now: t0).first?.title, "Claude session at 55%")
        c.sessionOn = false
        var st2 = AlertState()
        XCTAssertFalse(AlertEngine.evaluate(snap(99, at: t0, reset: reset), config: c, state: &st2, now: t0).contains { $0.title.hasPrefix("Claude session at") })
        XCTAssertNil(AlertConfig.parseList("abc"))
    }

    func testTimeLeftOnlyWhileUnder70AndStale() {
        var st = AlertState()
        let reset = t0.addingTimeInterval(14 * 60)
        let a = AlertEngine.evaluate(snap(30, at: t0, reset: reset), config: AlertConfig(), state: &st, now: t0)
        XCTAssertEqual(a.filter { $0.title.contains("min left") }.count, 1, "only one of 60/15 fires")
        var st2 = AlertState()
        XCTAssertTrue(AlertEngine.evaluate(snap(75, at: t0, reset: reset), config: AlertConfig(), state: &st2, now: t0)
            .filter { $0.title.contains("min left") }.isEmpty)
        var st3 = AlertState()
        let stale = AlertEngine.evaluate(snap(30, at: t0, reset: t0.addingTimeInterval(4 * 3600)), config: AlertConfig(), state: &st3, now: t0.addingTimeInterval(31 * 60))
        XCTAssertTrue(stale.contains { $0.title == "Claude usage not updating" })
    }

    func testExtraUsageAlerts() throws {
        var st = AlertState()
        let s = try UsageParser.snapshot(from: raw(session: 100, sessionReset: t0.addingTimeInterval(3600), spend: true), at: t0)
        let a = AlertEngine.evaluate(s, config: AlertConfig(), state: &st, now: t0)
        XCTAssertTrue(a.contains { $0.title == "Extra usage at 94% of monthly budget" && $0.body.contains("Passed 80%") })
    }

    func testStatusParseAndOutageAlertOnce() {
        let json = #"{"status":{"indicator":"minor","description":"Partially Degraded Service"},"incidents":[{"id":"abc","name":"Elevated errors","status":"investigating","impact":"minor"},{"id":"old","name":"x","status":"resolved","impact":"minor"}]}"#
        let s = ServiceStatus.parse(Data(json.utf8), at: t0)!
        XCTAssertEqual(s.incidents.map(\.id), ["abc"])
        XCTAssertFalse(s.isOperational)
        var st = AlertState()
        XCTAssertEqual(AlertEngine.evaluate(status: s, config: AlertConfig(), state: &st).count, 1)
        XCTAssertEqual(AlertEngine.evaluate(status: s, config: AlertConfig(), state: &st).count, 0)
    }

    // MARK: chat tracking

    func testAttributionSumsToLoggedAndCarriesOver() {
        let reset = t0.addingTimeInterval(4 * 3600)
        let start = reset.addingTimeInterval(-5 * 3600)
        let r = { (m: Double, p: Double) in Reading(ts: start.addingTimeInterval(m * 60), key: "session", label: "S", percent: p, resetsAt: reset) }
        let readings = [r(10, 2), r(20, 2), r(30, 5)]
        let ev = [ChatTracking.Event(ts: start.addingTimeInterval(5 * 60), id: "a", title: "A", source: "chat", tokens: 300),
                  ChatTracking.Event(ts: start.addingTimeInterval(15 * 60), id: "b", title: "B", source: "chat", tokens: 100),
                  ChatTracking.Event(ts: start.addingTimeInterval(25 * 60), id: "b", title: "B renamed", source: "chat", tokens: 100)]
        let rows = ChatTracking.attribute(readings: readings, events: ev)
        let tot = ChatTracking.totals(rows, window: reset)
        XCTAssertEqual(tot.reduce(0) { $0 + $1.percent }, 5, accuracy: 1e-9)
        XCTAssertEqual(tot.first { $0.id == "a" }!.percent, 2, accuracy: 1e-9)
        XCTAssertEqual(tot.first { $0.id == "b" }!.percent, 3, accuracy: 1e-9, "b's 10-min activity carried to the next rise")
        XCTAssertEqual(tot.first { $0.id == "b" }!.title, "B renamed")
        let lone = ChatTracking.attribute(readings: [r(10, 3)], events: [])
        XCTAssertEqual(lone.first?.id, ChatTracking.unattributed)
    }

    func testCodeTranscriptsDedupeAndIncremental() throws {
        let proj = tmp.appendingPathComponent("projects/-Users-x-Proj")
        try FileManager.default.createDirectory(at: proj, withIntermediateDirectories: true)
        let ts = iso(t0)
        func line(_ sid: String, _ mid: String, _ out: Int) -> String {
            #"{"type":"assistant","sessionId":"\#(sid)","cwd":"/Users/x/Proj","timestamp":"\#(ts)","message":{"id":"\#(mid)","usage":{"input_tokens":0,"output_tokens":0,"iterations":[{"input_tokens":2,"output_tokens":\#(out),"cache_read_input_tokens":1000,"cache_creation_input_tokens":0}]}}}"#
        }
        let a = proj.appendingPathComponent("s1.jsonl"), b = proj.appendingPathComponent("s2.jsonl")
        try (line("s1", "m1", 10) + "\n" + line("s1", "m1", 50) + "\n" + #"{"type":"ai-title","aiTitle":"Fix bug","sessionId":"s1"}"# + "\n").write(to: a, atomically: true, encoding: .utf8)
        // s2 continues s1: copies m1, adds m2. Written later so s1 counts as first.
        try (line("s2", "m1", 50) + "\n").write(to: b, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.creationDate: t0.addingTimeInterval(-100)], ofItemAtPath: a.path)
        try FileManager.default.setAttributes([.creationDate: t0], ofItemAtPath: b.path)
        var st = ChatTracking.Store()
        ChatTracking.updateCode(&st, root: tmp.appendingPathComponent("projects"), now: t0)
        XCTAssertEqual(st.code["s1"]?.title, "Fix bug")
        XCTAssertEqual(st.code["s1"]?.events["m1"]?[1], 1052)
        var ev = ChatTracking.events(st)
        XCTAssertEqual(ev.count, 1, "copied message counted once")
        XCTAssertEqual(ev.first?.id, "s1")
        // Append to s2 and re-read: only the new line is parsed.
        let h = try FileHandle(forWritingTo: b); try h.seekToEnd(); try h.write(contentsOf: Data((line("s2", "m2", 8) + "\n").utf8)); try h.close()
        ChatTracking.updateCode(&st, root: tmp.appendingPathComponent("projects"), now: t0)
        ev = ChatTracking.events(st)
        XCTAssertEqual(ev.filter { $0.id == "s2" }.map(\.tokens), [1010])
    }

    func testPageOutputApply() {
        var st = ChatTracking.Store()
        XCTAssertEqual(ChatTracking.apply(pageOutput: "NO_TAB", to: &st, now: t0), ChatTracking.pausedNoTab)
        let out = #"{"ok":true,"org":"o1","items":[{"uuid":"c1","title":"Trip","updated_at":"\#(iso(t0))","platform":"CLAUDE_AI"},{"uuid":"c2","title":"Two","updated_at":"\#(iso(t0))","platform":""}],"details":{"c1":[["\#(iso(t0))",12000]]}}"#
        XCTAssertNil(ChatTracking.apply(pageOutput: out, to: &st, now: t0))
        XCTAssertEqual(st.org, "o1")
        XCTAssertFalse(st.chats["c1"]!.stale)
        XCTAssertTrue(st.chats["c2"]!.stale, "listed but not read yet -> read next pass")
        XCTAssertEqual(st.chats["c1"]!.events.first?[1], 12000)
        let args = ChatTracking.pageArguments(st, now: t0)
        XCTAssertTrue(args.contains("\"want\":[\"c2\"]"))
        XCTAssertFalse(args.contains("__ARGS__"))
        XCTAssertFalse(args.contains("XMLHttpRequest"), "no synchronous XHR: it freezes the claude.ai tab")
        XCTAssertNotNil(ChatTracking.apply(pageOutput: "TIMEOUT", to: &st, now: t0))
    }

    func testPageJobWrapsBodyAndPollsSameKey() {
        let job = ChatTracking.pageJob("return \"x\";", id: "ab-12")
        XCTAssertTrue(job.start.contains("__usagebarapp_ab12"))
        XCTAssertTrue(job.poll.contains("__usagebarapp_ab12"))
        XCTAssertTrue(job.start.contains("return \"x\";"))
        XCTAssertTrue(job.start.contains("return \"PENDING\""))
        let a = ChatTracking.osascriptArguments("return 1;")
        XCTAssertEqual(a.count, 4)
        XCTAssertEqual(a[0], "-e")
    }

    func testTokensPerPercentCalibration() {
        let reset = t0.addingTimeInterval(-3600)
        let w = History.Window(reset: reset, peak: 50, done: true)
        let ev = [ChatTracking.Event(ts: reset.addingTimeInterval(-1000), id: "a", title: "A", source: "chat", tokens: 5_000_000)]
        let c = ChatTracking.tokensPerPercent(windows: [w], events: ev, now: t0)!
        XCTAssertEqual(c.rate, 100_000)
        XCTAssertEqual(c.windows, 1)
    }

    // MARK: pre-mortem fixes

    func testSingleFailedFetchIsNotStale() {
        var s = snap(30, at: t0, reset: t0.addingTimeInterval(3600))
        s.error = "offline"; s.errorAt = t0.addingTimeInterval(60)
        XCTAssertNil(s.staleReason(staleAfter: 600, now: t0.addingTimeInterval(120)), "fresh reading + one error isn't stale")
        XCTAssertEqual(s.lastError, "offline")
        XCTAssertEqual(s.staleReason(staleAfter: 600, now: t0.addingTimeInterval(700)), "offline")
        var st = AlertState()
        XCTAssertFalse(AlertEngine.evaluate(s, config: AlertConfig(), state: &st, now: t0.addingTimeInterval(120))
            .contains { $0.title == "Claude usage not updating" })
    }

    func testDateFractionsAndCSVMixedQuoting() {
        XCTAssertEqual(UsageParser.date("2026-11-02T04:00:00.316268+00:00")?.timeIntervalSince1970, 1_793_592_000)
        XCTAssertEqual(UsageParser.date("2026-11-02T04:00:00.3Z")?.timeIntervalSince1970, 1_793_592_000)
        XCTAssertEqual(UsageParser.date("2026-11-02T04:00:00+00:00")?.timeIntervalSince1970, 1_793_592_000)
        XCTAssertNil(UsageParser.date(""))
        let rows = CSV.rows("h1,h2\r\na,b\n\"x, y\",z\n")
        XCTAssertEqual(rows, [["h1", "h2"], ["a", "b"], ["x, y", "z"]])
    }

    func testLogLoadSpeed() throws {
        let log = ReadingsLog(directory: tmp)
        var text = "fetched_at,key,label,percent,resets_at\n"
        for i in 0..<30000 { text += "\(CSV.iso(t0.addingTimeInterval(Double(i) * 120))),session,Session (5h),12.0,\(CSV.iso(t0.addingTimeInterval(18000)))\n" }
        try text.write(to: log.url, atomically: true, encoding: .utf8)
        let start = Date()
        XCTAssertEqual(log.load().count, 30000)
        XCTAssertLessThan(Date().timeIntervalSince(start), 1.0, "30k rows should load well under a second")
    }

    // MARK: status line

    func testStatuslineText() {
        let reset = t0.addingTimeInterval(2 * 3600 + 14 * 60 + 30)
        let s = snap(64, at: t0, reset: reset, weekly: 33)
        XCTAssertEqual(Statusline.text(s, sessionPace: nil, staleAfter: 600, now: t0, color: false), "S 64% 2h14m · W 33%")
        XCTAssertTrue(Statusline.text(s, sessionPace: nil, staleAfter: 600, now: t0.addingTimeInterval(700), color: false).contains("(as of"))
        XCTAssertEqual(Statusline.text(nil, sessionPace: nil, staleAfter: 600), "Claude usage: no reading yet")
    }
}
