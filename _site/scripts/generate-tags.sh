#!/bin/bash

# Directory where tag pages will be created
TAG_DIR="tag"
LAYOUT="tag"

# Create tag directory if it doesn't exist
mkdir -p "$TAG_DIR"
rm -rf "$TAG_DIR"/*

# Extract all tags from posts
TAGS=$(grep -h '^tags:' _posts/*.md | \
  sed 's/^tags:[[:space:]]*//' | \
  tr -d '[],' | \
  tr ' ' '\n' | \
  sort -u | \
  grep -v '^$')

# Generate a tag page for each unique tag
for tag in $TAGS; do
  TAG_FILE="$TAG_DIR/$tag.md"
  if [ ! -f "$TAG_FILE" ]; then
    cat <<EOF > "$TAG_FILE"
---
layout: $LAYOUT
title: "Tag: $tag"
tag: $tag
permalink: /tag/$tag
---
EOF
    echo "Created: $TAG_FILE"
  else
    echo "Exists:  $TAG_FILE"
  fi
done
