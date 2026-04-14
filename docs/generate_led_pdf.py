#!/usr/bin/env python3
"""Generate branded LED Pairing Spec PDF — one page per state."""

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm, cm
from reportlab.lib.colors import HexColor, Color, white, black
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Image
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.platypus.flowables import HRFlowable
import os

# Brand colors
BRAND_BLUE = HexColor('#3B5EE8')
BRAND_PURPLE = HexColor('#8B45B5')
BRAND_MAGENTA = HexColor('#D63384')
BRAND_RED = HexColor('#EF3350')
BRAND_PINK = HexColor('#F5758C')
BRAND_SILVER = HexColor('#C8CDD5')
BRAND_AMBER = HexColor('#D4A012')
SAFETY_RED = HexColor('#FF3B30')
SAFETY_YELLOW = HexColor('#FFD600')
BG_PRIMARY = HexColor('#0A0C10')
BG_CARD = HexColor('#151820')
BG_SURFACE = HexColor('#0D0F14')
TEXT_PRIMARY = HexColor('#E8EAED')
TEXT_SECONDARY = HexColor('#8B929E')
TEXT_MUTED = HexColor('#555D6E')
WHITE = HexColor('#FFFFFF')

# Styles
TITLE_STYLE = ParagraphStyle('Title', fontName='Helvetica-Bold', fontSize=32, textColor=TEXT_PRIMARY, alignment=TA_CENTER, spaceAfter=8)
SUBTITLE_STYLE = ParagraphStyle('Subtitle', fontName='Helvetica', fontSize=14, textColor=TEXT_SECONDARY, alignment=TA_CENTER, spaceAfter=4)
STATE_NUM_STYLE = ParagraphStyle('StateNum', fontName='Helvetica-Bold', fontSize=14, textColor=BRAND_PURPLE, spaceAfter=4)
STATE_TITLE_STYLE = ParagraphStyle('StateTitle', fontName='Helvetica-Bold', fontSize=28, textColor=TEXT_PRIMARY, spaceAfter=12)
LABEL_STYLE = ParagraphStyle('Label', fontName='Helvetica-Bold', fontSize=9, textColor=TEXT_MUTED, spaceAfter=2, spaceBefore=14)
BODY_STYLE = ParagraphStyle('Body', fontName='Helvetica', fontSize=11, textColor=TEXT_PRIMARY, leading=16, spaceAfter=4)
BODY_MUTED = ParagraphStyle('BodyMuted', fontName='Helvetica', fontSize=10, textColor=TEXT_SECONDARY, leading=14, spaceAfter=4)
FOOTER_STYLE = ParagraphStyle('Footer', fontName='Helvetica', fontSize=8, textColor=TEXT_MUTED, alignment=TA_CENTER)

