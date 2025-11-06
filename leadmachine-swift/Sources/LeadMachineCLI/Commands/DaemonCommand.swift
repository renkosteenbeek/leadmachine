import ArgumentParser
import Foundation
import Darwin

@available(macOS 26.0, *)
struct DaemonCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "daemon",
        abstract: "Run continuously and check for new emails periodically"
    )

    @Option(name: .long, help: "Check interval in seconds (default: 300)")
    var interval: Int = 300

    func run() async throws {
        print("🚀 LeadMachine CPQ Lead Processor - Daemon Mode")
        print("==============================================\n")

        let config = try Config.load()
        print("✓ Config loaded")

        let authenticator = Authenticator(config: config)
        print("✓ Authenticator initialized")

        let apiClient = GraphAPIClient(authenticator: authenticator, config: config)
        print("✓ API Client initialized")

        let analyzer = try CPQLeadAnalyzer()
        print("✓ LLM Analyzer initialized\n")

        let mailService = MailService(apiClient: apiClient, analyzer: analyzer, config: config)

        print("🔁 Running in daemon mode (check every \(interval) seconds)")
        print("   Press Ctrl+C to stop\n")

        setupSignalHandlers()

        var iteration = 1

        while true {
            let now = Date()
            print("[\(now.formatted())] Iteration #\(iteration)")

            do {
                let stats = try await mailService.processEmails(dryRun: false, limit: nil)

                if stats.totalProcessed == 0 {
                    print("   No new emails to process")
                } else {
                    print("   Processed: \(stats.totalProcessed), Leads: \(stats.leadsForwarded)")
                }
            } catch {
                print("   ❌ Error: \(error)")
            }

            print("   Next check in \(interval) seconds...\n")

            try await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)

            iteration += 1
        }
    }

    private func setupSignalHandlers() {
        signal(SIGINT) { _ in
            print("\n\n🛑 Received SIGINT, shutting down gracefully...")
            Darwin.exit(0)
        }

        signal(SIGTERM) { _ in
            print("\n\n🛑 Received SIGTERM, shutting down gracefully...")
            Darwin.exit(0)
        }
    }
}
