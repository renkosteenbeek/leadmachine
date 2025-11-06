# LeadMachine Swift CLI

Microsoft Graph email processor that uses Apple's on-device LLM to detect CPQ leads.

## Requirements

- macOS 15+ (Sequoia)
- Apple Silicon (M1/M2/M3/M4)
- Apple Intelligence enabled
- Swift 6.2+

## Setup

1. Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

2. Configure your Microsoft Graph API credentials in `.env`

3. Ensure the following folders exist in your mailbox:
   - `Inbox/leadmachine` - Source folder for emails to process
   - `Inbox/leadmachine/processed` - Destination folder for processed emails

## Build

```bash
swift build
```

## Usage

### Process Emails Once

Process all emails in the leadmachine folder:
```bash
swift run LeadMachineCLI process
```

Dry run (see what would happen without actually doing it):
```bash
swift run LeadMachineCLI process --dry-run
```

Process maximum 5 emails:
```bash
swift run LeadMachineCLI process --limit 5
```

### Run as Daemon

Check for new emails every 5 minutes:
```bash
swift run LeadMachineCLI daemon --interval 300
```

### Restore Emails for Testing

Restore last email back to leadmachine folder:
```bash
swift run LeadMachineCLI restore
```

Restore last 5 emails:
```bash
swift run LeadMachineCLI restore --count 5
```

Restore all processed emails:
```bash
swift run LeadMachineCLI restore --all
```

## How It Works

1. **Read** emails from `Inbox/leadmachine` folder
2. **Analyze** each email with Apple's on-device LLM for CPQ lead potential
3. **Forward** leads to admin email with reasoning prepended
4. **Move** all processed emails to `Inbox/leadmachine/processed`

## Development

### Project Structure

```
Sources/LeadMachineCLI/
├── LeadMachineCLI.swift        # Main entry point
├── Models/
│   ├── Message.swift            # Email models
│   ├── Folder.swift             # Folder models
│   ├── TokenResponse.swift      # OAuth token
│   └── CPQLeadDecision.swift    # LLM output
├── Services/
│   ├── Config.swift             # Configuration loader
│   ├── Authenticator.swift      # OAuth authentication
│   ├── GraphAPIClient.swift     # Microsoft Graph API
│   ├── CPQLeadAnalyzer.swift    # Apple LLM integration
│   └── MailService.swift        # Email processing orchestration
└── Commands/
    ├── ProcessCommand.swift     # One-time processing
    ├── DaemonCommand.swift      # Continuous monitoring
    └── RestoreCommand.swift     # Email restoration
```

### Testing Workflow

1. Run initial processing:
   ```bash
   swift run LeadMachineCLI process --dry-run
   ```

2. Review LLM decisions in output

3. Process for real:
   ```bash
   swift run LeadMachineCLI process --limit 1
   ```

4. Check forwarded email in admin inbox

5. Restore email for reprocessing:
   ```bash
   swift run LeadMachineCLI restore
   ```

6. Iterate on LLM prompt in `CPQLeadAnalyzer.swift`

## Deployment

### Build Release Binary

```bash
swift build -c release
cp .build/release/LeadMachineCLI /usr/local/bin/leadmachine
```

### Run as macOS Daemon (launchd)

Create `~/Library/LaunchAgents/com.leadmachine.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.leadmachine</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/leadmachine</string>
        <string>daemon</string>
        <string>--interval</string>
        <string>300</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/path/to/leadmachine-swift</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/leadmachine.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/leadmachine.error.log</string>
</dict>
</plist>
```

Load the daemon:
```bash
launchctl load ~/Library/LaunchAgents/com.leadmachine.plist
```

## API Documentation

See `../API-DOCUMENTATION.md` for detailed Microsoft Graph API endpoint documentation.
