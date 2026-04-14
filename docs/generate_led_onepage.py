#!/usr/bin/env python3
"""Generate single-page LED spec PDF — White/Green/Red colors."""

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER
import os

# Brand
BRAND_BLUE = HexColor('#3B5EE8')
BRAND_PURPLE = HexColor('#8B45B5')
BRAND_MAGENTA = HexColor('#D63384')
BRAND_RED = HexColor('#EF3350')
BRAND_PINK = HexColor('#F5758C')
BRAND_SILVER = HexColor('#C8CDD5')
BG = HexColor('#0A0C10')
BG_CARD = HexColor('#151820')
BG_SURFACE = HexColor('#0D0F14')
TEXT = HexColor('#E8EAED')
TEXT2 = HexColor('#8B929E')
MUTED = HexColor('#555D6E')
WHITE = HexColor('#FFFFFF')

# LED colors
LED_WHITE = HexColor('#E8EAED')
LED_GREEN = HexColor('#00C853')
LED_RED = HexColor('#FF3B30')

def draw_bg(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(BG)
    canvas.rect(0, 0, A4[0], A4[1], fill=True, stroke=False)
    colors = [BRAND_BLUE, BRAND_PURPLE, BRAND_MAGENTA, BRAND_RED, BRAND_PINK, BRAND_SILVER]
    w = A4[0] / len(colors)
    for i, c in enumerate(colors):
        canvas.setFillColor(c)
        canvas.rect(i * w, A4[1] - 8 * mm, w, 2.5 * mm, fill=True, stroke=False)
    canvas.setFont('Helvetica', 7)
    canvas.setFillColor(MUTED)
    canvas.drawString(15 * mm, 8 * mm, 'ChoreRobotics')
    canvas.drawRightString(A4[0] - 15 * mm, 8 * mm, 'Confidential — Hardware & Firmware Team')
    canvas.restoreState()

def build():
    out = os.path.join(os.path.dirname(__file__), 'ChoreRobotics_LED_Spec_OnePage.pdf')
    doc = SimpleDocTemplate(out, pagesize=A4, leftMargin=15*mm, rightMargin=15*mm, topMargin=14*mm, bottomMargin=14*mm)

    title = ParagraphStyle('T', fontName='Helvetica-Bold', fontSize=18, textColor=TEXT, alignment=TA_CENTER, spaceAfter=2)
    sub = ParagraphStyle('S', fontName='Helvetica', fontSize=9, textColor=TEXT2, alignment=TA_CENTER, spaceAfter=6)
    note = ParagraphStyle('N', fontName='Helvetica', fontSize=7.5, textColor=MUTED, leading=10, spaceAfter=2)
    label = ParagraphStyle('L', fontName='Helvetica-Bold', fontSize=7.5, textColor=MUTED, spaceAfter=2, spaceBefore=6)

    story = []
    story.append(Spacer(1, 6*mm))

    logo = os.path.join(os.path.dirname(__file__), '..', 'assets', 'logo', 'chore-robots-logo.png')
    if os.path.exists(logo):
        story.append(Image(logo, width=40*mm, height=28*mm, hAlign='CENTER'))
        story.append(Spacer(1, 2*mm))

    story.append(Paragraph('LED Behavior During BLE Pairing', title))
    story.append(Paragraph('3 LED Colors: White (neutral) · Green (success) · Red (error)', sub))
    story.append(Spacer(1, 3*mm))

    # Hardware
    story.append(Paragraph('HARDWARE', label))
    story.append(Paragraph('Front-mounted LED strip (horizontal bar). 3 colors available: <b>White</b>, <b>Green</b>, <b>Red</b>. Patterns: Solid ON, OFF, Slow blink, Fast blink, Double-blink.', note))
    story.append(Spacer(1, 2*mm))

    # Color legend
    legend_data = [
        ['Color', 'Meaning', 'Used In'],
        ['WHITE', 'Neutral / in-progress / waiting', 'States 1-5 (discovery → verification)'],
        ['GREEN', 'Success / connected / ready', 'States 6-8 (paired, WiFi, complete)'],
        ['RED', 'Error / emergency / stop', 'States 9-10 (failed, E-Stop)'],
    ]
    legend = Table(legend_data, colWidths=[25*mm, 55*mm, 73*mm])
    legend.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), BRAND_PURPLE),
        ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 7.5),
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('TEXTCOLOR', (0, 1), (0, 1), LED_WHITE),
        ('TEXTCOLOR', (0, 2), (0, 2), LED_GREEN),
        ('TEXTCOLOR', (0, 3), (0, 3), LED_RED),
        ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
        ('TEXTCOLOR', (1, 1), (-1, -1), TEXT),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [BG_CARD, BG_SURFACE]),
        ('GRID', (0, 0), (-1, -1), 0.4, HexColor('#1E1E1E')),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ]))
    story.append(legend)
    story.append(Spacer(1, 3*mm))

    # Main table
    data = [
        ['#', 'State', 'Color', 'Pattern', 'Timing', 'Meaning'],
        ['1', 'Discoverable', 'WHITE', 'Slow blink', '1s on / 1s off', 'I\'m here. Ready to pair.'],
        ['2', 'Found', 'WHITE', 'Fast blink', '300ms on / 300ms off', 'I see your phone.'],
        ['3', 'Pairing', 'WHITE', 'Double blink', '100ms on, 100ms off,\n100ms on, 700ms off', 'Connecting. Please wait.'],
        ['4', 'Awaiting Code', 'WHITE', 'Solid ON', 'Constant', 'Enter the code. Your turn.'],
        ['5', 'Verifying', 'WHITE', 'Rapid blink', '100ms on / 100ms off', 'Checking code...'],
        ['6', 'Success', 'GREEN', '3 flashes → solid', '150ms on/off ×3\nthen constant', 'Paired! Ready for Wi-Fi.'],
        ['7', 'Wi-Fi Setup', 'GREEN', 'Slow blink', '2s on / 0.5s off', 'Connecting to Wi-Fi...'],
        ['8', 'Complete', 'GREEN', 'Solid ON', 'Constant', 'All set. Ready to work.'],
        ['9', 'Failed', 'RED', '3 flashes → off', '500ms on/off ×3\nthen → State 1', 'Error. Try again.'],
        ['10', 'E-STOP', 'RED', 'Rapid flash', '200ms on / 200ms off\nNON-STOP', 'EMERGENCY. Stopped.'],
    ]

    col_w = [8*mm, 23*mm, 16*mm, 28*mm, 35*mm, 43*mm]
    t = Table(data, colWidths=col_w, repeatRows=1)

    # Build style list
    style_cmds = [
        ('BACKGROUND', (0, 0), (-1, 0), BRAND_BLUE),
        ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 7.5),
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 1), (-1, -1), 7),
        ('TEXTCOLOR', (0, 1), (-1, -1), TEXT),
        ('LEADING', (0, 0), (-1, -1), 9),
        # # column bold
        ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
        ('TEXTCOLOR', (0, 1), (0, -1), MUTED),
        # State column
        ('FONTNAME', (1, 1), (1, -1), 'Helvetica-Bold'),
        # Color column colors
        ('TEXTCOLOR', (2, 1), (2, 5), LED_WHITE),  # States 1-5 white
        ('TEXTCOLOR', (2, 6), (2, 8), LED_GREEN),  # States 6-8 green
        ('TEXTCOLOR', (2, 9), (2, 10), LED_RED),    # States 9-10 red
        ('FONTNAME', (2, 1), (2, -1), 'Helvetica-Bold'),
        # Alternating rows
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [BG_CARD, BG_SURFACE]),
        # E-Stop row highlight
        ('BACKGROUND', (0, -1), (-1, -1), HexColor('#1A0808')),
        ('TEXTCOLOR', (0, -1), (-1, -1), LED_RED),
        ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
        # Grid
        ('GRID', (0, 0), (-1, -1), 0.4, HexColor('#1E1E1E')),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 5),
        ('RIGHTPADDING', (0, 0), (-1, -1), 4),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ]
    t.setStyle(TableStyle(style_cmds))
    story.append(t)
    story.append(Spacer(1, 3*mm))

    # State flow
    story.append(Paragraph('STATE FLOW', label))
    sm = ParagraphStyle('SM', fontName='Courier', fontSize=6.5, textColor=TEXT, backColor=BG_SURFACE, leading=9, leftIndent=4, rightIndent=4, borderPadding=4)
    story.append(Paragraph(
        '<font color="#E8EAED">POWER ON → </font>'
        '<font color="#E8EAED">[1.White Blink]</font> → '
        '<font color="#E8EAED">[2.White Fast]</font> → '
        '<font color="#E8EAED">[3.White Double]</font> → '
        '<font color="#E8EAED">[4.White Solid]</font> → '
        '<font color="#E8EAED">[5.White Rapid]</font><br/>'
        '  ├─ OK → <font color="#00C853">[6.Green Flash]</font> → '
        '<font color="#00C853">[7.Green Blink]</font> → '
        '<font color="#00C853">[8.Green Solid]</font> → READY<br/>'
        '  └─ FAIL → <font color="#FF3B30">[9.Red Flash]</font> → back to [1]'
        '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
        '<font color="#FF3B30"><b>[10.Red Rapid] = E-STOP, overrides ALL</b></font>', sm))
    story.append(Spacer(1, 3*mm))

    # Notes
    story.append(Paragraph('NOTES', label))
    story.append(Paragraph('• <b>White</b> = robot is working/waiting. <b>Green</b> = something succeeded. <b>Red</b> = something went wrong or emergency.', note))
    story.append(Paragraph('• E-Stop (#10) is HIGHEST PRIORITY — interrupts any pattern immediately. Red rapid flash until cleared.', note))
    story.append(Paragraph('• State 1 is default after power-on. Robot returns to it after failure or 2-min timeout.', note))
    story.append(Paragraph('• Transition from White→Green happens at State 6 (pairing success). This is the key visual "it worked" moment.', note))
    story.append(Paragraph('• Blink timings are approximate — ±50ms acceptable. Pattern distinctness matters more than exact timing.', note))
    story.append(Paragraph('• Hardware coordination needed with Sufyan for LED strip placement and wiring.', note))

    doc.build(story, onFirstPage=draw_bg, onLaterPages=draw_bg)
    print(f'Generated: {out}')

if __name__ == '__main__':
    build()
