#!/usr/bin/env python3
"""
ChoreRobotics — Robot/App Interface Parameters PDF
Dark-mode branded PDF matching the existing document suite.
"""

import os
from datetime import datetime

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, Flowable,
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

# ---------------------------------------------------------------------------
# Font setup
# ---------------------------------------------------------------------------
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
        c.drawCentredString(w / 2, ty, "Robot / App")
        c.drawCentredString(w / 2, ty - 36, "Interface Parameters")

        # Subtitle
        c.setFillColor(BRAND_BLUE)
        c.setFont(FONT_MEDIUM, 14)
        c.drawCentredString(w / 2, ty - 78, "Perception & Motion Planning I/O Reference")

        # Info box
        iy = ty - 200
        bw, bh = 280, 100
        bx = (w - bw) / 2
        c.setFillColor(CARD_BG)
        c.roundRect(bx, iy, bw, bh, 6, fill=1, stroke=0)
        c.setFillColor(TEXT_SECONDARY)
        c.setFont(FONT_BODY, 10)
        c.drawCentredString(w / 2, iy + bh - 22, "Version 1.0.0")
        c.drawCentredString(w / 2, iy + bh - 38, datetime.now().strftime("%B %d, %Y"))
        c.drawCentredString(w / 2, iy + bh - 54, "For App, Firmware & Autonomy Teams")
        c.setFillColor(TEXT_MUTED)
        c.setFont(FONT_BODY, 9)
        c.drawCentredString(w / 2, iy + bh - 72, "Perception Module  \u2022  Motion Planning Module  \u2022  Telemetry")

        # Bottom gradient
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


# ---------------------------------------------------------------------------
# Section tracking for headers
# ---------------------------------------------------------------------------
current_section = [""]


class SectionMarker(Flowable):
    def __init__(self, name):
        super().__init__()
        self.section_name = name

    def wrap(self, aW, aH):
        return (0, 0)

    def draw(self):
        current_section[0] = self.section_name


# ---------------------------------------------------------------------------
# Page background / header / footer
# ---------------------------------------------------------------------------
def page_bg(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(BG_DARK)
    canvas.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    pn = canvas.getPageNumber()
    if pn > 1:
        # Header line
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
# Styles
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
    s["section_label"] = ParagraphStyle("section_label", fontName=FONT_BODY, fontSize=12,
                                        textColor=BRAND_BLUE, spaceAfter=4)
    s["th"] = ParagraphStyle("th", fontName=FONT_BOLD, fontSize=7.5, leading=10,
                             textColor=TEXT_PRIMARY)
    s["td"] = ParagraphStyle("td", fontName=FONT_BODY, fontSize=7.5, leading=10,
                             textColor=TEXT_PRIMARY)
    s["td_mono"] = ParagraphStyle("td_mono", fontName=FONT_MONO, fontSize=7, leading=9.5,
                                  textColor=HexColor("#79C0FF"))
    s["td_muted"] = ParagraphStyle("td_muted", fontName=FONT_BODY, fontSize=7.5, leading=10,
                                   textColor=TEXT_SECONDARY)
    s["toc_title"] = ParagraphStyle("toc_title", fontName=FONT_EXTRABOLD, fontSize=20, leading=26,
                                    textColor=TEXT_PRIMARY, spaceAfter=20)
    s["toc_item"] = ParagraphStyle("toc_item", fontName=FONT_BODY, fontSize=11, leading=22,
                                   textColor=TEXT_PRIMARY, leftIndent=10, spaceAfter=2)
    s["note"] = ParagraphStyle("note", fontName=FONT_BODY, fontSize=8.5, leading=12,
                               textColor=TEXT_SECONDARY, leftIndent=8, spaceAfter=6)
    return s


# ---------------------------------------------------------------------------
# Table builder helper
# ---------------------------------------------------------------------------
def make_param_table(rows, styles, col_widths=None):
    """Build a branded parameter table.

    rows: list of lists. First row is header.
    """
    ncol = len(rows[0])
    if col_widths is None:
        col_widths = [CONTENT_W / ncol] * ncol

    data = []
    for i, row in enumerate(rows):
        style = styles["th"] if i == 0 else styles["td"]
        data.append([Paragraph(cell, style) for cell in row])

    tbl = Table(data, colWidths=col_widths, repeatRows=1)
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


def make_param_table_rich(rows, styles, col_widths=None):
    """Build a table where the first row is header (th style) and remaining rows
    use mono style for column 0, muted for column 2, and td for others."""
    ncol = len(rows[0])
    if col_widths is None:
        col_widths = [CONTENT_W / ncol] * ncol

    data = []
    for i, row in enumerate(rows):
        if i == 0:
            data.append([Paragraph(cell, styles["th"]) for cell in row])
        else:
            cells = []
            for j, cell in enumerate(row):
                if j == 0:
                    cells.append(Paragraph(cell, styles["td_mono"]))
                elif j == 2 and ncol >= 4:
                    cells.append(Paragraph(cell, styles["td_muted"]))
                else:
                    cells.append(Paragraph(cell, styles["td"]))
            data.append(cells)

    tbl = Table(data, colWidths=col_widths, repeatRows=1)
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
# Data
# ---------------------------------------------------------------------------
# Column widths for parameter tables: Name, Type, Unit/Range, Description
PARAM_COLS = [42 * mm, 14 * mm, 28 * mm, CONTENT_W - 84 * mm]

BATTERY_TELEMETRY = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["battery_pct", "float", "0\u2013100", "State of charge percentage"],
    ["battery_voltage", "float", "volts", "Terminal voltage (e.g. 25.4 V)"],
    ["battery_current_amps", "float", "amps", "Current draw (negative = charging)"],
    ["battery_temp_c", "float", "\u00b0C", "Pack temperature"],
    ["battery_health_pct", "float", "0\u2013100", "State of health percentage"],
    ["battery_cycles", "int", "\u2014", "Total charge/discharge cycles"],
]

