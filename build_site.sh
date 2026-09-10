#!/bin/bash

# Ensure we are in the repository root
cd "$(dirname "$0")"

echo "Building static site in docs/..."

# Create docs structure
mkdir -p docs/history

# Copy frontend
cp index.html docs/

# Extract all commits modifying the resumes
echo "Extracting historical commits..."
COMMITS=$(git log --format="%h|%aI|%s" -- "Resume 1/main.tex" "Resume 2/main.tex")
HISTORY_JSON="[]"

echo "$COMMITS" | while IFS='|' read -r HASH DATE MSG; do
  if [ -z "$HASH" ]; then continue; fi
  
  echo "Processing commit $HASH..."
  
  # Extract source code
  git show $HASH:"Resume 1/main.tex" > "docs/history/resume1-${HASH}.tex" 2>/dev/null || true
  git show $HASH:"Resume 2/main.tex" > "docs/history/resume2-${HASH}.tex" 2>/dev/null || true
  
  # Extract PDFs (since they are tracked in git)
  git show $HASH:"Resume 1/resume.pdf" > "docs/history/resume1-${HASH}.pdf" 2>/dev/null || true
  git show $HASH:"Resume 2/resume.pdf" > "docs/history/resume2-${HASH}.pdf" 2>/dev/null || true
  
  # Sanitize commit message for JSON
  MSG_CLEAN=$(echo "$MSG" | sed 's/"/\\"/g')
  NEW_ENTRY="{\"hash\": \"$HASH\", \"date\": \"$DATE\", \"message\": \"$MSG_CLEAN\"}"
  
  # Append to JSON array string
  if [ "$HISTORY_JSON" = "[]" ]; then
    HISTORY_JSON="[$NEW_ENTRY]"
  else
    HISTORY_JSON=$(echo "$HISTORY_JSON" | sed "s/]$/,\n$NEW_ENTRY]/")
  fi
  
  echo "$HISTORY_JSON" > docs/history.json
done

echo "Build complete! You can now serve the docs/ directory or commit it to GitHub."
