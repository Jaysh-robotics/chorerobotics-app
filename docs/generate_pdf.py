#!/usr/bin/env python3
"""
ChoreRobotics -- Premium PDF Generator
Converts the database & user flows architecture reference into a
professionally designed dark-mode PDF with brand identity.
"""

import os
import re
from datetime import datetime

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, Flowable, XPreformatted
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

# ---------------------------------------------------------------------------
# Brand colours
# ---------------------------------------------------------------------------
BRAND_BLUE    = HexColor("#3B5EE8")
BRAND_PURPLE  = HexColor("#8B45B5")
BRAND_MAGENTA = HexColor("#D63384")
BRAND_RED     = HexColor("#EF3350")
BRAND_PINK    = HexColor("#F5758C")
BRAND_SILVER  = HexColor("#C8CDD5")
BG_DARK       = HexColor("#0A0C10")
CARD_BG       = HexColor("#151820")
TEXT_PRIMARY   = HexColor("#E8EAED")
TEXT_SECONDARY = HexColor("#8B929E")
TEXT_MUTED     = HexColor("#555D6E")
CODE_BG        = HexColor("#0D1117")
TABLE_ROW_ALT  = HexColor("#1A1E28")
TABLE_HEADER_BG = HexColor("#1E2330")

GRADIENT_COLORS = [BRAND_BLUE, BRAND_PURPLE, BRAND_MAGENTA, BRAND_RED, BRAND_PINK, BRAND_SILVER]

PAGE_W, PAGE_H = A4
LEFT_MARGIN  = 20 * mm
RIGHT_MARGIN = 20 * mm
TOP_MARGIN   = 25 * mm
BOTTOM_MARGIN = 25 * mm
CONTENT_W = PAGE_W - LEFT_MARGIN - RIGHT_MARGIN

# ---------------------------------------------------------------------------
# Font setup
# ---------------------------------------------------------------------------
FONT_BODY      = "Helvetica"
FONT_BOLD      = "Helvetica-Bold"
FONT_EXTRABOLD = "Helvetica-Bold"
FONT_MEDIUM    = "Helvetica"
FONT_MONO      = "Courier"
FONT_MONO_BOLD = "Courier-Bold"


def register_fonts():
    """Try to register Inter and JetBrains Mono; fall back to built-ins."""
    global FONT_BODY, FONT_BOLD, FONT_EXTRABOLD, FONT_MEDIUM, FONT_MONO, FONT_MONO_BOLD

    font_dirs = [
        os.path.expanduser("~/Library/Fonts"),
        "/System/Library/Fonts",
        "/Library/Fonts",
        "/usr/share/fonts/truetype",
    ]
    ttf_map = {
        "Inter":           ["Inter-Regular.ttf", "Inter-Regular.otf"],
        "Inter-Bold":      ["Inter-Bold.ttf", "Inter-Bold.otf"],
        "Inter-ExtraBold": ["Inter-ExtraBold.ttf", "Inter-ExtraBold.otf"],
        "Inter-Medium":    ["Inter-Medium.ttf", "Inter-Medium.otf"],
        "JetBrainsMono":      ["JetBrainsMono-Regular.ttf"],
        "JetBrainsMono-Bold": ["JetBrainsMono-Bold.ttf"],
    }
    found = set()
    for name, candidates in ttf_map.items():
        for d in font_dirs:
            if name in found:
                break
            for fn in candidates:
                p = os.path.join(d, fn)
                if os.path.exists(p):
                    try:
                        pdfmetrics.registerFont(TTFont(name, p))
                        found.add(name)
                    except Exception:
                        pass
                    break

    if "Inter" in found:
        FONT_BODY = "Inter"
        FONT_BOLD = "Inter-Bold" if "Inter-Bold" in found else "Inter"
        FONT_EXTRABOLD = "Inter-ExtraBold" if "Inter-ExtraBold" in found else FONT_BOLD
        FONT_MEDIUM = "Inter-Medium" if "Inter-Medium" in found else "Inter"

    if "JetBrainsMono" in found:
        FONT_MONO = "JetBrainsMono"
        FONT_MONO_BOLD = "JetBrainsMono-Bold" if "JetBrainsMono-Bold" in found else "JetBrainsMono"

    return found


