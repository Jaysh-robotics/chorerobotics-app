#!/usr/bin/env python3
"""
ChoreRobotics — Perception Module Outputs XLSX
Generates a branded spreadsheet showing what Nimra's perception module
outputs to Noman (SLAM/Navigation) and Jaysh (Controls/Motion Planning).
"""

import os
from openpyxl import Workbook
from openpyxl.styles import (
    Font, PatternFill, Alignment, Border, Side, NamedStyle
)
from openpyxl.utils import get_column_letter

# Brand colors (hex without #)
BRAND_BLUE    = "3B5EE8"
BRAND_PURPLE  = "8B45B5"
BRAND_MAGENTA = "D63384"
BRAND_RED     = "EF3350"
BG_DARK       = "0A0C10"
CARD_BG       = "151820"
BG_SURFACE    = "0D0F14"
TABLE_HEADER  = "1E2330"
TABLE_ROW_1   = "151820"
TABLE_ROW_2   = "1A1E28"
TEXT_PRIMARY   = "E8EAED"
TEXT_SECONDARY = "8B929E"
TEXT_MUTED     = "555D6E"
WHITE          = "FFFFFF"

# Data
ROWS = [
    # (Team Member, Module, Output #, Output Description)
    ("Nimra", "Perception", "—",
     "Nimra owns the Perception module. All outputs below are produced by "
     "Perception and consumed by Noman's and Jaysh's modules."),

    # Outputs to Noman
    ("Noman", "SLAM / Navigation / Coverage", 1,
     "Semantic segmentation of the environment (road, grass, indoor floor, racks, obstacles)"),
    ("Noman", "SLAM / Navigation / Coverage", 2,
     "Identification of traversable vs non-traversable areas"),
    ("Noman", "SLAM / Navigation / Coverage", 3,
     "Basic scene context classification (indoor, outdoor, warehouse, etc.)"),
    ("Noman", "SLAM / Navigation / Coverage", 4,
     "Ground/traversable surface understanding for navigation support"),
    ("Noman", "SLAM / Navigation / Coverage", 5,
     "Dynamic obstacle awareness (to avoid affecting SLAM accuracy)"),
    ("Noman", "SLAM / Navigation / Coverage", 6,
     "Environment understanding to assist navigation and coverage path planning"),
    ("Noman", "SLAM / Navigation / Coverage", 7,
     "Occupancy mapping and landmark-level cues for improved SLAM"),

    # Outputs to Jaysh
    ("Jaysh", "Controls / Motion Planning", 1,
     "Real-time object detection (class labels + bounding boxes)"),
    ("Jaysh", "Controls / Motion Planning", 2,
     "Distance/depth estimation of detected objects"),
    ("Jaysh", "Controls / Motion Planning", 3,
     "Closest obstacle distance calculation"),
    ("Jaysh", "Controls / Motion Planning", 4,
     "Basic collision risk assessment (low / medium / high)"),
    ("Jaysh", "Controls / Motion Planning", 5,
     "Action signals: GO / SLOW / STOP"),
    ("Jaysh", "Controls / Motion Planning", 6,
     "Basic free-space awareness in front of the robot"),
    ("Jaysh", "Controls / Motion Planning", 7,
     "Provides inputs for safe motion control decisions"),
    ("Jaysh", "Controls / Motion Planning", 8,
     "Avoidance direction (left/right) and improved risk modeling"),
]