MOTION_TELEMETRY = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["speed_ms", "float", "m/s", "Ground speed from odometry"],
    ["heading_deg", "float", "0\u2013359.99", "Compass heading (0=N, 90=E)"],
]

GPS_TELEMETRY = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["latitude", "float", "degrees", "WGS84 latitude"],
    ["longitude", "float", "degrees", "WGS84 longitude"],
    ["rtk_status", "string", "enum", "none | single | float | fix"],
    ["satellite_count", "int", "\u2014", "Satellites in solution"],
    ["accuracy_cm", "float", "cm", "Horizontal position accuracy"],
]

MOTOR_TELEMETRY = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["fl_rpm", "int", "RPM", "Front-left motor speed"],
    ["fr_rpm", "int", "RPM", "Front-right motor speed"],
    ["rl_rpm", "int", "RPM", "Rear-left motor speed"],
    ["rr_rpm", "int", "RPM", "Rear-right motor speed"],
]

SYSTEM_TELEMETRY = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["system_temp_c", "float", "\u00b0C", "Jetson board temperature"],
    ["state", "string", "enum", "idle | working | charging | paused | error | estop | docked"],
    ["signal_strength", "int", "0\u20134", "Connection quality bars"],
    ["attachment_type", "string", "enum", "mower_blade | snow_plow | leaf_collector | none"],
    ["estop_active", "bool", "\u2014", "Whether E-Stop is engaged"],
    ["blade_on", "bool", "\u2014", "Whether attachment motor is running"],
]

TASK_PROGRESS = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["task_id", "string", "\u2014", "Unique task ID"],
    ["task_type", "string", "enum", "mow | plow | collect"],
    ["zone_id", "string", "\u2014", "Zone being operated on"],
    ["zone_name", "string", "\u2014", "Human-readable zone name"],
    ["task_status", "string", "enum", "idle | running | paused | completed | failed | cancelled"],
    ["progress_pct", "float", "0\u2013100", "Completion percentage"],
    ["area_completed_sq_m", "float", "m\u00b2", "Area covered so far"],
    ["area_total_sq_m", "float", "m\u00b2", "Total zone area"],
    ["elapsed_seconds", "int", "seconds", "Wall-clock time since start"],
    ["battery_used_pct", "float", "0\u2013100", "Battery consumed by this task"],
    ["coverage_path", "list", "lat/lng", "GPS breadcrumb trail"],
    ["fail_reason", "string", "enum", "obstacle | battery_low | stuck | connection_lost | estop | null"],
    ["can_resume", "bool", "\u2014", "Whether task can resume from current position"],
]

