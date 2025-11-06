# LeadMachine - Geautomatiseerde CPQ Lead Detectie

Geautomatiseerd emailverwerkingssysteem dat Microsoft Graph API en OpenAI GPT-5 gebruikt om potentiële HiveCPQ implementatie leads te detecteren en doorsturen.

## Features

- Microsoft Graph API integratie (lezen, verplaatsen, doorsturen)
- OpenAI GPT-5 analyse voor lead kwalificatie
- Doorsturen naar meerdere ontvangers met HTML analyse
- CLI commando's: process, daemon, restore
- macOS daemon met automatische start bij login
- Gebruikt alleen AI credits wanneer emails aanwezig zijn

## Vereisten

- macOS 13.0+
- Swift 6.2+
- Microsoft Graph API credentials (Azure AD)
- OpenAI API key
- Mailbox folders: `Inbox/leadmachine` en `Inbox/leadmachine/processed`

## Installatie

### 1. Configuratie

```bash
cd ~/docker/leadmachine
cp .env.example .env
```

Bewerk `.env`:
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

### 4. Installeer als Daemon

```bash
# Fix directory ownership (eenmalig)
sudo chown $USER:staff ~/Library/LaunchAgents/

# Kopieer plist
cp com.configurewise.leadmachine.plist ~/Library/LaunchAgents/

# Laad daemon (start bij login + elke 30 min)
launchctl load ~/Library/LaunchAgents/com.configurewise.leadmachine.plist

# Start direct
launchctl start com.configurewise.leadmachine

# Check status
launchctl list | grep leadmachine
```

## Gebruik

### Emails Verwerken

```bash
cd ~/docker/leadmachine

# Eenmalig verwerken
./leadmachine-swift/.build/release/LeadMachineCLI process

# Met limiet
./leadmachine-swift/.build/release/LeadMachineCLI process --limit 5

# Dry-run (preview)
./leadmachine-swift/.build/release/LeadMachineCLI process --dry-run
```

### Emails Terugzetten (Testing)

```bash
# 1 email terugzetten
./leadmachine-swift/.build/release/LeadMachineCLI restore

# Meerdere terugzetten
./leadmachine-swift/.build/release/LeadMachineCLI restore --count 5

# Alles terugzetten
./leadmachine-swift/.build/release/LeadMachineCLI restore --all
```

## Daemon Beheer

### Status Checken

```bash
launchctl list | grep leadmachine
```

### Logs Bekijken

```bash
# Live logs (stdout)
tail -f ~/Library/Logs/LeadMachine/stdout.log

# Live logs (stderr met info)
tail -f ~/Library/Logs/LeadMachine/stderr.log
```

### Daemon Stoppen/Herstarten

```bash
# Stoppen
launchctl unload ~/Library/LaunchAgents/com.configurewise.leadmachine.plist

# Herstarten
launchctl load ~/Library/LaunchAgents/com.configurewise.leadmachine.plist
```

### Interval Wijzigen

Bewerk `~/Library/LaunchAgents/com.configurewise.leadmachine.plist`:
```xml
<key>StartInterval</key>
<integer>1800</integer>  <!-- 30 minuten (in seconden) -->
```

Herlaad:
```bash
launchctl unload ~/Library/LaunchAgents/com.configurewise.leadmachine.plist
launchctl load ~/Library/LaunchAgents/com.configurewise.leadmachine.plist
```

## Hoe Het Werkt

1. **Authenticatie** - OAuth met Microsoft Graph
2. **Lezen** - Emails ophalen uit `Inbox/leadmachine`
3. **Analyseren** - GPT-5 analyseert elke email op CPQ lead signalen
4. **Doorsturen** - Bij lead → doorsturen naar alle admin emails met HTML analyse
5. **Verplaatsen** - Alle emails naar `Inbox/leadmachine/processed`

### Lead Detectie Criteria

GPT-5 controleert op:
- **Manufacturing bedrijven** met eigen productie (geen handelaren)
- **Configuratie behoefte** - portal, configurator, productvarianten
- **Complexe producten** met klantopties

