# Setting Up Your Agent's Identity

Your agent needs its own accounts — separate from yours. Here's how to set them up.

## 1. Email (Required)

Create a dedicated email for your agent. Options:
- **Gmail** — Free, works everywhere, easy to set up
- **AgentMail** (agentmail.to) — Purpose-built for AI agents, API access
- **Proton Mail** — Privacy-focused alternative
- **Custom domain** — e.g., agent@yourdomain.com

**Tips:**
- Use a memorable name that reflects the agent's identity
- Enable 2FA immediately
- Save recovery codes somewhere secure (not in the agent's browser profile)

## 2. Social Media (Optional)

### Twitter/X
1. Sign up at x.com with the agent's email
2. Complete profile: name, bio, avatar, location
3. Follow accounts relevant to your interests
4. Start with read-only monitoring before posting

### Substack
1. Sign up at substack.com with the agent's email
2. Choose a handle and set up the publication
3. Your agent can draft and publish posts via the browser

### Other Platforms
The same pattern works for any web-based service — Reddit, LinkedIn, Discord, etc.

## 3. Password Management

**Recommended:** Use a password manager with a separate vault or service account.

- **1Password**: Create a service account with just-in-time secret access
- **Bitwarden**: Self-hosted option with API access
- **KeePass**: Local-only, encrypted database

**Alternative:** Store credentials in an encrypted file on the machine running the agent. Never commit credentials to version control.

## 4. Sign Into the Agent Browser

Once accounts are created:

1. Start the CDP bridge: `./start.sh`
2. In the Chrome window that opens, navigate to each service
3. Sign in with the agent's credentials
4. Check "Remember me" / "Stay signed in" where available
5. Sessions persist in the Chrome profile directory

## 5. Verify It Works

From OpenClaw:
```
browser(action="navigate", profile="openclaw", targetUrl="https://x.com/home")
browser(action="snapshot", profile="openclaw", compact=true)
```

If you see the agent's feed/inbox, the identity is working.

## 6. Maintenance

- **Session expiry:** Some sites expire sessions after days/weeks. Your agent may need to re-authenticate occasionally.
- **2FA prompts:** If a site triggers 2FA, the agent can't solve it autonomously (yet). You may need to intervene.
- **Account security alerts:** Sites may flag "new device" logins. Dismiss these in the agent's browser.
