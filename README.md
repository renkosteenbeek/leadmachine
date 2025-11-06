# LeadMachine - Automated CPQ Lead Detection

Automated email processing system that uses Microsoft Graph API and Apple's on-device LLM to detect potential CPQ implementation leads.

## Project Structure

```
leadmachine/
├── leadmachine-swift/          # Swift CLI application
│   ├── Sources/
│   │   └── LeadMachineCLI/
│   │       ├── Models/          # Data models
│   │       ├── Services/        # Core services
│   │       └── Commands/        # CLI commands
│   ├── Package.swift
│   ├── .env                     # Credentials (not in git)
│   └── README.md
│
├── node_modules/                # Node.js dependencies
├── package.json
├── .env                         # Microsoft Graph credentials
│
├── test-mail.js                 # Test: Read emails
├── test-send-mail.js            # Test: Send email
├── test-graph-capabilities.js   # Test: All API operations
├── create-leadmachine-folder.js # Setup: Create folder
│
└── API-DOCUMENTATION.md         # Complete API reference
```

## Features

✅ **Microsoft Graph API Integration**
- OAuth client credentials authentication
- Read emails from specific folders
- Move emails between folders
- Forward emails with custom content

✅ **Apple LLM Integration**
- On-device AI analysis (macOS 26+)
- CPQ lead detection
- Structured output with reasoning

✅ **CLI Commands**
- `process` - One-time email processing
- `daemon` - Continuous monitoring
- `restore` - Restore emails for testing

✅ **Smart Processing**
- Only processes bodyPreview (context window limit)
- Handles token limit errors gracefully
- Logging for debugging
- Dry-run mode for testing

## Quick Start

### Prerequisites

- macOS 26+ (Sequoia) with Apple Intelligence
- Swift 6.2+
- Microsoft Graph API credentials
- Mailbox folder structure: `Inbox/leadmachine` and `Inbox/leadmachine/processed`

### Setup

1. Configure credentials:
```bash
cd leadmachine-swift
cp .env.example .env
# Edit .env with your credentials
```

2. Build:
```bash
cd leadmachine-swift
swift build
```

3. Test:
```bash
swift run LeadMachineCLI process --dry-run --limit 1
```

4. Process for real:
```bash
swift run LeadMachineCLI process
```

## Usage Examples

### Process Emails Once
```bash
cd leadmachine-swift
swift run LeadMachineCLI process
```

### Run as Daemon (check every 5 minutes)
```bash
swift run LeadMachineCLI daemon --interval 300
```

### Restore Emails for Testing
```bash
swift run LeadMachineCLI restore
swift run LeadMachineCLI restore --count 5
swift run LeadMachineCLI restore --all
```

### Dry Run (no changes)
```bash
swift run LeadMachineCLI process --dry-run
```

## How It Works

1. **Authentication**: OAuth client credentials flow with Microsoft Graph
2. **Read**: Fetch emails from `Inbox/leadmachine` folder
3. **Analyze**: Each email is analyzed by Apple's on-device LLM
4. **Forward**: If CPQ lead detected → forward to admin with reasoning
5. **Move**: All processed emails → `Inbox/leadmachine/processed`

## Testing Workflow

```bash
# 1. Run dry-run to see what would happen
swift run LeadMachineCLI process --dry-run

# 2. Process one email
swift run LeadMachineCLI process --limit 1

# 3. Check if email was moved and/or forwarded

# 4. Restore for reprocessing
swift run LeadMachineCLI restore

# 5. Iterate on LLM prompt in CPQLeadAnalyzer.swift
```

## API Testing

Node.js test scripts for API validation:

```bash
# Test all Microsoft Graph capabilities
node test-graph-capabilities.js

# Test sending email
node test-send-mail.js

# Test reading emails
npm test  # runs test-mail.js
```

## Configuration

### Environment Variables (.env)
```
GRAPH_CLIENT_ID=<your-client-id>
GRAPH_CLIENT_SECRET=<your-client-secret>
GRAPH_TENANT_ID=<your-tenant-id>
SENDER_EMAIL=<mailbox-email>
ADMIN_EMAIL=<forward-to-email>
```

### Folder Structure
Must exist in mailbox:
- `Inbox/leadmachine` - Source folder
- `Inbox/leadmachine/processed` - Destination folder

## Deployment

### Build Release Binary
```bash
cd leadmachine-swift
swift build -c release
cp .build/release/LeadMachineCLI /usr/local/bin/leadmachine
```

### Run as macOS Daemon
See `leadmachine-swift/README.md` for launchd configuration.

## Troubleshooting

### "Model unavailable"
- Requires macOS 26+ (Sequoia 15.2+)
- Apple Intelligence must be enabled
- Apple Silicon (M1/M2/M3/M4) required

### "Context window exceeded"
- Email body too large (>4096 tokens)
- Solution: Uses bodyPreview instead of full body
- Already implemented in current version

### "Authentication failed"
- Check credentials in `.env`
- Verify API permissions in Azure Portal
- Required: Mail.Read, Mail.Send, Mail.ReadWrite

### "Folder not found"
- Create folders manually in Outlook/Mail app
- Structure: Inbox → leadmachine → processed

## Development

Built with:
- **Swift 6.2** - Modern Swift with async/await
- **FoundationModels** - Apple's on-device LLM
- **ArgumentParser** - CLI argument handling
- **Swift Log** - Structured logging
- **URLSession** - HTTP client for Graph API

## License

Private project - ConfigureWise

## Credits

Developed with Claude Code
2025-11-06