# ---------------------------------------------------------------------------
# Custom flowable: gradient line
# ---------------------------------------------------------------------------
class GradientLine(Flowable):
    """Horizontal brand gradient accent line."""
    def __init__(self, width, height=2.5):
        super().__init__()
        self._width = width
        self._height = height

    def wrap(self, aW, aH):
        return (self._width, self._height)

    def draw(self):
        n = len(GRADIENT_COLORS)
        seg = self._width / n
        for i, col in enumerate(GRADIENT_COLORS):
            self.canv.setFillColor(col)
            self.canv.rect(i * seg, 0, seg + 0.5, self._height, fill=1, stroke=0)


class SectionMarker(Flowable):
    """Zero-height flowable that updates the current section name during rendering."""
    def __init__(self, section_name):
        super().__init__()
        self.section_name = section_name

    def wrap(self, aW, aH):
        return (0, 0)

    def draw(self):
        current_section[0] = self.section_name


# ---------------------------------------------------------------------------
# Cover page flowable
# ---------------------------------------------------------------------------
class CoverPage(Flowable):
    def __init__(self, logo_path=None):
        super().__init__()
        self.logo_path = logo_path

    def wrap(self, aW, aH):
        # Report a size that fits the frame exactly
        return (aW, aH)

    def draw(self):
        c = self.canv
        w = CONTENT_W
        h = PAGE_H - TOP_MARGIN - BOTTOM_MARGIN

        # Logo
        logo_y = h - 80
        if self.logo_path and os.path.exists(self.logo_path):
            try:
                from PIL import Image as PILImage
                img = PILImage.open(self.logo_path)
                iw, ih = img.size
                max_w, max_h = 180, 120
                scale = min(max_w / iw, max_h / ih)
                dw, dh = iw * scale, ih * scale
                c.drawImage(self.logo_path, (w - dw) / 2, logo_y - dh + 20,
                            width=dw, height=dh, mask='auto')
                logo_y = logo_y - dh - 10
            except Exception:
                logo_y = h - 40

        # Gradient accent line
        line_w = w * 0.6
        seg = line_w / len(GRADIENT_COLORS)
        lx = (w - line_w) / 2
        for i, col in enumerate(GRADIENT_COLORS):
            c.setFillColor(col)
            c.rect(lx + i * seg, logo_y - 20, seg + 0.5, 3, fill=1, stroke=0)

        # Title
        ty = logo_y - 70
        c.setFillColor(TEXT_PRIMARY)
        c.setFont(FONT_EXTRABOLD, 28)
        c.drawCentredString(w / 2, ty, "Database Design")
        c.drawCentredString(w / 2, ty - 36, "& User Flows")

        # Subtitle
        c.setFillColor(BRAND_BLUE)
        c.setFont(FONT_MEDIUM, 16)
        c.drawCentredString(w / 2, ty - 80, "Complete Reference Manual")

        # Info box
        iy = ty - 140
        bw, bh = 260, 90
        bx = (w - bw) / 2
        c.setFillColor(CARD_BG)
        c.roundRect(bx, iy, bw, bh, 6, fill=1, stroke=0)
        c.setFillColor(TEXT_SECONDARY)
        c.setFont(FONT_BODY, 10)
        c.drawCentredString(w / 2, iy + bh - 22, "Version 1.0.0")
        c.drawCentredString(w / 2, iy + bh - 38, datetime.now().strftime("March %d, %Y"))
        c.drawCentredString(w / 2, iy + bh - 54, "Architecture Reference Guide")

        # Bottom gradient
        by = 30
        for i, col in enumerate(GRADIENT_COLORS):
            c.setFillColor(col)
            c.rect(lx + i * seg, by, seg + 0.5, 2, fill=1, stroke=0)

        c.setFillColor(BRAND_RED)
        c.setFont(FONT_BOLD, 10)
        c.drawCentredString(w / 2, by - 20, "CONFIDENTIAL -- Internal Use Only")
        c.setFillColor(TEXT_MUTED)
        c.setFont(FONT_BODY, 8)
        c.drawCentredString(w / 2, by - 36, "ChoreRobotics, Inc. -- All Rights Reserved")


