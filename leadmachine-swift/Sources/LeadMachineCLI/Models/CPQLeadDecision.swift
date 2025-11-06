import Foundation
import FoundationModels

@available(macOS 26.0, *)
@Generable
struct CPQLeadDecision: Equatable {
    let isLead: Bool
    let reasoning: String
}
