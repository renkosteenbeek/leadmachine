# LeadMachine - Automated CPQ Lead Detection

Automated email processing system that uses Microsoft Graph API and OpenAI GPT-5 to detect and forward potential HiveCPQ implementation leads.

## Features

✅ **Microsoft Graph API Integration**
- OAuth client credentials authentication
- Read emails from specific folders
- Move emails between folders
- Forward to multiple recipients with custom HTML content

✅ **OpenAI GPT-5 Integration**
- Advanced AI analysis for lead qualification
- Structured JSON output with reasoning and summary
- Only uses API credits when emails are present
- Optimized prompts for HiveCPQ lead detection

✅ **CLI Commands**
- `process` - One-time email processing
- `daemon` - Continuous monitoring (custom interval)
- `restore` - Restore emails for testing

✅ **Smart Processing**
- Processes full email body (HTML stripped, truncated to 4000 chars)
- Forwards to multiple admin emails
- Comprehensive logging
- Dry-run mode for testing

✅ **macOS Daemon**
- Runs automatically at startup
- Configurable interval (default: 30 minutes)
- No sudo required
- Logs to `~/Library/Logs/LeadMachine/`

## Prerequisites

- macOS 13.0+ (any Intel/Apple Silicon)
- Swift 6.2+
- Microsoft Graph API credentials (Azure AD)
- OpenAI API key
- Mailbox folder structure: `Inbox/leadmachine` and `Inbox/leadmachine/processed`

## Installation

### 1. Clone & Configure

```bash
cd ~/docker/leadmachine
cp .env.example .env
```

Edit `.env`:
```bash
GRAPH_CLIENT_ID=your-client-id-here
GRAPH_CLIENT_SECRET=your-client-secret-here
GRAPH_TENANT_ID=your-tenant-id-here
SENDER_EMAIL=your-mailbox@company.com
ADMIN_EMAILS=admin1@company.com,admin2@company.com,admin3@company.com
OPENAI_API_KEY=sk-proj-...
```

### 2. Build

```bash
cd leadmachine-swift
swift build --configuration release
```

### 3. Test

```bash
cd ..
./leadmachine-swift/.build/release/LeadMachineCLI process --dry-run --limit 1
```

### 4. Install as Daemon (Auto-start)

```bash
# Fix LaunchAgents directory ownership (one time)
sudo chown $USER:staff ~/Library/LaunchAgents/

# Copy plist file
cp com.configurewise.leadmachine.plist ~/Library/LaunchAgents/

# Load daemon (starts at login + runs every 30 min)
launchctl load ~/Library/LaunchAgents/com.configurewise.leadmachine.plist

# Start immediately for testing
launchctl start com.configurewise.leadmachine

# Check status
launchctl list | grep leadmachine

# View logs
tail -f ~/Library/Logs/LeadMachine/stdout.log
```

## Usage

### Process Emails Once

```bash
cd ~/docker/leadmachine
./leadmachine-swift/.build/release/LeadMachineCLI process
```

### Process with Limit

```bash
./leadmachine-swift/.build/release/LeadMachineCLI process --limit 5
```

### Dry Run (Preview)

```bash
./leadmachine-swift/.build/release/LeadMachineCLI process --dry-run
```

### Run as Daemon (Manual)

```bash
# Check every 5 minutes
./leadmachine-swift/.build/release/LeadMachineCLI daemon --interval 300

# Default: every 5 minutes
./leadmachine-swift/.build/release/LeadMachineCLI daemon
```

### Restore Emails for Testing

```bash
# Restore 1 email
./leadmachine-swift/.build/release/LeadMachineCLI restore

# Restore 5 emails
./leadmachine-swift/.build/release/LeadMachineCLI restore --count 5

# Restore all
./leadmachine-swift/.build/release/LeadMachineCLI restore --all
```

## Daemon Management

### Check Status

```bash
launchctl list | grep leadmachine
```

Output: `PID  Status  Label`
- If PID shown → running
- Status 0 → successful last run

### View Logs

```bash
# Live stdout
tail -f ~/Library/Logs/LeadMachine/stdout.log

# Live stderr (includes info logs)
tail -f ~/Library/Logs/LeadMachine/stderr.log

# All logs
cat ~/Library/Logs/LeadMachine/*.log
```

### Stop Daemon

```bash
launchctl unload ~/Library/LaunchAgents/com.configurewise.leadmachine.plist
```

### Restart Daemon

```bash
launchctl unload ~/Library/LaunchAgents/com.configurewise.leadmachine.plist
launchctl load ~/Library/LaunchAgents/com.configurewise.leadmachine.plist
```

### Change Interval

Edit `~/Library/LaunchAgents/com.configurewise.leadmachine.plist`:
```xml
<key>StartInterval</key>
<integer>1800</integer>  <!-- 30 minutes in seconds -->
```

Then restart:
```bash
launchctl unload ~/Library/LaunchAgents/com.configurewise.leadmachine.plist
launchctl load ~/Library/LaunchAgents/com.configurewise.leadmachine.plist
```

## How It Works

1. **Authenticate** - OAuth client credentials flow with Microsoft Graph
2. **Read** - Fetch unread emails from `Inbox/leadmachine` folder
3. **Analyze** - Each email analyzed by OpenAI GPT-5 for CPQ lead signals
4. **Forward** - If lead detected → forward to all admin emails with HTML analysis
5. **Move** - All processed emails moved to `Inbox/leadmachine/processed`

### Lead Detection Criteria