✅ **Goede leads:**
- Metaalfabrikant zoekt portal voor plaatwerk configuratie
- Deurenfabrikant wil online configurator voor dealers
- HVAC producent zoekt complexe productconfiguratie systeem

❌ **Geen leads:**
- Distributeurs die CRM zoeken
- WMS/logistiek systemen
- Simpele ERP zonder varianten
- Spam

## Configuratie

### Meerdere Admin Emails

```bash
ADMIN_EMAILS=email1@company.com,email2@company.com,email3@company.com
```

Alle ontvangers krijgen:
- Originele email als forward
- HTML analyse met reasoning en samenvatting
- Gekleurde secties

### API Kosten

**Microsoft Graph API**: Gratis (bij Microsoft 365)

**OpenAI GPT-5**: Pay-per-use
- Alleen kosten bij aanwezige emails
- ~€0.01-0.05 per email
- Voorbeeld: 10 emails/dag ≈ €10-15/maand

**Optimalisatie:**
- Geen emails = geen API calls = €0
- Daemon checkt eerst folders
- Max 4000 karakters per email

## Troubleshooting

### "Missing required fields in .env"
Check `.env` bevat: GRAPH_CLIENT_ID, GRAPH_CLIENT_SECRET, GRAPH_TENANT_ID, SENDER_EMAIL, ADMIN_EMAILS, OPENAI_API_KEY

### "Authentication failed"
- Controleer credentials in Azure Portal
- Vereiste permissions: Mail.Read, Mail.Send, Mail.ReadWrite (Application)
- Grant admin consent

### "Folder not found"
Maak folders in Outlook:
```
Inbox
└── leadmachine
    └── processed
```

### Daemon start niet
```bash
# Check status
launchctl list | grep leadmachine

# Check logs
cat ~/Library/Logs/LeadMachine/stderr.log

# Herlaad
launchctl unload ~/Library/LaunchAgents/com.configurewise.leadmachine.plist
launchctl load ~/Library/LaunchAgents/com.configurewise.leadmachine.plist
```

### OpenAI API errors
- Controleer API key: https://platform.openai.com/api-keys
- Check quota: https://platform.openai.com/usage

## Development

### Tech Stack
- Swift 6.2 (async/await actors)
- MacPaw OpenAI Swift SDK
- ArgumentParser (CLI)
- Swift Log
- URLSession (Graph API)

### Build

```bash
cd leadmachine-swift
swift build                    # Debug
swift build -c release         # Release (optimized)
```

### Testing Workflow

```bash
# 1. Preview
./leadmachine-swift/.build/release/LeadMachineCLI process --dry-run

# 2. Proces 1 email
./leadmachine-swift/.build/release/LeadMachineCLI process --limit 1

# 3. Check inbox ontvangers

# 4. Terugzetten
./leadmachine-swift/.build/release/LeadMachineCLI restore
```

### LLM Prompt Aanpassen

Bewerk `leadmachine-swift/Sources/LeadMachineCLI/Services/CPQLeadAnalyzer.swift`:
- `systemPrompt` - Instructies en voorbeelden voor GPT-5
- `buildPrompt()` - User message formaat

Rebuild:
```bash
cd leadmachine-swift
swift build -c release
```

## Project Structuur

```
leadmachine/
├── .env                              # Credentials (gitignored)
├── .env.example                      # Template
├── README.md                         # Dit bestand
├── com.configurewise.leadmachine.plist  # LaunchAgent config
│
└── leadmachine-swift/
    ├── Package.swift
    ├── Sources/LeadMachineCLI/
    │   ├── Models/              # Message, Folder, CPQLeadDecision
    │   ├── Services/            # Config, Auth, GraphAPI, Analyzer
    │   └── Commands/            # Process, Daemon, Restore
    └── .build/release/
        └── LeadMachineCLI       # Binary
```

## License

Private - ConfigureWise
