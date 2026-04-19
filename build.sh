#!/bin/bash

# Build the project
echo "🔨 Building Swift CPU Monitor..."
swift build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "🚀 To run the application, use:"
    echo "   .build/debug/stats &"
else
    echo "❌ Build failed."
    exit 1
fi