# ---------------------------------------------------------------------------
# Header / footer callback
# ---------------------------------------------------------------------------
current_section = [""]


def page_bg(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(BG_DARK)
    canvas.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    pn = canvas.getPageNumber()
    if pn > 1:
        # Header
        canvas.setStrokeColor(HexColor("#1E2330"))
        canvas.setLineWidth(0.5)
        canvas.line(LEFT_MARGIN, PAGE_H - 18 * mm, PAGE_W - RIGHT_MARGIN, PAGE_H - 18 * mm)
        canvas.setFillColor(TEXT_MUTED)
        canvas.setFont(FONT_BOLD, 8)
        canvas.drawString(LEFT_MARGIN, PAGE_H - 16 * mm, "ChoreRobotics")
        if current_section[0]:
            canvas.setFont(FONT_BODY, 8)
            canvas.drawRightString(PAGE_W - RIGHT_MARGIN, PAGE_H - 16 * mm, current_section[0])
        # Footer
        canvas.line(LEFT_MARGIN, BOTTOM_MARGIN - 8 * mm, PAGE_W - RIGHT_MARGIN, BOTTOM_MARGIN - 8 * mm)
        canvas.setFillColor(TEXT_SECONDARY)
        canvas.setFont(FONT_BODY, 8)
        canvas.drawCentredString(PAGE_W / 2, BOTTOM_MARGIN - 14 * mm, str(pn))
        canvas.setFillColor(TEXT_MUTED)
        canvas.setFont(FONT_BODY, 7)
        canvas.drawRightString(PAGE_W - RIGHT_MARGIN, BOTTOM_MARGIN - 14 * mm, "Confidential")
    canvas.restoreState()


# ---------------------------------------------------------------------------
# Style definitions
# ---------------------------------------------------------------------------
def make_styles():
    s = {}
    s["body"] = ParagraphStyle("body", fontName=FONT_BODY, fontSize=9.5, leading=14,
                               textColor=TEXT_PRIMARY, spaceAfter=6)
    s["h1"] = ParagraphStyle("h1", fontName=FONT_EXTRABOLD, fontSize=22, leading=28,
                             textColor=TEXT_PRIMARY, spaceAfter=4)
    s["h2"] = ParagraphStyle("h2", fontName=FONT_BOLD, fontSize=16, leading=22,
                             textColor=TEXT_PRIMARY, spaceBefore=16, spaceAfter=6)
    s["h3"] = ParagraphStyle("h3", fontName=FONT_BOLD, fontSize=12.5, leading=18,
                             textColor=BRAND_BLUE, spaceBefore=12, spaceAfter=4)
    s["h4"] = ParagraphStyle("h4", fontName=FONT_BOLD, fontSize=10.5, leading=15,
                             textColor=BRAND_PURPLE, spaceBefore=10, spaceAfter=3)
    s["code"] = ParagraphStyle("code", fontName=FONT_MONO, fontSize=7, leading=9.5,
                               textColor=HexColor("#C9D1D9"), spaceAfter=0)
    s["code_sm"] = ParagraphStyle("code_sm", fontName=FONT_MONO, fontSize=6.2, leading=8.2,
                                  textColor=HexColor("#C9D1D9"), spaceAfter=0)
    s["toc_title"] = ParagraphStyle("toc_title", fontName=FONT_EXTRABOLD, fontSize=20, leading=26,
                                    textColor=TEXT_PRIMARY, spaceAfter=20)
    s["toc_item"] = ParagraphStyle("toc_item", fontName=FONT_BODY, fontSize=11, leading=20,
                                   textColor=TEXT_PRIMARY, leftIndent=10, spaceAfter=2)
    s["toc_app"] = ParagraphStyle("toc_app", fontName=FONT_BODY, fontSize=10, leading=18,
                                  textColor=TEXT_SECONDARY, leftIndent=10, spaceAfter=2)
    s["bullet"] = ParagraphStyle("bullet", fontName=FONT_BODY, fontSize=9.5, leading=14,
                                 textColor=TEXT_PRIMARY, leftIndent=20, bulletIndent=8,
                                 spaceAfter=3, bulletColor=BRAND_BLUE)
    s["th"] = ParagraphStyle("th", fontName=FONT_BOLD, fontSize=7.5, leading=10,
                             textColor=TEXT_PRIMARY)
    s["td"] = ParagraphStyle("td", fontName=FONT_BODY, fontSize=7.5, leading=10,
                             textColor=TEXT_PRIMARY)
    return s


# ---------------------------------------------------------------------------
# Markdown helpers
# ---------------------------------------------------------------------------
def esc(t):
    return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def fmt(text):
    """Convert markdown inline formatting to ReportLab XML tags."""
    text = esc(text)
    text = re.sub(r'\*\*\*(.+?)\*\*\*', r'<b><i>\1</i></b>', text)
    text = re.sub(r'\*\*(.+?)\*\*', rf'<font name="{FONT_BOLD}">\1</font>', text)
    text = re.sub(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)', r'<i>\1</i>', text)
    text = re.sub(r'`([^`]+)`', rf'<font name="{FONT_MONO}" size="8" color="#79C0FF">\1</font>', text)
    text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)
    return text


