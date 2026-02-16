#!/bin/bash
# Launch Chrome with CDP remote debugging enabled
# Kills any existing CDP Chrome instance first

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CDP_PORT=9222
PROFILE="$HOME/.cdp-bridge/chrome-profile"

if [ ! -x "$CHROME" ]; then
  echo "Error: Chrome not found at $CHROME" >&2
  exit 1
fi

mkdir -p "$PROFILE"

# Kill any existing process on the CDP port
if lsof -i :$CDP_PORT -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Killing existing CDP process on port $CDP_PORT..."
  kill $(lsof -i :$CDP_PORT -sTCP:LISTEN -t) 2>/dev/null
  sleep 2
fi

echo "Launching Chrome with CDP on port $CDP_PORT..."
"$CHROME" \
  --remote-debugging-port=$CDP_PORT \
  --user-data-dir="$PROFILE" \
  &>/dev/null &

# Wait for Chrome CDP to become available
for i in $(seq 1 15); do
  sleep 1
  if curl -s "http://127.0.0.1:$CDP_PORT/json/version" >/dev/null 2>&1; then
    echo "Chrome CDP ready on port $CDP_PORT"
    exit 0
  fi
done

echo "Error: Chrome CDP did not start within 15 seconds" >&2
exit 1
