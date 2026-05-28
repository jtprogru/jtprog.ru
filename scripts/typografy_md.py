# -*- coding: utf-8 -*-

"""
typografy_md.py
Run ArtLebedev Typograf over Markdown *prose only*, leaving code, YAML/TOML
frontmatter and other markup untouched.

What is protected (sent to the service verbatim / not at all):
  - YAML (---) or TOML (+++) frontmatter
  - fenced code blocks (``` and ~~~)
  - inline code spans (`...` and ``...``)
  - math: inline ($...$) and display ($$...$$)
  - Hugo/Go shortcodes and templates ({{< >}}, {{% %}}, {{ }})
  - raw HTML tags
  - Markdown link / image URLs and bare URLs
  - line-leading markers: list bullets, ordered markers, headings,
    blockquotes, horizontal rules (so "-" is not turned into an em-dash)
  - blank lines between paragraphs (the service collapses them otherwise)

Usage:
    python3 typografy_md.py post.md > post.typo.md
    python3 typografy_md.py -i post.md            # edit in place
    python3 typografy_md.py -i content/posts/*.md # several files in place
    cat post.md | python3 typografy_md.py         # stdin -> stdout
"""

import argparse
import re
import sys

from typograf import RemoteTypograf

FRONTMATTER_RE = re.compile(r"(?s)\A(---\n.*?\n---|\+\+\+\n.*?\n\+\+\+)(\n|\Z)")
FENCE_RE = re.compile(r"(?ms)^[ \t]*(`{3,}|~{3,})[^\n]*\n.*?^[ \t]*\1[ \t]*$")

INLINE_CODE_RE = re.compile(r"``[^`]*``|`[^`]*`")
DISPLAY_MATH_RE = re.compile(r"(?s)\$\$.+?\$\$")
INLINE_MATH_RE = re.compile(r"\$[^$\n]+?\$")
SHORTCODE_RE = re.compile(r"(?s)\{\{[<%].*?[%>]\}\}|\{\{.*?\}\}")
HTML_TAG_RE = re.compile(r"</?[a-zA-Z][^>\n]*>|<!--.*?-->", re.S)
LINK_URL_RE = re.compile(r"(?<=\])\([^)]*\)")
BARE_URL_RE = re.compile(r"https?://[^\s)\]>]+")
LEAD_MARKER_RE = re.compile(r"(?m)^([ \t]*(?:[-*+]|\d+[.)]|>+|#{1,6}))(?=\s)")
HR_LINE_RE = re.compile(r"(?m)^[ \t]*(?:-{3,}|\*{3,}|_{3,})[ \t]*$")


def _make_placeholder(i):
    return "XPLH%dHLPX" % i


class _Stasher:
    def __init__(self):
        self.store = {}

    def stash(self, text):
        key = _make_placeholder(len(self.store))
        self.store[key] = text
        return key

    def restore(self, text):
        for key, value in self.store.items():
            text = text.replace(key, value)
        return text


def _protect_prose(segment, stasher):
    segment = INLINE_CODE_RE.sub(lambda m: stasher.stash(m.group(0)), segment)
    segment = DISPLAY_MATH_RE.sub(lambda m: stasher.stash(m.group(0)), segment)
    segment = INLINE_MATH_RE.sub(lambda m: stasher.stash(m.group(0)), segment)
    segment = SHORTCODE_RE.sub(lambda m: stasher.stash(m.group(0)), segment)
    segment = HTML_TAG_RE.sub(lambda m: stasher.stash(m.group(0)), segment)
    segment = LINK_URL_RE.sub(lambda m: stasher.stash(m.group(0)), segment)
    segment = BARE_URL_RE.sub(lambda m: stasher.stash(m.group(0)), segment)
    segment = HR_LINE_RE.sub(lambda m: stasher.stash(m.group(0)), segment)
    segment = LEAD_MARKER_RE.sub(lambda m: stasher.stash(m.group(1)), segment)

    # Protect blank lines: the service collapses runs of them otherwise.
    lines = segment.split("\n")
    for i, line in enumerate(lines):
        if line.strip() == "" and line != "":
            lines[i] = stasher.stash(line)
        elif line == "":
            lines[i] = stasher.stash("")
    return "\n".join(lines)


def _typografy_chunk(chunk, rt):
    if chunk.strip() == "":
        return chunk
    # Preserve leading / trailing newlines exactly; the service trims them.
    m = re.match(r"(?s)\A(\n*)(.*?)(\n*)\Z", chunk)
    lead, core, trail = m.groups()
    if core.strip() == "":
        return chunk
    stasher = _Stasher()
    protected = _protect_prose(core, stasher)
    typo = rt.process_text(protected)
    typo = stasher.restore(typo)
    typo = typo.strip("\n")  # the service adds boundary newlines of its own
    return lead + typo + trail


def process_markdown(text, rt):
    m = FRONTMATTER_RE.match(text)
    if m:
        frontmatter = m.group(0)
        body = text[m.end():]
    else:
        frontmatter = ""
        body = text

    out = []
    pos = 0
    for fence in FENCE_RE.finditer(body):
        prose = body[pos:fence.start()]
        out.append(_typografy_chunk(prose, rt))
        out.append(fence.group(0))  # code block verbatim
        pos = fence.end()
    out.append(_typografy_chunk(body[pos:], rt))

    return frontmatter + "".join(out)


def _build_typograf():
    rt = RemoteTypograf()
    rt.no_entities()  # raw unicode «», — for Markdown
    rt.br(0)
    rt.p(0)
    rt.nobr(3)
    return rt


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="*", help="Markdown files (default: stdin)")
    parser.add_argument(
        "-i", "--in-place", action="store_true",
        help="rewrite files in place instead of printing to stdout",
    )
    args = parser.parse_args(argv)

    rt = _build_typograf()

    if not args.files:
        sys.stdout.write(process_markdown(sys.stdin.read(), rt))
        return 0

    for path in args.files:
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        result = process_markdown(text, rt)
        if args.in_place:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(result)
            sys.stderr.write("typografied: %s\n" % path)
        else:
            sys.stdout.write(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
