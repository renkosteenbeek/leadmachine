import Foundation

struct CPQLeadDecision: Codable, Equatable {
    let isLead: Bool
    let reasoning: String
    let summary: String
}
