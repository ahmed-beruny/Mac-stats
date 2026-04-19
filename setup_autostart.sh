#!/bin/bash

# Configuration
APP_NAME="stats"
PLIST_LABEL="com.ahmedberuny.stats"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
BINARY_PATH="$(pwd)/.build/debug/$APP_NAME"

echo "🚀 Setting up auto-start for $APP_NAME..."

# 1. Ensure the binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo "🏗️ Binary not found. Building first..."
    ./build.sh
fi

if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Build failed. Cannot proceed."
    exit 1
fi

# 2. Create the Launch Agent plist
echo "📝 Creating Launch Agent plist at $PLIST_PATH..."
cat <<EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BINARY_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/$PLIST_LABEL.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/$PLIST_LABEL.stderr.log</string>
</dict>
</plist>
EOF

# 3. Load the agent
echo "🔄 Loading Launch Agent..."
launchctl unload "$PLIST_PATH" 2>/dev/null
launchctl load "$PLIST_PATH"

echo "✅ Success! The stats app will now start automatically at login."
echo "   Note: If you move this folder, you will need to run this script again."
