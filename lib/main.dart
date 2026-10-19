import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SatisfyingScraperApp());
}

// ============================================================================
// GERÇEK KİR KATMANI VE DOKU VARYASYONLARI
// ============================================================================
class DirtLayerConfig {
  final String name;
  final String assetPath;
  final List<Color> flakeColors;

  const DirtLayerConfig({
    required this.name,
    required this.assetPath,
    required this.flakeColors,
  });

  static const List<DirtLayerConfig> configs = [
    DirtLayerConfig(
      name: 'Kızıl Pas',
      assetPath: 'assets/images/kirli_pas.png',
      flakeColors: [
        Color(0xFF8B4513),
        Color(0xFFA0522D),
        Color(0xFFD2691E),
        Color(0xFF5C3A21),
      ],
    ),
    DirtLayerConfig(
      name: 'Kurumuş Çamur',
      assetPath: 'assets/images/kirli_camur.png',
      flakeColors: [
        Color(0xFF4E342E),
        Color(0xFF6D4C41),
        Color(0xFF8D6E63),
        Color(0xFF3E2723),
      ],
    ),
    DirtLayerConfig(
      name: 'Kahve Tortusu',
      assetPath: 'assets/images/kirli_kahve.png',
      flakeColors: [
        Color(0xFF3E2723),
        Color(0xFF5D4037),
        Color(0xFF795548),
        Color(0xFFA1887F),
      ],
    ),
    DirtLayerConfig(
      name: 'Ağır Oksit & Pas',
      assetPath: 'assets/images/kirli_pas2.png',
      flakeColors: [
        Color(0xFFBF360C),
        Color(0xFFD84315),
        Color(0xFF6D4C41),
        Color(0xFFFF7043),
      ],
    ),
  ];
}

// ============================================================================
// GELİR MODELİ YÖNETİCİSİ
// ============================================================================
class MonetizationManager {
  bool isProUser = false;
  bool isLaserUnlockedForSession = false;

  Future<void> showInterstitialAdIfNeeded(
    BuildContext context,
    int completedLevel,
  ) async {
    if (isProUser) return;
    if (completedLevel % 2 != 0) return;

    await _showSimulatedAdDialog(
      context,
      title: 'REKLAM MOLASI (AdMob / AppLovin)',
      subtitle:
          'Seviye $completedLevel tamamlandı. Geçiş reklamı simüle ediliyor...',
      durationSeconds: 2,
    );
  }

  Future<bool> showRewardedAd(BuildContext context) async {
    if (isProUser) return true;

    final bool? watched = await _showSimulatedAdDialog(
      context,
      title: 'ÖDÜLLÜ VİDEO REKLAM',
      subtitle:
          'MEGA LAZER aracını açmak için 2 saniyelik test reklamı oynatılıyor...',
      durationSeconds: 2,
    );

    if (watched == true) {
      isLaserUnlockedForSession = true;
      return true;
    }
    return false;
  }

  Future<bool> purchaseProPackage(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 600));
    isProUser = true;
    isLaserUnlockedForSession = true;
    return true;
  }

  Future<bool?> _showSimulatedAdDialog(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int durationSeconds,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        int remaining = durationSeconds;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Timer(const Duration(seconds: 1), () {
              if (ctx.mounted && remaining > 0) {
                setDialogState(() => remaining--);
                if (remaining == 0) {
                  Navigator.of(ctx).pop(true);
                }
              }
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(Icons.tv_rounded, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(subtitle, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                  CircularProgressIndicator(
                    color: Colors.amber,
                    value: (durationSeconds - remaining) / durationSeconds,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kapanmasına $remaining sn...',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ScrapeParticle {
  Offset position;
  Offset velocity;
  double size;
  double life;
  final double decay;
  final Color color;
  final bool isSquare;

  ScrapeParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    this.life = 1.0,
    this.decay = 0.035,
    this.isSquare = false,
  });

  void update() {
    position += velocity;
    velocity = Offset(velocity.dx * 0.96, velocity.dy + 0.38);
    life -= decay;
    size *= 0.98;
  }
}

class ScraperTool {
  final String id;
  final String name;
  final IconData icon;
  final double brushSize;
  final StrokeCap strokeCap;
  final String audioAsset;
  final int vibrationDuration;
  final int vibrationAmplitude;
  final bool requiresUnlock;

  const ScraperTool({
    required this.id,
    required this.name,
    required this.icon,
    required this.brushSize,
    required this.strokeCap,
    required this.audioAsset,
    required this.vibrationDuration,
    required this.vibrationAmplitude,
    this.requiresUnlock = false,
  });
}

/// Mağaza Satın Alınabilir Skin Modeli
class ShopItem {
  final String id;
  final String name;
  final int price;
  final Color primaryColor;
  final IconData icon;

  const ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.primaryColor,
    required this.icon,
  });
}

class GeneratedLevel {
  final int levelNumber;
  final String title;
  final String subtitle;
  final String cleanAsset;
  final DirtLayerConfig dirtConfig;
  final int coinReward;

  const GeneratedLevel({
    required this.levelNumber,
    required this.title,
    required this.subtitle,
    required this.cleanAsset,
    required this.dirtConfig,
    required this.coinReward,
  });
}

class SatisfyingScraperApp extends StatelessWidget {
  const SatisfyingScraperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Satisfying Scraper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const ScraperScreen(),
    );
  }
}

