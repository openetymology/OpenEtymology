#!/usr/bin/env python3
"""Build the public OpenEtymology word-book package.

The package intentionally publishes exam word books as TXT/PDF/EPUB while
keeping the full production SQLite dictionaries out of the public tree.
"""

from __future__ import annotations

import argparse
import html
import json
import os
import re
import shutil
import sqlite3
import textwrap
import uuid
import zipfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
from reportlab.platypus import PageBreak, Paragraph, SimpleDocTemplate, Spacer


ROOT = Path(__file__).resolve().parents[1]
SOURCE_APP_ROOT = ROOT / "wordety"
OUT_DIR = ROOT / "OpenEtymology-WordBooks"

ENCN_DB = SOURCE_APP_ROOT / "wordety_encn_54760_lite.db"
ENEN_DB = SOURCE_APP_ROOT / "wordety_enen_54700_lite.db"
ENCN_TABLE = "wordety_encn_54760_v1"
ENEN_TABLE = "wordety_enen_54700_v1"

WORD_RE = re.compile(r"^[A-Za-z][A-Za-z'-]*")

BOOKS = [
    ("CET4", SOURCE_APP_ROOT / "wordety" / "CET4_edited.txt", "College English Test Band 4"),
    ("CET6", SOURCE_APP_ROOT / "wordety" / "CET6_edited.txt", "College English Test Band 6"),
    ("TEM8", SOURCE_APP_ROOT / "wordety" / "TEM8.txt", "Test for English Majors Band 8"),
    ("TOEFL", SOURCE_APP_ROOT / "wordety" / "TOEFL.txt", "TOEFL Vocabulary"),
    ("GRE8000", SOURCE_APP_ROOT / "wordety" / "GRE_8000_Words.txt", "GRE 8000 Vocabulary"),
]


@dataclass(frozen=True)
class WordEntry:
    word: str
    slug: str
    pron_uk: str
    pron_us: str
    definitions: list[dict]
    examples: list[dict]
    morphemes: list[dict]
    etymology_origin: str
    etymology_analysis: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=Path, default=OUT_DIR)
    parser.add_argument("--sample-size", type=int, default=500)
    parser.add_argument("--clean", action="store_true")
    return parser.parse_args()


def normalize_words(path: Path) -> list[str]:
    words: list[str] = []
    seen: set[str] = set()
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.replace("\ufeff", "").strip()
        if not line:
            continue
        match = WORD_RE.match(line)
        if not match:
            continue
        word = match.group(0).strip("'").lower()
        if word and word not in seen:
            seen.add(word)
            words.append(word)
    return words


def load_json(raw: str | None) -> list:
    if not raw:
        return []
    try:
        value = json.loads(raw)
    except json.JSONDecodeError:
        return []
    return value if isinstance(value, list) else []


def clean_text(value: str | None, max_chars: int | None = None) -> str:
    if not value:
        return ""
    text = value.replace("**", "").replace("*", "")
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r" *\n *", "\n", text)
    text = text.strip()
    if max_chars and len(text) > max_chars:
        return text[: max_chars - 1].rstrip() + "..."
    return text


def xml_text(value: str | None) -> str:
    return html.escape(clean_text(value), quote=True)


def pdf_text(value: str | None) -> str:
    escaped = html.escape(clean_text(value), quote=False)
    return escaped.replace("\n", "<br/>")


def safe_id(value: str) -> str:
    normalized = re.sub(r"[^A-Za-z0-9_-]+", "-", value.strip().lower())
    normalized = normalized.strip("-") or "entry"
    if not normalized[0].isalpha():
        normalized = f"w-{normalized}"
    return normalized


def fetch_word(conn: sqlite3.Connection, table: str, word: str) -> WordEntry | None:
    row = conn.execute(
        f"""
        select word, slug, pron_uk, pron_us, definitions_json, examples_json,
               morphemes_json, etymology_origin, etymology_analysis
        from {table}
        where lower(slug) = ? or lower(word) = ?
        limit 1
        """,
        (word, word),
    ).fetchone()
    if not row:
        return None
    return WordEntry(
        word=row["word"] or word,
        slug=row["slug"] or word,
        pron_uk=row["pron_uk"] or "",
        pron_us=row["pron_us"] or "",
        definitions=load_json(row["definitions_json"]),
        examples=load_json(row["examples_json"]),
        morphemes=load_json(row["morphemes_json"]),
        etymology_origin=row["etymology_origin"] or "",
        etymology_analysis=row["etymology_analysis"] or "",
    )