PERCEPTION_OUTPUT = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["detected_obstacles", "list", "\u2014", "Array of obstacles currently seen"],
    ["\u00a0\u00a0.type", "string", "enum", "person | animal | vehicle | object | unknown"],
    ["\u00a0\u00a0.distance_m", "float", "meters", "Distance from robot"],
    ["\u00a0\u00a0.bearing_deg", "float", "degrees", "Relative angle from robot heading"],
    ["\u00a0\u00a0.confidence", "float", "0\u20131.0", "Detection confidence"],
    ["\u00a0\u00a0.bounding_box", "object", "{x,y,w,h}", "In camera frame (optional)"],
    ["terrain_type", "string", "enum", "grass | gravel | concrete | snow | mud | leaves | unknown"],
    ["terrain_condition", "string", "enum", "dry | wet | icy | soft"],
    ["boundary_detected", "bool", "\u2014", "Whether robot sees a zone boundary"],
    ["boundary_distance_m", "float", "meters", "Distance to nearest boundary edge"],
    ["slope_deg", "float", "degrees", "Current ground slope (0 = flat)"],
    ["slope_direction_deg", "float", "degrees", "Direction of steepest descent"],
    ["camera_feed_available", "bool", "\u2014", "Whether live camera stream is active"],
    ["camera_feed_url", "string", "URL", "Local stream URL (WebRTC / MJPEG)"],
]

MOTION_PLAN_OUTPUT = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["planned_path", "list", "lat/lng", "Upcoming planned waypoints"],
    ["current_waypoint_index", "int", "\u2014", "Index in planned_path being targeted"],
    ["path_remaining_m", "float", "meters", "Distance remaining on current path"],
    ["eta_seconds", "int", "seconds", "Estimated time to task completion"],
    ["replanning", "bool", "\u2014", "Whether the planner is recalculating"],
    ["replan_reason", "string", "enum", "obstacle | boundary | stuck | user_zone_update | null"],
    ["nav_mode", "string", "enum", "manual | autonomous | docking | returning_home"],
    ["linear_velocity_cmd", "float", "m/s", "Current commanded forward speed"],
    ["angular_velocity_cmd", "float", "rad/s", "Current commanded turn rate"],
]

ALERTS_OUTPUT = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["alert_id", "string", "\u2014", "Unique alert ID"],
    ["severity", "string", "enum", "critical | warning | info"],
    ["category", "string", "enum", "motor | blade | battery | connection | gps | sensor | system | safety"],
    ["code", "string", "\u2014", "Machine-readable error code (e.g. MOTOR_FL_OVERCURRENT)"],
    ["title", "string", "\u2014", "Short human-readable title"],
    ["message", "string", "\u2014", "Detailed description"],
    ["component", "string", "\u2014", "Affected component name"],
    ["is_active", "bool", "\u2014", "Whether fault is still present"],
]

# --- Commands: App -> Perception ---
ZONE_DEFS = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["zone_id", "string", "\u2014", "Zone identifier"],
    ["zone_name", "string", "\u2014", "Human-readable name"],
    ["zone_type", "string", "enum", "mow | plow | collect"],
    ["vertices", "list", "lat/lng", "Polygon vertices [{lat, lng}, ...]"],
    ["area_sq_m", "float", "m\u00b2", "Computed zone area"],
]

NOGO_ZONES = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["nogo_zone_id", "string", "\u2014", "Zone identifier"],
    ["vertices", "list", "lat/lng", "Polygon vertices"],
    ["reason", "string", "enum", "garden | pool | structure | custom"],
]

