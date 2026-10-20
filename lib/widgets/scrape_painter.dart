import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/game_models.dart';

class ScrapePainter extends CustomPainter {
  final ui.Image cleanImage;
  final List<ui.Image> stageDirtyImages;
  final List<DirtLayerConfig> dirtStages;
  final int currentStageIndex;
  final List<ScrapeStroke> strokes;
  final List<ScrapeParticle> particles;
  final bool isLevelCompleted;
  final bool isShowingBefore;
  final double shineProgress;
  final Offset? activeFingerPos;
  final ScraperTool activeTool;
  final double effectiveBrushSize;
  final double toolTiltAngle;
  final double dirtOpacity;
  final ToolSkin activeSkin;
  final bool isFeverActive;

  ScrapePainter({
    required this.cleanImage,
    required this.stageDirtyImages,
    required this.dirtStages,
    required this.currentStageIndex,
    required this.strokes,
    required this.particles,
    required this.isLevelCompleted,
    required this.isShowingBefore,
    required this.shineProgress,
    required this.activeFingerPos,
    required this.activeTool,
    required this.effectiveBrushSize,
    required this.toolTiltAngle,
    required this.dirtOpacity,
    required this.activeSkin,
    required this.isFeverActive,
  });

  static const List<double> _polishFoamMatrix = [
    0.3,
    0.3,
    0.4,
    0,
    130,
    0.3,
    0.4,
    0.4,
    0,
    155,
    0.4,
    0.4,
    0.6,
    0,
    185,
    0,
    0,
    0,
    0.85,
    0,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Rect canvasRect = Offset.zero & size;

    final Rect cleanSrcRect = Rect.fromLTWH(
      0,
      0,
      cleanImage.width.toDouble(),
      cleanImage.height.toDouble(),
    );

    canvas.drawImageRect(
      cleanImage,
      cleanSrcRect,
      canvasRect,
      Paint()..filterQuality = FilterQuality.medium,
    );

    if (isLevelCompleted && !isShowingBefore) {
      if (shineProgress > 0.0 && shineProgress < 1.0) {
        canvas.saveLayer(canvasRect, Paint());
        canvas.drawImageRect(cleanImage, cleanSrcRect, canvasRect, Paint());

        final double slide = (shineProgress * 2.4) - 0.7;
        final Gradient gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: [
            (slide - 0.18).clamp(0.0, 1.0),
            slide.clamp(0.0, 1.0),
            (slide + 0.18).clamp(0.0, 1.0),
          ],
        );

        final Paint shinePaint = Paint()
          ..shader = gradient.createShader(canvasRect)
          ..blendMode = BlendMode.srcATop;

        canvas.drawRect(canvasRect, shinePaint);
        canvas.restore();
      }
      return;
    }

    if (stageDirtyImages.isEmpty) return;

    final int safeIndex = currentStageIndex.clamp(
      0,
      stageDirtyImages.length - 1,
    );

    if (!isShowingBefore && safeIndex + 1 < stageDirtyImages.length) {
      final ui.Image nextDirtyImg = stageDirtyImages[safeIndex + 1];
      final bool nextIsPolish = dirtStages[safeIndex + 1].isPolishStage;
      _drawMaskedDirtLayer(
        canvas,
        canvasRect,
        cleanSrcRect,
        nextDirtyImg,
        opacity: nextIsPolish ? 0.65 : dirtOpacity,
        applyEraseStrokes: false,
        isPolishFoam: nextIsPolish,
      );
    }

    final ui.Image currentDirtyImg = isShowingBefore
        ? stageDirtyImages.first
        : stageDirtyImages[safeIndex];
    final bool currentIsPolish =
        !isShowingBefore && dirtStages[safeIndex].isPolishStage;
    _drawMaskedDirtLayer(
      canvas,
      canvasRect,
      cleanSrcRect,
      currentDirtyImg,
      opacity: currentIsPolish
          ? 0.68
          : ((!isShowingBefore && safeIndex + 1 < stageDirtyImages.length)
                ? 0.94
                : dirtOpacity),
      applyEraseStrokes: !isShowingBefore,
      isPolishFoam: currentIsPolish,
    );