# LED States data
LED_STATES = [
    {
        'num': '01',
        'name': 'DISCOVERABLE',
        'color': BRAND_BLUE,
        'color_name': 'Brand Blue',
        'color_hex': '#3B5EE8',
        'when': 'Robot is powered on and not yet paired.\nApp is on BLE Scan screen.',
        'app_screen': '02a — Find Your Robot',
        'pattern': 'Slow breathing pulse',
        'pattern_desc': 'Brightness fades smoothly in and out.\n3-second cycle (1.5s in, 1.5s out)\nBrightness: 20% → 80% → 20%',
        'purpose': '"I\'m here, I\'m ready to be found."\nThe slow pulse is calm and non-urgent — the robot is waiting patiently.',
        'trigger': 'Default state when BLE advertising is active and no device is connected.',
    },
    {
        'num': '02',
        'name': 'FOUND',
        'color': BRAND_BLUE,
        'color_name': 'Brand Blue',
        'color_hex': '#3B5EE8',
        'when': 'App has detected the robot via BLE scan.\nRobot appears in the discovered list.',
        'app_screen': '02a — Find Your Robot (robot card visible)',
        'pattern': 'Faster breathing pulse',
        'pattern_desc': 'Same fade pattern, quicker rhythm.\n1.5-second cycle (0.75s in, 0.75s out)\nBrightness: 30% → 100% → 30%',
        'purpose': '"Yes, I see you too."\nHelps confirm the right robot if multiple are nearby.',
        'trigger': 'BLE scan response sent to a device.',
    },
    {
        'num': '03',
        'name': 'PAIRING IN PROGRESS',
        'color': BRAND_PURPLE,
        'color_name': 'Brand Purple',
        'color_hex': '#8B45B5',
        'when': 'User tapped "Pair This Robot".\nBLE connection is being established.',
        'app_screen': '02b — Pairing',
        'pattern': 'Rapid double-flash',
        'pattern_desc': 'Two quick flashes then a pause, repeating.\nFlash 100ms on, 100ms off, 100ms on, 600ms off\n1-second total cycle. Sharp on/off, not faded.',
        'purpose': '"I\'m processing the connection."\nPurple differentiates from discovery blue.\nDouble-flash is distinct and unmistakable.',
        'trigger': 'BLE connection established (GATT connection callback).',
    },
    {
        'num': '04',
        'name': 'AWAITING CODE',
        'color': BRAND_AMBER,
        'color_name': 'Brand Amber',
        'color_hex': '#D4A012',
        'when': 'BLE connected. Robot displays its 6-digit code.\nApp shows the code entry screen.',
        'app_screen': '02b — Pairing (code entry fields)',
        'pattern': 'Steady solid glow',
        'pattern_desc': 'No animation. Constant brightness.\n70% steady. No change until code entered.\n2-minute timeout.',
        'purpose': '"I\'m waiting for you to enter the code."\nAmber is warm and patient.\nSteady means "your turn."',
        'trigger': 'Pairing code generated and sent via BLE characteristic.',
    },
    {
        'num': '05',
        'name': 'CODE VERIFICATION',
        'color': BRAND_MAGENTA,
        'color_name': 'Brand Magenta',
        'color_hex': '#D63384',
        'when': 'User entered the code. Robot is verifying.',
        'app_screen': '02b — Pairing (loading after code)',
        'pattern': 'Fast chase sweep',
        'pattern_desc': 'Lights sweep left to right across strip.\nFull sweep in 500ms, repeating.\nLeading LED 100%, trailing fade to 20%.',
        'purpose': '"I\'m checking..."\nChase pattern conveys computation.\nBrief — lasts only 1-2 seconds.',
        'trigger': 'Code received via BLE write. Verification called.',
    },
    {
        'num': '06',
        'name': 'PAIRING SUCCESS',
        'color': BRAND_BLUE,
        'color_name': 'Brand Blue → White',
        'color_hex': '#3B5EE8 → #E8EAED',
        'when': 'Code verified. Secure BLE link established.',
        'app_screen': '02c — Wi-Fi Setup (success banner)',
        'pattern': 'Triple celebration flash → solid',
        'pattern_desc': 'Three quick flashes (blue), transition to solid white.\nFlash 150ms on / 100ms off × 3\nThen 500ms transition to solid white at 60%.',
        'purpose': '"Success!"\nTriple-flash is a clear celebration.\nWhite means "paired and ready."',
        'trigger': 'Code verification returns True. State → PAIRED.',
    },
    {
        'num': '07',
        'name': 'WIFI CONNECTING',
        'color': BRAND_BLUE,
        'color_name': 'Brand Blue',
        'color_hex': '#3B5EE8',
        'when': 'Robot connecting to user\'s home Wi-Fi.',
        'app_screen': '02c — Wi-Fi Setup (connecting)',
        'pattern': 'Slow wave ripple',
        'pattern_desc': 'Brightness ripples across strip like a wave.\nWave traverses full strip in 2 seconds.\nPeak 80%, trough 20%.',
        'purpose': '"I\'m connecting to your network."\nWave suggests data flowing.\nDistinct from breathing pulse.',
        'trigger': 'Wi-Fi credentials received. Connection attempt started.',
    },
    {
        'num': '08',
        'name': 'SETUP COMPLETE',
        'color': BRAND_BLUE,  # gradient actually
        'color_name': 'Brand Gradient → White',
        'color_hex': 'Blue→Purple→Magenta→Red→Pink',
        'when': 'Wi-Fi connected (or skipped). Fully paired.',
        'app_screen': '02d — Setup Complete',
        'pattern': 'Brand gradient sweep → solid white',
        'pattern_desc': 'Full brand spectrum sweeps across strip.\n2-second sweep (one pass left to right).\nSettles to solid white at 50%.',
        'purpose': 'The grand finale. Brand gradient sweep\nmirrors the logo. "I\'m fully ready to work."\nSolid white = idle/ready going forward.',
        'trigger': 'Wi-Fi confirmed or skip received. State → READY.',
    },
    {
        'num': '09',
        'name': 'PAIRING FAILED',
        'color': SAFETY_RED,
        'color_name': 'Safety Red',
        'color_hex': '#FF3B30',
        'when': 'Code wrong, BLE dropped, or 2-min timeout.',
        'app_screen': 'Error dialog / return to BLE Scan',
        'pattern': 'Three slow red pulses → discoverable',
        'pattern_desc': 'Pulse 500ms on / 300ms off × 3 (2.4s total).\n1s pause. Then resume State 1 (discoverable).\n100% brightness — unmissable.',
        'purpose': '"Something went wrong — let\'s try again."\nReturns to discoverable automatically.\nNo power cycle needed.',
        'trigger': 'Verification False, BLE disconnect, or timeout.',
    },
    {
        'num': '10',
        'name': 'E-STOP ACTIVE',
        'color': SAFETY_RED,
        'color_name': 'Safety Red + Yellow',
        'color_hex': '#FF3B30 / #FFD600',
        'when': 'Emergency stop triggered from any source.',
        'app_screen': 'Any screen — E-Stop activated',
        'pattern': 'Rapid red/yellow alternating flash',
        'pattern_desc': '200ms red / 200ms yellow, continuous.\n100% brightness. Visible from 20+ meters.\nOverrides ALL other states. HIGHEST PRIORITY.',
        'purpose': 'SAFETY CRITICAL.\nMatches industrial E-Stop convention.\nImpossible to ignore or mistake.',
        'trigger': 'E-Stop via BLE, WiFi, MQTT, or physical button.',
    },
]


