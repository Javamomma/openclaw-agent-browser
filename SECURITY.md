# Security Guide

This project gives an AI agent autonomous browser access. That's powerful — and dangerous if misconfigured. Read this before deploying.

## Critical: CDP Port Binding

The Chrome DevTools Protocol gives **full control** over the browser — navigation, cookie access, JavaScript execution, file downloads. 

**NEVER expose CDP ports to the network.**

```bash
# ✅ CORRECT — loopback only (default)
--remote-debugging-port=9222
# Chrome binds to 127.0.0.1 by default

# ❌ DANGEROUS — accessible from network
--remote-debugging-address=0.0.0.0 --remote-debugging-port=9222
```

The bridge server also binds to `127.0.0.1:18793` by default. Do not change this unless you're tunneling through a VPN (e.g., Tailscale).

## Profile Directory Security

The Chrome profile directory (`~/.cdp-bridge/chrome-profile/` by default) contains:
- Session cookies for all logged-in sites
- OAuth tokens
- Saved passwords (if any)
- Browser history
- Local storage data

**Treat this directory like a credentials store.** Recommendations:
- Set permissions to `700` (owner only): `chmod 700 ~/.cdp-bridge/chrome-profile`
- Back it up if the identity matters
- Don't commit it to version control (it's in `.gitignore`)
- Consider encrypting at rest on shared machines

## JavaScript Execution Risk

OpenClaw's `browser act kind=evaluate` executes arbitrary JavaScript in the page context. This means:
- A prompt injection in page content could execute JS through the agent
- Malicious pages could attempt to exfiltrate cookies or tokens

**Mitigation:**
- Set `browser.evaluateEnabled: false` in OpenClaw config if you don't need JS evaluation
- Use `snapshot` (accessibility tree) instead of `evaluate` for reading page content
- Be cautious about navigating to untrusted URLs

## Identity Separation

The entire point of this project is identity separation. Maintain it:
- **Never sign into your personal accounts** in the agent's Chrome profile
- **Never sign into the agent's accounts** in your personal browser
- Use a **dedicated email address** for the agent identity
- Enable **2FA** on the agent's accounts (use an authenticator app, store recovery codes securely)
- Consider a **password manager service account** (1Password, Bitwarden) for the agent's credentials

## Network Considerations

If the OpenClaw Gateway and CDP bridge are on different machines:
- **Use Tailscale or WireGuard** to create a private tunnel
- **Never expose CDP over the public internet**
- The bridge's `cdpUrl` in OpenClaw config becomes a secret — don't commit it to public repos

## Rate Limiting & Abuse Prevention

Your agent can browse fast. Sites may:
- Rate-limit or block the IP
- Flag the account for suspicious activity
- Trigger CAPTCHAs

**Recommendations:**
- Add delays between page loads in cron jobs
- Don't scrape aggressively — read, don't hammer
- Monitor the agent's browsing for unexpected navigation patterns

## Audit Logging

Consider enabling logging in the bridge server to track:
- What URLs the agent visits
- When CDP connections are made
- Any errors or unusual activity

The bridge logs to `~/.cdp-bridge/logs/` by default.

## Incident Response

If you suspect the agent's identity is compromised:
1. Kill the Chrome process: `pkill -f "cdp-bridge"`
2. Change passwords on all agent accounts immediately
3. Revoke OAuth tokens
4. Delete and recreate the Chrome profile directory
5. Review bridge logs for unauthorized access

## Terms of Service Compliance

Automated browser interaction may violate certain platforms' terms of service. Many major platforms explicitly prohibit non-API-based automation, scraping, or automated account usage.

**It is your responsibility to:**
- Review and comply with each platform's terms of service
- Use official APIs where available instead of browser automation
- Understand that accounts used for automated browsing may be suspended by the platform

This tool provides a technical capability. How you use it is up to you.

## Summary

| Risk | Mitigation | Priority |
|------|-----------|----------|
| CDP port exposure | Loopback-only binding | 🔴 Critical |
| Profile credential theft | File permissions, encryption | 🔴 Critical |
| JS execution injection | Disable `evaluate`, use `snapshot` | 🟡 High |
| Personal/agent identity mixing | Strict profile separation | 🟡 High |
| Site rate limiting/bans | Polite scraping, delays | 🟢 Medium |
| Unauthorized access | Audit logging, Gateway auth | 🟢 Medium |
