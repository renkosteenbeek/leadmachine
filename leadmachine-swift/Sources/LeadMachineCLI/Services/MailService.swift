import Foundation
import Logging

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
            logger.info("   Summary: \(decision.summary)")

            let comment = buildForwardComment(decision: decision)

            if !dryRun {
                try await apiClient.forwardMessage(
                    messageId: message.id,
                    to: config.adminEmails,
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

    private func buildForwardComment(decision: CPQLeadDecision) -> String {
        """
        <html>
        <head>
            <style>
                body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; }
                .header { background: #667eea; color: #ffffff; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
                .header h1 { margin: 0; font-size: 24px; font-weight: 600; color: #ffffff; }
                .section { background: #f8f9fa; padding: 15px; border-radius: 6px; margin-bottom: 15px; border-left: 4px solid #667eea; }
                .section h2 { margin-top: 0; color: #667eea; font-size: 18px; }
                .reasoning { background: #e3f2fd; padding: 15px; border-radius: 6px; margin-bottom: 15px; border-left: 4px solid #2196f3; }
                .summary { background: #f1f8e9; padding: 15px; border-radius: 6px; margin-bottom: 15px; border-left: 4px solid #8bc34a; }
                .footer { color: #666; font-size: 12px; padding-top: 20px; border-top: 1px solid #ddd; }
                ul { margin: 10px 0; padding-left: 20px; }
                li { margin: 5px 0; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>🎯 CPQ Lead Gedetecteerd</h1>
            </div>

            <div class="reasoning">
                <h2>📋 Analyse</h2>
                <p>\(decision.reasoning)</p>
            </div>

            <div class="summary">
                <h2>📊 Lead Samenvatting</h2>
                <p>\(decision.summary.replacingOccurrences(of: "\n", with: "<br>"))</p>
            </div>

            <div class="footer">
                <p><strong>Originele email hieronder ↓</strong></p>
            </div>
        </body>
        </html>
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