def make_code_block(code_lines, styles):
    """Wrap code in a multi-row Table (one row per line) with dark background.

    Using one row per code line makes the table splittable across pages.
    """
    max_len = max((len(l) for l in code_lines), default=0)
    style_key = "code" if max_len < 85 else "code_sm"

    data = []
    for cl in code_lines:
        txt = esc(cl) if cl.strip() else " "
        data.append([XPreformatted(txt, styles[style_key])])

    if not data:
        data = [[XPreformatted(" ", styles[style_key])]]

    tbl = Table(data, colWidths=[CONTENT_W])
    n = len(data)
    cmds = [
        ('BACKGROUND', (0, 0), (-1, -1), CODE_BG),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
        ('TOPPADDING', (0, 0), (-1, -1), 0),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
    ]
    # Extra padding on first and last rows
    if n > 0:
        cmds.append(('TOPPADDING', (0, 0), (-1, 0), 8))
        cmds.append(('BOTTOMPADDING', (0, n - 1), (-1, n - 1), 8))
    tbl.setStyle(TableStyle(cmds))
    return tbl


def make_md_table(lines, styles):
    """Parse markdown table lines into a styled ReportLab Table."""
    header = [c.strip() for c in lines[0].strip("|").split("|")]
    ncol = len(header)
    if ncol == 0:
        return None

    rows = []
    for line in lines[2:]:  # skip separator
        cells = [c.strip() for c in line.strip("|").split("|")]
        while len(cells) < ncol:
            cells.append("")
        rows.append(cells[:ncol])

    data = [[Paragraph(fmt(c), styles["th"]) for c in header]]
    for r in rows:
        data.append([Paragraph(fmt(c), styles["td"]) for c in r])

    cw = [CONTENT_W / ncol] * ncol
    tbl = Table(data, colWidths=cw, repeatRows=1)

    cmds = [
        ('BACKGROUND', (0, 0), (-1, 0), TABLE_HEADER_BG),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ('GRID', (0, 0), (-1, -1), 0.4, HexColor("#2A2F3A")),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ]
    for i in range(1, len(data)):
        bg = CARD_BG if i % 2 == 1 else TABLE_ROW_ALT
        cmds.append(('BACKGROUND', (0, i), (-1, i), bg))
    tbl.setStyle(TableStyle(cmds))
    return tbl


