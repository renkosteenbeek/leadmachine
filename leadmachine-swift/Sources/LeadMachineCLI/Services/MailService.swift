import Foundation
import Logging

@available(macOS 26.0, *)
actor MailService {
    private let apiClient: GraphAPIClient
    private let analyzer: CPQLeadAnalyzer
    private let config: Config
    private let logger = Logger(label: "com.leadmachine.mailservice")

    private var leadmachineFolderId: String?
    private var processedFolderId: String?

    init(apiClient: GraphAPIClient, analyzer: CPQLeadAnalyzer, config: Config) {
        self.apiClient = apiClient
        self.analyzer = analyzer
        self.config = config
    }

    func processEmails(dryRun: Bool = false, limit: Int? = nil) async throws -> ProcessingStats {
        logger.info("Starting email processing (dryRun=\(dryRun))")

        try await ensureFoldersFound()

        guard let leadmachineFolderId, let processedFolderId else {
            throw MailServiceError.foldersNotFound
        }

        var messages = try await apiClient.getMessages(folderId: leadmachineFolderId, top: limit ?? 50)

        if let limit {
            messages = Array(messages.prefix(limit))
        }

        logger.info("Found \(messages.count) emails to process")

        var stats = ProcessingStats()

        for message in messages {
            do {
                let result = try await processMessage(
                    message,
                    processedFolderId: processedFolderId,
                    dryRun: dryRun
                )

                stats.totalProcessed += 1

                if result.wasForwarded {
                    stats.leadsForwarded += 1
                }

                logger.info("✓ Processed: \(message.subject) (lead: \(result.wasForwarded))")

            } catch {
                stats.errors += 1
                logger.error("✗ Failed to process \(message.subject): \(error)")
            }
        }

        logger.info("Processing complete. Stats: \(stats)")
        return stats
    }

    func restoreEmails(count: Int? = nil, all: Bool = false) async throws -> Int {
        logger.info("Restoring emails from processed folder")

        try await ensureFoldersFound()

        guard let leadmachineFolderId, let processedFolderId else {
            throw MailServiceError.foldersNotFound
        }

        var messages = try await apiClient.getMessages(folderId: processedFolderId, top: 50)

        if let count {
            messages = Array(messages.prefix(count))
        } else if !all && !messages.isEmpty {
            messages = Array(messages.prefix(1))
        }

        logger.info("Restoring \(messages.count) emails")

        for message in messages {
            _ = try await apiClient.moveMessage(messageId: message.id, to: leadmachineFolderId)
            logger.info("✓ Restored: \(message.subject)")
        }

        return messages.count
    }

    private func processMessage(
        _ message: Message,
        processedFolderId: String,
        dryRun: Bool
    ) async throws -> ProcessingResult {
        let decision = try await analyzer.analyze(message: message)

        var wasForwarded = false

        if decision.isLead {
            logger.info("🎯 CPQ Lead detected: \(message.subject)")
            logger.info("   Reasoning: \(decision.reasoning)")

            let comment = buildForwardComment(reasoning: decision.reasoning)

            if !dryRun {
                try await apiClient.forwardMessage(
                    messageId: message.id,
                    to: [config.adminEmail],
                    comment: comment
                )
            }

            wasForwarded = true
        }

        if !dryRun {
            _ = try await apiClient.moveMessage(messageId: message.id, to: processedFolderId)
        }

        return ProcessingResult(wasForwarded: wasForwarded, decision: decision)
    }

    private func buildForwardComment(reasoning: String) -> String {
        """
        === CPQ LEAD ANALYSE ===

        Dit is een potentieel interessante lead voor een CPQ implementatie.

        Reden: \(reasoning)

        === ORIGINELE EMAIL HIERONDER ===
        """
    }

    private func ensureFoldersFound() async throws {
        if leadmachineFolderId != nil && processedFolderId != nil {
            return
        }

        logger.info("Finding leadmachine folders...")

        let folders = try await apiClient.getFolders()

        guard let inboxFolder = folders.first(where: { $0.displayName == "Inbox" }) else {
            throw MailServiceError.inboxNotFound
        }

        let inboxChildren = try await apiClient.getChildFolders(parentId: inboxFolder.id)

        guard let leadmachine = inboxChildren.first(where: { $0.displayName.lowercased() == "leadmachine" }) else {
            throw MailServiceError.leadmachineFolderNotFound
        }

        leadmachineFolderId = leadmachine.id
        logger.info("Found leadmachine folder: \(leadmachine.id)")

        let leadmachineChildren = try await apiClient.getChildFolders(parentId: leadmachine.id)

        guard let processed = leadmachineChildren.first(where: { $0.displayName.lowercased() == "processed" }) else {
            throw MailServiceError.processedFolderNotFound
        }

        processedFolderId = processed.id
        logger.info("Found processed folder: \(processed.id)")
    }
}

struct ProcessingStats: CustomStringConvertible {
    var totalProcessed = 0
    var leadsForwarded = 0
    var errors = 0

    var description: String {
        "Processed: \(totalProcessed), Leads: \(leadsForwarded), Errors: \(errors)"
    }
}

@available(macOS 26.0, *)
struct ProcessingResult {
    let wasForwarded: Bool
    let decision: CPQLeadDecision
}

enum MailServiceError: Error, CustomStringConvertible {
    case foldersNotFound
    case inboxNotFound
    case leadmachineFolderNotFound
    case processedFolderNotFound

    var description: String {
        switch self {
        case .foldersNotFound:
            return "Required folders not found"
        case .inboxNotFound:
            return "Inbox folder not found"
        case .leadmachineFolderNotFound:
            return "leadmachine folder not found under Inbox"
        case .processedFolderNotFound:
            return "processed folder not found under leadmachine"
        }
    }
}