def fetch_entries(words: Iterable[str]) -> tuple[list[WordEntry], list[str]]:
    entries: list[WordEntry] = []
    missing: list[str] = []
    with sqlite3.connect(ENCN_DB) as encn, sqlite3.connect(ENEN_DB) as enen:
        encn.row_factory = sqlite3.Row
        enen.row_factory = sqlite3.Row
        for word in words:
            entry = fetch_word(encn, ENCN_TABLE, word) or fetch_word(enen, ENEN_TABLE, word)
            if entry:
                entries.append(entry)
            else:
                missing.append(word)
    return entries, missing


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def chunks[T](items: list[T], size: int) -> list[list[T]]:
    return [items[i : i + size] for i in range(0, len(items), size)]


def render_entry_xhtml(entry: WordEntry, index: int) -> str:
    pron_parts = []
    if entry.pron_uk:
        pron_parts.append(f"UK /{xml_text(entry.pron_uk)}/")
    if entry.pron_us and entry.pron_us != entry.pron_uk:
        pron_parts.append(f"US /{xml_text(entry.pron_us)}/")
    pron_html = f"<p class=\"pronunciation\">{' · '.join(pron_parts)}</p>" if pron_parts else ""

    definitions_html = ""
    definition_items = [
        f"<li><strong>{xml_text(item.get('pos', ''))}</strong> {xml_text(item.get('meaning', ''))}</li>"
        for item in entry.definitions[:5]
        if item.get("meaning")
    ]
    if definition_items:
        definitions_html = f"""<section>
  <h3>Definitions</h3>
  <ol class="definitions">
    {chr(10).join(definition_items)}
  </ol>
</section>"""

    morpheme_items = []
    for item in entry.morphemes[:8]:
        piece = xml_text(item.get("piece", ""))
        gloss = xml_text(item.get("gloss", ""))
        lang = xml_text(item.get("lang", ""))
        if piece and gloss:
            extra = f" <span class=\"note\">{lang}</span>" if lang else ""
            morpheme_items.append(f"<li><strong>{piece}</strong> {gloss}{extra}</li>")
    morphemes_html = ""
    if morpheme_items:
        morphemes_html = f"""<section>
  <h3>Morphemes</h3>
  <ul class="morphemes">
    {chr(10).join(morpheme_items)}
  </ul>
</section>"""

    origin = entry.etymology_origin or clean_text(entry.etymology_analysis, 650)
    etymology_html = ""
    if origin:
        etymology_html = f"""<section>
  <h3>Etymology</h3>
  <p>{xml_text(origin)}</p>
</section>"""

    example_items = []
    for item in entry.examples[:3]:
        en = xml_text(item.get("en", ""))
        zh = xml_text(item.get("zh", ""))
        if en:
            zh_html = f"<p class=\"example-zh\">{zh}</p>" if zh else ""
            example_items.append(f"""<li>
  <p class="example-en">{en}</p>
  {zh_html}
</li>""")
    examples_html = ""
    if example_items:
        examples_html = f"""<section>
  <h3>Examples</h3>
  <ol class="examples">
    {chr(10).join(example_items)}
  </ol>
</section>"""

    return f"""<section class="word-entry" id="{safe_id(entry.slug)}">
  <p class="entry-number">{index}</p>
  <h2>{xml_text(entry.word)}</h2>
  {pron_html}
  {definitions_html}
  {morphemes_html}
  {etymology_html}
  {examples_html}
</section>"""


def xhtml_page(title: str, body: str) -> str:
    return f"""<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="zh-CN" lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <title>{xml_text(title)}</title>
  <link rel="stylesheet" type="text/css" href="../styles.css" />
</head>
<body>
{body}
</body>
</html>
"""


