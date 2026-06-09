#!/usr/bin/env python3
"""
ChoreRobotics — Backend Research Report PDF
Firebase vs MongoDB (+ AWS S3) — pricing, scaling, security, recommendation.
Dark-mode branded PDF matching the existing document suite.
"""

import os
from datetime import datetime

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, Flowable, KeepTogether,
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

# ---------------------------------------------------------------------------
# Brand
# ---------------------------------------------------------------------------
BRAND_BLUE    = HexColor("#3B5EE8")
BRAND_PURPLE  = HexColor("#8B45B5")
BRAND_MAGENTA = HexColor("#D63384")
BRAND_RED     = HexColor("#EF3350")
BRAND_PINK    = HexColor("#F5758C")
BRAND_SILVER  = HexColor("#C8CDD5")
BRAND_GREEN   = HexColor("#22C55E")
BG_DARK       = HexColor("#0A0C10")
CARD_BG       = HexColor("#151820")
BG_SURFACE    = HexColor("#0D0F14")
TEXT_PRIMARY   = HexColor("#E8EAED")
TEXT_SECONDARY = HexColor("#8B929E")
TEXT_MUTED     = HexColor("#555D6E")
WHITE          = HexColor("#FFFFFF")
TABLE_HEADER_BG = HexColor("#1E2330")
TABLE_ROW_ALT   = HexColor("#1A1E28")

GRADIENT_COLORS = [BRAND_BLUE, BRAND_PURPLE, BRAND_MAGENTA, BRAND_RED, BRAND_PINK, BRAND_SILVER]

PAGE_W, PAGE_H = A4
LEFT_MARGIN  = 20 * mm
RIGHT_MARGIN = 20 * mm
TOP_MARGIN   = 25 * mm
BOTTOM_MARGIN = 25 * mm
CONTENT_W = PAGE_W - LEFT_MARGIN - RIGHT_MARGIN

FONT_BODY      = "Helvetica"
FONT_BOLD      = "Helvetica-Bold"
FONT_EXTRABOLD = "Helvetica-Bold"
FONT_MEDIUM    = "Helvetica"
FONT_MONO      = "Courier"


