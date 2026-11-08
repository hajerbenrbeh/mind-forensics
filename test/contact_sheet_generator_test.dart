import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Generate Contact Sheet for 8 Verified Screens', () async {
    // Load local font for labels
    final fontLoader = FontLoader('Inter');
    final boldFont = File('assets/fonts/Inter-Bold.ttf');
    if (boldFont.existsSync()) {
      fontLoader.addFont(boldFont.readAsBytes().then((b) => ByteData.sublistView(Uint8List.fromList(b))));
      await fontLoader.load();
    }

    final screens = [
      {'file': '01_home_screen_light.png', 'label': '1. Home Screen (Light)'},
      {'file': '02_home_screen_dark.png', 'label': '2. Home Screen (Dark)'},
      {'file': '03_daily_checkin.png', 'label': '3. Daily Check-in'},
      {'file': '04_mood_tracking.png', 'label': '4. Mood Tracking'},
      {'file': '05_ai_companion.png', 'label': '5. AI Companion Hub'},
      {'file': '06_insights_progress.png', 'label': '6. Insights / Progress'},
      {'file': '07_psychological_profile.png', 'label': '7. Psychological Profile'},
      {'file': '08_main_navigation.png', 'label': '8. Main Navigation'},
    ];

    final loadedImages = <ui.Image>[];
    for (final s in screens) {
      final file = File('screenshots/vqa_phase2/${s['file']}');
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      loadedImages.add(frame.image);
    }

    const cardW = 540.0;
    const cardH = 1170.0;
    const pad = 40.0;
    const gap = 30.0;
    const headerH = 120.0;
    const totalW = (cardW * 4) + (gap * 3) + (pad * 2); // 2330
    const totalH = headerH + (cardH * 2) + (gap * 2) + 120.0 + pad; // ~2660

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, totalW, totalH));

    // Background
    final bgPaint = Paint()..color = const Color(0xFF151B19);
    canvas.drawRect(const Rect.fromLTWH(0, 0, totalW, totalH), bgPaint);

    // Header Title
    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'MIND FORENSICS — PHASE 2: VISUAL QUALITY ASSURANCE CONTACT SHEET',
        style: TextStyle(
          color: Color(0xFFF0F2EC),
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(canvas, const Offset(pad, pad));

    // Subtitle
    final subPainter = TextPainter(
      text: const TextSpan(
        text: '8 Core Screens Rendered with Inter Typography, Earth & Sage Palette, and Data Integrity',
        style: TextStyle(
          color: Color(0xFF91AD9A),
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subPainter.paint(canvas, const Offset(pad, pad + 44));

    // Draw 4x2 Grid of Screens
    for (int i = 0; i < loadedImages.length; i++) {
      final img = loadedImages[i];
      final col = i % 4;
      final row = i ~/ 4;

      final x = pad + col * (cardW + gap);
      final y = headerH + row * (cardH + gap + 60);

      // Card Header Label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: screens[i]['label']!,
          style: const TextStyle(
            color: Color(0xFFF0F2EC),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(canvas, Offset(x, y));

      final imgRect = Rect.fromLTWH(x, y + 36, cardW, cardH);

      // Border behind image
      final borderPaint = Paint()
        ..color = const Color(0xFF303E37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      final rrect = RRect.fromRectAndRadius(imgRect, const Radius.circular(20));

      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        imgRect,
        Paint(),
      );
      canvas.restore();

      canvas.drawRRect(rrect, borderPaint);
    }

    final picture = recorder.endRecording();
    final contactSheetImage = await picture.toImage(totalW.toInt(), totalH.toInt());
    final byteData = await contactSheetImage.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // Save contact sheet to all required destinations
    final dests = [
      'screenshots/vqa_phase2/contact_sheet.png',
      r'C:\Users\HAJER\.gemini\antigravity\brain\100c2c6a-b7d8-4885-b5e6-8d8002edd3bd\contact_sheet.png',
      r'C:\Users\HAJER\.gemini\antigravity\brain\100c2c6a-b7d8-4885-b5e6-8d8002edd3bd\screenshots\contact_sheet.png',
    ];

    for (final dest in dests) {
      final file = File(dest);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(pngBytes);
    }
  });
}