def build_epub(book_dir: Path, book_name: str, title: str, entries: list[WordEntry]) -> Path:
    work_dir = book_dir / "_epub_build"
    if work_dir.exists():
        shutil.rmtree(work_dir)
    (work_dir / "META-INF").mkdir(parents=True)
    (work_dir / "OEBPS" / "text").mkdir(parents=True)

    book_uuid = f"urn:uuid:{uuid.uuid4()}"
    modified = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    write_text(work_dir / "mimetype", "application/epub+zip")
    write_text(
        work_dir / "META-INF" / "container.xml",
        """<?xml version="1.0" encoding="utf-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/package.opf" media-type="application/oebps-package+xml" />
  </rootfiles>
</container>
""",
    )
    write_text(
        work_dir / "OEBPS" / "styles.css",
        """body {
  line-height: 1.58;
  margin: 0 5%;
}
h1, h2, h3 {
  line-height: 1.25;
}
h2 {
  margin-bottom: 0.15em;
}
h3 {
  margin: 1em 0 0.25em;
}
.cover-title {
  margin-top: 20%;
  text-align: center;
}
.cover-subtitle {
  text-align: center;
}
.word-entry {
  border-top: 1px solid currentColor;
  margin-top: 1.35em;
  padding-top: 1em;
}
.entry-number,
.pronunciation,
.note {
  font-size: 0.9em;
  opacity: 0.82;
}
.definitions,
.examples,
.morphemes,
.chapter-index ol {
  padding-left: 1.4em;
}
.example-en {
  font-style: italic;
  margin-bottom: 0.2em;
}
.example-zh {
  margin-top: 0;
}
""",
    )

    cover_body = f"""<section epub:type="cover">
  <h1 class="cover-title">{xml_text(title)}</h1>
  <p class="cover-subtitle">OpenEtymology Word Books</p>
  <p class="cover-subtitle">{len(entries)} entries · TXT / PDF / EPUB</p>
</section>"""
    write_text(work_dir / "OEBPS" / "text" / "cover.xhtml", xhtml_page(title, cover_body))

    intro_body = f"""<section epub:type="frontmatter">
  <h1>{xml_text(title)}</h1>
  <p>This EPUB is part of the OpenEtymology open word-book collection. It includes entries from the {xml_text(book_name)} word pack only.</p>
  <p>The complete OpenEtymology dictionary database is not included in this repository.</p>
  <p>Generated: {xml_text(modified)}</p>
</section>"""
    write_text(work_dir / "OEBPS" / "text" / "introduction.xhtml", xhtml_page("Introduction", intro_body))

    chapter_files: list[tuple[str, str]] = []
    for chapter_index, group in enumerate(chunks(entries, 100), start=1):
        filename = f"chapter-{chapter_index:02d}.xhtml"
        first_index = (chapter_index - 1) * 100 + 1
        last_index = first_index + len(group) - 1
        chapter_title = f"{book_name} Entries {first_index}-{last_index}"
        chapter_files.append((filename, chapter_title))
        links = "\n".join(
            f'      <li><a href="#{safe_id(entry.slug)}">{xml_text(entry.word)}</a></li>' for entry in group
        )
        body = f"""<section epub:type="chapter">
  <h1>{xml_text(chapter_title)}</h1>
  <nav class="chapter-index" aria-label="Words in this chapter">
    <ol>
{links}
    </ol>
  </nav>
  {chr(10).join(render_entry_xhtml(entry, first_index + offset) for offset, entry in enumerate(group))}
</section>"""
        write_text(work_dir / "OEBPS" / "text" / filename, xhtml_page(chapter_title, body))

    toc_items = "\n".join(
        f'    <li><a href="text/{filename}">{xml_text(chapter_title)}</a></li>'
        for filename, chapter_title in chapter_files
    )
    nav = f"""<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="en" lang="en">
<head>
  <meta charset="utf-8" />
  <title>Contents</title>
  <link rel="stylesheet" type="text/css" href="styles.css" />
</head>
<body>
<nav epub:type="toc" id="toc">
  <h1>Contents</h1>
  <ol>
    <li><a href="text/cover.xhtml">Cover</a></li>
    <li><a href="text/introduction.xhtml">Introduction</a></li>
{toc_items}
  </ol>
</nav>
</body>
</html>
"""
    write_text(work_dir / "OEBPS" / "nav.xhtml", nav)

    manifest_chapters = "\n".join(
        f'    <item id="chapter-{i:02d}" href="text/{filename}" media-type="application/xhtml+xml" />'
        for i, (filename, _) in enumerate(chapter_files, start=1)
    )
    spine_chapters = "\n".join(f'    <itemref idref="chapter-{i:02d}" />' for i in range(1, len(chapter_files) + 1))
    write_text(
        work_dir / "OEBPS" / "package.opf",
        f"""<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid" xml:lang="zh-CN">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="bookid">{xml_text(book_uuid)}</dc:identifier>
    <dc:title>{xml_text(title)}</dc:title>
    <dc:creator>OpenEtymology</dc:creator>
    <dc:language>zh-CN</dc:language>
    <dc:description>{xml_text(book_name)} vocabulary book with definitions, morphemes, etymology notes, and examples.</dc:description>
    <meta property="dcterms:modified">{xml_text(modified)}</meta>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav" />
    <item id="styles" href="styles.css" media-type="text/css" />
    <item id="cover" href="text/cover.xhtml" media-type="application/xhtml+xml" />
    <item id="introduction" href="text/introduction.xhtml" media-type="application/xhtml+xml" />
{manifest_chapters}
  </manifest>
  <spine>
    <itemref idref="cover" />
    <itemref idref="introduction" />
{spine_chapters}
  </spine>
</package>
""",
    )

    epub_path = book_dir / f"{book_name}.epub"
    if epub_path.exists():
        epub_path.unlink()
    with zipfile.ZipFile(epub_path, "w") as epub:
        epub.write(work_dir / "mimetype", "mimetype", compress_type=zipfile.ZIP_STORED)
        for path in sorted(work_dir.rglob("*")):
            if path.is_dir() or path.name == "mimetype":
                continue
            epub.write(path, path.relative_to(work_dir).as_posix(), compress_type=zipfile.ZIP_DEFLATED)
    shutil.rmtree(work_dir)
    return epub_path