# ---------------------------------------------------------------------------
# Parse the markdown into flowables
# ---------------------------------------------------------------------------
def parse_md(md_text, styles):
    story = []
    lines = md_text.split("\n")
    i = 0
    first_part_seen = False
    # H2 sections whose heading AND body we skip entirely (duplicate of cover/TOC)
    skip_with_body = {"Document Metadata", "Table of Contents"}
    # H2 heading we skip (we render our own styled version) but keep its body content
    skip_heading_only = {"System Overview for New Developers"}
    skipping = False

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if not stripped:
            i += 1
            continue

        if stripped in ("---", "***"):
            if not skipping:
                story.append(Spacer(1, 6))
            i += 1
            continue

        # Check for H2 sections to skip (before PART 1)
        h2_check = re.match(r'^##\s+(.+)', stripped)
        if h2_check and not first_part_seen:
            title = h2_check.group(1).strip()
            if title in skip_with_body:
                skipping = True
                i += 1
                continue
            elif title in skip_heading_only:
                # Skip just this heading line, but stop skipping after
                skipping = False
                i += 1
                continue
            else:
                skipping = False

        # Check for PART header which ends any skip
        pm = re.match(r'^#\s+PART\s+(\d+):\s*(.+)', stripped)
        if pm:
            skipping = False

        if skipping:
            i += 1
            continue

        # -- Code blocks --
        if stripped.startswith("```"):
            code = []
            i += 1
            while i < len(lines) and not lines[i].strip().startswith("```"):
                code.append(lines[i])
                i += 1
            i += 1
            if code:
                story.append(Spacer(1, 4))
                story.append(make_code_block(code, styles))
                story.append(Spacer(1, 6))
            continue

        # -- Tables --
        if stripped.startswith("|"):
            tlines = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                tlines.append(lines[i])
                i += 1
            tbl = make_md_table(tlines, styles)
            if tbl:
                story.append(Spacer(1, 4))
                story.append(tbl)
                story.append(Spacer(1, 6))
            continue

        # -- PART headers --
        if pm:
            pnum, ptitle = pm.group(1), pm.group(2).strip()
            first_part_seen = True
            story.append(PageBreak())
            story.append(SectionMarker(f"Part {pnum}: {ptitle}"))
            story.append(Spacer(1, 30))
            story.append(Paragraph(
                f'<font color="{BRAND_BLUE.hexval()}" size="12">PART {esc(pnum)}</font>',
                styles["body"]))
            story.append(Spacer(1, 6))
            story.append(Paragraph(esc(ptitle), styles["h1"]))
            story.append(Spacer(1, 8))
            story.append(GradientLine(CONTENT_W, 3))
            story.append(Spacer(1, 16))
            i += 1
            continue

        # -- H1 (doc title -- skip, we have cover) --
        if re.match(r'^#\s+[^#]', stripped) and not pm:
            i += 1
            continue

        # -- H2 --
        m = re.match(r'^##\s+(.+)', stripped)
        if m:
            title = m.group(1).strip()
            # Appendix sections get their own page
            if title.startswith("Appendix"):
                story.append(PageBreak())
                story.append(SectionMarker(title))
                story.append(Spacer(1, 20))
                story.append(Paragraph(
                    f'<font color="{BRAND_PURPLE.hexval()}" size="12">APPENDIX</font>',
                    styles["body"]))
                story.append(Spacer(1, 6))
                app_title = re.sub(r'^Appendix\s+[A-Z]:\s*', '', title)
                story.append(Paragraph(esc(app_title if app_title else title), styles["h1"]))
                story.append(Spacer(1, 8))
                story.append(GradientLine(CONTENT_W, 3))
                story.append(Spacer(1, 16))
            else:
                story.append(Spacer(1, 10))
                story.append(Paragraph(fmt(title), styles["h2"]))
                story.append(GradientLine(CONTENT_W * 0.3, 1.5))
                story.append(Spacer(1, 6))
            i += 1
            continue

        # -- H3 --
        m = re.match(r'^###\s+(.+)', stripped)
        if m:
            story.append(Paragraph(fmt(m.group(1).strip()), styles["h3"]))
            story.append(Spacer(1, 4))
            i += 1
            continue

        # -- H4 --
        m = re.match(r'^####\s+(.+)', stripped)
        if m:
            story.append(Paragraph(fmt(m.group(1).strip()), styles["h4"]))
            story.append(Spacer(1, 3))
            i += 1
            continue

        # -- Bullets --
        m = re.match(r'^[-*]\s+(.+)', stripped)
        if m:
            story.append(Paragraph(fmt(m.group(1)), styles["bullet"], bulletText="\u2022"))
            i += 1
            continue

        # -- Numbered list --
        m = re.match(r'^(\d+)\.\s+(.+)', stripped)
        if m:
            ns = ParagraphStyle("nl", parent=styles["bullet"],
                                bulletFontName=FONT_BOLD, bulletColor=BRAND_BLUE)
            story.append(Paragraph(fmt(m.group(2)), ns, bulletText=f"{m.group(1)}."))
            i += 1
            continue

        # -- Regular paragraph --
        story.append(Paragraph(fmt(stripped), styles["body"]))
        i += 1

    return story


