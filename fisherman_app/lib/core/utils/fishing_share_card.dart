import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class FishingShareCard {
  static Future<void> share({
    required String title,
    required String subtitle,
    required List<String> details,
    required String message,
  }) async {
    final image = await render(title, subtitle, details);
    await SharePlus.instance.share(
      ShareParams(
        title: title,
        text: message,
        files: [XFile.fromData(image, mimeType: 'image/png')],
        fileNameOverrides: ['fisherman-share.png'],
      ),
    );
  }

  static Future<Uint8List> render(
    String title,
    String subtitle,
    List<String> details,
  ) async {
    const width = 1080.0;
    const height = 1350.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF0F172A)],
        ).createShader(const Rect.fromLTWH(0, 0, width, height)),
    );
    canvas.drawCircle(
      const Offset(1000, 110),
      250,
      Paint()..color = const Color(0x22FFFFFF),
    );
    canvas.drawCircle(
      const Offset(35, 1220),
      300,
      Paint()..color = const Color(0x16FFFFFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(56, 170, 968, 1000),
        const Radius.circular(42),
      ),
      Paint()..color = const Color(0xF5FFFFFF),
    );

    _drawText(
      canvas,
      '钓鱼佬 · FisherMan',
      108,
      78,
      880,
      45,
      const Color(0xFFFFFFFF),
    );
    _drawText(
      canvas,
      title,
      112,
      235,
      856,
      64,
      const Color(0xFF0F172A),
      bold: true,
    );
    _drawText(canvas, subtitle, 112, 338, 856, 37, const Color(0xFF475569));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(112, 430, 856, 4),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF14B8A6),
    );

    var y = 492.0;
    for (final detail in details.take(6)) {
      _drawText(canvas, detail, 112, y, 856, 38, const Color(0xFF1E293B));
      y += 86;
    }
    _drawText(
      canvas,
      '记录每一次出钓，分享每一份渔获',
      112,
      1055,
      856,
      30,
      const Color(0xFF64748B),
    );
    _drawText(
      canvas,
      'FisherMan',
      112,
      1195,
      856,
      34,
      const Color(0xFFFFFFFF),
      bold: true,
    );

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(width.toInt(), height.toInt());
    final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
    rendered.dispose();
    if (data == null) {
      throw StateError('无法生成分享图片');
    }
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  static void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    double maxWidth,
    double fontSize,
    Color color, {
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(x, y));
  }
}