def pdf_footer(canvas, doc) -> None:
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(colors.HexColor("#6b6b6b"))
    canvas.drawRightString(A4[0] - 16 * mm, 10 * mm, f"OpenEtymology Word Books · {doc.page}")
    canvas.restoreState()


def build_pdf(book_dir: Path, book_name: str, title: str, entries: list[WordEntry]) -> Path:
    pdfmetrics.registerFont(UnicodeCIDFont("STSong-Light"))
    path = book_dir / f"{book_name}.pdf"
    doc = SimpleDocTemplate(
        str(path),
        pagesize=A4,
        rightMargin=16 * mm,
        leftMargin=16 * mm,
        topMargin=18 * mm,
        bottomMargin=18 * mm,
        title=title,
        author="OpenEtymology",
    )

    base = getSampleStyleSheet()
    styles = {
        "title": ParagraphStyle(
            "BookTitle",
            parent=base["Title"],
            fontName="Helvetica-Bold",
            fontSize=26,
            leading=31,
            textColor=colors.HexColor("#1d2b27"),
            spaceAfter=12,
        ),
        "meta": ParagraphStyle(
            "BookMeta",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=10,
            leading=14,
            textColor=colors.HexColor("#4d5853"),
            spaceAfter=6,
        ),
        "word": ParagraphStyle(
            "Word",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=15,
            leading=19,
            textColor=colors.HexColor("#142620"),
            spaceBefore=8,
            spaceAfter=2,
        ),
        "small": ParagraphStyle(
            "Small",
            parent=base["BodyText"],
            fontName="STSong-Light",
            fontSize=9.5,
            leading=13,
            textColor=colors.HexColor("#333333"),
            spaceAfter=2,
        ),
        "label": ParagraphStyle(
            "Label",
            parent=base["BodyText"],
            fontName="Helvetica-Bold",
            fontSize=9,
            leading=12,
            textColor=colors.HexColor("#496158"),
            spaceBefore=3,
            spaceAfter=1,
        ),
    }

    story: list = [
        Paragraph(title, styles["title"]),
        Paragraph(f"{len(entries)} entries · generated from OpenEtymology public word-pack data", styles["meta"]),
        Paragraph(
            "This PDF includes the selected exam word-pack entries only. The full 50,000+ entry OpenEtymology dictionary database is not included.",
            styles["meta"],
        ),
        Spacer(1, 8),
    ]

    for index, entry in enumerate(entries, start=1):
        story.append(Paragraph(f"{index}. {html.escape(entry.word)}", styles["word"]))
        pron = " · ".join(part for part in [f"UK /{entry.pron_uk}/" if entry.pron_uk else "", f"US /{entry.pron_us}/" if entry.pron_us and entry.pron_us != entry.pron_uk else ""] if part)
        if pron:
            story.append(Paragraph(html.escape(pron), styles["small"]))

        definition_lines = []
        for item in entry.definitions[:4]:
            meaning = item.get("meaning", "")
            if meaning:
                pos = item.get("pos", "")
                definition_lines.append(f"{pos} {meaning}".strip())
        if definition_lines:
            story.append(Paragraph("Definitions", styles["label"]))
            story.append(Paragraph("<br/>".join(f"- {pdf_text(line)}" for line in definition_lines), styles["small"]))

        morpheme_lines = []
        for item in entry.morphemes[:6]:
            piece = item.get("piece", "")
            gloss = item.get("gloss", "")
            if piece and gloss:
                morpheme_lines.append(f"{piece}: {gloss}")
        if morpheme_lines:
            story.append(Paragraph("Morphemes", styles["label"]))
            story.append(Paragraph("<br/>".join(f"- {pdf_text(line)}" for line in morpheme_lines), styles["small"]))

        origin = entry.etymology_origin or clean_text(entry.etymology_analysis, 520)
        if origin:
            story.append(Paragraph("Etymology", styles["label"]))
            story.append(Paragraph(pdf_text(clean_text(origin, 620)), styles["small"]))

        example_lines = []
        for item in entry.examples[:2]:
            en = item.get("en", "")
            zh = item.get("zh", "")
            if en:
                example_lines.append(f"{en} / {zh}" if zh else en)
        if example_lines:
            story.append(Paragraph("Examples", styles["label"]))
            story.append(Paragraph("<br/>".join(f"- {pdf_text(line)}" for line in example_lines), styles["small"]))

        if index % 120 == 0:
            story.append(PageBreak())
        else:
            story.append(Spacer(1, 4))

    doc.build(story, onFirstPage=pdf_footer, onLaterPages=pdf_footer)
    return path


