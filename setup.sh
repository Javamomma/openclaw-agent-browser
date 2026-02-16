#!/bin/bash
# Interactive setup for OpenClaw Agent Browser
set -e

PROFILE_DIR="$HOME/.cdp-bridge/chrome-profile"
LOG_DIR="$HOME/.cdp-bridge/logs"
CDP_PORT=9222
BRIDGE_PORT=18793
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🌐 OpenClaw Agent Browser Setup"
echo "================================"
echo ""

# Check for Chrome
CHROME=""
for path in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/usr/bin/google-chrome" \
  "/usr/bin/google-chrome-stable" \
  "/usr/bin/chromium" \
  "/usr/bin/chromium-browser"; do
  if [ -x "$path" ]; then
    CHROME="$path"
    break
  fi
done

if [ -z "$CHROME" ]; then
  echo "❌ Chrome/Chromium not found. Please install Google Chrome first."
  exit 1
fi
echo "✅ Found Chrome: $CHROME"

# Check for Node.js
if ! command -v node &>/dev/null; then
  echo "❌ Node.js not found. Please install Node.js (v18+)."
  exit 1
fi
echo "✅ Found Node.js: $(node --version)"

# Check for npm dependencies
if [ ! -d "$SCRIPT_DIR/node_modules" ]; then
  echo "📦 Installing dependencies..."
  cd "$SCRIPT_DIR"
  npm install 2>/dev/null || echo "⚠️  No package.json — bridge runs without dependencies"
fi

# Create directories
mkdir -p "$PROFILE_DIR"
mkdir -p "$LOG_DIR"
chmod 700 "$PROFILE_DIR"
echo "✅ Created profile directory: $PROFILE_DIR"
echo "✅ Created log directory: $LOG_DIR"

# Check if ports are available
if lsof -i :$CDP_PORT -sTCP:LISTEN >/dev/null 2>&1; then
  echo "⚠️  Port $CDP_PORT already in use (existing Chrome CDP?)"
  echo "   Kill it first or change CDP_PORT in launch.sh"
fi

if lsof -i :$BRIDGE_PORT -sTCP:LISTEN >/dev/null 2>&1; then
  echo "⚠️  Port $BRIDGE_PORT already in use (existing bridge?)"
fi

# Launch Chrome
echo ""
echo "🚀 Launching Chrome with isolated profile..."
"$SCRIPT_DIR/launch.sh"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  Chrome is running with a fresh profile.        ║"
echo "║                                                  ║"
echo "║  👉 Sign into your agent's accounts NOW:        ║"
echo "║     - Google account                             ║"
echo "║     - Twitter/X                                  ║"
echo "║     - Any other services                         ║"
echo "║                                                  ║"
echo "║  These sessions will persist in the profile.     ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Start bridge
echo "Starting CDP bridge on port $BRIDGE_PORT..."
node "$SCRIPT_DIR/server.js" &
BRIDGE_PID=$!
sleep 2

if curl -s "http://127.0.0.1:$BRIDGE_PORT/json/version" >/dev/null 2>&1; then
  echo "✅ CDP Bridge running on port $BRIDGE_PORT (PID: $BRIDGE_PID)"
else
  echo "❌ Bridge failed to start"
  exit 1
fi

echo ""
echo "📋 Add this to your OpenClaw config.json5:"
echo ""
echo "  browser: {"
echo "    cdpUrl: \"http://127.0.0.1:$BRIDGE_PORT\","
echo "    attachOnly: true"
echo "  }"
echo ""
echo "Then use profile=\"openclaw\" in browser tool calls."
echo ""
echo "To auto-start on boot (macOS):"
echo "  cp launchd/com.cdp-bridge.plist ~/Library/LaunchAgents/"
echo "  launchctl load ~/Library/LaunchAgents/com.cdp-bridge.plist"
echo ""
echo "To auto-start on boot (Linux):"
echo "  sudo cp systemd/cdp-bridge.service /etc/systemd/system/"
echo "  sudo systemctl enable --now cdp-bridge"
echo ""
echo "✨ Setup complete! Press Ctrl+C to stop the bridge when done signing in."
wait $BRIDGE_PID
