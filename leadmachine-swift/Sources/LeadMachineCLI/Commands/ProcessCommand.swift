import ArgumentParser
import Foundation

struct ProcessCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "process",
        abstract: "Process emails from leadmachine folder one time"
    )

    @Flag(name: .long, help: "Show what would happen without actually doing it")
    var dryRun = false

    @Option(name: .long, help: "Maximum number of emails to process")
    var limit: Int?

    func run() async throws {
        print("🚀 LeadMachine CPQ Lead Processor")
        print("=================================\n")

        if dryRun {
            print("⚠️  DRY RUN MODE - No actual changes will be made\n")
        }

        let config = try Config.load()
        print("✓ Config loaded")

        let authenticator = Authenticator(config: config)
        print("✓ Authenticator initialized")

        let apiClient = GraphAPIClient(authenticator: authenticator, config: config)
        print("✓ API Client initialized")

        let analyzer = CPQLeadAnalyzer(apiKey: config.openAIKey)
        print("✓ LLM Analyzer initialized\n")

        let mailService = MailService(apiClient: apiClient, analyzer: analyzer, config: config)

        print("📧 Processing emails...\n")

        let stats = try await mailService.processEmails(dryRun: dryRun, limit: limit)

        print("\n✅ Processing complete!")
        print("   Emails processed: \(stats.totalProcessed)")
        print("   Leads forwarded: \(stats.leadsForwarded)")
        print("   Errors: \(stats.errors)")

        if dryRun {
            print("\n⚠️  This was a dry run. Run without --dry-run to actually process emails.")
        }
    }
}