def register_fonts():
    global FONT_BODY, FONT_BOLD, FONT_EXTRABOLD, FONT_MEDIUM, FONT_MONO
    font_dirs = [
        os.path.expanduser("~/Library/Fonts"),
        "/System/Library/Fonts",
        "/Library/Fonts",
    ]
    ttf_map = {
        "Inter":           ["Inter-Regular.ttf", "Inter-Regular.otf"],
        "Inter-Bold":      ["Inter-Bold.ttf", "Inter-Bold.otf"],
        "Inter-ExtraBold": ["Inter-ExtraBold.ttf", "Inter-ExtraBold.otf"],
        "Inter-Medium":    ["Inter-Medium.ttf", "Inter-Medium.otf"],
        "JetBrainsMono":   ["JetBrainsMono-Regular.ttf"],
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
    return found


# ---------------------------------------------------------------------------
# Custom flowables
# ---------------------------------------------------------------------------
class GradientLine(Flowable):
    def __init__(self, width, height=2.5):
        super().__init__()
        self._width = width
        self._height = height

    def wrap(self, aW, aH):
        return (self._width, self._height)

    def draw(self):
        seg = self._width / len(GRADIENT_COLORS)
        for i, col in enumerate(GRADIENT_COLORS):
            self.canv.setFillColor(col)
            self.canv.rect(i * seg, 0, seg + 0.5, self._height, fill=1, stroke=0)


class CoverPage(Flowable):
    def __init__(self, logo_path=None):
        super().__init__()
        self.logo_path = logo_path

    def wrap(self, aW, aH):
        return (aW, aH)

    def draw(self):
        c = self.canv
        w = CONTENT_W
        h = PAGE_H - TOP_MARGIN - BOTTOM_MARGIN

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

        line_w = w * 0.6
        seg = line_w / len(GRADIENT_COLORS)
        lx = (w - line_w) / 2
        for i, col in enumerate(GRADIENT_COLORS):
            c.setFillColor(col)
            c.rect(lx + i * seg, logo_y - 20, seg + 0.5, 3, fill=1, stroke=0)

        ty = logo_y - 70
        c.setFillColor(TEXT_PRIMARY)
        c.setFont(FONT_EXTRABOLD, 28)
        c.drawCentredString(w / 2, ty, "Backend Research")
        c.drawCentredString(w / 2, ty - 36, "& Security Report")

        c.setFillColor(BRAND_BLUE)
        c.setFont(FONT_MEDIUM, 14)
        c.drawCentredString(w / 2, ty - 78, "Firebase vs MongoDB  \u2022  AWS S3  \u2022  Robot \u21c4 Cloud Security")

        iy = ty - 210
        bw, bh = 300, 110
        bx = (w - bw) / 2
        c.setFillColor(CARD_BG)
        c.roundRect(bx, iy, bw, bh, 6, fill=1, stroke=0)
        c.setFillColor(TEXT_SECONDARY)
        c.setFont(FONT_BODY, 10)
        c.drawCentredString(w / 2, iy + bh - 22, "Version 1.0.0")
        c.drawCentredString(w / 2, iy + bh - 38, datetime.now().strftime("%B %d, %Y"))
        c.drawCentredString(w / 2, iy + bh - 54, "For Founders, Engineering & Security Review")
        c.setFillColor(TEXT_MUTED)
        c.setFont(FONT_BODY, 9)
        c.drawCentredString(w / 2, iy + bh - 74, "Backend Comparison  \u2022  Pricing  \u2022  Scaling  \u2022  Security")
        c.drawCentredString(w / 2, iy + bh - 88, "Local Robot Server  \u2022  Cloud Bridge  \u2022  OTA")

        by = 30
        for i, col in enumerate(GRADIENT_COLORS):
            c.setFillColor(col)
            c.rect(lx + i * seg, by, seg + 0.5, 2, fill=1, stroke=0)

        c.setFillColor(BRAND_RED)
        c.setFont(FONT_BOLD, 10)
        c.drawCentredString(w / 2, by - 20, "CONFIDENTIAL \u2014 Internal Use Only")
        c.setFillColor(TEXT_MUTED)
        c.setFont(FONT_BODY, 8)
        c.drawCentredString(w / 2, by - 36, "ChoreRobotics, Inc. \u2014 All Rights Reserved")


current_section = [""]


class SectionMarker(Flowable):
    def __init__(self, name):
        super().__init__()
        self.section_name = name

    def wrap(self, aW, aH):
        return (0, 0)

    def draw(self):
        current_section[0] = self.section_name


def page_bg(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(BG_DARK)
    canvas.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    pn = canvas.getPageNumber()
    if pn > 1:
        canvas.setStrokeColor(HexColor("#1E2330"))
        canvas.setLineWidth(0.5)
        canvas.line(LEFT_MARGIN, PAGE_H - 18 * mm, PAGE_W - RIGHT_MARGIN, PAGE_H - 18 * mm)
        canvas.setFillColor(TEXT_MUTED)
        canvas.setFont(FONT_BOLD, 8)
        canvas.drawString(LEFT_MARGIN, PAGE_H - 16 * mm, "ChoreRobotics")
        if current_section[0]:
            canvas.setFont(FONT_BODY, 8)
            canvas.drawRightString(PAGE_W - RIGHT_MARGIN, PAGE_H - 16 * mm, current_section[0])
        canvas.line(LEFT_MARGIN, BOTTOM_MARGIN - 8 * mm, PAGE_W - RIGHT_MARGIN, BOTTOM_MARGIN - 8 * mm)
        canvas.setFillColor(TEXT_SECONDARY)
        canvas.setFont(FONT_BODY, 8)
        canvas.drawCentredString(PAGE_W / 2, BOTTOM_MARGIN - 14 * mm, str(pn))
        canvas.setFillColor(TEXT_MUTED)
        canvas.setFont(FONT_BODY, 7)
        canvas.drawRightString(PAGE_W - RIGHT_MARGIN, BOTTOM_MARGIN - 14 * mm, "Confidential")
    canvas.restoreState()


# ---------------------------------------------------------------------------
# Styles
# ---------------------------------------------------------------------------
def make_styles():
    s = {}
    s["body"] = ParagraphStyle("body", fontName=FONT_BODY, fontSize=9.5, leading=14,
                               textColor=TEXT_PRIMARY, spaceAfter=6)
    s["body_sec"] = ParagraphStyle("body_sec", fontName=FONT_BODY, fontSize=9.5, leading=14,
                                   textColor=TEXT_SECONDARY, spaceAfter=6)
    s["h1"] = ParagraphStyle("h1", fontName=FONT_EXTRABOLD, fontSize=22, leading=28,
                             textColor=TEXT_PRIMARY, spaceAfter=4)
    s["h2"] = ParagraphStyle("h2", fontName=FONT_BOLD, fontSize=16, leading=22,
                             textColor=TEXT_PRIMARY, spaceBefore=14, spaceAfter=6)
    s["h3"] = ParagraphStyle("h3", fontName=FONT_BOLD, fontSize=12.5, leading=18,
                             textColor=BRAND_BLUE, spaceBefore=12, spaceAfter=4)
    s["h3p"] = ParagraphStyle("h3p", fontName=FONT_BOLD, fontSize=12.5, leading=18,
                              textColor=BRAND_PURPLE, spaceBefore=12, spaceAfter=4)
    s["h3m"] = ParagraphStyle("h3m", fontName=FONT_BOLD, fontSize=12.5, leading=18,
                              textColor=BRAND_MAGENTA, spaceBefore=12, spaceAfter=4)
    s["h3r"] = ParagraphStyle("h3r", fontName=FONT_BOLD, fontSize=12.5, leading=18,
                              textColor=BRAND_RED, spaceBefore=12, spaceAfter=4)
    s["h3g"] = ParagraphStyle("h3g", fontName=FONT_BOLD, fontSize=12.5, leading=18,
                              textColor=BRAND_GREEN, spaceBefore=12, spaceAfter=4)
    s["h4"] = ParagraphStyle("h4", fontName=FONT_BOLD, fontSize=10.5, leading=15,
                             textColor=TEXT_PRIMARY, spaceBefore=8, spaceAfter=3)
    s["bullet"] = ParagraphStyle("bullet", fontName=FONT_BODY, fontSize=9.5, leading=14,
                                 textColor=TEXT_PRIMARY, leftIndent=14, bulletIndent=4,
                                 spaceAfter=3)
    s["bullet_pos"] = ParagraphStyle("bullet_pos", parent=s["bullet"],
                                     textColor=TEXT_PRIMARY, leftIndent=14, bulletIndent=4)
    s["note"] = ParagraphStyle("note", fontName=FONT_BODY, fontSize=8.5, leading=12,
                               textColor=TEXT_SECONDARY, leftIndent=8, spaceAfter=6)
    s["th"] = ParagraphStyle("th", fontName=FONT_BOLD, fontSize=8, leading=11,
                             textColor=TEXT_PRIMARY)
    s["td"] = ParagraphStyle("td", fontName=FONT_BODY, fontSize=8, leading=11,
                             textColor=TEXT_PRIMARY)
    s["td_mono"] = ParagraphStyle("td_mono", fontName=FONT_MONO, fontSize=7.5, leading=10,
                                  textColor=HexColor("#79C0FF"))
    s["td_muted"] = ParagraphStyle("td_muted", fontName=FONT_BODY, fontSize=8, leading=11,
                                   textColor=TEXT_SECONDARY)
    s["td_good"] = ParagraphStyle("td_good", fontName=FONT_BOLD, fontSize=8, leading=11,
                                  textColor=BRAND_GREEN)
    s["td_warn"] = ParagraphStyle("td_warn", fontName=FONT_BOLD, fontSize=8, leading=11,
                                  textColor=HexColor("#F59E0B"))
    s["td_bad"] = ParagraphStyle("td_bad", fontName=FONT_BOLD, fontSize=8, leading=11,
                                 textColor=BRAND_RED)
    s["toc_title"] = ParagraphStyle("toc_title", fontName=FONT_EXTRABOLD, fontSize=20, leading=26,
                                    textColor=TEXT_PRIMARY, spaceAfter=20)
    s["toc_item"] = ParagraphStyle("toc_item", fontName=FONT_BODY, fontSize=11, leading=22,
                                   textColor=TEXT_PRIMARY, leftIndent=10, spaceAfter=2)
    s["callout"] = ParagraphStyle("callout", fontName=FONT_BODY, fontSize=9.5, leading=14,
                                  textColor=TEXT_PRIMARY, leftIndent=12, rightIndent=12,
                                  backColor=CARD_BG, borderPadding=10, spaceAfter=10)
    s["verdict"] = ParagraphStyle("verdict", fontName=FONT_EXTRABOLD, fontSize=14, leading=20,
                                  textColor=BRAND_GREEN, spaceAfter=6)
    return s


# ---------------------------------------------------------------------------
# Table builders
# ---------------------------------------------------------------------------
def make_table(rows, styles, col_widths=None, row_styler=None):
    ncol = len(rows[0])
    if col_widths is None:
        col_widths = [CONTENT_W / ncol] * ncol
    data = []
    for i, row in enumerate(rows):
        cells = []
        for j, cell in enumerate(row):
            if i == 0:
                style = styles["th"]
            elif row_styler is not None:
                style = row_styler(i, j, cell, styles)
            else:
                style = styles["td"]
            if isinstance(cell, Paragraph):
                cells.append(cell)
            else:
                cells.append(Paragraph(str(cell), style))
        data.append(cells)
    tbl = Table(data, colWidths=col_widths, repeatRows=1)
    cmds = [
        ('BACKGROUND', (0, 0), (-1, 0), TABLE_HEADER_BG),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
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


def bullets(items, styles, style_name="bullet"):
    return [Paragraph(f"\u2022&nbsp;&nbsp;{item}", styles[style_name]) for item in items]


# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
def build_pdf():
    base = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(base)
    logo_path = os.path.join(project_root, "assets", "logo", "chore-robots-logo.png")
    output_path = os.path.join(base, "ChoreRobotics_Backend_Research.pdf")

    found = register_fonts()
    print(f"Registered fonts: {found or 'built-in fallbacks'}")

    styles = make_styles()

    doc = SimpleDocTemplate(
        output_path, pagesize=A4,
        leftMargin=LEFT_MARGIN, rightMargin=RIGHT_MARGIN,
        topMargin=TOP_MARGIN, bottomMargin=BOTTOM_MARGIN,
        title="ChoreRobotics \u2014 Backend Research & Security Report",
        author="ChoreRobotics, Inc.",
        subject="Firebase vs MongoDB, AWS S3, Robot-Cloud Security",
        creator="ChoreRobotics Document Generator",
    )

    story = []

    # ── COVER ──
    story.append(CoverPage(logo_path))
    story.append(PageBreak())

    # ── TOC ──
    story.append(SectionMarker("Table of Contents"))
    story.append(Spacer(1, 20))
    story.append(Paragraph("Table of Contents", styles["toc_title"]))
    story.append(GradientLine(CONTENT_W, 2.5))
    story.append(Spacer(1, 20))

    toc = [
        ("Section 1", "Executive Summary & Context", BRAND_BLUE),
        ("Section 2", "Firebase \u2014 Overview, Pricing, Scaling, Security", BRAND_PURPLE),
        ("Section 3", "MongoDB Atlas \u2014 Overview, Pricing, Scaling, Security", BRAND_MAGENTA),
        ("Section 4", "AWS S3 \u2014 Storage Strategy & Cost", BRAND_RED),
        ("Section 5", "Robot \u21c4 Cloud Security Architecture", BRAND_PINK),
        ("Section 6", "Caching & Local Storage Strategy", BRAND_SILVER),
        ("Section 7", "Side-by-Side Comparison", BRAND_SILVER),
        ("Section 8", "Cost Estimates at Scale (1K \u2192 1M users)", BRAND_BLUE),
        ("Section 9", "Recommendation", BRAND_GREEN),
        ("Section 10", "Bottom Line \u2014 Simple Summary", BRAND_GREEN),
    ]
    for label, title, color in toc:
        story.append(Paragraph(
            f'<font name="{FONT_BOLD}" color="{color.hexval()}">{label}</font>'
            f'&nbsp;&nbsp;&nbsp;{title}',
            styles["toc_item"]))

    story.append(PageBreak())

    # ======================================================================
    # SECTION 1: EXECUTIVE SUMMARY
    # ======================================================================
    story.append(SectionMarker("Section 1: Executive Summary"))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        f'<font color="{BRAND_BLUE.hexval()}" size="12">SECTION 1</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("Executive Summary & Context", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 10))

    story.append(Paragraph(
        "ChoreRobotics ships an autonomous outdoor robot (mow / plow / collect) paired with "
        "a Flutter mobile app and an on-robot Python server. The cloud backend is "
        "<b>deliberately lean</b>: it handles authentication, remote text commands "
        "(\u201cstart mowing the front yard\u201d), alerts, task history, and firmware "
        "metadata. Live telemetry and joystick control stay on a <b>direct</b> "
        "robot-to-phone connection (BLE / local Wi-Fi) \u2014 they never hit the cloud. "
        "This report compares <b>Firebase</b> and <b>MongoDB Atlas</b>, covers S3 usage, "
        "details the security architecture, and closes with a recommendation.",
        styles["body"]))

    story.append(Paragraph("What we are optimizing for", styles["h4"]))
    for p in bullets([
        "<b>Event-driven cloud, not streaming cloud</b> \u2014 commands, alerts, and task history \u2014 not 1 Hz telemetry.",
        "<b>Local-first for live data</b> \u2014 telemetry, camera, joystick run over direct BLE/Wi-Fi to the robot. Zero cloud cost.",
        "<b>Mobile-first, offline-capable</b> \u2014 Flutter app works offline in the yard; queues commands when connection is lost.",
        "<b>Small team, limited backend ops</b> \u2014 we want managed infrastructure, not DevOps burden.",
        "<b>Fleet at unknown scale</b> \u2014 start at dozens of robots, scale to tens of thousands without re-platforming.",
        "<b>Safety-critical commands</b> \u2014 e-stop, blade, drive must be auditable and tamper-resistant.",
        "<b>Cost predictability</b> \u2014 pricing that doesn\u2019t surprise us as fleet grows.",
    ], styles):
        story.append(p)

    story.append(Spacer(1, 8))
    story.append(Paragraph("What\u2019s live vs cloud vs cached", styles["h3"]))
    story.append(Paragraph(
        "This is the most important clarification in the whole document. Most things "
        "that <i>look</i> real-time are not actually cloud real-time \u2014 they are direct "
        "connections to the robot when the user is nearby.",
        styles["body"]))

    def cell_c(text, color_key):
        colors = {"live": BRAND_GREEN, "cloud": BRAND_BLUE, "cached": BRAND_PURPLE, "local": BRAND_MAGENTA}
        return Paragraph(
            f'<font color="{colors[color_key].hexval()}"><b>{text}</b></font>',
            styles["td"])

    flow = [
        ["Data / Action", "Channel", "Cadence", "Notes"],
        ["Battery %, GPS, speed, heading",   cell_c("DIRECT (BLE/Wi-Fi)", "live"),  "1\u20135 Hz",  "Never touches cloud"],
        ["Live camera / video stream",       cell_c("DIRECT (Wi-Fi)", "live"),      "30 fps",      "WebRTC / MJPEG, local only"],
        ["Joystick / manual drive",          cell_c("DIRECT (BLE/Wi-Fi)", "live"),  "30 Hz",       "Local only; safer latency"],
        ["E-stop",                           cell_c("DIRECT + CLOUD", "live"),      "on press",    "Sent on all channels for safety"],
        ["Live obstacle overlay / perception", cell_c("DIRECT (Wi-Fi)", "live"),    "10 Hz",       "Local only when nearby"],
        ["Remote text command (\u201cstart mow\u201d)", cell_c("CLOUD (IoT Core)", "cloud"), "on action", "User not on-site"],
        ["Task completed / failed alert",    cell_c("CLOUD (FCM push)", "cloud"),   "on event",    "Single push, not a stream"],
        ["Critical alerts (stuck, low bat, theft)", cell_c("CLOUD (FCM push)", "cloud"), "on event", "Push notification"],
        ["Robot online/offline presence",    cell_c("CLOUD (write)", "cloud"),      "on change",   "One Firestore write on connect/drop"],
        ["Robot heartbeat",                  cell_c("CLOUD (write)", "cloud"),      "30\u201360 s",    "Minimal: just last-seen timestamp"],
        ["Task summary (after completion)",  cell_c("CLOUD (write)", "cloud"),      "once/task",   "Not per-second progress"],
        ["Zones, no-go zones, settings",     cell_c("CACHED", "cached"),            "rare edit",   "Loaded once, version-bumped on change"],
        ["Task history",                     cell_c("CACHED", "cached"),            "paginated",   "Loaded once, cached locally"],
        ["Map tiles",                        cell_c("CACHED (offline)", "cached"),  "load-once",   "30-day disk cache"],
        ["User profile / robot ownership",   cell_c("CACHED", "cached"),            "rare edit",   "Loaded at login"],
    ]
    story.append(make_table(flow, styles,
                            col_widths=[55*mm, 38*mm, 22*mm, CONTENT_W - 115*mm]))

    story.append(Spacer(1, 10))
    story.append(Paragraph(
        "<b>Consequence:</b> the cloud sees only event-level traffic \u2014 a handful "
        "of writes per robot per day plus push notifications. No continuous listeners "
        "on live telemetry. This shrinks Firebase read/write volume by roughly 10\u00d7 "
        "vs. a naive \u201ceverything through the cloud\u201d design, and makes Firebase "
        "an even better fit than the initial analysis suggested.",
        styles["callout"]))

    story.append(Paragraph(
        "<b>TL;DR:</b> Recommend <b>Firebase</b> for app data, auth, push, and remote "
        "commands; <b>AWS S3</b> for media/firmware; <b>AWS IoT Core with mTLS + X.509</b> "
        "as the robot\u2019s cloud channel. Live control stays on direct BLE/Wi-Fi to the "
        "robot. See Section 9 for the full rationale.",
        styles["callout"]))

    # ======================================================================
    # SECTION 2: FIREBASE
    # ======================================================================
    story.append(PageBreak())
    story.append(SectionMarker("Section 2: Firebase"))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        f'<font color="{BRAND_PURPLE.hexval()}" size="12">SECTION 2</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("Firebase", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        "Firebase is Google\u2019s managed BaaS: Auth, Firestore (document DB), Realtime "
        "Database, Cloud Functions, FCM (push), Storage, and App Check.",
        styles["body"]))

    story.append(Paragraph("Strengths for this use case", styles["h3p"]))
    for p in bullets([
        "<b>Perfect fit for event-driven cloud</b> \u2014 writes on task start/end + push on alerts. Exactly Firestore + FCM\u2019s sweet spot.",
        "<b>Flutter SDK is first-class</b> \u2014 <font color='#79C0FF'>firebase_auth</font>, <font color='#79C0FF'>cloud_firestore</font>, <font color='#79C0FF'>firebase_messaging</font> are maintained by FlutterFire.",
        "<b>FCM push is free, unlimited</b> \u2014 alerts, task-done, theft warnings all piggy-back on FCM.",
        "<b>Offline-first baked in</b> \u2014 app queues writes when offline; syncs on reconnect.",
        "<b>Auth out-of-the-box</b> \u2014 email, Google, Apple, phone OTP in a few lines.",
        "<b>Zero infrastructure</b> \u2014 no servers, load balancers, or Kubernetes. Great for a small team.",
        "<b>Free tier covers MVP</b> \u2014 50K reads/day, 20K writes/day, 1 GiB stored on Spark. Our event-driven design uses ~5\u201310% of this per 100 robots.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Weaknesses / watch-outs", styles["h3r"]))
    for p in bullets([
        "<b>Per-document write rate ceiling</b> \u2014 ~1 sustained write/sec per document. Not a problem for us since we don\u2019t stream telemetry, but still a reason not to use a single-doc counter pattern.",
        "<b>Read-heavy pricing model</b> \u2014 stray listeners silently burn reads. Detach on screen close; never leave listeners running in background.",
        "<b>Query limitations</b> \u2014 no joins, limited compound indexes, no full-text search without extensions. Not a blocker for our data shape.",
        "<b>Vendor lock-in</b> \u2014 Firestore data model and security rules do not port cleanly elsewhere.",
        "<b>Cold starts on Cloud Functions</b> \u2014 2nd-gen has min-instance pinning, but it costs.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Pricing (Blaze pay-as-you-go, 2026)", styles["h3"]))
    fb_pricing = [
        ["Service", "Unit", "Price", "Free tier (monthly)"],
        ["Firestore reads", "per 100K", "$0.06", "1.5M reads (50K/day)"],
        ["Firestore writes", "per 100K", "$0.18", "600K writes (20K/day)"],
        ["Firestore deletes", "per 100K", "$0.02", "200K deletes"],
        ["Firestore storage", "per GiB/mo", "$0.18", "1 GiB"],
        ["Firestore egress", "per GiB", "$0.12", "10 GiB"],
        ["Realtime DB storage", "per GiB/mo", "$5.00", "1 GiB"],
        ["Realtime DB egress", "per GiB", "$1.00", "10 GiB"],
        ["Cloud Functions invocations", "per million", "$0.40", "2M"],
        ["Cloud Functions compute", "per GB-sec", "Google Cloud rate", "400K GB-sec"],
        ["FCM push notifications", "\u2014", "Free (unlimited)", "\u2014"],
        ["Auth (email/Google/Apple)", "\u2014", "Free", "\u2014"],
        ["Phone auth (SMS)", "per verification", "~$0.01\u2013$0.06", "10K/mo (US/CA)"],
    ]
    story.append(make_table(fb_pricing, styles,
                            col_widths=[50*mm, 25*mm, 35*mm, CONTENT_W - 110*mm]))

    story.append(Paragraph("Scaling limits", styles["h3"]))
    for p in bullets([
        "<b>Firestore writes:</b> up to 10,000 writes/sec per database; ~1 write/sec per single document.",
        "<b>Firestore concurrent connections:</b> 1,000,000 per database.",
        "<b>Ramp rule:</b> 500/50/5 \u2014 start at 500 ops/sec, grow by 50% every 5 minutes.",
        "<b>Realtime DB:</b> 200K concurrent, 1,000 writes/sec per database instance (shard across DBs for more).",
        "<b>Cloud Functions:</b> auto-scales to thousands of concurrent instances; quota bumps available.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Security & compliance", styles["h3"]))
    for p in bullets([
        "<b>App Check</b> \u2014 attests that requests come from your real app (not scraped/cloned). Blocks abuse.",
        "<b>Security Rules</b> \u2014 declarative, per-path authorization evaluated server-side. Testable in emulator.",
        "<b>Encryption</b> \u2014 TLS in transit; AES-256 at rest (Google-managed keys by default, CMEK available).",
        "<b>Compliance</b> \u2014 SOC 1 / 2 / 3, ISO 27001 / 27017 / 27018, GDPR DPA. HIPAA is possible via BAA, but only on HIPAA-eligible GCP services (Firestore yes, Realtime DB no).",
        "<b>Audit logs</b> \u2014 Cloud Audit Logs in GCP; admin actions are logged.",
        "<b>IAM</b> \u2014 fine-grained roles at the project/service level for engineers.",
    ], styles):
        story.append(p)

    # ======================================================================
    # SECTION 3: MONGODB
    # ======================================================================
    story.append(PageBreak())
    story.append(SectionMarker("Section 3: MongoDB Atlas"))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        f'<font color="{BRAND_MAGENTA.hexval()}" size="12">SECTION 3</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("MongoDB Atlas", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        "MongoDB Atlas is a fully managed document database on AWS / GCP / Azure. "
        "For our use case we would pair it with Atlas App Services (Functions, Triggers, "
        "Device Sync) or a self-hosted Node/Express API.",
        styles["body"]))

    story.append(Paragraph("Strengths for this use case", styles["h3p"]))
    for p in bullets([
        "<b>Flexible schema</b> \u2014 telemetry shapes evolve; document storage handles that cleanly.",
        "<b>Powerful query + aggregation</b> \u2014 full-text search, geospatial, time-series collections, joins via $lookup.",
        "<b>Multi-cloud</b> \u2014 deploy on AWS in the same region as S3 / IoT Core \u2192 free VPC egress.",
        "<b>Change streams</b> \u2014 server-side listeners that drive real-time pipelines (trigger functions, push to clients).",
        "<b>No lock-in at the data layer</b> \u2014 MongoDB is portable; move off Atlas without rewriting data access.",
        "<b>CSFLE / Queryable Encryption</b> \u2014 field-level encryption where the key never leaves the client.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Weaknesses / watch-outs", styles["h3r"]))
    for p in bullets([
        "<b>No first-class Flutter SDK</b> \u2014 you connect through a REST/GraphQL API you build, or via Realm/Device Sync (smaller Flutter community).",
        "<b>You own more infrastructure</b> \u2014 API layer, auth flow, push notifications (FCM/APNs wiring) are DIY.",
        "<b>Fixed minimum cost</b> \u2014 M10 dedicated cluster is always on; no true scale-to-zero for dedicated tiers.",
        "<b>Real-time streaming is change-stream based</b> \u2014 works, but not as turnkey as Firestore listeners for mobile.",
        "<b>Atlas Device Sync roadmap uncertainty</b> \u2014 Realm/Device Sync has had positioning shifts; confirm long-term support before betting on it.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Pricing (2026)", styles["h3m"]))
    mdb_pricing = [
        ["Tier", "RAM / Storage", "Hourly", "Monthly (approx)"],
        ["M0 (Free Shared)", "512 MB / 5 GB", "$0.00", "$0"],
        ["M10 Dedicated", "2 GB / 10 GB", "$0.08/hr", "~$58"],
        ["M20 Dedicated", "4 GB / 20 GB", "$0.20/hr", "~$144"],
        ["M30 Dedicated", "8 GB / 40 GB", "$0.54/hr", "~$388"],
        ["Serverless", "pay per op", "\u2014", "$0.10 / M read units + $1.25 / M write units"],
        ["Backups", "\u2014", "~20% of cluster cost", "\u2014"],
        ["AWS egress", "per GB", "$0.09", "free within same AWS region"],
    ]
    story.append(make_table(mdb_pricing, styles,
                            col_widths=[45*mm, 40*mm, 30*mm, CONTENT_W - 115*mm]))

    story.append(Paragraph("Atlas App Services free tier", styles["note"]))
    for p in bullets([
        "1M requests OR 500 compute hours OR 10,000 sync hours per month (whichever comes first).",
        "10 GB data transfer free.",
        "Beyond: $2.00 per million requests, $0.000016 per GB-second compute.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Scaling & operations", styles["h3m"]))
    for p in bullets([
        "<b>Replica sets by default</b> \u2014 3-node HA out of the box on M10+.",
        "<b>Horizontal sharding</b> \u2014 supported on M30+; scales writes linearly past single-node limits.",
        "<b>No hot-document limit</b> \u2014 any doc can take sustained high-rate writes (vs. Firestore\u2019s ~1/sec).",
        "<b>Global clusters</b> \u2014 zone-aware sharding across regions for latency-sensitive multi-region fleets.",
        "<b>Change streams</b> \u2014 push-based cursor on inserts/updates/deletes; no polling.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Security & compliance", styles["h3m"]))
    for p in bullets([
        "<b>Encryption</b> \u2014 TLS in transit; AES-256 at rest. BYOK via AWS KMS / Azure KV / GCP KMS.",
        "<b>CSFLE + Queryable Encryption</b> \u2014 sensitive fields stay encrypted even from the DB admin.",
        "<b>Network isolation</b> \u2014 VPC Peering, AWS PrivateLink, IP allow-lists.",
        "<b>Compliance</b> \u2014 SOC 2 Type II, ISO 27001:2022, ISO 27017 / 27018, PCI DSS v4, HIPAA-ready (via BAA).",
        "<b>Auth</b> \u2014 Atlas Auth (email, API keys, Google, Apple, custom JWT, anon). Weaker than Firebase Auth\u2019s out-of-the-box UX.",
    ], styles):
        story.append(p)

    # ======================================================================
    # SECTION 4: AWS S3
    # ======================================================================
    story.append(PageBreak())
    story.append(SectionMarker("Section 4: AWS S3"))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        f'<font color="{BRAND_RED.hexval()}" size="12">SECTION 4</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("AWS S3 \u2014 Media & Firmware Storage", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        "S3 stores what should never touch the primary database: camera snapshots, "
        "obstacle images, task recording videos, firmware binaries, map tiles.",
        styles["body"]))

    story.append(Paragraph("Pricing (2026, us-east-1)", styles["h3r"]))
    s3_pricing = [
        ["Item", "Rate"],
        ["Storage (Standard, first 50 TB)", "$0.023 / GB-month"],
        ["Storage (next 450 TB)", "$0.022 / GB-month"],
        ["Storage (Intelligent-Tiering, infrequent)", "$0.0125 / GB-month"],
        ["Storage (Glacier Instant, archive)", "$0.004 / GB-month"],
        ["PUT / COPY / POST / LIST", "$0.005 per 1,000 requests"],
        ["GET / SELECT", "$0.0004 per 1,000 requests"],
        ["Egress to internet (first 100 GB/mo)", "Free"],
        ["Egress to internet (next 9.9 TB)", "$0.09 / GB"],
        ["Egress to same-region AWS services", "Free"],
    ]
    story.append(make_table(s3_pricing, styles,
                            col_widths=[CONTENT_W * 0.6, CONTENT_W * 0.4]))

    story.append(Paragraph("Typical ChoreRobotics cost pattern", styles["h3r"]))
    for p in bullets([
        "Per robot: ~100 images/day @ 2 MB = 200 MB/day = 6 GB/month \u2192 <b>~$0.14 raw storage/mo</b>.",
        "1,000 robots: 6 TB stored \u2192 ~$140/mo + request/egress costs.",
        "Firmware binaries: a few hundred MB each, versioned \u2192 negligible storage; costs come from download egress during OTA rollouts.",
        "<b>Cost control:</b> lifecycle-tier old camera frames to Intelligent-Tiering after 30 days; Glacier after 180.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Security for S3", styles["h3r"]))
    for p in bullets([
        "<b>Block Public Access</b> ON at the account level. No bucket is ever public by default.",
        "<b>SSE-KMS with customer-managed keys</b> \u2014 rotate annually; audit via CloudTrail.",
        "<b>Pre-signed URLs</b> for mobile uploads / downloads \u2014 short-lived (5\u201315 min), scoped to one object.",
        "<b>VPC Gateway Endpoint</b> for S3 \u2014 backend traffic never traverses public internet.",
        "<b>Bucket policy + IAM</b> \u2014 least-privilege; separate buckets for camera, firmware, logs.",
        "<b>Object Lock (WORM)</b> on firmware bucket \u2014 published firmware is immutable and tamper-proof.",
    ], styles):
        story.append(p)

    # ======================================================================
    # SECTION 5: ROBOT <-> CLOUD SECURITY
    # ======================================================================
    story.append(PageBreak())
    story.append(SectionMarker("Section 5: Robot \u21c4 Cloud Security"))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        f'<font color="{BRAND_PINK.hexval()}" size="12">SECTION 5</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("Robot \u21c4 Cloud Security Architecture", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 10))

    story.append(Paragraph(
        "The on-robot Linux server (Python asyncio) is a trust boundary. It has physical "
        "access (anyone who owns the robot can open it), operates on untrusted Wi-Fi, and "
        "executes safety-critical commands (drive, blade, e-stop). Security design must "
        "assume the robot could be stolen, cloned, or put on a hostile network.",
        styles["body"]))

    story.append(Paragraph("Threat model", styles["h3"]))
    threats = [
        ["Threat", "Concern", "Mitigation"],
        ["Stolen / resold robot", "Attacker extracts credentials, joins fleet, sends forged telemetry.",
         "Per-robot X.509 cert in TPM/secure element + remote revocation + cert rotation."],
        ["Hostile Wi-Fi (MITM)", "Rogue AP intercepts robot\u2013cloud traffic.",
         "mTLS on every connection. Pin cloud CA. No plaintext protocols."],
        ["Replay of old commands", "Attacker replays a captured 'start task' message.",
         "Include monotonic nonce + timestamp in every command; server rejects duplicates."],
        ["Firmware rollback attack", "Attacker flashes an old vulnerable firmware.",
         "Monotonic version counter in secure boot chain. Reject older images."],
        ["Unsigned firmware", "Attacker flashes malicious firmware via OTA.",
         "Firmware signed with offline key; robot verifies signature before apply."],
        ["Compromised app account", "Attacker logs in and commands random robot.",
         "Robot ownership check on every command; 2FA for dangerous ops; device attestation via App Check."],
        ["Cloud credential leak", "Robot stores long-lived AWS/Firebase key.",
         "Never. Short-lived tokens from STS / Firebase custom-token exchange over mTLS."],
    ]
    story.append(make_table(threats, styles,
                            col_widths=[40*mm, 65*mm, CONTENT_W - 105*mm]))

    story.append(Paragraph("Recommended control channel", styles["h3"]))
    story.append(Paragraph(
        "<b>AWS IoT Core (MQTT over TLS 1.2 + X.509 mutual auth)</b> for <b>remote "
        "commands and status events</b> between robot and cloud. Firebase is used "
        "from the mobile app, not from the robot directly. Live telemetry and "
        "joystick control do <b>not</b> flow through IoT Core \u2014 they run on a "
        "direct BLE/Wi-Fi channel between app and robot. IoT Core only carries: "
        "remote commands (when user is off-site), status events (task complete, "
        "alerts), heartbeat, and the OTA control plane.",
        styles["body"]))

    for p in bullets([
        "<b>Per-robot X.509 cert</b> \u2014 generated at manufacturing, private key lives in a TPM or OP-TEE secure element. Never exported.",
        "<b>Thing + Policy per robot</b> \u2014 robot can only publish/subscribe to topics under <font color='#79C0FF'>robots/{robot_id}/#</font>.",
        "<b>Short-lived credentials for S3/Firestore</b> \u2014 robot calls an AssumeRole / Firebase custom-token exchange over MQTT; receives 15-min STS creds.",
        "<b>Device Shadow</b> for robot state (online, battery %, last-seen) \u2014 updates asynchronously, not a real-time stream.",
        "<b>E-stop broadcast</b> \u2014 app sends e-stop on BLE, Wi-Fi, AND cloud (IoT Core) simultaneously; robot acts on whichever arrives first.",
        "<b>Audit every command</b> \u2014 IoT Core logs to CloudWatch; every command writes to an append-only audit collection.",
    ], styles):
        story.append(p)

    story.append(Paragraph("AWS IoT Core cost (relevant to this channel)", styles["note"]))
    for p in bullets([
        "MQTT messaging: <b>$1.00 per million messages</b> (metered in 5 KB blocks).",
        "Rules engine: <b>$0.15 per million rules + $0.15 per million actions</b> triggered.",
        "Device registry / shadow state: small per-operation fees; negligible for our volumes.",
        "<b>Our volume:</b> ~20\u201350 messages / robot / day (commands + events + heartbeat). 1K robots = ~1M messages/month = <b>~$1</b>. This is essentially free at our scale.",
    ], styles):
        story.append(p)

    story.append(Paragraph("OTA firmware update security", styles["h3p"]))
    for p in bullets([
        "Sign every firmware binary with an <b>offline signing key</b> (HSM or air-gapped machine).",
        "Robot bootloader verifies signature <b>before</b> writing to inactive partition; rollback on failure.",
        "<b>Monotonic version</b> enforced: cannot install an image with version \u2264 currently-installed (blocks downgrade attacks).",
        "<b>Staged rollout</b>: 1% \u2192 10% \u2192 50% \u2192 100% with 24-hour soak windows and automatic halt on error-rate spike.",
        "Signing key rotation: yearly; new key cross-signed by old, published via signed manifest.",
        "Firmware bucket uses <b>S3 Object Lock (WORM)</b> \u2014 once published, cannot be overwritten.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Data privacy (end-user impact)", styles["h3p"]))
    for p in bullets([
        "Property GPS coordinates and yard imagery are <b>personally identifiable</b> in many jurisdictions.",
        "Store coordinates and images in region-scoped buckets/clusters aligned with user location (EU data in eu-*).",
        "GDPR: support <b>right-to-delete</b> \u2014 delete request purges Firestore/Mongo documents, S3 objects, and backups within 30 days.",
        "Consider CSFLE (MongoDB) or CMEK (Firestore) for property-sensitive fields.",
    ], styles):
        story.append(p)

    # ======================================================================
    # SECTION 6: CACHING & LOCAL STORAGE
    # ======================================================================
    story.append(PageBreak())
    story.append(SectionMarker("Section 6: Caching & Local Storage"))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        f'<font color="{BRAND_SILVER.hexval()}" size="12">SECTION 6</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("Caching & Local Storage Strategy", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 10))

    story.append(Paragraph(
        "Not everything lives in the cloud. The robot operates on unreliable rural "
        "Wi-Fi, the app must work offline mid-yard, and every avoided Firestore read is "
        "money saved. The storage stack has <b>four layers</b>, each with a specific "
        "purpose and lifetime.",
        styles["body"]))

    story.append(Paragraph("The four storage layers", styles["h3"]))
    layers = [
        ["Layer", "Where", "What it holds", "Lifetime"],
        ["L1 \u2014 App persistent cache", "Flutter (Hive / Isar / SQLite)",
         "User profile, owned robots, zones, task history, settings, map tiles",
         "Until logout or uninstall"],
        ["L2 \u2014 Firestore SDK cache", "Flutter (automatic)",
         "Last-seen documents from active listeners, pending writes",
         "LRU, default ~40 MB (configurable, or unlimited)"],
        ["L3 \u2014 Robot local buffer", "On-robot SQLite + ring files",
         "Command queue (inbound), unsent status events, debug telemetry ring, logs",
         "Command queue: until ACK\u2019d. Debug ring: 24\u201372 h circular."],
        ["L4 \u2014 Media cache", "Flutter (cached_network_image + disk)",
         "Camera thumbnails, S3 image previews, firmware binaries (on robot)",
         "TTL-based (7\u201330 days); evicted on size pressure"],
    ]
    story.append(make_table(layers, styles,
                            col_widths=[38*mm, 40*mm, 55*mm, CONTENT_W - 133*mm]))

    story.append(Paragraph("What lives where", styles["h3"]))
    where = [
        ["Data", "Source of truth", "Cached on phone", "Cached on robot"],
        ["User profile / auth", "Firebase Auth + Firestore", "Yes (Hive)", "No"],
        ["Owned robots list", "Firestore", "Yes (Hive)", "No"],
        ["Work zones / no-go zones", "Firestore", "Yes (Hive)", "Yes (SQLite \u2014 needed offline)"],
        ["Task history (summaries)", "Firestore", "Yes (last 30 days)", "Yes (unsent completions)"],
        ["Live telemetry", "Robot (in-memory)", "Session only (direct conn.)", "SQLite ring (24 h, for debugging)"],
        ["Robot presence / last-seen", "IoT Core Device Shadow + Firestore mirror", "Yes (short TTL)", "n/a"],
        ["Camera images", "S3", "Thumbnails (7-day TTL)", "Full-res until upload ACK"],
        ["Firmware binaries", "S3 (Object Lock)", "No", "Staged partition until verified"],
        ["Map tiles", "3rd-party (Mapbox / Google)", "Yes (disk, offline maps)", "No"],
    ]
    story.append(make_table(where, styles,
                            col_widths=[40*mm, 45*mm, 40*mm, CONTENT_W - 125*mm]))

    story.append(PageBreak())
    story.append(SectionMarker("Section 6: Sync & Offline Rules"))
    story.append(Paragraph("Sync and offline rules", styles["h3"]))
    for p in bullets([
        "<b>Live telemetry stays local.</b> Battery, GPS, speed, camera flow direct robot\u2192app over BLE/Wi-Fi when user is nearby. They are <i>never</i> written to Firestore. When the user isn\u2019t nearby, those live values aren\u2019t needed anyway.",
        "<b>Writes are queued, never dropped.</b> Firestore SDK queues offline mutations; robot SQLite queues inbound commands with monotonic IDs.",
        "<b>Last-write-wins on user preferences</b> (zones, sensitivity). Conflicts are rare; a warning toast is enough.",
        "<b>Server-authoritative on safety fields</b> (e-stop, blade, ownership). Client writes are rejected by Security Rules if they don\u2019t match server state.",
        "<b>Status events are append-only.</b> Task-started / task-completed / alert events are idempotent on event-id; safe to retry.",
        "<b>Robot keeps 24 h of local telemetry</b> in SQLite ring \u2014 for on-robot debugging and crash forensics only, not for cloud sync.",
        "<b>Commands expire.</b> Every command carries a <font color='#79C0FF'>expires_at</font> (default 30 s). A queued remote-start from 10 minutes ago shouldn\u2019t suddenly fire when the robot reconnects.",
        "<b>Manual refresh</b> on app pull-to-refresh forces a re-read; otherwise trust the SDK cache.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Cache invalidation (the actually hard part)", styles["h3"]))
    for p in bullets([
        "<b>Zones / no-go zones</b> \u2014 use a <font color='#79C0FF'>version</font> field; Cloud Function bumps it on any edit; robot and app re-fetch on version mismatch.",
        "<b>Ownership changes</b> \u2014 when a robot is transferred to a new account, the <i>old</i> app must drop its cache. Use Firestore security-rule denial as the signal, not a timer.",
        "<b>Stale \u201cdirect\u201d telemetry</b> \u2014 when connected directly, UI greys out any value older than 2 s. If the direct link drops, UI falls back to the last-seen presence value from Firestore with a \u201clast seen at \u2026\u201d label. Never present stale data as live.",
        "<b>Firmware cache</b> \u2014 verify signature on <i>every</i> boot, not just at download. A cached binary could be tampered with after download.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Impact on Firebase cost", styles["h3"]))
    story.append(Paragraph(
        "<b>Two compounding effects</b> keep Firebase cost low. (1) The event-driven "
        "architecture means we don\u2019t stream telemetry through the cloud at all \u2014 "
        "that alone is a ~10\u00d7 reduction vs. a naive \u201ceverything through Firestore\u201d "
        "design. (2) Client caching on top of that cuts the remaining reads another "
        "60\u201380%. Section 8 cost numbers reflect both.",
        styles["callout"]))

    for p in bullets([
        "Turn on <b>offline persistence</b> (default in Flutter FlutterFire).",
        "Prefer <b>get() with Source.cache</b> for data that rarely changes (zones, profile).",
        "<b>Use listeners sparingly</b> \u2014 only for current task status and active alerts. Never on live telemetry; that\u2019s the direct channel\u2019s job.",
        "Detach listeners when the screen closes \u2014 stray listeners silently burn reads.",
        "Ship <b>bundled queries</b> (pre-computed datasets) for static reference data.",
        "Set a <b>daily budget alert</b> on GCP billing at 20%, 50%, 80% of expected spend.",
    ], styles):
        story.append(p)

    # ======================================================================
    # SECTION 7: COMPARISON
    # ======================================================================
    story.append(PageBreak())
    story.append(SectionMarker("Section 7: Side-by-Side"))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        f'<font color="{BRAND_SILVER.hexval()}" size="12">SECTION 7</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("Side-by-Side Comparison", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 10))

    def cell(text, kind):
        return Paragraph(text, styles[{"good": "td_good", "warn": "td_warn",
                                       "bad": "td_bad"}.get(kind, "td")])
    compare = [
        ["Dimension", "Firebase", "MongoDB Atlas"],
        ["Flutter SDK",             cell("First-class (FlutterFire)", "good"), cell("DIY (REST / Realm)", "warn")],
        ["Event-driven writes / listeners", cell("Native, turnkey", "good"),   cell("Change streams via API", "warn")],
        ["Offline queue (app)",     cell("Built-in", "good"),                  cell("Realm Device Sync (roadmap risk)", "warn")],
        ["Auth (email/Google/Apple)", cell("Out-of-box", "good"),             cell("DIY / App Services", "warn")],
        ["Push notifications (FCM/APNs)", cell("Built-in (FCM)", "good"),    cell("Integrate separately", "warn")],
        ["Query flexibility",       cell("Limited, index-bound", "warn"),      cell("Rich, aggregation + $lookup", "good")],
        ["Hot-document writes",     cell("~1/sec limit (n/a for us)", "good"), cell("No practical limit", "good")],
        ["Geospatial queries",      cell("Basic (via geohash libs)", "warn"),  cell("Native geo indexes", "good")],
        ["Full-text search",        cell("Extension / 3rd-party", "warn"),     cell("Atlas Search (built-in)", "good")],
        ["Cost at low scale (<10K MAU)", cell("~$0\u2013$20/mo", "good"),     cell("$58\u2013$200/mo min", "warn")],
        ["Cost at high scale (1M MAU)", cell("Manageable (event-driven)", "good"), cell("Predictable cluster scaling", "good")],
        ["Vendor lock-in",          cell("High (rules + schema)", "bad"),      cell("Low (portable)", "good")],
        ["Time to MVP",             cell("Days", "good"),                      cell("Weeks", "warn")],
        ["Ops burden",              cell("Near zero", "good"),                 cell("Moderate (API layer)", "warn")],
        ["HIPAA / SOC2 / ISO",      cell("Yes (scoped)", "good"),              cell("Yes", "good")],
        ["CSFLE / field encryption", cell("CMEK only", "warn"),               cell("CSFLE + Queryable Enc.", "good")],
        ["Works well with AWS S3",  cell("Yes (cross-cloud egress)", "warn"),  cell("Yes (same region = free)", "good")],
        ["Works well with AWS IoT Core", cell("Via bridge function", "warn"), cell("Same AWS account", "good")],
    ]
    story.append(make_table(compare, styles,
                            col_widths=[55*mm, CONTENT_W*0.35, CONTENT_W - 55*mm - CONTENT_W*0.35]))

    # ======================================================================
    # SECTION 8: COST ESTIMATES
    # ======================================================================
    story.append(PageBreak())
    story.append(SectionMarker("Section 8: Cost at Scale"))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        f'<font color="{BRAND_BLUE.hexval()}" size="12">SECTION 8</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("Cost Estimates at Scale", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 10))

    story.append(Paragraph("Assumptions per active user (per robot)", styles["h4"]))
    for p in bullets([
        "App opens: 10\u201320 sessions/day. Most reads served from cache; ~30\u2013100 actual Firestore reads/day.",
        "<b>No streaming telemetry to cloud.</b> Live values are direct-connection only.",
        "Status events: ~20\u201350 Firestore writes/day per robot (task start/end, alerts, heartbeat, presence).",
        "IoT Core messages: ~30\u2013100/day per robot (commands + status events + shadow updates).",
        "Push notifications: ~3\u20135/day per user (free).",
        "Camera images: 100/day @ 2 MB = 6 GB/month to S3 per robot.",
        "Firmware update: ~300 MB, once per month.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Monthly cost \u2014 Event-driven design (recommended)", styles["h3g"]))
    story.append(Paragraph(
        "Live telemetry stays direct (robot\u2194app). Cloud handles only commands, "
        "alerts, task summaries, and presence. Client caching on; listeners detached "
        "on screen close. ~10\u00d7 cheaper than streaming telemetry through cloud.",
        styles["note"]))
    cost_rows_event = [
        ["Scale", "Firebase (Firestore + Fn + FCM)", "AWS S3 + IoT Core", "MongoDB path (compare)", "Total (Firebase path)"],
        ["1K users",   "~$5\u2013$20",    "~$15\u2013$30",    "~$75\u2013$150 (M10)",         "~$20\u2013$50"],
        ["10K users",  "~$30\u2013$100",  "~$100\u2013$200",  "~$250\u2013$450 (M20)",        "~$130\u2013$300"],
        ["100K users", "~$300\u2013$1K",  "~$800\u2013$1.5K", "~$1.8K\u2013$3.5K (M30/M40)",  "~$1.1K\u2013$2.5K"],
        ["1M users",   "~$3K\u2013$10K",  "~$6K\u2013$12K",   "~$14K\u2013$28K (sharded)",    "~$9K\u2013$22K"],
    ]
    story.append(make_table(cost_rows_event, styles,
                            col_widths=[18*mm, 45*mm, 30*mm, 42*mm, CONTENT_W - 135*mm]))

    story.append(Spacer(1, 10))
    story.append(Paragraph("Contrast: naive \u201cstream everything through cloud\u201d design", styles["h3r"]))
    story.append(Paragraph(
        "If we pushed 1 Hz telemetry through Firestore with no caching \u2014 what a "
        "typical SaaS team might build by default \u2014 costs would look like this. "
        "Shown for contrast to quantify what the event-driven decision saves us.",
        styles["note"]))
    cost_rows_naive = [
        ["Scale", "Firebase (naive streaming)", "AWS S3 + IoT Core", "Total (naive)"],
        ["1K users",   "~$60\u2013$180",   "~$15\u2013$30",   "~$75\u2013$210"],
        ["10K users",  "~$600\u2013$1.5K", "~$100\u2013$200", "~$700\u2013$1.7K"],
        ["100K users", "~$6K\u2013$15K",   "~$800\u2013$1.5K", "~$7K\u2013$16.5K"],
        ["1M users",   "~$60K\u2013$180K", "~$6K\u2013$12K",  "~$66K\u2013$192K"],
    ]
    story.append(make_table(cost_rows_naive, styles,
                            col_widths=[25*mm, 55*mm, 40*mm, CONTENT_W - 120*mm]))

    story.append(Spacer(1, 10))
    story.append(Paragraph(
        "<b>The architecture choice dwarfs every other cost lever.</b> Going event-driven "
        "vs. streaming saves <b>~$55K\u2013$170K/month at 1M users</b>. Client caching "
        "on top saves another ~60\u201370% of what remains. Our recommendation captures "
        "both.",
        styles["callout"]))

    story.append(Paragraph("Architecture impact \u2014 Firebase cost side-by-side", styles["h4"]))
    impact = [
        ["Scale",       "Event-driven (ours)", "Streaming (naive)", "Savings"],
        ["1K users",    "~$5\u2013$20",    "~$60\u2013$180",   "~85\u201390%"],
        ["10K users",   "~$30\u2013$100",  "~$600\u2013$1.5K", "~90\u201395%"],
        ["100K users",  "~$300\u2013$1K",  "~$6K\u2013$15K",   "~90\u201395%"],
        ["1M users",    "~$3K\u2013$10K",  "~$60K\u2013$180K", "~90\u201395%"],
    ]
    story.append(make_table(impact, styles,
                            col_widths=[28*mm, 50*mm, 50*mm, CONTENT_W - 128*mm]))

    story.append(Paragraph("How to keep cost low on Firebase", styles["h4"]))
    for p in bullets([
        "<b>Do not stream telemetry through Firestore.</b> Keep live values on the direct BLE/Wi-Fi channel.",
        "Use <b>listeners only for current task status and alerts</b> \u2014 detach on screen close.",
        "Turn on <b>offline persistence</b> (default in FlutterFire) so cache survives app restarts.",
        "Use <b>Firestore TTL</b> on short-lived docs (alerts, presence) to cap storage.",
        "Use <b>App Check</b> to block scrapers that would otherwise burn reads.",
        "Set <b>billing alerts</b> at 20%, 50%, 80% of expected monthly spend on GCP.",
    ], styles):
        story.append(p)

    # ======================================================================
    # SECTION 9: RECOMMENDATION
    # ======================================================================
    story.append(PageBreak())
    story.append(SectionMarker("Section 9: Recommendation"))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        f'<font color="{BRAND_GREEN.hexval()}" size="12">SECTION 9</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("Recommendation", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 16))

    story.append(Paragraph("Use Firebase as the primary backend.", styles["verdict"]))
    story.append(Paragraph(
        "For a Flutter-first product with a small team, an event-driven cloud "
        "(not a streaming cloud), and a go-to-market timeline measured in weeks, "
        "Firebase wins on three fronts that matter more than anything else right "
        "now: <b>(1) time to ship</b>, <b>(2) ops burden</b>, and <b>(3) mobile "
        "SDK quality</b>. Since live telemetry is handled by the direct "
        "robot\u2194app channel, the cloud only needs to be good at auth, push, "
        "event writes, and remote commands \u2014 which is exactly Firebase\u2019s "
        "sweet spot. MongoDB would make us build the API layer, auth flow, and "
        "push wiring ourselves \u2014 weeks of work for no advantage.",
        styles["body"]))

    story.append(Paragraph("Recommended architecture", styles["h3g"]))
    for p in bullets([
        "<b>Firebase Auth</b> \u2014 user identity (email / Google / Apple).",
        "<b>Firestore</b> \u2014 user profiles, robot ownership, zones, task summaries, alerts, presence. <i>Not</i> live telemetry.",
        "<b>FCM</b> \u2014 push notifications for alerts and task completion.",
        "<b>Cloud Functions (2nd gen)</b> \u2014 IoT Core \u2194 Firestore bridge, webhook endpoints, security rules enforcement for commands.",
        "<b>Firebase App Check</b> \u2014 block non-app traffic.",
        "<b>AWS S3</b> \u2014 camera images, video clips, firmware binaries (separate buckets, SSE-KMS, Object Lock on firmware).",
        "<b>AWS IoT Core (MQTT + mTLS)</b> \u2014 robot\u2019s cloud channel: remote commands, status events, Device Shadow for presence. <i>Not</i> telemetry streaming.",
        "<b>Direct BLE / local Wi-Fi</b> between app and robot \u2014 live telemetry, joystick, camera, local e-stop. Never touches cloud.",
        "<b>Per-robot X.509 certs</b> in TPM/secure element, provisioned at manufacturing.",
    ], styles):
        story.append(p)

    story.append(Paragraph("When to revisit this decision", styles["h3r"]))
    for p in bullets([
        "<b>MAU crosses ~100K</b> with Firestore writes dominating cost \u2014 re-model; consider a dedicated event store (BigQuery for analytics, Timestream/Influx for any on-device time-series we decide to retain).",
        "<b>Compliance scope expands</b> (HIPAA-regulated customers, SOC2 Type II with auditor scrutiny on data controls) \u2014 MongoDB\u2019s CSFLE + BYOK story is stronger.",
        "<b>Complex cross-user queries</b> (fleet analytics, geospatial joins, dashboard exports) become a recurring need \u2014 add a read-replica pipeline into BigQuery or MongoDB Atlas for analytics; keep Firebase as the OLTP layer.",
        "<b>We start persisting time-series telemetry</b> (for ML training, replay, fleet-level trend analysis) \u2014 route that to a dedicated store, not Firestore.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Hybrid fallback (if Firebase ever becomes limiting)", styles["h3g"]))
    story.append(Paragraph(
        "Keep Firebase for Auth, FCM, and app-facing data. Add MongoDB Atlas or "
        "BigQuery as a secondary store for analytics and any retained telemetry, "
        "populated via Cloud Functions from IoT Core. This hybrid preserves the "
        "fast iteration loop while giving us the database flexibility Firestore "
        "lacks for heavy analytical workloads.",
        styles["body"]))

    story.append(Spacer(1, 14))
    story.append(GradientLine(CONTENT_W, 2.5))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        "<b>Final verdict:</b> Firebase + AWS S3 + AWS IoT Core (mTLS) + direct "
        "BLE/Wi-Fi for live data. Ship fast, monitor cost at 10K MAU, keep the "
        "door open to MongoDB/BigQuery for analytics later.",
        styles["callout"]))

    # ======================================================================
    # SECTION 10: BOTTOM LINE
    # ======================================================================
    story.append(PageBreak())
    story.append(SectionMarker("Section 10: Bottom Line"))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        f'<font color="{BRAND_GREEN.hexval()}" size="12">SECTION 10</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("Bottom Line \u2014 Simple Summary", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 16))

    story.append(Paragraph("What we picked", styles["h3g"]))
    picked = [
        ["Purpose", "Choice"],
        ["User auth", "Firebase Auth"],
        ["App data (profile, zones, task history, alerts, presence)", "Cloud Firestore"],
        ["Live telemetry / joystick / camera (when user is on-site)", "Direct BLE + local Wi-Fi between app and robot"],
        ["Remote commands + status events (when off-site)", "AWS IoT Core \u2192 Cloud Function \u2192 Firestore"],
        ["Push notifications (alerts, task complete)", "Firebase Cloud Messaging (FCM)"],
        ["Server-side logic", "Firebase Cloud Functions (2nd gen)"],
        ["Images / video / firmware", "AWS S3 (SSE-KMS, Object Lock on firmware)"],
        ["Robot \u2194 cloud transport", "MQTT over TLS 1.2 with X.509 mutual auth"],
        ["App local cache", "Hive / Isar + Firestore SDK cache"],
        ["Robot local cache", "SQLite (command queue, unsent events, 24 h debug ring)"],
    ]
    story.append(make_table(picked, styles,
                            col_widths=[CONTENT_W * 0.45, CONTENT_W * 0.55]))

    story.append(Spacer(1, 14))
    story.append(Paragraph("Why Firebase, in one paragraph", styles["h3g"]))
    story.append(Paragraph(
        "We are a small team shipping a Flutter app that needs auth, push, offline "
        "support, and event-driven cloud writes \u2014 <i>not</i> streaming telemetry. "
        "Live data (battery, GPS, camera, joystick) runs on a direct link to the "
        "robot when the user is nearby, so the cloud only handles remote commands, "
        "status events, alerts, and history. Firebase gives us all of that on day "
        "one: FlutterFire is first-class, offline persistence is default, FCM is "
        "free and unlimited, and Auth removes a whole build-out. MongoDB would "
        "make us build the API, auth, and push wiring ourselves for no advantage "
        "at this scale. <b>Time to ship and zero ops beats database purity.</b> "
        "We revisit when we cross ~100K MAU or hit a schema wall.",
        styles["body"]))

    story.append(Paragraph("Why not MongoDB \u2014 plainly", styles["h3r"]))
    for p in bullets([
        "No first-class Flutter SDK \u2192 we build the API layer ourselves.",
        "No built-in push \u2192 we wire up FCM/APNs ourselves.",
        "Auth is DIY \u2192 more code, more bugs, more support load.",
        "Minimum $58/mo for an M10 even with zero traffic \u2192 wrong shape for pre-revenue months.",
        "Real-time via change streams works, but less turnkey than Firestore listeners on mobile.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Why AWS S3 (not Firebase Storage)", styles["h3r"]))
    for p in bullets([
        "Cheaper at scale for media-heavy workloads (camera frames, videos).",
        "Lifecycle tiering (Standard \u2192 Intelligent \u2192 Glacier) is mature.",
        "Object Lock (WORM) for firmware \u2014 published binaries become tamper-proof.",
        "Same AWS account as IoT Core \u2192 zero egress cost inside the region.",
        "Pre-signed URLs give us fine-grained, short-lived upload/download permissions.",
    ], styles):
        story.append(p)

    story.append(Paragraph("Why AWS IoT Core for the robot", styles["h3r"]))
    for p in bullets([
        "Purpose-built for per-device X.509 mTLS \u2014 exactly our threat model.",
        "MQTT is the right protocol for intermittent, low-bandwidth field Wi-Fi.",
        "Per-device policies isolate robots from each other.",
        "Audit logs, device shadows, and OTA jobs are built in.",
        "$1 per million messages \u2014 effectively free for our scale.",
    ], styles):
        story.append(p)

    story.append(Spacer(1, 16))
    story.append(GradientLine(CONTENT_W, 2.5))
    story.append(Spacer(1, 12))
    story.append(Paragraph(
        "<b>One-line summary:</b> Direct BLE/Wi-Fi to the robot for live data, "
        "Firebase for the app (auth, events, push, history), AWS IoT Core for "
        "remote commands, AWS S3 for media and firmware. The cloud is event-driven, "
        "not streaming \u2014 which keeps cost under control and lets us ship in weeks.",
        styles["callout"]))

    # Build
    print(f"Building PDF with {len(story)} flowables ...")
    doc.build(story, onFirstPage=page_bg, onLaterPages=page_bg)

    sz = os.path.getsize(output_path) / 1024
    print(f"PDF generated: {output_path}")
    print(f"File size: {sz:.1f} KB")


if __name__ == "__main__":
    build_pdf()