def draw_background(canvas, doc):
    """Dark background on every page."""
    canvas.saveState()
    canvas.setFillColor(BG_PRIMARY)
    canvas.rect(0, 0, A4[0], A4[1], fill=True, stroke=False)

    # Footer
    canvas.setFont('Helvetica', 8)
    canvas.setFillColor(TEXT_MUTED)
    canvas.drawCentredString(A4[0] / 2, 15 * mm, f'Page {doc.page}')
    canvas.drawRightString(A4[0] - 20 * mm, 15 * mm, 'Confidential — Internal Use Only')
    canvas.drawString(20 * mm, 15 * mm, 'ChoreRobotics')

    # Brand gradient line at top (thin)
    gradient_colors = [BRAND_BLUE, BRAND_PURPLE, BRAND_MAGENTA, BRAND_RED, BRAND_PINK, BRAND_SILVER]
    bar_width = (A4[0] - 40 * mm) / len(gradient_colors)
    for i, c in enumerate(gradient_colors):
        canvas.setFillColor(c)
        canvas.setStrokeColor(c)
        canvas.rect(20 * mm + i * bar_width, A4[1] - 12 * mm, bar_width, 2 * mm, fill=True, stroke=False)

    canvas.restoreState()


def draw_cover(canvas, doc):
    """Cover page with dark bg and branding."""
    canvas.saveState()
    canvas.setFillColor(BG_PRIMARY)
    canvas.rect(0, 0, A4[0], A4[1], fill=True, stroke=False)

    # Large gradient bar
    gradient_colors = [BRAND_BLUE, BRAND_PURPLE, BRAND_MAGENTA, BRAND_RED, BRAND_PINK, BRAND_SILVER]
    bar_width = A4[0] / len(gradient_colors)
    y = A4[1] * 0.58
    for i, c in enumerate(gradient_colors):
        canvas.setFillColor(c)
        canvas.rect(i * bar_width, y, bar_width, 4 * mm, fill=True, stroke=False)

    # Footer
    canvas.setFont('Helvetica', 8)
    canvas.setFillColor(TEXT_MUTED)
    canvas.drawCentredString(A4[0] / 2, 20 * mm, 'CONFIDENTIAL — INTERNAL USE ONLY')

    canvas.restoreState()