def build_book(out_dir: Path, name: str, source_path: Path, description: str) -> dict:
    words = normalize_words(source_path)
    entries, missing = fetch_entries(words)
    book_dir = out_dir / name
    book_dir.mkdir(parents=True, exist_ok=True)

    write_text(book_dir / f"{name}.txt", "\n".join(words) + "\n")
    write_text(
        book_dir / "README.md",
        f"""# {name} Word Book

{description} from the OpenEtymology open word-book collection.

- Words: {len(words):,}
- Entries found in dictionary data: {len(entries):,}
- Formats: TXT / PDF / EPUB

## Files

- [{name}.txt](./{name}.txt)
- [{name}.pdf](./{name}.pdf)
- [{name}.epub](./{name}.epub)

The complete OpenEtymology SQLite dictionary database is not included in this repository.
""",
    )

    title = f"OpenEtymology {name} Word Book"
    build_epub(book_dir, name, title, entries)
    build_pdf(book_dir, name, title, entries)

    return {
        "name": name,
        "description": description,
        "word_count": len(words),
        "entry_count": len(entries),
        "missing": missing,
    }


def apache_license() -> str:
    return """Apache License
Version 2.0, January 2004
https://www.apache.org/licenses/

Copyright 2026 OpenEtymology contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""


def build_root_docs(out_dir: Path, book_reports: list[dict]) -> None:
    raw_total = sum(report["word_count"] for report in book_reports)
    unique_words: set[str] = set()
    for _, source_path, _ in BOOKS:
        unique_words.update(normalize_words(source_path))

    rows = "\n".join(
        f"| {report['name']} | {report['word_count']:,} | [{report['name']}.txt](./{report['name']}/{report['name']}.txt) | [{report['name']}.pdf](./{report['name']}/{report['name']}.pdf) | [{report['name']}.epub](./{report['name']}/{report['name']}.epub) |"
        for report in book_reports
    )
    write_text(
        out_dir / "README.md",
        f"""# OpenEtymology Word Books

