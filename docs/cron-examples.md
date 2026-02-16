# Cron Job Examples

Here are practical examples of automated browser tasks you can run with OpenClaw cron jobs.

## Twitter/X Feed Scan

Scan your agent's Twitter timeline twice daily and report highlights:

```json5
{
  name: "twitter-feed-scan",
  schedule: { kind: "cron", expr: "0 10,18 * * *", tz: "America/Chicago" },
  payload: {
    kind: "agentTurn",
    message: "Use the CDP browser (profile=openclaw) to scan the home timeline on x.com. Navigate to https://x.com/home, snapshot the timeline, scroll once for more posts, snapshot again. Identify the top 3-5 interesting items. Report a brief digest.",
    timeoutSeconds: 180
  },
  delivery: { mode: "announce" },
  sessionTarget: "isolated"
}
```

## Email Check

Check the agent's Gmail for important messages:

```json5
{
  name: "agent-email-check",
  schedule: { kind: "cron", expr: "0 9,17 * * *", tz: "America/Chicago" },
  payload: {
    kind: "agentTurn",
    message: "Use the CDP browser (profile=openclaw) to check Gmail at https://mail.google.com. Snapshot the inbox. Report any messages that aren't newsletters or spam. Summarize anything interesting.",
    timeoutSeconds: 120
  },
  delivery: { mode: "announce" },
  sessionTarget: "isolated"
}
```

## Dashboard Monitoring

Check a web dashboard for status changes:

```json5
{
  name: "dashboard-check",
  schedule: { kind: "cron", expr: "*/30 * * * *" },
  payload: {
    kind: "agentTurn",
    message: "Use the CDP browser (profile=openclaw) to check https://status.example.com. Snapshot the page and report any services showing degraded or down status. If everything is green, reply with NO_REPLY.",
    timeoutSeconds: 60
  },
  delivery: { mode: "announce" },
  sessionTarget: "isolated"
}
```

## Price/Stock Monitoring

Check a page for price changes (useful for items without APIs):

```json5
{
  name: "price-watch",
  schedule: { kind: "cron", expr: "0 8 * * *", tz: "America/Chicago" },
  payload: {
    kind: "agentTurn",
    message: "Use the CDP browser (profile=openclaw) to check [product URL]. Snapshot the page and extract the current price. Compare with yesterday's price from memory. Alert only if the price changed significantly (>5%).",
    timeoutSeconds: 90
  },
  delivery: { mode: "announce" },
  sessionTarget: "isolated"
}
```

## Tips

- **Set reasonable timeouts** — browser tasks are slower than API calls
- **Use `compact=true`** on snapshots to reduce token usage
- **Scroll for more content** — `browser(action="act", request={kind: "press", key: "Space"})` 
- **Target specific elements** — use `element` parameter to snapshot only the relevant part of the page
- **Respect rate limits** — don't run browser crons more than necessary
