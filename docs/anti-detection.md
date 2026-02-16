# Anti-Detection: Why Full Chrome Matters

## The Problem

Many websites detect and block headless browsers:
- `HeadlessChrome` appears in the user-agent string
- `navigator.webdriver` is `true` in headless mode
- Missing browser plugins, screen dimensions, WebGL fingerprints
- Cloudflare, Akamai, and reCAPTCHA all check for these signals

## Our Approach: Full Chrome

This project uses **full (headed) Chrome** — not headless. This means:
- Standard user-agent string (no `HeadlessChrome`)
- `navigator.webdriver` is `false`
- All browser APIs behave identically to a human's browser
- Plugins, fonts, and WebGL fingerprints are real

The tradeoff: you need a display (or virtual framebuffer on Linux).

## Linux: Running Without a Display

On headless Linux servers, use Xvfb (X Virtual Framebuffer):

```bash
# Install Xvfb
sudo apt install xvfb

# Run Chrome with virtual display
Xvfb :99 -screen 0 1920x1080x24 &
export DISPLAY=:99
./start.sh
```

Or use the Docker setup which handles this automatically.

## Additional Hardening (Optional)

### Randomize viewport size
Sites can fingerprint exact window dimensions. Vary them slightly:
```bash
# In launch.sh, add:
--window-size=$((1900 + RANDOM % 100)),$((1060 + RANDOM % 40))
```

### Disable automation flags
Chrome sets some automation-related flags. Disable them:
```bash
--disable-blink-features=AutomationControlled
```

### Timezone consistency
Make sure the browser timezone matches the agent's claimed location:
```bash
TZ="America/Chicago" ./start.sh
```

## What We Don't Do

- **No stealth plugins** (puppeteer-extra-plugin-stealth, etc.) — these are arms-race tools that break frequently
- **No proxy rotation** — if you need this, you're probably scraping at scale, which isn't our use case
- **No CAPTCHA solving** — if a site CAPTCHAs you, slow down or find another approach

## Best Practices

1. **Browse at human speed** — add delays between page loads
2. **Don't hammer endpoints** — rate-limit your cron jobs
3. **Accept cookies** — declining them is a bot signal
4. **Use realistic browsing patterns** — don't just hit API endpoints directly
5. **Monitor for blocks** — if a site starts showing CAPTCHAs, back off
