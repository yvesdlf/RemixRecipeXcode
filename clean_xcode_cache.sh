#!/bin/bash

# Script to clean Xcode build artifacts and derived data
# This resolves persistent "Type '()' cannot conform to 'View'" errors

echo "🧹 Cleaning Xcode Build Artifacts..."
echo ""

# Close Xcode if running
echo "⚠️  Please close Xcode before running this script!"
read -p "Press Enter when Xcode is closed..."

# Clean project build folder
echo "1️⃣ Cleaning project build folder..."
cd "$(dirname "$0")"
if [ -d "build" ]; then
    rm -rf build/
    echo "   ✅ Removed build/ directory"
else
    echo "   ℹ️  No build/ directory found"
fi

# Clean DerivedData
echo ""
echo "2️⃣ Cleaning DerivedData..."
DERIVED_DATA_PATH=~/Library/Developer/Xcode/DerivedData
if [ -d "$DERIVED_DATA_PATH" ]; then
    # Find this project's derived data
    PROJECT_NAME="RemixRecipeXcode"
    find "$DERIVED_DATA_PATH" -maxdepth 1 -name "${PROJECT_NAME}*" -exec rm -rf {} \;
    echo "   ✅ Removed DerivedData for $PROJECT_NAME"
else
    echo "   ℹ️  No DerivedData directory found"
fi

# Clean Module Cache
echo ""
echo "3️⃣ Cleaning Module Cache..."
MODULE_CACHE_PATH=~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
if [ -d "$MODULE_CACHE_PATH" ]; then
    rm -rf "$MODULE_CACHE_PATH"
    echo "   ✅ Removed Module Cache"
else
    echo "   ℹ️  No Module Cache found"
fi

# Clean Swift Package Manager cache (if applicable)
echo ""
echo "4️⃣ Cleaning SPM Cache..."
SPM_CACHE_PATH=~/Library/Caches/org.swift.swiftpm
if [ -d "$SPM_CACHE_PATH" ]; then
    rm -rf "$SPM_CACHE_PATH"
    echo "   ✅ Removed SPM Cache"
else
    echo "   ℹ️  No SPM Cache found"
fi

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Open RemixRecipeXcode.xcodeproj in Xcode"
echo "   2. Press: ⌘⇧K (Product → Clean Build Folder)"
echo "   3. Press: ⌘B (Product → Build)"
echo ""
echo "If errors persist, restart your Mac and try again."