def build_color_swatch(color, size=14*mm):
    """Create a colored square as a table cell."""
    t = Table([['']], colWidths=[size], rowHeights=[size])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, 0), color),
        ('ROUNDEDCORNERS', [4, 4, 4, 4]),
        ('BOX', (0, 0), (0, 0), 0.5, HexColor('#333333')),
    ]))
    return t


def build_pdf():
    output_path = os.path.join(os.path.dirname(__file__), 'ChoreRobotics_LED_Pairing_Spec.pdf')

    doc = SimpleDocTemplate(
        output_path,
        pagesize=A4,
        leftMargin=20 * mm,
        rightMargin=20 * mm,
        topMargin=20 * mm,
        bottomMargin=25 * mm,
    )

    story = []

    # ── COVER PAGE ──
    story.append(Spacer(1, 80 * mm))

    # Try to add logo
    logo_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'logo', 'chore-robots-logo.png')
    if os.path.exists(logo_path):
        story.append(Image(logo_path, width=60 * mm, height=40 * mm))
        story.append(Spacer(1, 10 * mm))

    story.append(Paragraph('LED Behavior Specification', TITLE_STYLE))
    story.append(Spacer(1, 4 * mm))
    story.append(Paragraph('BLE Pairing Visual Feedback Guide', SUBTITLE_STYLE))
    story.append(Spacer(1, 8 * mm))

    version_style = ParagraphStyle('Version', fontName='Helvetica', fontSize=11, textColor=TEXT_MUTED, alignment=TA_CENTER)
    story.append(Paragraph('Version 1.0 — March 2026', version_style))
    story.append(Spacer(1, 4 * mm))
    story.append(Paragraph('For Hardware, Firmware & App Teams', version_style))
    story.append(Spacer(1, 15 * mm))

    # Quick reference table on cover
    summary_data = [['State', 'Color', 'Pattern']]
    for s in LED_STATES:
        summary_data.append([f"{s['num']}. {s['name']}", s['color_name'], s['pattern']])

    summary_table = Table(summary_data, colWidths=[60 * mm, 45 * mm, 55 * mm])
    summary_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), BRAND_BLUE),
        ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 9),
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 1), (-1, -1), 8),
        ('TEXTCOLOR', (0, 1), (-1, -1), TEXT_PRIMARY),
        ('BACKGROUND', (0, 1), (-1, -1), BG_CARD),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [BG_CARD, BG_SURFACE]),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#222222')),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ]))
    story.append(summary_table)
    story.append(PageBreak())

    # ── ONE PAGE PER STATE ──
    for state in LED_STATES:
        # State number
        story.append(Paragraph(f'STATE {state["num"]}', STATE_NUM_STYLE))
        # State name
        story.append(Paragraph(state['name'], STATE_TITLE_STYLE))

        # Gradient divider
        story.append(HRFlowable(
            width='100%', thickness=2,
            color=state['color'],
            spaceAfter=10
        ))

        # Color swatch + info row
        info_data = [[
            build_color_swatch(state['color']),
            Paragraph(f'<b>{state["color_name"]}</b><br/><font color="#8B929E" size="9">{state["color_hex"]}</font>',
                      ParagraphStyle('ColorInfo', fontName='Helvetica', fontSize=12, textColor=TEXT_PRIMARY, leading=16)),
        ]]
        info_table = Table(info_data, colWidths=[18 * mm, 140 * mm])
        info_table.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('LEFTPADDING', (0, 0), (-1, -1), 0),
        ]))
        story.append(info_table)
        story.append(Spacer(1, 6 * mm))

        # When
        story.append(Paragraph('WHEN', LABEL_STYLE))
        for line in state['when'].split('\n'):
            story.append(Paragraph(line, BODY_STYLE))

        # App Screen
        story.append(Paragraph('APP SCREEN', LABEL_STYLE))
        story.append(Paragraph(state['app_screen'], BODY_STYLE))

        # Pattern
        story.append(Paragraph('LED PATTERN', LABEL_STYLE))
        story.append(Paragraph(f'<b>{state["pattern"]}</b>', BODY_STYLE))
        for line in state['pattern_desc'].split('\n'):
            story.append(Paragraph(line, BODY_MUTED))

        # Purpose
        story.append(Paragraph('PURPOSE', LABEL_STYLE))
        for line in state['purpose'].split('\n'):
            story.append(Paragraph(line, BODY_STYLE))

        # Script Trigger
        story.append(Paragraph('SCRIPT TRIGGER', LABEL_STYLE))
        trigger_style = ParagraphStyle('Trigger', fontName='Courier', fontSize=10, textColor=BRAND_BLUE,
                                        backColor=BG_SURFACE, leading=14, spaceBefore=4, spaceAfter=4,
                                        leftIndent=8, rightIndent=8, borderPadding=6)
        story.append(Paragraph(state['trigger'], trigger_style))

        story.append(PageBreak())

    # ── STATE MACHINE PAGE ──
    story.append(Paragraph('STATE MACHINE', STATE_NUM_STYLE))
    story.append(Paragraph('LED State Transitions', STATE_TITLE_STYLE))
    story.append(HRFlowable(width='100%', thickness=2, color=BRAND_BLUE, spaceAfter=10))

    sm_text = """
POWER ON → [1. DISCOVERABLE] → BLE scan → [2. FOUND] → Pair tap → [3. PAIRING]
→ Connected → [4. AWAITING CODE] → Code entered → [5. VERIFICATION]
→ Success → [6. PAIRING SUCCESS] → [7. WIFI CONNECTING] → [8. SETUP COMPLETE]
→ Failure → [9. PAIRING FAILED] → back to [1. DISCOVERABLE]

[10. E-STOP] can be triggered from ANY state. HIGHEST PRIORITY.
"""
    sm_style = ParagraphStyle('SM', fontName='Courier', fontSize=10, textColor=TEXT_PRIMARY,
                               backColor=BG_SURFACE, leading=16, leftIndent=8, rightIndent=8, borderPadding=10)
    story.append(Paragraph(sm_text.replace('\n', '<br/>'), sm_style))

    story.append(Spacer(1, 10 * mm))
    story.append(Paragraph('HARDWARE REQUIREMENTS', LABEL_STYLE))

    hw_data = [
        ['Requirement', 'Specification'],
        ['LED Type', 'WS2812B / SK6812 (addressable RGB)'],
        ['LED Count', '30-60 LEDs across front accent bar'],
        ['Controller', 'Jetson GPIO (PWM) or SPI via NeoPixel library'],
        ['Power', '5V, ~1A max (60 LEDs at full white)'],
        ['Viewing Distance', 'Patterns distinguishable from 5m in daylight'],
        ['Weatherproofing', 'IP65 LED strip + sealed housing'],
    ]
    hw_table = Table(hw_data, colWidths=[55 * mm, 105 * mm])
    hw_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), BRAND_PURPLE),
        ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('TEXTCOLOR', (0, 1), (-1, -1), TEXT_PRIMARY),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [BG_CARD, BG_SURFACE]),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#222222')),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(hw_table)

    # Build
    doc.build(story, onFirstPage=draw_cover, onLaterPages=draw_background)
    print(f'Generated: {output_path}')
    print(f'Pages: cover + {len(LED_STATES)} states + state machine = {len(LED_STATES) + 2}')


if __name__ == '__main__':
    build_pdf()