GPT-5 checks for:
- **Manufacturing companies** with own production (not distributors)
- **Configuration needs** - portal, configurator, product variants
- **Complex products** requiring customer options/choices

Examples of valid leads:
- Metal manufacturer seeking portal for part configuration
- Door manufacturer wanting online configurator for dealers
- HVAC producer needing complex product configuration system

Examples of non-leads:
- Distributors seeking CRM (no production)
- WMS/logistics systems (no configuration aspect)
- Simple ERP without variants
- Spam/notifications

## Configuration

### Multiple Admin Emails

The system forwards detected leads to multiple recipients:

```bash
ADMIN_EMAILS=email1@company.com,email2@company.com,email3@company.com
```

All recipients receive:
- Original email as forward
- HTML analysis with reasoning and summary
- Styled with color-coded sections

### API Costs

**Microsoft Graph API**: Free (included with Microsoft 365)

**OpenAI GPT-5 API**: Pay per use
- Only charged when emails are present
- ~$0.01-0.05 per email analyzed
- Example: 10 emails/day = ~$10-15/month

**Cost optimization:**
- No emails = no API calls = $0
- Daemon checks folders first before analyzing
- Full body analysis (4000 chars max) for accuracy

## Project Structure

```
leadmachine/
├── .env                              # Credentials (gitignored)
├── .env.example                      # Template
├── README.md                         # This file
├── com.configurewise.leadmachine.plist  # LaunchAgent config
│
└── leadmachine-swift/                # Swift CLI application
    ├── Package.swift                 # Dependencies
    ├── Sources/LeadMachineCLI/
    │   ├── LeadMachineCLI.swift     # Main entry point
    │   ├── Models/
    │   │   ├── Message.swift        # Email model
    │   │   ├── Folder.swift         # Folder model
    │   │   ├── CPQLeadDecision.swift # LLM response
    │   │   └── TokenResponse.swift  # Auth token
    │   ├── Services/
    │   │   ├── Config.swift         # .env loader
    │   │   ├── Authenticator.swift  # OAuth handler
    │   │   ├── GraphAPIClient.swift # Microsoft Graph
    │   │   ├── CPQLeadAnalyzer.swift # OpenAI GPT-5
    │   │   └── MailService.swift    # Orchestration
    │   └── Commands/
    │       ├── ProcessCommand.swift  # process command
    │       ├── DaemonCommand.swift   # daemon command
    │       └── RestoreCommand.swift  # restore command
    └── .build/release/
        └── LeadMachineCLI           # Compiled binary
```

## Troubleshooting

### "Missing required fields in .env"
Check that `.env` contains all fields:
- GRAPH_CLIENT_ID
- GRAPH_CLIENT_SECRET
- GRAPH_TENANT_ID
- SENDER_EMAIL
- ADMIN_EMAILS (comma-separated)
- OPENAI_API_KEY

### "Authentication failed"
- Verify credentials in Azure Portal
- Required Graph API permissions:
  - Mail.Read (Application)
  - Mail.Send (Application)
  - Mail.ReadWrite (Application)
- Grant admin consent in Azure Portal

### "Folder not found"
Create folders in Outlook/Mail:
```
Inbox
└── leadmachine
    └── processed
```

### Daemon not starting
```bash
# Check if loaded
launchctl list | grep leadmachine

# Check logs for errors
cat ~/Library/Logs/LeadMachine/stderr.log

# Verify plist syntax
plutil -lint ~/Library/LaunchAgents/com.configurewise.leadmachine.plist

# Reload
launchctl unload ~/Library/LaunchAgents/com.configurewise.leadmachine.plist
launchctl load ~/Library/LaunchAgents/com.configurewise.leadmachine.plist
```

### OpenAI API errors
- Verify API key is valid: https://platform.openai.com/api-keys
- Check quota/billing: https://platform.openai.com/usage
- GPT-5 requires specific API access tier

### No emails forwarded but logs say "lead detected"
- Check dry-run mode is OFF
- Verify ADMIN_EMAILS in .env
- Check spam folders of recipients
- View logs for forward success/failure

## Development

### Tech Stack
- **Swift 6.2** - Modern Swift with async/await actors
- **OpenAI Swift SDK** - MacPaw/OpenAI package
- **ArgumentParser** - CLI argument handling
- **Swift Log** - Structured logging
- **URLSession** - HTTP client for Graph API

### Building from Source

```bash
cd leadmachine-swift
swift build                    # Debug build
swift build -c release         # Release build (optimized)
swift run LeadMachineCLI --help  # Run from source
```

### Testing Workflow

```bash
# 1. Dry-run to preview
./leadmachine-swift/.build/release/LeadMachineCLI process --dry-run

# 2. Process one email
./leadmachine-swift/.build/release/LeadMachineCLI process --limit 1

# 3. Check recipient inbox for forwarded email

# 4. Restore email for reprocessing
./leadmachine-swift/.build/release/LeadMachineCLI restore

# 5. Iterate on prompt in CPQLeadAnalyzer.swift if needed
```

### Modifying LLM Prompt

Edit `leadmachine-swift/Sources/LeadMachineCLI/Services/CPQLeadAnalyzer.swift`:
- `systemPrompt` - Instructions and examples for GPT-5
- `buildPrompt()` - User message format

Rebuild after changes:
```bash
cd leadmachine-swift
swift build -c release
```

## License

Private project - ConfigureWise

## Credits

Developed with Claude Code
2025-11-06