def build_xlsx():
    base = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(base, "ChoreRobotics_Perception_Outputs.xlsx")

    wb = Workbook()

    # ── Sheet 1: Perception Outputs ──
    ws = wb.active
    ws.title = "Perception Outputs"
    ws.sheet_properties.tabColor = BRAND_BLUE

    # Column widths
    ws.column_dimensions['A'].width = 18
    ws.column_dimensions['B'].width = 38
    ws.column_dimensions['C'].width = 12
    ws.column_dimensions['D'].width = 75

    # Fills
    header_fill = PatternFill(start_color=TABLE_HEADER, end_color=TABLE_HEADER, fill_type="solid")
    row1_fill = PatternFill(start_color=TABLE_ROW_1, end_color=TABLE_ROW_1, fill_type="solid")
    row2_fill = PatternFill(start_color=TABLE_ROW_2, end_color=TABLE_ROW_2, fill_type="solid")
    dark_fill = PatternFill(start_color=BG_DARK, end_color=BG_DARK, fill_type="solid")
    accent_fill = PatternFill(start_color=BRAND_BLUE, end_color=BRAND_BLUE, fill_type="solid")
    purple_fill = PatternFill(start_color=BRAND_PURPLE, end_color=BRAND_PURPLE, fill_type="solid")

    # Fonts
    title_font = Font(name="Helvetica", size=18, bold=True, color=TEXT_PRIMARY)
    subtitle_font = Font(name="Helvetica", size=11, color=TEXT_SECONDARY)
    header_font = Font(name="Helvetica", size=10, bold=True, color=WHITE)
    body_font = Font(name="Helvetica", size=10, color=TEXT_PRIMARY)
    muted_font = Font(name="Helvetica", size=10, color=TEXT_SECONDARY)
    accent_font = Font(name="Helvetica", size=10, bold=True, color=BRAND_BLUE)
    nimra_font = Font(name="Helvetica", size=10, bold=True, color=BRAND_PURPLE)

    # Borders
    thin_border = Border(
        left=Side(style="thin", color="2A2F3A"),
        right=Side(style="thin", color="2A2F3A"),
        top=Side(style="thin", color="2A2F3A"),
        bottom=Side(style="thin", color="2A2F3A"),
    )

    # Alignment
    center_align = Alignment(horizontal="center", vertical="center")
    left_align = Alignment(horizontal="left", vertical="center", wrap_text=True)

    # ── Title rows ──
    for r in range(1, 5):
        for c in range(1, 5):
            ws.cell(row=r, column=c).fill = dark_fill

    ws.merge_cells('A1:D1')
    title_cell = ws.cell(row=1, column=1, value="ChoreRobotics — Perception Module Outputs")
    title_cell.font = title_font
    title_cell.fill = dark_fill
    title_cell.alignment = Alignment(horizontal="left", vertical="center")
    ws.row_dimensions[1].height = 36

    ws.merge_cells('A2:D2')
    sub_cell = ws.cell(row=2, column=2)
    ws.cell(row=2, column=1, value="What the Perception module (Nimra) provides to each consumer module")
    ws.cell(row=2, column=1).font = subtitle_font
    ws.cell(row=2, column=1).fill = dark_fill
    ws.row_dimensions[2].height = 22

    # Team legend row
    ws.merge_cells('A3:D3')
    legend = ws.cell(row=3, column=1,
                     value="Nimra = Perception  |  Noman = SLAM / Navigation / Coverage  |  Jaysh = App & Controls / Motion Planning")
    legend.font = Font(name="Helvetica", size=9, italic=True, color=TEXT_MUTED)
    legend.fill = dark_fill
    ws.row_dimensions[3].height = 20

    # Empty separator
    ws.row_dimensions[4].height = 8
    for c in range(1, 5):
        ws.cell(row=4, column=c).fill = dark_fill

    # ── Header row ──
    headers = ["Team Member", "Consumer Module", "Output #", "Output Description"]
    header_row = 5
    ws.row_dimensions[header_row].height = 28
    for col_idx, h in enumerate(headers, 1):
        cell = ws.cell(row=header_row, column=col_idx, value=h)
        cell.font = header_font
        cell.fill = accent_fill
        cell.alignment = center_align if col_idx == 3 else left_align
        cell.border = thin_border

    # ── Data rows ──
    data_start = 6
    for i, (member, module, num, desc) in enumerate(ROWS):
        row_idx = data_start + i
        fill = row1_fill if i % 2 == 0 else row2_fill
        ws.row_dimensions[row_idx].height = 30 if len(desc) < 80 else 42

        # Skip the Nimra overview row styling
        is_nimra_row = (member == "Nimra")

        if is_nimra_row:
            fill = PatternFill(start_color=BRAND_PURPLE + "33", end_color="1E1528", fill_type="solid")
            fill = purple_fill

        # Team Member
        c1 = ws.cell(row=row_idx, column=1, value=member)
        c1.font = nimra_font if is_nimra_row else (accent_font if member == "Jaysh" else body_font)
        c1.fill = fill
        c1.border = thin_border
        c1.alignment = left_align

        # Module
        c2 = ws.cell(row=row_idx, column=2, value=module)
        c2.font = Font(name="Helvetica", size=10, color=WHITE) if is_nimra_row else muted_font
        c2.fill = fill
        c2.border = thin_border
        c2.alignment = left_align

        # Output #
        c3 = ws.cell(row=row_idx, column=3, value=num)
        c3.font = Font(name="Helvetica", size=10, color=WHITE) if is_nimra_row else body_font
        c3.fill = fill
        c3.border = thin_border
        c3.alignment = center_align

        # Description
        c4 = ws.cell(row=row_idx, column=4, value=desc)
        c4.font = Font(name="Helvetica", size=10, italic=True, color=WHITE) if is_nimra_row else body_font
        c4.fill = fill
        c4.border = thin_border
        c4.alignment = left_align

    # ── Fill remaining visible area with dark bg ──
    last_data_row = data_start + len(ROWS)
    for r in range(last_data_row, last_data_row + 5):
        for c in range(1, 5):
            ws.cell(row=r, column=c).fill = dark_fill

    # ── Sheet 2: Summary ──
    ws2 = wb.create_sheet("Summary")
    ws2.sheet_properties.tabColor = BRAND_PURPLE

    ws2.column_dimensions['A'].width = 22
    ws2.column_dimensions['B'].width = 38
    ws2.column_dimensions['C'].width = 15
    ws2.column_dimensions['D'].width = 50

    for r in range(1, 3):
        for c in range(1, 5):
            ws2.cell(row=r, column=c).fill = dark_fill

    ws2.merge_cells('A1:D1')
    ws2.cell(row=1, column=1, value="Team Responsibility Summary").font = title_font
    ws2.cell(row=1, column=1).fill = dark_fill
    ws2.row_dimensions[1].height = 36

    ws2.row_dimensions[2].height = 8

    summary_headers = ["Team Member", "Module", "Role", "Key Outputs"]
    for col_idx, h in enumerate(summary_headers, 1):
        cell = ws2.cell(row=3, column=col_idx, value=h)
        cell.font = header_font
        cell.fill = accent_fill
        cell.alignment = left_align
        cell.border = thin_border
    ws2.row_dimensions[3].height = 28

    summary_data = [
        ("Nimra", "Perception",
         "Perception Owner",
         "Object detection, semantic segmentation, depth estimation, scene classification, terrain analysis"),
        ("Noman", "SLAM / Navigation / Coverage",
         "Motion Planning Owner",
         "Consumes perception outputs for mapping, traversability, obstacle-aware navigation, coverage planning"),
        ("Jaysh", "App & Controls / Motion Planning",
         "App & Controls Owner",
         "Consumes perception outputs for real-time obstacle avoidance, collision risk, action signals (GO/SLOW/STOP)"),
    ]
    for i, (member, module, role, outputs) in enumerate(summary_data):
        row_idx = 4 + i
        fill = row1_fill if i % 2 == 0 else row2_fill
        ws2.row_dimensions[row_idx].height = 42

        for col_idx, val in enumerate([member, module, role, outputs], 1):
            cell = ws2.cell(row=row_idx, column=col_idx, value=val)
            cell.font = accent_font if col_idx == 1 else body_font
            cell.fill = fill
            cell.border = thin_border
            cell.alignment = left_align

    for r in range(7, 12):
        for c in range(1, 5):
            ws2.cell(row=r, column=c).fill = dark_fill

    # ── Freeze panes ──
    ws.freeze_panes = "A6"
    ws2.freeze_panes = "A4"

    # ── Auto-filter ──
    ws.auto_filter.ref = f"A5:D{data_start + len(ROWS) - 1}"

    # Save
    wb.save(output_path)
    sz = os.path.getsize(output_path) / 1024
    print(f"XLSX generated: {output_path}")
    print(f"File size: {sz:.1f} KB")
    print(f"Sheets: {[s.title for s in wb.sheetnames and wb.worksheets]}")


if __name__ == "__main__":
    build_xlsx()