class ScraperScreen extends StatefulWidget {
  const ScraperScreen({super.key});

  @override
  State<ScraperScreen> createState() => _ScraperScreenState();
}

class _ScraperScreenState extends State<ScraperScreen>
    with TickerProviderStateMixin {
  final MonetizationManager _monetization = MonetizationManager();
  final Random _random = Random();

  final List<Map<String, String>> _cleanObjects = const [
    {'asset': 'assets/images/elmas.png', 'title': 'KRALİYET ELMASI'},
    {'asset': 'assets/images/bitcoin.png', 'title': 'ALTIN BITCOIN'},
    {'asset': 'assets/images/disko_topu.png', 'title': 'RETRO DİSKO TOPU'},
    {'asset': 'assets/images/zumrut.png', 'title': 'KADİM ZÜMRÜT'},
    {'asset': 'assets/images/teker.png', 'title': 'YARIŞ JANTI & TEKER'},
  ];

  final List<ScraperTool> _tools = const [
    ScraperTool(
      id: 'brush',
      name: 'Fırça',
      icon: Icons.brush_rounded,
      brushSize: 42.0,
      strokeCap: StrokeCap.round,
      audioAsset: 'audio/scrape_loop.wav',
      vibrationDuration: 15,
      vibrationAmplitude: 90,
    ),
    ScraperTool(
      id: 'razor',
      name: 'Jilet Spatula',
      icon: Icons.carpenter_rounded,
      brushSize: 52.0,
      strokeCap: StrokeCap.square,
      audioAsset: 'audio/razor_loop.wav',
      vibrationDuration: 10,
      vibrationAmplitude: 150,
    ),
    ScraperTool(
      id: 'mega',
      name: 'Mega Lazer',
      icon: Icons.bolt_rounded,
      brushSize: 85.0,
      strokeCap: StrokeCap.round,
      audioAsset: 'audio/laser_loop.wav',
      vibrationDuration: 28,
      vibrationAmplitude: 240,
      requiresUnlock: true,
    ),
  ];

  // --- MAĞAZA ÖĞELERİ (SKINLER) ---
  final List<ShopItem> _shopItems = const [
    ShopItem(
      id: 'skin_default',
      name: 'Klasik Ahşap',
      price: 0,
      primaryColor: Color(0xFFE53935),
      icon: Icons.brush_rounded,
    ),
    ShopItem(
      id: 'skin_emerald',
      name: 'Zümrüt Fırça',
      price: 250,
      primaryColor: Color(0xFF00C853),
      icon: Icons.eco_rounded,
    ),
    ShopItem(
      id: 'skin_cyber',
      name: 'Cyberpunk Neon',
      price: 500,
      primaryColor: Color(0xFF00E5FF),
      icon: Icons.flash_on_rounded,
    ),
    ShopItem(
      id: 'skin_gold',
      name: 'Kraliyet Altını',
      price: 1000,
      primaryColor: Color(0xFFFFD700),
      icon: Icons.workspace_premium_rounded,
    ),
  ];

  List<String> _unlockedSkinIds = ['skin_default'];
  String _currentSkinId = 'skin_default';

  int _currentLevelNumber = 1;
  int _totalCoins = 0;
  int _selectedToolIndex = 0;

  late GeneratedLevel _currentLevel;
  ScraperTool get _currentTool => _tools[_selectedToolIndex];

  bool _isZenMode = false;
  Offset? _activeFingerPos;
  double _toolTiltAngle = 0.25;
  bool _isShowingBefore = false;

  final double _dirtOpacity = 0.72;

  ui.Image? _cleanImage;
  ui.Image? _dirtyImage;
  ByteData? _cleanPixelData;
  bool _isLoading = true;

  final List<ScrapeStroke> _strokes = [];
  Path? _currentPath;

  final List<ScrapeParticle> _particles = [];
  late final Ticker _particleTicker;

  final Map<String, AudioPlayer> _toolPlayers = {};
  late final AudioPlayer _completePlayer;
  bool _isPlayingSound = false;
  Timer? _movementStopTimer;

  bool _hasVibrator = false;
  DateTime _lastVibrationTime = DateTime.now();

  static const int _gridSize = 100;
  late List<List<bool>> _isTargetCell;
  late List<List<bool>> _isCleanedCell;

  int _totalTargetCells = 0;
  int _cleanedTargetCells = 0;
  double _cleanPercentage = 0.0;
  bool _isLevelCompleted = false;
  Offset? _lastPanPosition;

  late final ConfettiController _confettiController;
  late final AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _particleTicker = createTicker(_onTickParticles)..start();
    _initGame();
  }

  Future<void> _initGame() async {
    await _loadSavedProgress();
    await _initAudioAndHaptics();
    _currentLevel = _generateLevelData(_currentLevelNumber);
    await _loadLevelAssets();
  }

  Future<void> _loadSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLevelNumber = prefs.getInt('saved_level') ?? 1;
    _totalCoins = prefs.getInt('saved_coins') ?? 0;
    _monetization.isProUser = prefs.getBool('saved_is_pro') ?? false;
    _currentSkinId = prefs.getString('saved_skin') ?? 'skin_default';

    final List<String>? savedSkins = prefs.getStringList(
      'saved_unlocked_skins',
    );
    if (savedSkins != null) {
      _unlockedSkinIds = savedSkins;
    }

    if (_monetization.isProUser) {
      _monetization.isLaserUnlockedForSession = true;
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_level', _currentLevelNumber);
    await prefs.setInt('saved_coins', _totalCoins);
    await prefs.setBool('saved_is_pro', _monetization.isProUser);
    await prefs.setString('saved_skin', _currentSkinId);
    await prefs.setStringList('saved_unlocked_skins', _unlockedSkinIds);
  }

  GeneratedLevel _generateLevelData(int levelNum) {
    final int idx = levelNum - 1;
    final cleanObj = _cleanObjects[idx % _cleanObjects.length];
    final dirtConfig =
        DirtLayerConfig.configs[idx % DirtLayerConfig.configs.length];

    return GeneratedLevel(
      levelNumber: levelNum,
      title: cleanObj['title']!,
      subtitle: 'Kaplama: ${dirtConfig.name}',
      cleanAsset: cleanObj['asset']!,
      dirtConfig: dirtConfig,
      coinReward: 50 + (levelNum * 10).clamp(0, 150),
    );
  }

  void _onTickParticles(Duration elapsed) {
    if (_particles.isEmpty) return;

    setState(() {
      for (int i = _particles.length - 1; i >= 0; i--) {
        _particles[i].update();
        if (_particles[i].life <= 0.02 || _particles[i].size <= 0.5) {
          _particles.removeAt(i);
        }
      }
    });
  }

  void _spawnParticles(Offset position, Offset dragDelta) {
    if (_particles.length > 160) return;

    final tool = _currentTool;
    final int count = tool.id == 'mega' ? 9 : 6;

    final List<Color> activePalette = tool.id == 'mega'
        ? const [
            Color(0xFF00E5FF),
            Color(0xFF18FFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFEA00),
          ]
        : _currentLevel.dirtConfig.flakeColors;

    for (int i = 0; i < count; i++) {
      final double spread = tool.brushSize * 0.45;
      final Offset spawnPos =
          position +
          Offset(
            (_random.nextDouble() - 0.5) * spread,
            (_random.nextDouble() - 0.5) * spread,
          );

      final double angle = _random.nextDouble() * 2 * pi;
      final double speed = 1.2 + _random.nextDouble() * 4.2;

      final Offset velocity = Offset(
        cos(angle) * speed + (dragDelta.dx * 0.15),
        sin(angle) * speed - 1.5,
      );

      final Color color = activePalette[_random.nextInt(activePalette.length)];
      final double size =
          3.5 + _random.nextDouble() * (tool.id == 'mega' ? 6.5 : 5.0);

      _particles.add(
        ScrapeParticle(
          position: spawnPos,
          velocity: velocity,
          size: size,
          color: color,
          decay: 0.025 + _random.nextDouble() * 0.025,
          isSquare: tool.id == 'razor',
        ),
      );
    }
  }

  Future<void> _initAudioAndHaptics() async {
    for (final tool in _tools) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setSource(AssetSource(tool.audioAsset));
      await player.setVolume(0.9);
      _toolPlayers[tool.id] = player;
    }

    _completePlayer = AudioPlayer();
    await _completePlayer.setReleaseMode(ReleaseMode.stop);
    await _completePlayer.setSource(AssetSource('audio/level_complete.wav'));
    await _completePlayer.setVolume(1.0);

    final bool? hasVib = await Vibration.hasVibrator();
    _hasVibrator = hasVib ?? false;
  }

  Future<void> _loadLevelAssets() async {
    setState(() {
      _isLoading = true;
      _activeFingerPos = null;
      _isShowingBefore = false;
    });

    final cleanImg = await _loadUiImage(_currentLevel.cleanAsset);
    final dirtyImg = await _loadUiImage(_currentLevel.dirtConfig.assetPath);
    final ByteData? pixelData = await cleanImg.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    if (mounted) {
      _cleanImage = cleanImg;
      _dirtyImage = dirtyImg;
      _cleanPixelData = pixelData;
      _strokes.clear();
      _particles.clear();
      _buildTargetGrid();

      setState(() => _isLoading = false);
    }
  }

  void _buildTargetGrid() {
    _isTargetCell = List.generate(
      _gridSize,
      (_) => List.filled(_gridSize, false),
    );
    _isCleanedCell = List.generate(
      _gridSize,
      (_) => List.filled(_gridSize, false),
    );
    _totalTargetCells = 0;
    _cleanedTargetCells = 0;
    _cleanPercentage = 0.0;
    _isLevelCompleted = false;

    if (_cleanImage == null || _cleanPixelData == null) return;

    final int imgW = _cleanImage!.width;
    final int imgH = _cleanImage!.height;

    for (int gy = 0; gy < _gridSize; gy++) {
      for (int gx = 0; gx < _gridSize; gx++) {
        final int px = ((gx + 0.5) / _gridSize * imgW).floor().clamp(
          0,
          imgW - 1,
        );
        final int py = ((gy + 0.5) / _gridSize * imgH).floor().clamp(
          0,
          imgH - 1,
        );

        final int alphaIndex = (py * imgW + px) * 4 + 3;
        final int alpha = _cleanPixelData!.getUint8(alphaIndex);

        if (alpha > 40) {
          _isTargetCell[gy][gx] = true;
          _totalTargetCells++;
        }
      }
    }
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  bool _markCellsAlongLine(Offset from, Offset to, double canvasSize) {
    if (canvasSize <= 0 || _totalTargetCells == 0 || _isLevelCompleted)
      return false;

    bool newlyScrapedAny = false;
    final double brushSize = _currentTool.brushSize;
    final double brushRadiusInGrid =
        ((brushSize * 0.5) / canvasSize) * _gridSize;
    final double radiusSq = brushRadiusInGrid * brushRadiusInGrid;

    final double distance = (to - from).distance;
    final int steps = (distance / 4.0).ceil().clamp(1, 30);

    for (int i = 0; i <= steps; i++) {
      final double t = i / steps;
      final double curX = from.dx + (to.dx - from.dx) * t;
      final double curY = from.dy + (to.dy - from.dy) * t;

      final double centerGx = (curX / canvasSize) * _gridSize;
      final double centerGy = (curY / canvasSize) * _gridSize;

      final int minGx = (centerGx - brushRadiusInGrid).floor().clamp(
        0,
        _gridSize - 1,
      );
      final int maxGx = (centerGx + brushRadiusInGrid).ceil().clamp(
        0,
        _gridSize - 1,
      );
      final int minGy = (centerGy - brushRadiusInGrid).floor().clamp(
        0,
        _gridSize - 1,
      );
      final int maxGy = (centerGy + brushRadiusInGrid).ceil().clamp(
        0,
        _gridSize - 1,
      );

      for (int gy = minGy; gy <= maxGy; gy++) {
        for (int gx = minGx; gx <= maxGx; gx++) {
          if (_isTargetCell[gy][gx] && !_isCleanedCell[gy][gx]) {
            final double dx = (gx + 0.5) - centerGx;
            final double dy = (gy + 0.5) - centerGy;
            if (dx * dx + dy * dy <= radiusSq) {
              _isCleanedCell[gy][gx] = true;
              _cleanedTargetCells++;
              newlyScrapedAny = true;
            }
          }
        }
      }
    }

    if (newlyScrapedAny) {
      _cleanPercentage = (_cleanedTargetCells / _totalTargetCells) * 100.0;

      if (_cleanPercentage >= 99.0 && !_isLevelCompleted) {
        _completeLevelAutomatically(canvasSize);
      }
    }

    return newlyScrapedAny;
  }

  void _completeLevelAutomatically(double canvasSize) {
    _isLevelCompleted = true;
    _cleanPercentage = 100.0;
    _activeFingerPos = null;
    _stopScrapeFeedback();
    _particles.clear();

    _totalCoins += _currentLevel.coinReward;
    _currentLevelNumber++;
    _saveProgress();

    final fullClearPath = Path()
      ..addRect(Rect.fromLTWH(-50, -50, canvasSize + 100, canvasSize + 100));
    _strokes.add(
      ScrapeStroke(
        path: fullClearPath,
        brushSize: canvasSize,
        strokeCap: StrokeCap.round,
      ),
    );

    _completePlayer.stop().then((_) {
      _completePlayer.play(AssetSource('audio/level_complete.wav'));
    });

    _confettiController.play();
    _shineController.forward(from: 0.0);

    if (_hasVibrator) {
      Vibration.vibrate(
        pattern: [0, 60, 80, 120],
        intensities: [0, 180, 0, 255],
      );
    }
  }

  Future<void> _nextLevel() async {
    _confettiController.stop();

    if (!_isZenMode) {
      await _monetization.showInterstitialAdIfNeeded(
        context,
        _currentLevel.levelNumber,
      );
    }

    if (!mounted) return;
    setState(() {
      _currentLevel = _generateLevelData(_currentLevelNumber);
    });
    _loadLevelAssets();
  }

  Future<void> _onSelectTool(int index) async {
    final tool = _tools[index];

    if (tool.requiresUnlock &&
        !_monetization.isProUser &&
        !_monetization.isLaserUnlockedForSession) {
      final bool unlocked = await _monetization.showRewardedAd(context);
      if (!unlocked || !mounted) return;
    }

    _stopScrapeFeedback();

    setState(() {
      _selectedToolIndex = index;
    });
  }

  void _showProPaywall() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.amber,
                size: 56,
              ),
              const SizedBox(height: 12),
              const Text(
                'VIP ASMR DENEYİMİ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Tüm Geçiş Reklamlarını Kaldır (No Ads)\n• Mega Lazer Aracını Kalıcı Olarak Aç\n• Sınırsız Rahatlama Modu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await _monetization.purchaseProPackage(
                      context,
                    );
                    if (success && ctx.mounted) {
                      await _saveProgress();
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _onSelectTool(2);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🎉 PRO sürüm aktif! Mega Lazer kalıcı olarak açıldı!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'TEK TIKLA PRO OL (₺49.99 / Ömür Boyu)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /// **AŞAMA 9: ALET MAĞAZASI (SHOP) BOTTOM SHEET EKRANI**
  void _showShopModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            color: Colors.amber,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'FIRÇA MAĞAZASI (SKINS)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_totalCoins',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _shopItems.length,
                      itemBuilder: (context, index) {
                        final item = _shopItems[index];
                        final bool isUnlocked = _unlockedSkinIds.contains(
                          item.id,
                        );
                        final bool isEquipped = _currentSkinId == item.id;

                        return Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isEquipped
                                ? item.primaryColor.withValues(alpha: 0.15)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isEquipped
                                  ? item.primaryColor
                                  : (isUnlocked
                                        ? Colors.white24
                                        : Colors.amber.withValues(alpha: 0.4)),
                              width: isEquipped ? 2.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: item.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                child: Icon(
                                  item.icon,
                                  color: item.primaryColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (isUnlocked) {
                                      setState(() => _currentSkinId = item.id);
                                      setModalState(() {});
                                      _saveProgress();
                                    } else if (_totalCoins >= item.price) {
                                      setState(() {
                                        _totalCoins -= item.price;
                                        _unlockedSkinIds.add(item.id);
                                        _currentSkinId = item.id;
                                      });
                                      setModalState(() {});
                                      _saveProgress();
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '⚠️ Bu skin için yeterli altının yok!',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isEquipped
                                        ? Colors.greenAccent
                                        : (isUnlocked
                                              ? Colors.white24
                                              : Colors.amber),
                                    foregroundColor: isEquipped || isUnlocked
                                        ? Colors.black
                                        : Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    isEquipped
                                        ? 'KULLANILIYOR'
                                        : (isUnlocked
                                              ? 'SEÇ'
                                              : '${item.price} 🪙'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _triggerScrapeFeedback() {
    if (!_isPlayingSound) {
      _isPlayingSound = true;
      _toolPlayers[_currentTool.id]?.resume();
    }

    _movementStopTimer?.cancel();
    _movementStopTimer = Timer(const Duration(milliseconds: 120), () {
      _stopScrapeFeedback();
    });

    final now = DateTime.now();
    if (now.difference(_lastVibrationTime).inMilliseconds > 45) {
      _lastVibrationTime = now;
      if (_hasVibrator) {
        Vibration.vibrate(
          duration: _currentTool.vibrationDuration,
          amplitude: _currentTool.vibrationAmplitude,
        );
      } else {
        HapticFeedback.selectionClick();
      }
    }
  }

  void _stopScrapeFeedback() {
    _movementStopTimer?.cancel();
    if (_isPlayingSound) {
      for (final player in _toolPlayers.values) {
        player.pause();
      }
      _isPlayingSound = false;
    }
  }

  void _onPanStart(DragStartDetails details, double canvasSize) {
    if (_isLevelCompleted) return;
    _lastPanPosition = details.localPosition;

    setState(() {
      _activeFingerPos = details.localPosition;
      _toolTiltAngle = 0.2;
      _currentPath = Path()
        ..moveTo(details.localPosition.dx, details.localPosition.dy);
      _strokes.add(
        ScrapeStroke(
          path: _currentPath!,
          brushSize: _currentTool.brushSize,
          strokeCap: _currentTool.strokeCap,
        ),
      );
      final bool didScrape = _markCellsAlongLine(
        details.localPosition,
        details.localPosition,
        canvasSize,
      );
      if (didScrape) {
        _spawnParticles(details.localPosition, Offset.zero);
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details, double canvasSize) {
    if (_isLevelCompleted) return;

    final Offset currentPos = details.localPosition;
    final Offset fromPos = _lastPanPosition ?? currentPos;
    _lastPanPosition = currentPos;

    final bool didScrapeNewDirt = _markCellsAlongLine(
      fromPos,
      currentPos,
      canvasSize,
    );

    if (details.delta.distance > 0.5) {
      if (didScrapeNewDirt) {
        _triggerScrapeFeedback();
        _spawnParticles(currentPos, details.delta);
      } else {
        _stopScrapeFeedback();
      }
    }

    final double targetTilt = (0.2 + (details.delta.dx * 0.025)).clamp(
      -0.45,
      0.55,
    );

    setState(() {
      _activeFingerPos = currentPos;
      _toolTiltAngle = _toolTiltAngle * 0.75 + targetTilt * 0.25;
      _currentPath?.lineTo(currentPos.dx, currentPos.dy);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _activeFingerPos = null;
    });
    _currentPath = null;
    _lastPanPosition = null;
    _stopScrapeFeedback();
  }

  void _resetCanvas() {
    _stopScrapeFeedback();
    _confettiController.stop();
    setState(() {
      _activeFingerPos = null;
      _isShowingBefore = false;
      _strokes.clear();
      _particles.clear();
      _buildTargetGrid();
    });
  }

  @override
  void dispose() {
    _particleTicker.dispose();
    _movementStopTimer?.cancel();
    for (final player in _toolPlayers.values) {
      player.dispose();
    }
    _completePlayer.dispose();
    _confettiController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final int displayPercent = _cleanPercentage.floor().clamp(0, 100);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => setState(() => _isZenMode = !_isZenMode),
          icon: Icon(
            _isZenMode ? Icons.visibility_off_rounded : Icons.videocam_rounded,
            color: _isZenMode ? Colors.white24 : Colors.white70,
          ),
          tooltip: 'TikTok Kayıt Modu',
        ),
        title: _isZenMode
            ? null
            : Column(
                children: [
                  Text(
                    'SEVİYE ${_currentLevel.levelNumber} • ${_currentLevel.subtitle.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.amber,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    _currentLevel.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
        centerTitle: true,
        actions: _isZenMode
            ? []
            : [
                // MAĞAZA BUTONU
                IconButton(
                  onPressed: _showShopModal,
                  icon: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.amber,
                  ),
                  tooltip: 'Alet Mağazası',
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$_totalCoins',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_monetization.isProUser)
                  IconButton(
                    onPressed: _showProPaywall,
                    icon: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.amber,
                    ),
                    tooltip: 'PRO Ol',
                  ),
                IconButton(
                  onPressed: _resetCanvas,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white70,
                  ),
                  tooltip: 'Sıfırla',
                ),
              ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isZenMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _isLevelCompleted
                                ? '+${_currentLevel.coinReward} ALTIN KAZANDIN!'
                                : 'TEMİZLENİYOR...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: _isLevelCompleted
                                  ? Colors.amberAccent
                                  : Colors.white70,
                            ),
                          ),
                          Text(
                            '%$displayPercent',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: _isLevelCompleted
                                  ? Colors.greenAccent
                                  : Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: _cleanPercentage / 100.0,
                          minHeight: 12,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isLevelCompleted
                                ? Colors.greenAccent
                                : Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double canvasSize = constraints.maxWidth;
                          return GestureDetector(
                            onTap: _isLevelCompleted ? _nextLevel : null,
                            onPanStart: (details) =>
                                _onPanStart(details, canvasSize),
                            onPanUpdate: (details) =>
                                _onPanUpdate(details, canvasSize),
                            onPanEnd: _onPanEnd,
                            child: AnimatedBuilder(
                              animation: _shineController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: ScrapePainter(
                                    cleanImage: _cleanImage!,
                                    dirtyImage: _dirtyImage!,
                                    strokes: _strokes,
                                    particles: _particles,
                                    isLevelCompleted: _isLevelCompleted,
                                    isShowingBefore: _isShowingBefore,
                                    shineProgress: _shineController.value,
                                    activeFingerPos: _activeFingerPos,
                                    activeTool: _currentTool,
                                    toolTiltAngle: _toolTiltAngle,
                                    dirtOpacity: _dirtOpacity,
                                    currentSkinId: _currentSkinId,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      if (_isLevelCompleted && !_isZenMode)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTapDown: (_) {
                              HapticFeedback.lightImpact();
                              setState(() => _isShowingBefore = true);
                            },
                            onTapUp: (_) =>
                                setState(() => _isShowingBefore = false),
                            onTapCancel: () =>
                                setState(() => _isShowingBefore = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _isShowingBefore
                                    ? Colors.amber
                                    : Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.amber,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.compare_rounded,
                                    size: 16,
                                    color: _isShowingBefore
                                        ? Colors.black
                                        : Colors.amber,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isShowingBefore
                                        ? 'İLK HALİ (KİRLİ)'
                                        : 'ÖNCESİ (BASILI TUT)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _isShowingBefore
                                          ? Colors.black
                                          : Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (!_isZenMode)
                SizedBox(
                  height: 76,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _isLevelCompleted
                        ? ElevatedButton.icon(
                            key: const ValueKey('next_btn'),
                            onPressed: _nextLevel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 26,
                            ),
                            label: Text(
                              'SEVİYE $_currentLevelNumber\'E GEÇ',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          )
                        : _buildToolSelectorBar(),
                  ),
                )
              else if (_isLevelCompleted)
                GestureDetector(
                  onTap: _nextLevel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sonraki nesne için dokun',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white38,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            emissionFrequency: 0.06,
            numberOfParticles: 25,
            maxBlastForce: 25,
            minBlastForce: 10,
            gravity: 0.25,
            colors: const [
              Colors.amber,
              Colors.greenAccent,
              Colors.cyanAccent,
              Colors.purpleAccent,
              Colors.white,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolSelectorBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        key: const ValueKey('tool_bar'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_tools.length, (index) {
          final tool = _tools[index];
          final bool isSelected = _selectedToolIndex == index;
          final bool isLocked =
              tool.requiresUnlock &&
              !_monetization.isProUser &&
              !_monetization.isLaserUnlockedForSession;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: InkWell(
              onTap: () => _onSelectTool(index),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.greenAccent.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? Colors.greenAccent
                        : (isLocked
                              ? Colors.amber.withValues(alpha: 0.5)
                              : Colors.white12),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLocked ? Icons.lock_rounded : tool.icon,
                      color: isSelected
                          ? Colors.greenAccent
                          : (isLocked ? Colors.amber : Colors.white70),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.greenAccent
                                : Colors.white,
                          ),
                        ),
                        if (isLocked)
                          const Text(
                            'REKLAM İZLE',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.amber,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        else if (tool.requiresUnlock)
                          const Text(
                            'AÇILDI',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ScrapeStroke {
  final Path path;
  final double brushSize;
  final StrokeCap strokeCap;

  const ScrapeStroke({
    required this.path,
    required this.brushSize,
    required this.strokeCap,
  });
}

class ScrapePainter extends CustomPainter {
  final ui.Image cleanImage;
  final ui.Image dirtyImage;
  final List<ScrapeStroke> strokes;
  final List<ScrapeParticle> particles;
  final bool isLevelCompleted;
  final bool isShowingBefore;
  final double shineProgress;
  final Offset? activeFingerPos;
  final ScraperTool activeTool;
  final double toolTiltAngle;
  final double dirtOpacity;
  final String currentSkinId;

  ScrapePainter({
    required this.cleanImage,
    required this.dirtyImage,
    required this.strokes,
    required this.particles,
    required this.isLevelCompleted,
    required this.isShowingBefore,
    required this.shineProgress,
    required this.activeFingerPos,
    required this.activeTool,
    required this.toolTiltAngle,
    required this.dirtOpacity,
    required this.currentSkinId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect canvasRect = Offset.zero & size;

    final Rect cleanSrcRect = Rect.fromLTWH(
      0,
      0,
      cleanImage.width.toDouble(),
      cleanImage.height.toDouble(),
    );
    final Rect dirtySrcRect = Rect.fromLTWH(
      0,
      0,
      dirtyImage.width.toDouble(),
      dirtyImage.height.toDouble(),
    );

    // 1. ALT KATMAN: Ödül nesnesi
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

    // 2. İZOLE KİR KATMANI (Saydamlık: 0.72)
    canvas.saveLayer(
      canvasRect,
      Paint()..color = Color.fromRGBO(255, 255, 255, dirtOpacity),
    );

    canvas.drawImageRect(
      cleanImage,
      cleanSrcRect,
      canvasRect,
      Paint()..filterQuality = FilterQuality.medium,
    );

    canvas.saveLayer(canvasRect, Paint()..blendMode = BlendMode.srcIn);

    canvas.drawImageRect(
      dirtyImage,
      dirtySrcRect,
      canvasRect,
      Paint()..filterQuality = FilterQuality.medium,
    );

    canvas.restore();

    if (!isShowingBefore) {
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

    // 3. KATMAN: DÖKÜLEN PARÇACIKLAR
    final Paint particlePaint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
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

    // 4. EN ÜST KATMAN: MAĞAZADAN SEÇİLEN SKIN RENGİNE GÖRE DEĞİŞEN 3D ALETLER
    if (activeFingerPos != null && !isLevelCompleted) {
      _drawRealisticTool(canvas, activeFingerPos!);
    }
  }

  void _drawRealisticTool(Canvas canvas, Offset pos) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    // Mağazadan seçilen skin'e göre fırçanın sap rengini dinamik değiştiriyoruz!
    Color handleColor1 = const Color(0xFFE53935);
    Color handleColor2 = const Color(0xFFB71C1C);
    if (currentSkinId == 'skin_emerald') {
      handleColor1 = const Color(0xFF00E676);
      handleColor2 = const Color(0xFF00C853);
    } else if (currentSkinId == 'skin_cyber') {
      handleColor1 = const Color(0xFF00E5FF);
      handleColor2 = const Color(0xFF00B0FF);
    } else if (currentSkinId == 'skin_gold') {
      handleColor1 = const Color(0xFFFFD700);
      handleColor2 = const Color(0xFFFFA000);
    }

    if (activeTool.id == 'brush') {
      canvas.rotate(toolTiltAngle);
      final double w = activeTool.brushSize;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w * 0.45 + 4, 6, w * 0.9, 95),
          const Radius.circular(12),
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      final Path bristlesPath = Path()
        ..moveTo(-w * 0.5, -6)
        ..quadraticBezierTo(0, -16, w * 0.5, -6)
        ..lineTo(w * 0.42, 18)
        ..lineTo(-w * 0.42, 18)
        ..close();

      canvas.drawPath(
        bristlesPath,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD54F), Color(0xFFD87A16)],
          ).createShader(Rect.fromLTWH(-w * 0.5, -16, w, 34)),
      );

      final Paint bristleLinePaint = Paint()
        ..color = const Color(0xFF8D4E00).withValues(alpha: 0.45)
        ..strokeWidth = 1.5;
      for (double x = -w * 0.38; x <= w * 0.38; x += 5.0) {
        canvas.drawLine(Offset(x, -9), Offset(x * 0.88, 17), bristleLinePaint);
      }

      final Rect ferruleRect = Rect.fromLTWH(-w * 0.43, 16, w * 0.86, 18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(ferruleRect, const Radius.circular(3)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF9E9E9E), Color(0xFFF5F5F5), Color(0xFF757575)],
          ).createShader(ferruleRect),
      );
      canvas.drawLine(
        Offset(-w * 0.42, 25),
        Offset(w * 0.42, 25),
        Paint()
          ..color = Colors.black26
          ..strokeWidth = 1.5,
      );

      final Path handlePath = Path()
        ..moveTo(-w * 0.40, 32)
        ..lineTo(w * 0.40, 32)
        ..cubicTo(w * 0.35, 60, w * 0.22, 85, w * 0.25, 110)
        ..arcToPoint(
          Offset(-w * 0.25, 110),
          radius: Radius.circular(w * 0.25),
          clockwise: true,
        )
        ..cubicTo(-w * 0.22, 85, -w * 0.35, 60, -w * 0.40, 32)
        ..close();

      canvas.drawPath(
        handlePath,
        Paint()
          ..shader = LinearGradient(
            colors: [handleColor1, handleColor2, Colors.black],
          ).createShader(Rect.fromLTWH(-w * 0.4, 32, w * 0.8, 85)),
      );

      canvas.drawCircle(
        const Offset(0, 102),
        4.5,
        Paint()..color = const Color(0xFF1A1A1A),
      );
    } else if (activeTool.id == 'razor') {
      canvas.rotate(toolTiltAngle * 0.8);
      final double w = activeTool.brushSize;

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

      final Paint screwPaint = Paint()..color = const Color(0xFF37474F);
      canvas.drawCircle(Offset(-w * 0.28, 2), 3.0, screwPaint);
      canvas.drawCircle(Offset(w * 0.28, 2), 3.0, screwPaint);

      final Path neckPath = Path()
        ..moveTo(-w * 0.52, 10)
        ..lineTo(w * 0.52, 10)
        ..lineTo(w * 0.24, 46)
        ..lineTo(-w * 0.24, 46)
        ..close();

      canvas.drawPath(
        neckPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF607D8B), Color(0xFFCFD8DC), Color(0xFF455A64)],
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
            colors: [handleColor1, handleColor2],
          ).createShader(gripRect.outerRect),
      );

      final Paint rubberPaint = Paint()
        ..color = const Color(0xFF212121)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;
      for (double y = 58; y <= 98; y += 10) {
        canvas.drawLine(Offset(-w * 0.16, y), Offset(w * 0.16, y), rubberPaint);
      }
    } else if (activeTool.id == 'mega') {
      final double r = activeTool.brushSize * 0.5;

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

      // Sırada nozzle çizimi
      canvas.drawPath(
        nozzlePath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF1C262B), Color(0xFF455A64), Color(0xFF10171A)],
          ).createShader(const Rect.fromLTWH(-26, -135, 52, 65)),
      );

      final Paint neonRingPaint = Paint()
        ..color = const Color(0xFF00E5FF)
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