# ---------------------------------------------------------------------------
# TOC builder
# ---------------------------------------------------------------------------
def build_toc(styles):
    items = [
        Spacer(1, 20),
        Paragraph("Table of Contents", styles["toc_title"]),
        GradientLine(CONTENT_W, 2.5),
        Spacer(1, 20),
    ]

    parts = [
        ("Part 1", "User Journey Map"),
        ("Part 2", "Screen-by-Data Matrix"),
        ("Part 3", "Database Design -- What Needs Firebase"),
        ("Part 4", "What Does NOT Need a Database"),
        ("Part 5", "Data Lifecycle"),
        ("Part 6", "Connection Modes & Data Routing"),
        ("Part 7", "Security & Permissions"),
        ("Part 8", "Attachment System"),
        ("Part 9", "Offline Strategy Decision Tree"),
    ]
    for pid, title in parts:
        items.append(Paragraph(
            f'<font name="{FONT_BOLD}" color="{BRAND_BLUE.hexval()}">{esc(pid)}</font>'
            f'&nbsp;&nbsp;&nbsp;{esc(title)}',
            styles["toc_item"]))

    items.append(Spacer(1, 16))

    appendices = [
        ("Appendix A", "Complete File-to-Screen Mapping"),
        ("Appendix B", "Firestore Index Requirements"),
        ("Appendix C", "Data Retention Policies"),
        ("Appendix D", "Cost Summary (Firebase Free Tier)"),
    ]
    for aid, title in appendices:
        items.append(Paragraph(
            f'<font name="{FONT_BOLD}" color="{BRAND_PURPLE.hexval()}">{esc(aid)}</font>'
            f'&nbsp;&nbsp;&nbsp;{esc(title)}',
            styles["toc_app"]))

    items.append(PageBreak())
    return items


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def generate_pdf(md_path, logo_path, output_path):
    found = register_fonts()
    print(f"Registered fonts: {found or 'built-in fallbacks'}")

    styles = make_styles()

    with open(md_path, "r", encoding="utf-8") as f:
        md_text = f.read()

    doc = SimpleDocTemplate(
        output_path, pagesize=A4,
        leftMargin=LEFT_MARGIN, rightMargin=RIGHT_MARGIN,
        topMargin=TOP_MARGIN, bottomMargin=BOTTOM_MARGIN,
        title="ChoreRobotics -- Database Design & User Flows",
        author="ChoreRobotics, Inc.",
        subject="Architecture Reference Guide",
        creator="ChoreRobotics Document Generator"
    )

    story = []

    # Cover
    story.append(CoverPage(logo_path))
    story.append(PageBreak())

    # TOC
    story.append(SectionMarker("Table of Contents"))
    story.extend(build_toc(styles))

    # Overview section header
    story.append(SectionMarker("System Overview"))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        f'<font color="{BRAND_BLUE.hexval()}" size="12">OVERVIEW</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("System Overview for New Developers", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 12))

    # Content (skips Document Metadata, Table of Contents, System Overview H2s)
    content = parse_md(md_text, styles)
    story.extend(content)

    print(f"Building PDF with {len(story)} flowables ...")
    doc.build(story, onFirstPage=page_bg, onLaterPages=page_bg)

    sz = os.path.getsize(output_path) / (1024 * 1024)
    print(f"PDF generated: {output_path}")
    print(f"File size: {sz:.2f} MB")


if __name__ == "__main__":
    base = "/Users/jaysh/Projects/chorerobotics/chorerobotics-app"
    generate_pdf(
        os.path.join(base, "architecture", "11-database-and-user-flows.md"),
        os.path.join(base, "assets", "logo", "chore-robots-logo.png"),
        os.path.join(base, "docs", "ChoreRobotics_Database_UserFlows_Manual.pdf"),
    )