OBSTACLE_MARKERS = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["marker_id", "string", "\u2014", "Unique marker ID"],
    ["position", "object", "lat/lng", "{lat, lng}"],
    ["radius_m", "float", "meters", "Avoidance radius"],
    ["label", "string", "\u2014", 'User label (e.g. "tree stump")'],
    ["permanent", "bool", "\u2014", "Whether to remember across sessions"],
]

PERCEPTION_SENSITIVITY = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["obstacle_sensitivity", "string", "enum", "low | medium | high"],
    ["min_obstacle_distance_m", "float", "meters", "Minimum clearance from obstacles"],
    ["enable_person_detection", "bool", "\u2014", "Whether to use human detection model"],
    ["enable_animal_detection", "bool", "\u2014", "Whether to detect animals"],
]

# --- Commands: App -> Motion Planning ---
DRIVE_CMD = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["linear_x", "float", "\u22121.0 to 1.0", "Forward (+) / backward (\u2212)"],
    ["angular_z", "float", "\u22121.0 to 1.0", "Turn left (+) / right (\u2212)"],
    ["blade_on", "bool", "\u2014", "Run attachment motor"],
    ["turbo_mode", "bool", "\u2014", "Allow higher max speed"],
]

MOW_PARAMS = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["task_type", "string", 'literal "mow"', "Task type identifier"],
    ["zone_id", "string", "\u2014", "Target zone"],
    ["pattern", "string", "enum", "straight | diagonal | checker | spiral"],
    ["angle_deg", "float", "0\u2013180", "Stripe angle in degrees"],
    ["overlap_pct", "float", "0\u201330", "Pass overlap percentage"],
    ["cutting_height_mm", "int", "25\u2013100", "Blade cutting height in mm"],
]

PLOW_PARAMS = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["task_type", "string", 'literal "plow"', "Task type identifier"],
    ["zone_id", "string", "\u2014", "Target zone"],
    ["start_position", "string", "enum", "entrance | garage | center | custom"],
    ["custom_start_lat", "float", "degrees", "Custom start latitude (if custom)"],
    ["custom_start_lng", "float", "degrees", "Custom start longitude (if custom)"],
    ["snow_depth", "string", "enum", "light | medium | heavy"],
    ["disposal_direction", "string", "enum", "left | right | pile_zone"],
    ["pile_zone_id", "string", "\u2014", "Destination zone (if pile_zone)"],
]

COLLECT_PARAMS = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["task_type", "string", 'literal "collect"', "Task type identifier"],
    ["zone_id", "string", "\u2014", "Target zone"],
    ["mode", "string", "enum", "full_zone | spot_clean"],
    ["spot_clean_vertices", "list", "lat/lng", "Spot clean polygon (if spot_clean)"],
    ["collection_mode", "string", "enum", "mulch | bag"],
    ["dump_point_lat", "float", "degrees", "Dump point latitude (if bag)"],
    ["dump_point_lng", "float", "degrees", "Dump point longitude (if bag)"],
]

TASK_CONTROL = [
    ["Command", "Parameters", "Description"],
    ["task_stop", "reason: string", "user_requested | weather | schedule_end"],
    ["task_pause", "(none)", "Pause the currently running task"],
    ["task_resume", "(none)", "Resume a paused task"],
]

ESTOP_CMD = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["activate", "bool", "\u2014", "true = stop, false = clear"],
    ["confirmation_code", "string", "\u2014", "Required to clear (safety)"],
]

BLADE_CMD = [
    ["Parameter", "Type", "Description"],
    ["enabled", "bool", "true = on, false = off (local connection only, never via cloud)"],
]

SPEED_LIMITS = [
    ["Parameter", "Type", "Unit / Range", "Description"],
    ["max_speed_ms", "float", "m/s", "User-set speed cap"],
    ["enable_turbo", "bool", "\u2014", "Whether turbo mode is allowed"],
    ["edge_mode", "string", "enum", "stop | slow | turn (at zone boundary)"],
    ["path_type", "string", "enum", "efficient | thorough (speed vs. coverage)"],
]