Open-source English word books for exam vocabulary and etymology-based learning.

## Word Books

| Book | Words | TXT | PDF | EPUB |
|---|---:|---|---|---|
{rows}

Total raw entries: {raw_total:,}  
Unique words across all books: {len(unique_words):,}

## Sample App

A SwiftUI sample app is available in [`SampleApp`](./SampleApp/). It includes only a 500-word demo SQLite database.

## What Is Not Included

- Full 50,000+ entry OpenEtymology dictionary databases
- Full EN-CN / EN-EN production SQLite files
- App Store production configuration
- Real StoreKit product identifiers or purchase logic
- OpenEtymology Plus commercial features

Each word book is published separately to preserve its learning context. This repository intentionally does not provide a merged master list.
""",
    )
    write_text(out_dir / "LICENSE", apache_license())
    write_text(
        out_dir / "DATA_LICENSE.md",
        """# Data License

The public word-book files in this repository (`.txt`, `.pdf`, `.epub`) are released under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0).

License text: https://creativecommons.org/licenses/by-sa/4.0/

This license applies only to the public word-book files included here. The complete OpenEtymology production dictionary databases are not included and are not licensed by this repository.
""",
    )
    write_text(
        out_dir / "CONTRIBUTING.md",
        """# Contributing

Thanks for helping improve OpenEtymology Word Books.

Useful contributions:

- Report incorrect definitions, examples, roots, or etymology notes.
- Suggest better examples for exam vocabulary.
- Request additional ebook formats.
- Improve the sample app without adding the production databases.

Please do not submit copyrighted dictionary content copied from proprietary sources.
""",
    )


def create_sample_db(source_db: Path, source_table: str, target_db: Path, target_table: str, sample_words: list[str]) -> None:
    if target_db.exists():
        target_db.unlink()
    target_db.parent.mkdir(parents=True, exist_ok=True)
    schema = f"""CREATE TABLE {target_table} (
    word TEXT PRIMARY KEY,
    slug TEXT NOT NULL,
    pron_uk TEXT,
    pron_us TEXT,
    definitions_json TEXT,
    examples_json TEXT,
    morphemes_json TEXT,
    etymology_origin TEXT,
    etymology_analysis TEXT,
    quality_flags_json TEXT,
    source_version TEXT,
    created_at INTEGER NOT NULL DEFAULT (unixepoch()),
    updated_at INTEGER NOT NULL DEFAULT (unixepoch())
);
CREATE UNIQUE INDEX {target_table}_slug_unique ON {target_table}(slug);
CREATE INDEX {target_table}_word_idx ON {target_table}(word);
CREATE INDEX {target_table}_quality_idx ON {target_table}(quality_flags_json);
"""
    with sqlite3.connect(source_db) as source, sqlite3.connect(target_db) as target:
        source.row_factory = sqlite3.Row
        target.executescript(schema)
        columns = [
            "word",
            "slug",
            "pron_uk",
            "pron_us",
            "definitions_json",
            "examples_json",
            "morphemes_json",
            "etymology_origin",
            "etymology_analysis",
            "quality_flags_json",
            "source_version",
            "created_at",
            "updated_at",
        ]
        placeholders = ", ".join("?" for _ in columns)
        for word in sample_words:
            row = source.execute(
                f"select {', '.join(columns)} from {source_table} where lower(slug) = ? or lower(word) = ? limit 1",
                (word, word),
            ).fetchone()
            if not row:
                raise RuntimeError(f"Sample word missing from {source_table}: {word}")
            target.execute(
                f"insert into {target_table} ({', '.join(columns)}) values ({placeholders})",
                [row[column] for column in columns],
            )
        target.commit()


def select_common_sample_words(sample_size: int) -> list[str]:
    selected: list[str] = []
    seen: set[str] = set()
    candidates: list[str] = []
    for _, source_path, _ in BOOKS:
        candidates.extend(normalize_words(source_path))

    with sqlite3.connect(ENCN_DB) as encn, sqlite3.connect(ENEN_DB) as enen:
        for word in candidates:
            if word in seen:
                continue
            seen.add(word)
            has_encn = encn.execute(
                f"select 1 from {ENCN_TABLE} where lower(slug) = ? or lower(word) = ? limit 1",
                (word, word),
            ).fetchone()
            has_enen = enen.execute(
                f"select 1 from {ENEN_TABLE} where lower(slug) = ? or lower(word) = ? limit 1",
                (word, word),
            ).fetchone()
            if has_encn and has_enen:
                selected.append(word)
            if len(selected) >= sample_size:
                break

    if len(selected) < sample_size:
        raise RuntimeError(f"Only found {len(selected)} common sample words; needed {sample_size}.")
    return selected


def replace_file(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def patch_sample_app(sample_dir: Path) -> None:
    storekit_path = sample_dir / "Managers" / "StoreKitPurchaseManager.swift"
    replace_file(
        storekit_path,
        """//