    // 4. PARÇACIKLAR VE YÜKSELEN BUHAR BULUTLARI
    final Paint particlePaint = Paint()..style = PaintingStyle.fill;
    final Paint steamCloudPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (final p in particles) {
      if (p.isSteamCloud) {
        // Buhar bulutu: Yumuşak kenarlı, yarı saydam duman halkası!
        steamCloudPaint.color = p.color.withValues(
          alpha: (p.life * 0.55).clamp(0.0, 1.0),
        );
        canvas.drawCircle(p.position, p.size * 0.65, steamCloudPaint);
      } else {
        particlePaint.color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0));
        if (p.isSquare) {
          canvas.drawRect(
            Rect.fromCenter(center: p.position, width: p.size, height: p.size),
            particlePaint,
          );
        } else {
          canvas.drawCircle(p.position, p.size * 0.5, particlePaint);
        }
      }
    }

    if (activeFingerPos != null && !isLevelCompleted) {
      _drawRealisticTool(canvas, activeFingerPos!);
    }
  }

  void _drawMaskedDirtLayer(
    Canvas canvas,
    Rect canvasRect,
    Rect cleanSrcRect,
    ui.Image dirtyImg, {
    required double opacity,
    required bool applyEraseStrokes,
    required bool isPolishFoam,
  }) {
    final Rect dirtySrcRect = Rect.fromLTWH(
      0,
      0,
      dirtyImg.width.toDouble(),
      dirtyImg.height.toDouble(),
    );

    canvas.saveLayer(
      canvasRect,
      Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
    );

    canvas.drawImageRect(
      cleanImage,
      cleanSrcRect,
      canvasRect,
      Paint()..filterQuality = FilterQuality.medium,
    );

    canvas.saveLayer(canvasRect, Paint()..blendMode = BlendMode.srcIn);

    final Paint texPaint = Paint()..filterQuality = FilterQuality.medium;
    if (isPolishFoam) {
      texPaint.colorFilter = const ColorFilter.matrix(_polishFoamMatrix);
    }

    canvas.drawImageRect(dirtyImg, dirtySrcRect, canvasRect, texPaint);
    canvas.restore();

    if (applyEraseStrokes) {
      final Paint erasePaint = Paint()
        ..blendMode = BlendMode.dstOut
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;

      for (final stroke in strokes) {
        erasePaint
          ..strokeWidth = stroke.brushSize
          ..strokeCap = stroke.strokeCap;
        canvas.drawPath(stroke.path, erasePaint);
      }
    }

    canvas.restore();
  }

  void _drawRealisticTool(Canvas canvas, Offset pos) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    final double w = effectiveBrushSize;

    if (isFeverActive) {
      canvas.drawCircle(
        Offset.zero,
        w * 0.55,
        Paint()
          ..color = Colors.deepOrangeAccent.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawCircle(
        Offset.zero,
        w * 0.5,
        Paint()
          ..color = Colors.amberAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    if (activeSkin.customSparkColors != null) {
      canvas.drawCircle(
        const Offset(0, 35),
        w * 0.65,
        Paint()
          ..color = activeSkin.trimColor.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    if (activeTool.id == 'sponge') {
      // 1. ISLAK TEMİZLİK SÜNGERİ
      canvas.rotate(toolTiltAngle);
      final RRect spongeBody = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(0, 12),
          width: w * 1.05,
          height: 56,
        ),
        const Radius.circular(14),
      );
      canvas.drawRRect(
        spongeBody,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00E676), Color(0xFFFFEE58), Color(0xFFFBC02D)],
            stops: [0.0, 0.28, 1.0],
          ).createShader(spongeBody.outerRect),
      );
    } else if (activeTool.id == 'polish') {
      // 2. PARLATICI CİLA SPREYİ ŞİŞESİ & PÜSKÜRTME BAŞLIĞI
      canvas.rotate(toolTiltAngle * 0.7);
      // Püskürtülen parlak cila sisi
      canvas.drawCircle(
        Offset.zero,
        w * 0.55,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      // Beyaz sprey tetik ve boyun kısmı
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-10, 4, 20, 18),
          const Radius.circular(4),
        ),
        Paint()..color = Colors.white,
      );
      // Sprey şişesi gövdesi
      final RRect bottle = RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.38, 20, w * 0.76, 76),
        const Radius.circular(16),
      );
      canvas.drawRRect(
        bottle,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
          ).createShader(bottle.outerRect),
      );
    } else if (activeTool.id == 'steam') {
      // ==========================================================
      // 3. GERÇEKÇİ BASINÇLI BUHAR MAKİNESİ (STEAM CLEANER GUN)
      // ==========================================================
      canvas.rotate(toolTiltAngle * 0.8);

      // A) Namludan Yüzeye Püsküren Basınçlı Sıcak Buhar Konisi (Steam Jet)
      final Path steamJetCone = Path()
        ..moveTo(-w * 0.22, 16)
        ..lineTo(-w * 0.58, -14)
        ..quadraticBezierTo(0, -26, w * 0.58, -14)
        ..lineTo(w * 0.22, 16)
        ..close();

      canvas.drawPath(
        steamJetCone,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.white.withValues(alpha: 0.85),
              const Color(0xFFE0F7FA).withValues(alpha: 0.45),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(-w * 0.6, -26, w * 1.2, 42))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // B) 3 Delikli Çelik Buhar Difüzör Başlığı (y = 14 ile 28 arası)
      final RRect nozzleHead = RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.36, 14, w * 0.72, 14),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        nozzleHead,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF78909C), Color(0xFFECEFF1), Color(0xFF546E7A)],
          ).createShader(nozzleHead.outerRect),
      );
      // Buhar çıkış delikleri
      final Paint holePaint = Paint()..color = const Color(0xFF263238);
      canvas.drawCircle(Offset(-w * 0.20, 18), 2.5, holePaint);
      canvas.drawCircle(const Offset(0, 18), 2.5, holePaint);
      canvas.drawCircle(Offset(w * 0.20, 18), 2.5, holePaint);

      // C) Buhar Makinesi Sarı/Siyah Sanayi Gövdesi (y = 28 ile 96 arası)
      final RRect machineBody = RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.32, 28, w * 0.64, 68),
        const Radius.circular(14),
      );
      canvas.drawRRect(
        machineBody,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFFD600), Color(0xFFFFAB00), Color(0xFFFF6F00)],
          ).createShader(machineBody.outerRect),
      );

      // D) Gövde Üzerindeki Yuvarlak Basınç Göstergesi (Manometre Saati)
      const Offset gaugeCenter = Offset(0, 54);
      canvas.drawCircle(
        gaugeCenter,
        12,
        Paint()..color = const Color(0xFF212121),
      );
      canvas.drawCircle(gaugeCenter, 9.5, Paint()..color = Colors.white);
      // Kırmızı basınç ibresi
      canvas.drawLine(
        gaugeCenter,
        const Offset(5, 48),
        Paint()
          ..color = Colors.redAccent
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );

      // E) Alttan Çıkan Kalın Siyah Buhar Hortumu (y = 96 ile 122 arası)
      canvas.drawLine(
        const Offset(0, 96),
        const Offset(0, 122),
        Paint()
          ..color = const Color(0xFF263238)
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
    } else if (activeTool.id == 'razor' || activeTool.id == 'grinder') {
      // 4 & 5. ÇELİK JİLET SPATULA VE AĞIR ZIMPARA
      canvas.rotate(toolTiltAngle * 0.8);

      canvas.drawRect(
        Rect.fromLTWH(-w * 0.5 + 5, 4, w, 90),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      final Rect bladeRect = Rect.fromLTWH(-w * 0.5, -10, w, 20);
      canvas.drawRect(
        bladeRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFB0BEC5), Color(0xFF78909C)],
            stops: [0.0, 0.25, 1.0],
          ).createShader(bladeRect),
      );

      final Path neckPath = Path()
        ..moveTo(-w * 0.52, 10)
        ..lineTo(w * 0.52, 10)
        ..lineTo(w * 0.24, 46)
        ..lineTo(-w * 0.24, 46)
        ..close();

      canvas.drawPath(
        neckPath,
        Paint()
          ..shader = LinearGradient(
            colors: [
              activeSkin.trimColor,
              Colors.white,
              const Color(0xFF455A64),
            ],
          ).createShader(Rect.fromLTWH(-w * 0.52, 10, w * 1.04, 36)),
      );

      final RRect gripRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.26, 44, w * 0.52, 74),
        const Radius.circular(14),
      );
      canvas.drawRRect(
        gripRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: activeSkin.handleGradient,
          ).createShader(gripRect.outerRect),
      );
    } else if (activeTool.id == 'mega') {
      // 6. MEGA PLAZMA LAZERİ
      final double r = w * 0.5;

      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
      canvas.drawCircle(
        Offset.zero,
        r * 0.85,
        Paint()
          ..color = const Color(0xFF18FFFF).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      const Offset emitterTip = Offset(0, -72);

      canvas.drawLine(
        emitterTip,
        Offset.zero,
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.75)
          ..strokeWidth = 18.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      canvas.drawLine(
        emitterTip,
        Offset.zero,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawCircle(Offset.zero, 12.0, Paint()..color = Colors.white);

      final Path nozzlePath = Path()
        ..moveTo(-26, -135)
        ..lineTo(26, -135)
        ..lineTo(22, -92)
        ..lineTo(12, -70)
        ..lineTo(-12, -70)
        ..lineTo(-22, -92)
        ..close();

      canvas.drawPath(
        nozzlePath,
        Paint()
          ..shader = LinearGradient(
            colors: activeSkin.handleGradient,
          ).createShader(const Rect.fromLTWH(-26, -135, 52, 65)),
      );

      final Paint neonRingPaint = Paint()
        ..color = activeSkin.trimColor
        ..strokeWidth = 3.0;
      canvas.drawLine(
        const Offset(-23, -115),
        const Offset(23, -115),
        neonRingPaint,
      );
      canvas.drawLine(
        const Offset(-20, -98),
        const Offset(20, -98),
        neonRingPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ScrapePainter oldDelegate) {
    return true;
  }
}