SUMMARY_TABLE = [
    ["Direction", "Module / Category", "Count"],
    ["Robot \u2192 App", "Core Telemetry", "~30 fields"],
    ["Robot \u2192 App", "Perception Output", "~14 fields"],
    ["Robot \u2192 App", "Motion Planning Output", "~9 fields"],
    ["Robot \u2192 App", "Alerts / Diagnostics", "~8 fields"],
    ["App \u2192 Perception", "Zone Definitions", "~5 fields / zone"],
    ["App \u2192 Perception", "No-Go Zones", "~3 fields / zone"],
    ["App \u2192 Perception", "Obstacle Markers", "~5 fields / marker"],
    ["App \u2192 Perception", "Sensitivity Config", "~4 fields"],
    ["App \u2192 Motion Planning", "Drive Command (30 Hz)", "~4 fields"],
    ["App \u2192 Motion Planning", "Task Start (mow)", "~6 fields"],
    ["App \u2192 Motion Planning", "Task Start (plow)", "~8 fields"],
    ["App \u2192 Motion Planning", "Task Start (collect)", "~7 fields"],
    ["App \u2192 Motion Planning", "Task Control", "3 commands"],
    ["App \u2192 Motion Planning", "E-Stop", "~2 fields"],
    ["App \u2192 Motion Planning", "Speed / Plan Limits", "~4 fields"],
]


