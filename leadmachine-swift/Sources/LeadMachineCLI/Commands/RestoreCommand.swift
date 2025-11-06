import ArgumentParser
import Foundation

@available(macOS 26.0, *)
struct RestoreCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "restore",
        abstract: "Move emails back from processed folder to leadmachine folder for testing"
    )

    @Flag(name: .long, help: "Restore all emails from processed folder")
    var all = false

    @Option(name: .long, help: "Number of emails to restore (default: 1)")
    var count: Int?

    func run() async throws {
        print("🔄 LeadMachine Email Restore")
        print("===========================\n")

        let config = try Config.load()
        print("✓ Config loaded")

        let authenticator = Authenticator(config: config)
        let apiClient = GraphAPIClient(authenticator: authenticator, config: config)
        let analyzer = try CPQLeadAnalyzer()

        let mailService = MailService(apiClient: apiClient, analyzer: analyzer, config: config)

        print("📧 Restoring emails from processed folder...\n")

        let restored = try await mailService.restoreEmails(count: count, all: all)

        print("\n✅ Restored \(restored) email(s) to leadmachine folder")
        print("   Ready for reprocessing!\n")
    }
}
