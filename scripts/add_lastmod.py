#!/usr/bin/env python3
"""
Add lastmod to post frontmatter where it's missing.
Uses the value of 'date' field as fallback.
"""

import os
import re
import sys
from pathlib import Path


def find_posts(content_dir: Path) -> list[Path]:
    return sorted(content_dir.rglob("index.md"))


def process_file(filepath: Path) -> bool:
    text = filepath.read_text(encoding="utf-8")

    # Check if frontmatter exists
    if not text.startswith("---"):
        print(f"  SKIP (no frontmatter): {filepath}")
        return False

    # Find frontmatter boundaries
    end = text.find("\n---", 3)
    if end == -1:
        print(f"  SKIP (malformed frontmatter): {filepath}")
        return False

    frontmatter = text[3:end]  # content between opening and closing ---

    # Skip if lastmod already present
    if re.search(r"^lastmod\s*:", frontmatter, re.MULTILINE):
        return False

    # Extract date value
    date_match = re.search(r"^date\s*:\s*(.+)$", frontmatter, re.MULTILINE)
    if not date_match:
        print(f"  SKIP (no date field): {filepath}")
        return False

    date_value = date_match.group(1).strip()

    # Insert lastmod right after date line
    new_frontmatter = re.sub(
        r"^(date\s*:.+)$",
        r"\1\nlastmod: " + date_value,
        frontmatter,
        count=1,
        flags=re.MULTILINE,
    )

    new_text = "---" + new_frontmatter + text[end:]
    filepath.write_text(new_text, encoding="utf-8")
    return True


def main():
    content_dir = Path(__file__).parent.parent / "content"
    if not content_dir.exists():
        print(f"Content directory not found: {content_dir}", file=sys.stderr)
        sys.exit(1)

    posts = find_posts(content_dir)
    updated = 0
    skipped = 0

    for post in posts:
        result = process_file(post)
        if result:
            updated += 1
            print(f"  UPDATED: {post.relative_to(content_dir.parent)}")
        else:
            skipped += 1

    print(f"\nDone: {updated} updated, {skipped} skipped (already had lastmod or no date).")


if __name__ == "__main__":
    main()
