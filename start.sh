#!/bin/bash
# Start Chrome (if needed) and the CDP Bridge server
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.cdp-bridge/logs"

# Launch Chrome with CDP if not already running
if ! lsof -i :9222 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Starting Chrome with CDP..."
  "$SCRIPT_DIR/launch.sh"
  if [ $? -ne 0 ]; then
    echo "Failed to launch Chrome" >&2
    exit 1
  fi
else
  echo "Chrome CDP already running on port 9222"
fi

# Verify Chrome CDP is healthy
if ! curl -s http://127.0.0.1:9222/json/version >/dev/null 2>&1; then
  echo "Error: Chrome CDP not responding" >&2
  exit 1
fi
echo "Chrome CDP verified"

# Start bridge server (exec replaces this process for LaunchAgent KeepAlive)
echo "Starting CDP Bridge on port 18793..."
exec node "$SCRIPT_DIR/server.js"
