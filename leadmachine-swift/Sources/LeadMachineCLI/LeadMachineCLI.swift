import ArgumentParser

@main
struct LeadMachineCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "leadmachine",
        abstract: "Microsoft Graph Email Processor for CPQ Lead Detection",
        version: "1.0.0",
        subcommands: [ProcessCommand.self, DaemonCommand.self, RestoreCommand.self],
        defaultSubcommand: ProcessCommand.self
    )
}