# ---------------------------------------------------------------------------
# Build the PDF
# ---------------------------------------------------------------------------
def build_pdf():
    base = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(base)
    logo_path = os.path.join(project_root, "assets", "logo", "chore-robots-logo.png")
    output_path = os.path.join(base, "ChoreRobotics_Robot_App_Interface.pdf")

    found = register_fonts()
    print(f"Registered fonts: {found or 'built-in fallbacks'}")

    styles = make_styles()

    doc = SimpleDocTemplate(
        output_path, pagesize=A4,
        leftMargin=LEFT_MARGIN, rightMargin=RIGHT_MARGIN,
        topMargin=TOP_MARGIN, bottomMargin=BOTTOM_MARGIN,
        title="ChoreRobotics \u2014 Robot/App Interface Parameters",
        author="ChoreRobotics, Inc.",
        subject="Perception & Motion Planning I/O Reference",
        creator="ChoreRobotics Document Generator",
    )

    story = []

    # ── COVER ──
    story.append(CoverPage(logo_path))
    story.append(PageBreak())

    # ── TABLE OF CONTENTS ──
    story.append(SectionMarker("Table of Contents"))
    story.append(Spacer(1, 20))
    story.append(Paragraph("Table of Contents", styles["toc_title"]))
    story.append(GradientLine(CONTENT_W, 2.5))
    story.append(Spacer(1, 20))

    toc_sections = [
        ("Section A", "Data the App Receives from the Robot", BRAND_BLUE),
        ("", "  Battery Telemetry", None),
        ("", "  Motion Telemetry", None),
        ("", "  GPS / Positioning", None),
        ("", "  Motors", None),
        ("", "  System State", None),
        ("", "  Task Progress", None),
        ("", "  Perception Module Output", None),
        ("", "  Motion Planning Module Output", None),
        ("", "  Alerts / Diagnostics", None),
        ("Section B", "Commands the App Sends to the Perception Module", BRAND_PURPLE),
        ("", "  Zone Definitions", None),
        ("", "  No-Go Zones", None),
        ("", "  Obstacle Markers", None),
        ("", "  Perception Sensitivity", None),
        ("Section C", "Commands the App Sends to the Motion Planning Module", BRAND_MAGENTA),
        ("", "  Manual Drive", None),
        ("", "  Task Start: Mow / Plow / Collect", None),
        ("", "  Task Control", None),
        ("", "  E-Stop / Blade / Dock", None),
        ("", "  Speed & Planning Limits", None),
        ("Section D", "Summary Table", BRAND_RED),
    ]
    for label, title, color in toc_sections:
        if label:
            story.append(Paragraph(
                f'<font name="{FONT_BOLD}" color="{color.hexval()}">{label}</font>'
                f'&nbsp;&nbsp;&nbsp;{title}',
                styles["toc_item"]))
        else:
            sub_style = ParagraphStyle("toc_sub", parent=styles["toc_item"],
                                       fontSize=9.5, leading=16, textColor=TEXT_SECONDARY,
                                       leftIndent=30)
            story.append(Paragraph(title, sub_style))

    story.append(PageBreak())

    # ======================================================================
    # SECTION A: Robot -> App
    # ======================================================================
    story.append(SectionMarker("Section A: Robot \u2192 App"))
    story.append(Spacer(1, 20))
    story.append(Paragraph(
        f'<font color="{BRAND_BLUE.hexval()}" size="12">SECTION A</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("Data the App Receives from the Robot", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 8))
    story.append(Paragraph(
        "These are values the app displays or reacts to in real time. "
        "Data flows from the robot\u2019s ROS2 stack through BLE, WebSocket, "
        "or Firebase to the Flutter app.",
        styles["body"]))
    story.append(Spacer(1, 10))

    # Battery
    story.append(Paragraph("Battery", styles["h3"]))
    story.append(Paragraph("Source: ROS2 /battery/state @ 1 Hz", styles["note"]))
    story.append(make_param_table_rich(BATTERY_TELEMETRY, styles, PARAM_COLS))
    story.append(Spacer(1, 8))

    # Motion
    story.append(Paragraph("Motion (Odometry + IMU)", styles["h3"]))
    story.append(Paragraph("Source: ROS2 /odom @ 10 Hz, /imu/data @ 50 Hz", styles["note"]))
    story.append(make_param_table_rich(MOTION_TELEMETRY, styles, PARAM_COLS))
    story.append(Spacer(1, 8))

    # GPS
    story.append(Paragraph("GPS / Positioning", styles["h3"]))
    story.append(Paragraph("Source: ROS2 /gps/fix @ 5 Hz, /gps/rtk_status @ 1 Hz", styles["note"]))
    story.append(make_param_table_rich(GPS_TELEMETRY, styles, PARAM_COLS))
    story.append(Spacer(1, 8))

    # Motors
    story.append(Paragraph("Drive Motors", styles["h3"]))
    story.append(Paragraph("Source: ROS2 /motor_speeds @ 10 Hz", styles["note"]))
    story.append(make_param_table_rich(MOTOR_TELEMETRY, styles, PARAM_COLS))
    story.append(Spacer(1, 8))

    # System
    story.append(Paragraph("System State", styles["h3"]))
    story.append(make_param_table_rich(SYSTEM_TELEMETRY, styles, PARAM_COLS))
    story.append(Spacer(1, 8))

    # Task progress
    story.append(PageBreak())
    story.append(SectionMarker("Section A: Task Progress"))
    story.append(Paragraph("Task Progress", styles["h3"]))
    story.append(Paragraph("Source: ROS2 /task/progress @ 1 Hz during autonomous operation", styles["note"]))
    story.append(make_param_table_rich(TASK_PROGRESS, styles, PARAM_COLS))
    story.append(Spacer(1, 12))

    # Perception output
    story.append(PageBreak())
    story.append(SectionMarker("Section A: Perception Output"))
    story.append(Paragraph("Perception Module Output", styles["h3"]))
    story.append(Paragraph(
        "New parameters needed from the perception stack. "
        "These enable the app to show obstacle overlays, terrain info, "
        "and camera feeds.",
        styles["note"]))
    story.append(make_param_table_rich(PERCEPTION_OUTPUT, styles, PARAM_COLS))
    story.append(Spacer(1, 12))

    # Motion planning output
    story.append(Paragraph("Motion Planning Module Output", styles["h3"]))
    story.append(Paragraph(
        "New parameters needed from the motion planner. "
        "These let the app visualize the planned path, ETA, "
        "and replanning events.",
        styles["note"]))
    story.append(make_param_table_rich(MOTION_PLAN_OUTPUT, styles, PARAM_COLS))
    story.append(Spacer(1, 12))

    # Alerts
    story.append(Paragraph("Alerts / Diagnostics", styles["h3"]))
    story.append(Paragraph("Source: ROS2 /diagnostics @ 1 Hz + event-driven", styles["note"]))
    story.append(make_param_table_rich(ALERTS_OUTPUT, styles, PARAM_COLS))

    # ======================================================================
    # SECTION B: App -> Perception
    # ======================================================================
    story.append(PageBreak())
    story.append(SectionMarker("Section B: App \u2192 Perception"))
    story.append(Spacer(1, 20))
    story.append(Paragraph(
        f'<font color="{BRAND_PURPLE.hexval()}" size="12">SECTION B</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("Commands the App Sends to the Perception Module", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 8))
    story.append(Paragraph(
        "These configure what the perception system looks for and how "
        "it behaves. Sent via WebSocket or synced through Firebase.",
        styles["body"]))
    story.append(Spacer(1, 10))

    story.append(Paragraph("Zone Definitions", styles["h3"]))
    story.append(Paragraph("Tell perception where the work boundaries are.", styles["note"]))
    story.append(make_param_table_rich(ZONE_DEFS, styles, PARAM_COLS))
    story.append(Spacer(1, 10))

    story.append(Paragraph("No-Go Zones", styles["h3"]))
    story.append(Paragraph("Mark areas the robot must avoid (flower beds, pools, etc.).", styles["note"]))
    story.append(make_param_table_rich(NOGO_ZONES, styles, PARAM_COLS))
    story.append(Spacer(1, 10))

    story.append(Paragraph("User-Placed Obstacle Markers", styles["h3"]))
    story.append(Paragraph("Let user manually flag known obstacles on the map.", styles["note"]))
    story.append(make_param_table_rich(OBSTACLE_MARKERS, styles, PARAM_COLS))
    story.append(Spacer(1, 10))

    story.append(Paragraph("Perception Sensitivity", styles["h3"]))
    story.append(Paragraph("Let user tune how cautious the robot is.", styles["note"]))
    story.append(make_param_table_rich(PERCEPTION_SENSITIVITY, styles, PARAM_COLS))

    # ======================================================================
    # SECTION C: App -> Motion Planning
    # ======================================================================
    story.append(PageBreak())
    story.append(SectionMarker("Section C: App \u2192 Motion Planning"))
    story.append(Spacer(1, 20))
    story.append(Paragraph(
        f'<font color="{BRAND_MAGENTA.hexval()}" size="12">SECTION C</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("Commands the App Sends to the Motion Planning Module", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 8))
    story.append(Paragraph(
        "These control how the robot moves and plans paths. "
        "Drive commands are sent at 30 Hz during manual mode; "
        "task commands are event-driven.",
        styles["body"]))
    story.append(Spacer(1, 10))

    story.append(Paragraph("Manual Drive (Joystick / D-Pad)", styles["h3"]))
    story.append(Paragraph("Direct velocity control at 30 Hz during manual mode.", styles["note"]))
    story.append(make_param_table_rich(DRIVE_CMD, styles, PARAM_COLS))
    story.append(Spacer(1, 10))

    story.append(Paragraph("Task Start: Mow", styles["h3"]))
    story.append(make_param_table_rich(MOW_PARAMS, styles, PARAM_COLS))
    story.append(Spacer(1, 10))

    story.append(Paragraph("Task Start: Snow Plow", styles["h3"]))
    story.append(make_param_table_rich(PLOW_PARAMS, styles, PARAM_COLS))
    story.append(Spacer(1, 10))

    story.append(PageBreak())
    story.append(SectionMarker("Section C: Collect / Control"))

    story.append(Paragraph("Task Start: Leaf Collection", styles["h3"]))
    story.append(make_param_table_rich(COLLECT_PARAMS, styles, PARAM_COLS))
    story.append(Spacer(1, 10))

    story.append(Paragraph("Task Control", styles["h3"]))
    task_ctrl_cols = [35 * mm, 40 * mm, CONTENT_W - 75 * mm]
    story.append(make_param_table(TASK_CONTROL, styles, task_ctrl_cols))
    story.append(Spacer(1, 10))

    story.append(Paragraph("Emergency Stop", styles["h3"]))
    story.append(Paragraph("Highest priority command \u2014 sent on ALL channels simultaneously.", styles["note"]))
    story.append(make_param_table_rich(ESTOP_CMD, styles, PARAM_COLS))
    story.append(Spacer(1, 10))

    story.append(Paragraph("Blade Control", styles["h3"]))
    story.append(Paragraph("Local connection only (BLE / WiFi). Never accepted via cloud for safety.", styles["note"]))
    blade_cols = [35 * mm, 14 * mm, CONTENT_W - 49 * mm]
    story.append(make_param_table(BLADE_CMD, styles, blade_cols))
    story.append(Spacer(1, 10))

    story.append(Paragraph("Dock / Return Home", styles["h3"]))
    story.append(Paragraph("No parameters \u2014 robot navigates autonomously to its charging dock.", styles["note"]))
    story.append(Spacer(1, 10))

    story.append(Paragraph("Speed &amp; Planning Limits", styles["h3"]))
    story.append(Paragraph("Let user constrain motion planner behavior.", styles["note"]))
    story.append(make_param_table_rich(SPEED_LIMITS, styles, PARAM_COLS))

    # ======================================================================
    # SECTION D: Summary
    # ======================================================================
    story.append(PageBreak())
    story.append(SectionMarker("Section D: Summary"))
    story.append(Spacer(1, 20))
    story.append(Paragraph(
        f'<font color="{BRAND_RED.hexval()}" size="12">SECTION D</font>',
        styles["body"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("Summary", styles["h1"]))
    story.append(GradientLine(CONTENT_W, 3))
    story.append(Spacer(1, 16))

    summary_cols = [40 * mm, 55 * mm, CONTENT_W - 95 * mm]
    story.append(make_param_table(SUMMARY_TABLE, styles, summary_cols))

    story.append(Spacer(1, 20))
    flow_style = ParagraphStyle("flow", fontName=FONT_MONO, fontSize=8.5, leading=13,
                                textColor=TEXT_PRIMARY, backColor=HexColor("#0D1117"),
                                leftIndent=10, rightIndent=10, borderPadding=10,
                                spaceAfter=10)
    story.append(Paragraph(
        "DATA FLOW:<br/><br/>"
        "&nbsp;&nbsp;[Perception Module] \u2500\u2500\u2500 obstacles, terrain, camera \u2500\u2500\u2500\u25b6 [Robot Server] \u2500\u2500\u2500 BLE / WiFi / Firebase \u2500\u2500\u2500\u25b6 [Flutter App]<br/>"
        "&nbsp;&nbsp;[Motion Planner]&nbsp;&nbsp;&nbsp;&nbsp;\u2500\u2500\u2500 path, ETA, nav mode&nbsp;&nbsp;&nbsp;\u2500\u2500\u2500\u25b6 [Robot Server] \u2500\u2500\u2500 BLE / WiFi / Firebase \u2500\u2500\u2500\u25b6 [Flutter App]<br/><br/>"
        "&nbsp;&nbsp;[Flutter App] \u2500\u2500\u2500 zones, no-go, sensitivity \u2500\u2500\u2500\u25b6 [Robot Server] \u2500\u2500\u2500\u25b6 [Perception Module]<br/>"
        "&nbsp;&nbsp;[Flutter App] \u2500\u2500\u2500 drive, tasks, e-stop&nbsp;&nbsp;&nbsp;&nbsp;\u2500\u2500\u2500\u25b6 [Robot Server] \u2500\u2500\u2500\u25b6 [Motion Planner]",
        flow_style))

    # Build
    print(f"Building PDF with {len(story)} flowables ...")
    doc.build(story, onFirstPage=page_bg, onLaterPages=page_bg)

    sz = os.path.getsize(output_path) / 1024
    print(f"PDF generated: {output_path}")
    print(f"File size: {sz:.1f} KB")


if __name__ == "__main__":
    build_pdf()
