#!/bin/bash
#
# NovaDoom Version Update Script
# Usage: ./scripts/update-version.sh <new-version>
# Example: ./scripts/update-version.sh 0.0.7
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Validate arguments
if [ -z "$1" ]; then
    echo -e "${RED}Error: No version specified${NC}"
    echo "Usage: $0 <new-version>"
    echo "Example: $0 0.0.7"
    exit 1
fi

NEW_VERSION="$1"

# Validate version format (X.Y.Z)
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid version format. Expected X.Y.Z (e.g., 0.0.7)${NC}"
    exit 1
fi

# Extract version components
MAJOR=$(echo "$NEW_VERSION" | cut -d. -f1)
MINOR=$(echo "$NEW_VERSION" | cut -d. -f2)
PATCH=$(echo "$NEW_VERSION" | cut -d. -f3)

# Config version string (6 digits, zero-padded)
CONFIG_VERSION=$(printf "%02d%02d%02d" "$MAJOR" "$MINOR" "$PATCH")

# RC version (comma-separated with trailing 0)
RC_VERSION="${MAJOR},${MINOR},${PATCH},0"

# Today's date for release notes
TODAY=$(date +%Y-%m-%d)

echo -e "${YELLOW}Updating NovaDoom to version ${NEW_VERSION}${NC}"
echo "  Config version: $CONFIG_VERSION"
echo "  RC version: $RC_VERSION"
echo ""

# Track updated files
UPDATED_FILES=()

# Function to update a file
update_file() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    local description="$4"

    if [ -f "$file" ]; then
        if grep -q "$pattern" "$file" 2>/dev/null; then
            sed -i.bak "s|$pattern|$replacement|g" "$file"
            rm -f "${file}.bak"
            echo -e "  ${GREEN}✓${NC} $description"
            UPDATED_FILES+=("$file")
        else
            echo -e "  ${YELLOW}⚠${NC} Pattern not found in $description"
        fi
    else
        echo -e "  ${RED}✗${NC} File not found: $file"
    fi
}

echo "Updating version references..."

# 1. CMakeLists.txt - project version
update_file \
    "$PROJECT_ROOT/CMakeLists.txt" \
    'project(NovaDoom VERSION [0-9]*\.[0-9]*\.[0-9]*)' \
    "project(NovaDoom VERSION $NEW_VERSION)" \
    "CMakeLists.txt (project version)"

# 2. CMakeLists.txt - RC version
update_file \
    "$PROJECT_ROOT/CMakeLists.txt" \
    'set(PROJECT_RC_VERSION "[0-9]*,[0-9]*,[0-9]*,[0-9]*")' \
    "set(PROJECT_RC_VERSION \"$RC_VERSION\")" \
    "CMakeLists.txt (RC version)"

# 3. common/version.h - CONFIGVERSIONSTR
update_file \
    "$PROJECT_ROOT/common/version.h" \
    '#define CONFIGVERSIONSTR "[0-9]*"' \
    "#define CONFIGVERSIONSTR \"$CONFIG_VERSION\"" \
    "common/version.h (CONFIGVERSIONSTR)"

# 4. common/version.h - DOTVERSIONSTR
update_file \
    "$PROJECT_ROOT/common/version.h" \
    '#define DOTVERSIONSTR "[0-9]*\.[0-9]*\.[0-9]*"' \
    "#define DOTVERSIONSTR \"$NEW_VERSION\"" \
    "common/version.h (DOTVERSIONSTR)"

# 5. common/version.h - GAMEVER
update_file \
    "$PROJECT_ROOT/common/version.h" \
    '#define GAMEVER (MAKEVER([0-9]*, [0-9]*, [0-9]*))' \
    "#define GAMEVER (MAKEVER($MAJOR, $MINOR, $PATCH))" \
    "common/version.h (GAMEVER)"

# 6. Linux metainfo - add new release (special handling)
METAINFO_FILE="$PROJECT_ROOT/packaging/linux/net.novadoom.NovaDoom.metainfo.xml"
if [ -f "$METAINFO_FILE" ]; then
    # Check if this version already exists
    if grep -q "version=\"$NEW_VERSION\"" "$METAINFO_FILE"; then
        echo -e "  ${YELLOW}⚠${NC} Version $NEW_VERSION already in metainfo.xml"
    else
        # Add new release entry after <releases>
        sed -i.bak "s|<releases>|<releases>\n    <release version=\"$NEW_VERSION\" date=\"$TODAY\" />|" "$METAINFO_FILE"
        rm -f "${METAINFO_FILE}.bak"
        echo -e "  ${GREEN}✓${NC} packaging/linux/metainfo.xml (added release)"
        UPDATED_FILES+=("$METAINFO_FILE")
    fi
else
    echo -e "  ${RED}✗${NC} File not found: $METAINFO_FILE"
fi

echo ""
echo -e "${GREEN}Version update complete!${NC}"
echo ""
echo "Updated ${#UPDATED_FILES[@]} file(s):"
for f in "${UPDATED_FILES[@]}"; do
    echo "  - ${f#$PROJECT_ROOT/}"
done

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review changes: git diff"
echo "  2. Commit: git add -A && git commit -m \"Bump version to $NEW_VERSION\""
echo "  3. Tag: git tag -a v$NEW_VERSION -m \"Version $NEW_VERSION\""
echo "  4. Push: git push && git push --tags"
