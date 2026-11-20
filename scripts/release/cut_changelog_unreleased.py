#!/usr/bin/env python3
"""Cut CHANGELOG ## [Unreleased] into a dated ## [version] section.

Usage:
  cut_changelog_unreleased.py <CHANGELOG.md> <version> [YYYY-MM-DD]

Empty Unreleased category headings are omitted from the released section.
Unreleased is reset to empty Added/Changed/Fixed/Internal stubs.
"""
from __future__ import annotations

import re
import sys
from datetime import datetime, timezone
from pathlib import Path


def main() -> int:
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    changelog_path = Path(sys.argv[1])
    new_version = sys.argv[2]
    release_date = (
        sys.argv[3]
        if len(sys.argv) == 4
        else datetime.now(timezone.utc).date().isoformat()
    )

    if not changelog_path.is_file():
        print(f"error: missing changelog: {changelog_path}", file=sys.stderr)
        return 1

    text = changelog_path.read_text(encoding="utf-8")
    match = re.search(
        r"(## \[Unreleased\]\n)(.*?)(\n## \[)",
        text,
        flags=re.DOTALL,
    )
    if not match:
        print(
            "error: could not find ## [Unreleased] block before next ## [version]",
            file=sys.stderr,
        )
        return 1

    prefix, body, suffix_start = match.group(1), match.group(2), match.group(3)

    lines = body.splitlines()
    kept: list[str] = []
    current_heading: str | None = None
    buffer: list[str] = []

    def flush() -> None:
        nonlocal current_heading, buffer
        content = [ln for ln in buffer if ln.strip()]
        if current_heading is not None and content:
            kept.append(current_heading)
            kept.extend(buffer)
        current_heading = None
        buffer = []

    for line in lines:
        if line.startswith("### "):
            flush()
            current_heading = line
            buffer = []
        elif current_heading is None:
            if line.strip():
                kept.append(line)
        else:
            buffer.append(line)
    flush()

    released_body = "\n".join(kept).strip()
    if not released_body:
        released_body = (
            "_No user-facing notes captured in Unreleased; bump only._"
        )

    empty_unreleased = (
        "\n"
        "### Added\n"
        "\n"
        "### Changed\n"
        "\n"
        "### Fixed\n"
        "\n"
        "### Internal\n"
        "\n"
    )

    replacement = (
        f"{prefix}"
        f"{empty_unreleased}"
        f"## [{new_version}] - {release_date}\n"
        f"\n"
        f"{released_body}\n"
        f"{suffix_start}"
    )
    new_text = text[: match.start()] + replacement + text[match.end() :]
    changelog_path.write_text(new_text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
