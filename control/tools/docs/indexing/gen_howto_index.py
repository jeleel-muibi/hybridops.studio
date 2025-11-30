#!/usr/bin/env python3
"""Generate HOWTO topic views and indexes."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List

from _index_utils import (
    load_text,
    write_text,
    parse_front_matter,
    replace_block,
    utc_now,
    slugify,
    should_skip_file,
)

ROOT = Path.cwd()
HOWTO_DIR = ROOT / "docs" / "howto"
README = HOWTO_DIR / "README.md"
README_TMPL = HOWTO_DIR / "README.tmpl.md"
INDEX = HOWTO_DIR / "000-INDEX.md"
BYTOPIC_DIR = HOWTO_DIR / "by-topic"

TOPICS_START = "<!-- HOWTO:TOPICS START -->"
TOPICS_END = "<!-- HOWTO:TOPICS END -->"


@dataclass
class HowtoItem:
    title: str
    topic: str
    difficulty: str
    access: str
    rel_path: str
    video_url: str


def _first_h1_or_default(body: str, stem: str) -> str:
    for line in body.splitlines():
        stripped = line.strip()
        if stripped.startswith("# "):
            return stripped.lstrip("# ").strip()
    return stem.replace("_", " ").replace("-", " ").title()


def collect_items() -> List[HowtoItem]:
    items: List[HowtoItem] = []

    if not HOWTO_DIR.exists():
        return items

    for path in HOWTO_DIR.rglob("*.md"):
        rel = path.relative_to(HOWTO_DIR)

        if should_skip_file(rel, ignore_folders=["by-topic"]):
            continue

        fm, body = parse_front_matter(load_text(path))

        title = (fm.get("title") or "").strip()
        if not title:
            title = _first_h1_or_default(body, path.stem)

        raw_topic = fm.get("topic") or fm.get("category") or ""
        topic = slugify(str(raw_topic)) if raw_topic else "general"

        difficulty = str(fm.get("difficulty") or "").strip().title() or "General"
        access = str(fm.get("access") or "").strip().lower() or "public"
        video_url = str(fm.get("video_url") or fm.get("video") or "").strip()

        rel_path = "./" + str(rel).replace("\\", "/")

        items.append(
            HowtoItem(
                title=title,
                topic=topic,
                difficulty=difficulty,
                access=access,
                rel_path=rel_path,
                video_url=video_url,
            )
        )

    items.sort(key=lambda it: (it.topic, it.title.lower()))
    return items


def _topic_counts(items: List[HowtoItem]) -> Dict[str, int]:
    counts: Dict[str, int] = {}
    for it in items:
        counts[it.topic] = counts.get(it.topic, 0) + 1
    return counts


def write_000_index(items: List[HowtoItem]) -> None:
    now = utc_now()
    counts = _topic_counts(items)

    lines: List[str] = []
    lines.append("# 000-INDEX — How-To Guides")
    lines.append(f"_Last updated: {now}_")
    lines.append("")
    lines.append(
        "Task-oriented guides grouped by topic, showing difficulty, access level, and video presence."
    )
    lines.append("")
    if counts:
        pills = " · ".join(
            f"[{topic}](./by-topic/{topic}.md) ({count})"
            for topic, count in sorted(counts.items())
        )
        lines.append(f"**Topics:** {pills}")
        lines.append("")

    lines.append("| Guide | Topic | Difficulty | Access | Video |")
    lines.append("|:------|:------|:----------:|:------:|:-----:|")

    for it in items:
        video_flag = "Included" if it.video_url else "—"
        lines.append(
            f"| [{it.title}]({it.rel_path}) | {it.topic} | {it.difficulty} | {it.access} | {video_flag} |"
        )

    lines.append("")
    lines.append("- [Back to HOWTO overview](./README.md)")
    lines.append("- [Back to Docs Home](../README.md)")
    lines.append("")
    write_text(INDEX, "\n".join(lines))


def write_by_topic(items: List[HowtoItem]) -> None:
    BYTOPIC_DIR.mkdir(parents=True, exist_ok=True)
    buckets: Dict[str, List[HowtoItem]] = {}

    for it in items:
        buckets.setdefault(it.topic, []).append(it)

    for topic, bucket in buckets.items():
        bucket.sort(key=lambda it: it.title.lower())
        lines: List[str] = []
        lines.append(f"# {topic.title()} how-to guides")
        lines.append("")
        lines.append(f"Task-oriented guides tagged as `{topic}`.")
        lines.append("")
        lines.append("| Guide | Difficulty | Access | Video |")
        lines.append("|:------|:----------:|:------:|:-----:|")
        for it in bucket:
            rel = "../" + it.rel_path.lstrip("./")
            video_flag = "Included" if it.video_url else "—"
            lines.append(
                f"| [{it.title}]({rel}) | {it.difficulty} | {it.access} | {video_flag} |"
            )
        lines.append("")
        lines.append("[Back to HOWTO index](../000-INDEX.md)")
        lines.append("")
        lines.append("[Back to Docs Home](../README.md)")
        lines.append("")
        write_text(BYTOPIC_DIR / f"{topic}.md", "\n".join(lines))


def _ensure_readme_exists() -> None:
    if README.exists():
        return
    if README_TMPL.exists():
        write_text(README, load_text(README_TMPL))
        return

    skeleton = f"""# HOWTOs

## Topics

{TOPICS_START}
_No how-to guides found._
{TOPICS_END}
"""
    write_text(README, skeleton)


def _render_readme_block(items: List[HowtoItem]) -> str:
    counts = _topic_counts(items)
    now = utc_now()

    lines: List[str] = []
    if counts:
        pills = " · ".join(
            f"[{topic}](./by-topic/{topic}.md) ({count})"
            for topic, count in sorted(counts.items())
        )
        lines.append(f"**Topics:** {pills}")
        lines.append("")
    lines.append("---")
    lines.append("")
    lines.append(f"??? note \"All HOWTOs ({len(items)}) — click to browse\"")
    lines.append("")
    for it in items:
        lines.append(
            f"    - [{it.title}]({it.rel_path}) — {it.difficulty} · {it.access}"
        )
    lines.append("")
    lines.append(f"_Last generated: {now}_")
    lines.append("")
    return "\n".join(lines)


def patch_readme(items: List[HowtoItem]) -> None:
    _ensure_readme_exists()
    current = load_text(README)
    block = _render_readme_block(items)
    updated = replace_block(current, TOPICS_START, TOPICS_END, block)
    write_text(README, updated)


def main() -> None:
    items = collect_items()
    write_000_index(items)
    write_by_topic(items)
    patch_readme(items)
    print(f"Generation complete: {len(items)} how-to guides processed.")


if __name__ == "__main__":
    main()
