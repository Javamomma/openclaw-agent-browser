# 🌐 OpenClaw Agent Browser

**Give your AI agent its own persistent browser identity.**

A turnkey CDP (Chrome DevTools Protocol) bridge that gives your OpenClaw agent a dedicated Chrome instance with its own identity — separate from your personal browser. Your agent gets its own Google account, social media profiles, and persistent sessions that survive reboots.

## Why?

OpenClaw's built-in browser tool is powerful, but it shares your browser context or uses an ephemeral profile. If your agent needs to:

- **Maintain its own social media presence** (Twitter/X, Substack, etc.)
- **Have its own email account** for newsletters, signups, and notifications
- **Browse authenticated sites** without touching your personal sessions
- **Run autonomously** via cron jobs (scrape feeds, check dashboards, post updates)

...then it needs its own persistent browser identity.

## What's Included

```
openclaw-agent-browser/
├── server.js           # CDP proxy bridge (port 18793 → Chrome CDP 9222)
├── launch.sh           # Chrome launcher with isolated profile
├── start.sh            # Combined launcher (Chrome + bridge)
├── setup.sh            # Interactive setup script
├── launchd/
│   └── com.cdp-bridge.plist    # macOS LaunchAgent (auto-start on boot)
├── systemd/
│   └── cdp-bridge.service      # Linux systemd unit
├── docker/
│   └── docker-compose.yml      # Containerized setup
├── openclaw-config-example.json5  # OpenClaw config snippet
├── docs/
│   ├── identity-setup.md       # Creating agent-specific accounts
│   ├── anti-detection.md       # Why full Chrome matters
│   └── cron-examples.md        # Automated browser task examples
├── SECURITY.md                 # Critical security guidance
└── LICENSE                     # MIT
```

## Quick Start (macOS)

```bash
# 1. Clone and run setup
git clone https://github.com/Javamomma/openclaw-agent-browser.git
cd openclaw-agent-browser
./setup.sh

# 2. A new Chrome window opens — sign into your agent's accounts
#    (Google, Twitter, whatever identity you want it to have)

# 3. Add to your OpenClaw config (config.json5)
#    The setup script prints the exact config to add

# 4. Install auto-start (optional)
cp launchd/com.cdp-bridge.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.cdp-bridge.plist
```

## Quick Start (Linux)

```bash
# 1. Clone and run setup
git clone https://github.com/Javamomma/openclaw-agent-browser.git
cd openclaw-agent-browser
./setup.sh

# 2. Sign into your agent's accounts in the Chrome window

# 3. Install systemd service (optional)
sudo cp systemd/cdp-bridge.service /etc/systemd/system/
sudo systemctl enable --now cdp-bridge
```

## How It Works

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   OpenClaw   │────▶│  CDP Bridge  │────▶│    Chrome     │
│  browser()   │     │  :18793      │     │  :9222 (CDP)  │
│              │     │  (proxy)     │     │  Agent Profile│
└──────────────┘     └──────────────┘     └──────────────┘
                           │
                     Loopback only
                     (127.0.0.1)
```

1. **Chrome** launches with `--remote-debugging-port=9222` using an isolated user data directory
2. **CDP Bridge** (Node.js) proxies WebSocket connections on port 18793
3. **OpenClaw** connects via `browser.cdpUrl: "http://127.0.0.1:18793"` with `profile: "openclaw"`
4. Your agent browses as its own identity — cookies, sessions, and logins persist in the profile directory

## OpenClaw Configuration

Add this to your OpenClaw `config.json5`:

```json5
{
  browser: {
    cdpUrl: "http://127.0.0.1:18793",
    attachOnly: true
  }
}
```

Then use `profile="openclaw"` in your browser tool calls:

```
browser(action="navigate", profile="openclaw", targetUrl="https://x.com/home")
browser(action="snapshot", profile="openclaw", compact=true)
```

## Use Cases

### 🐦 Social Media Monitoring
Set up cron jobs to scan your agent's Twitter feed, summarize interesting posts, and report back.

### 📧 Agent Email
Give your agent its own Gmail. It can check newsletters, verify signups, and manage subscriptions.

### 🔍 Authenticated Research
Your agent can log into sites that require accounts — forums, dashboards, paywalled content (with a subscription).

### 📝 Content Publishing
Post to Substack, Medium, or any CMS through the browser — no API keys needed.

### 🤖 Workflow Automation
Fill forms, submit applications, interact with web apps that don't have APIs.

## Security

**Read [SECURITY.md](SECURITY.md) before deploying.** Key points:

- ⚠️ CDP ports must be **loopback-only** (127.0.0.1) — never bind to 0.0.0.0
- ⚠️ The Chrome profile directory contains session cookies and tokens — treat it as sensitive
- ⚠️ `browser act kind=evaluate` executes arbitrary JavaScript — consider disabling with `browser.evaluateEnabled=false`
- ⚠️ Keep your agent's identity separate from your personal accounts
- ✅ The bridge only accepts connections from localhost by default

## FAQ

**Q: Why not just use OpenClaw's built-in browser?**
A: The built-in browser ties to the Gateway lifecycle and uses an ephemeral or shared profile. This bridge runs independently, survives Gateway restarts, and maintains a persistent identity.

**Q: Why a proxy bridge instead of pointing directly at Chrome's CDP port?**
A: The bridge adds a layer of control — you can add auth, logging, rate limiting. It also lets you restart Chrome without reconfiguring OpenClaw.

**Q: Will sites detect this as a bot?**
A: We use full Chrome (not headless), which avoids most bot detection. See [docs/anti-detection.md](docs/anti-detection.md) for details.

**Q: Can I run multiple agent identities?**
A: Yes — run multiple Chrome instances on different CDP ports with separate profile directories and bridge instances.

## Contributing

PRs welcome. Areas that need help:
- Windows support (Task Scheduler equivalent)
- Browser fingerprint hardening
- OpenClaw skill wrapper for browser lifecycle management
- Integration tests

## License

MIT — see [LICENSE](LICENSE).

## Credits

Built by [Oz](https://ozane2004.substack.com) (an AI agent) and Javamomma (https://github.com/Javamomma), powered by [OpenClaw](https://github.com/openclaw/openclaw). 🦞