//  StoreKitPurchaseManager.swift
//  OpenEtymologySample
//
//  Demo-only purchase manager. The public sample app has no real StoreKit
//  products and unlocks study features for local exploration.
//

import Foundation

@MainActor
final class StoreKitPurchaseManager: ObservableObject {
    static let shared = StoreKitPurchaseManager()

    nonisolated static let monthlyProductID = "org.openetymology.sample.plus.monthly"
    nonisolated static let yearlyProductID = "org.openetymology.sample.plus.yearly"
    nonisolated static let lifetimeProductID = "org.openetymology.sample.plus.lifetime"

    @Published private(set) var products: [String] = [
        monthlyProductID,
        yearlyProductID,
        lifetimeProductID
    ]
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published var purchaseErrorMessage: String?

    private init() { }

    var hasPlusEntitlement: Bool { true }
    var activeEntitlement: PlusEntitlement { .debugOverride }

    nonisolated static func entitlement(for productIDs: Set<String>) -> PlusEntitlement {
        .debugOverride
    }

    func start() async {
        PlusAccessManager.shared.updateStoreKitEntitlement(.debugOverride)
    }

    func refreshPurchasedProducts() async {
        PlusAccessManager.shared.updateStoreKitEntitlement(.debugOverride)
    }

    func loadProducts() async { }

    func product(for plan: PaywallPlan) -> String? {
        plan.productID
    }

    func displayPrice(for plan: PaywallPlan) -> String? {
        plan.price
    }

    @discardableResult
    func purchase(_ plan: PaywallPlan) async -> Bool {
        PlusAccessManager.shared.updateStoreKitEntitlement(.debugOverride)
        return true
    }

