#!/bin/bash
# IntelliJ stores scratch *inside the application*, which is terrible.  The naming of folders (Mac silliness) makes it even harder.
# The result is we store a *prefix* here, and add the rest on the rsync command line, using wildcards to handle that each update of IntelliJ changes the path.
export SCRATCH_LOCATION_BASE="${HOME}/Library/Application Support/JetBrains/IntelliJIdea20"
git prune
git remote prune origin
git gc --aggressive
dateValue="$(date '+%Y-%m-%d')"

# synchronize the IntelliJ scratches here, so we can back those up...
rsync -aEhHq "${SCRATCH_LOCATION_BASE}"*/scratches/* ScratchFiles/

# Mac adds apple trackers in extended attributes; remove those.
xattr -c Snippets.md
git add Snippets.md
xattr -c Endnotes/*
git add Endnotes/
xattr -c Archives/*
git add Archives/
xattr -c ScratchFiles/*
git add ScratchFiles/
git commit -m "Daily commit for ${dateValue}"
git push

