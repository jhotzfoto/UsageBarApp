import Foundation

/// Claude's public status page (status.anthropic.com, a standard Statuspage summary).
public struct ServiceStatus: Codable, Equatable {
    public struct Incident: Codable, Equatable, Identifiable {
        public let id: String
        public let name: String
        public let status: String     // investigating, identified, monitoring, ...
        public let impact: String     // none, minor, major, critical
    }
    public let indicator: String      // none, minor, major, critical, maintenance
    public let description: String    // "All Systems Operational", ...
    public let incidents: [Incident]
    public let fetchedAt: Date

    public static let url = URL(string: "https://status.anthropic.com/api/v2/summary.json")!

    public var isOperational: Bool { indicator == "none" && incidents.isEmpty }

    public static func parse(_ data: Data, at now: Date = Date()) -> ServiceStatus? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let st = obj["status"] as? [String: Any] else { return nil }
        let incidents = (obj["incidents"] as? [[String: Any]] ?? []).compactMap { i -> Incident? in
            guard let id = i["id"] as? String, let name = i["name"] as? String else { return nil }
            let status = i["status"] as? String ?? ""
            guard status != "resolved", status != "postmortem" else { return nil }
            return Incident(id: id, name: name, status: status, impact: i["impact"] as? String ?? "none")
        }
        return ServiceStatus(indicator: st["indicator"] as? String ?? "none",
                             description: st["description"] as? String ?? "", incidents: incidents, fetchedAt: now)
    }
}