    @discardableResult
    func restorePurchases() async -> Bool {
        PlusAccessManager.shared.updateStoreKitEntitlement(.debugOverride)
        return true
    }
}
""",
    )

    plus_access_path = sample_dir / "Managers" / "PlusAccessManager.swift"
    plus_access_text = plus_access_path.read_text(encoding="utf-8")
    plus_access_text = re.sub(
        r'"openetymology\.[^"]*DebugOverrideUnlocked"',
        '"openetymology.samplePlusDebugOverrideUnlocked"',
        plus_access_text,
    )
    plus_access_path.write_text(plus_access_text, encoding="utf-8")

    project_path = sample_dir / "OpenEtymologySample.xcodeproj" / "project.pbxproj"
    text = project_path.read_text(encoding="utf-8")
    text = re.sub(r"DEVELOPMENT_TEAM = [^;]+;", 'DEVELOPMENT_TEAM = "";', text)
    def bundle_identifier_replacement(match: re.Match[str]) -> str:
        current_value = match.group(1)
        if "UITests" in current_value:
            return "PRODUCT_BUNDLE_IDENTIFIER = org.openetymology.sampleUITests;"
        if "Tests" in current_value:
            return "PRODUCT_BUNDLE_IDENTIFIER = org.openetymology.sampleTests;"
        return "PRODUCT_BUNDLE_IDENTIFIER = org.openetymology.sample;"

    text = re.sub(r"PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);", bundle_identifier_replacement, text)
    text = text.replace("INFOPLIST_KEY_CFBundleDisplayName = OpenEtymology;", "INFOPLIST_KEY_CFBundleDisplayName = OpenEtymologySample;")
    text = text.replace("INFOPLIST_KEY_CFBundleName = OpenEtymology;", "INFOPLIST_KEY_CFBundleName = OpenEtymologySample;")
    text = text.replace("PRODUCT_NAME = OpenEtymology;", "PRODUCT_NAME = OpenEtymologySample;")
    project_path.write_text(text, encoding="utf-8")


def copy_sample_app(out_dir: Path, sample_size: int) -> None:
    sample_dir = out_dir / "SampleApp"
    if sample_dir.exists():
        shutil.rmtree(sample_dir)
    sample_dir.mkdir(parents=True)

    shutil.copytree(
        SOURCE_APP_ROOT / "wordety.xcodeproj",
        sample_dir / "OpenEtymologySample.xcodeproj",
        ignore=shutil.ignore_patterns("xcuserdata", "*.xcuserstate"),
    )
    for name in ["Views", "Models", "ViewModels", "Managers", "Database", "wordety", "wordetyTests"]:
        shutil.copytree(SOURCE_APP_ROOT / name, sample_dir / name)
    shutil.copy2(SOURCE_APP_ROOT / "PrivacyInfo.xcprivacy", sample_dir / "PrivacyInfo.xcprivacy")

    sample_words = select_common_sample_words(sample_size)
    create_sample_db(ENCN_DB, ENCN_TABLE, sample_dir / "wordety_encn_54760_lite.db", ENCN_TABLE, sample_words)
    create_sample_db(ENEN_DB, ENEN_TABLE, sample_dir / "wordety_enen_54700_lite.db", ENEN_TABLE, sample_words)
    write_text(sample_dir / "wordety" / "sample_wordpack.txt", "\n".join(sample_words) + "\n")
    patch_sample_app(sample_dir)

    write_text(
        sample_dir / "README.md",
        f"""# OpenEtymology Sample App

This is a SwiftUI sample app for exploring the OpenEtymology reading, search, and practice flow.

Included:

- 500-word EN-CN demo SQLite database
- 500-word EN-EN demo SQLite database
- Public exam word-list text files
- Demo-only StoreKit stub with no real product identifiers

Not included:

- Full 50,000+ entry production dictionaries
- App Store production configuration
- Real purchase flow or commercial entitlement logic

Open `OpenEtymologySample.xcodeproj` in Xcode and run the `wordety` scheme.
""",
    )


def write_scripts(out_dir: Path) -> None:
    scripts_dir = out_dir / "scripts"
    scripts_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(Path(__file__), scripts_dir / "build_wordbooks.py")
    write_text(
        scripts_dir / "README.md",
        """# Scripts

`build_wordbooks.py` regenerates the public word-book package from the private local source project.

It is included for transparency, but it expects the private OpenEtymology source databases to exist locally and will not run from this public repository alone.
""",
    )


def main() -> None:
    args = parse_args()
    out_dir = args.out_dir.resolve()
    if args.clean and out_dir.exists():
        if out_dir.name != "OpenEtymology-WordBooks":
            raise RuntimeError(f"Refusing to clean unexpected output directory: {out_dir}")
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    book_reports = []
    for name, source_path, description in BOOKS:
        print(f"Building {name}...")
        book_reports.append(build_book(out_dir, name, source_path, description))

    build_root_docs(out_dir, book_reports)
    copy_sample_app(out_dir, args.sample_size)
    write_scripts(out_dir)

    write_text(
        out_dir / "build-report.json",
        json.dumps(
            {
                "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                "books": book_reports,
                "sample_app_words": args.sample_size,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
    )
    print(f"Created {out_dir}")


if __name__ == "__main__":
    main()
