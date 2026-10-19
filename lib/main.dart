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
// MÜZE VİTRİNİ (TROPHY ROOM) HAZİNE MODELİ
// ============================================================================
class TrophyItem {
  final String id;
  final String title;
  final String assetPath;
  final String rarity;
  final Color rarityColor;
  final int requiredLevelToDiscover;
  final String lore;

  const TrophyItem({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.rarity,
    required this.rarityColor,
    required this.requiredLevelToDiscover,
    required this.lore,
  });

  static const List<TrophyItem> allTrophies = [
    TrophyItem(
      id: 'elmas',
      title: 'KRALİYET ELMASI',
      assetPath: 'assets/images/elmas.png',
      rarity: 'NADİR',
      rarityColor: Colors.cyanAccent,
      requiredLevelToDiscover: 1,
      lore:
          'Yüzyıllarca paslı bir madenin derinliklerinde unutulmuş kusursuz kesim elmas.',
    ),
    TrophyItem(
      id: 'zumrut',
      title: 'KADİM ZÜMRÜT',
      assetPath: 'assets/images/zumrut.png',
      rarity: 'NADİR',
      rarityColor: Colors.greenAccent,
      requiredLevelToDiscover: 2,
      lore:
          'Antik tapınak kalıntılarından çıkarılan, zümrüt yeşili büyüleyici değerli taş.',
    ),
    TrophyItem(
      id: 'bitcoin',
      title: 'ALTIN BITCOIN',
      assetPath: 'assets/images/bitcoin.png',
      rarity: 'DESTANSI',
      rarityColor: Colors.amber,
      requiredLevelToDiscover: 4,
      lore:
          'Soğuk cüzdan mahzenlerinde çamura bulanmış fiziksel kripto koleksiyon parası.',
    ),
    TrophyItem(
      id: 'disko_topu',
      title: 'RETRO DİSKO TOPU',
      assetPath: 'assets/images/disko_topu.png',
      rarity: 'DESTANSI',
      rarityColor: Colors.purpleAccent,
      requiredLevelToDiscover: 8,
      lore:
          '80\'lerin efsanevi kulüplerinden kalma, yüzlerce ayna parçalı disko küresi.',
    ),
    TrophyItem(
      id: 'teker',
      title: 'YARIŞ JANTI & TEKER',
      assetPath: 'assets/images/teker.png',
      rarity: 'EFSANEVİ (BOSS)',
      rarityColor: Colors.redAccent,
      requiredLevelToDiscover: 10,
      lore:
          'Zorlu ralli etaplarında katran ve çamura gömülmüş özel alaşımlı yarış tekeri.',
    ),
  ];
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
// GELİR MODELİ, REKLAM VE GÜNLÜK PRO HAK YÖNETİCİSİ
// ============================================================================
class MonetizationManager {
  bool isProUser = false;
  Set<String> dailyAdUnlockedTools = {};

  static const int maxDailyProSkips = 5;
  int remainingProSkipsToday = 0;

  Future<void> showInterstitialAdIfNeeded(
    BuildContext context,
    int completedLevel,
  ) async {
    if (isProUser) return;
    if (completedLevel % 2 != 0) return;

    await _showSimulatedAdDialog(
      context,
      title: 'GEÇİŞ REKLAMI (AdMob / AppLovin)',
      subtitle: 'Seviye $completedLevel tamamlandı. Kısa reklam molası...',
      durationSeconds: 2,
    );
  }

  Future<bool> showRewardedAd(
    BuildContext context, {
    required String purpose,
  }) async {
    final bool? watched = await _showSimulatedAdDialog(
      context,
      title: 'ÖDÜLLÜ VİDEO REKLAM',
      subtitle: '$purpose için 2 saniyelik test reklamı oynatılıyor...',
      durationSeconds: 2,
    );
    return watched == true;
  }

  Future<bool> purchaseProPackage(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 600));
    isProUser = true;
    remainingProSkipsToday = maxDailyProSkips;
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
                    'Ödülün verilmesine $remaining sn...',
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
  final String shortName;
  final String fullName;
  final IconData icon;
  final double baseBrushSize;
  final int scrapePower;
  final StrokeCap strokeCap;
  final String audioAsset;
  final int vibrationDuration;
  final int vibrationAmplitude;
  final int unlockLevel;

  const ScraperTool({
    required this.id,
    required this.shortName,
    required this.fullName,
    required this.icon,
    required this.baseBrushSize,
    required this.scrapePower,
    required this.strokeCap,
    required this.audioAsset,
    required this.vibrationDuration,
    required this.vibrationAmplitude,
    required this.unlockLevel,
  });
}

class ToolSkin {
  final String id;
  final String name;
  final String description;
  final int price;
  final List<Color> handleGradient;
  final Color trimColor;
  final List<Color>? customSparkColors;
  final IconData icon;

  const ToolSkin({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.handleGradient,
    required this.trimColor,
    this.customSparkColors,
    required this.icon,
  });
}

class GeneratedLevel {
  final int levelNumber;
  final String objectId;
  final String title;
  final String difficultyLabel;
  final Color difficultyColor;
  final String cleanAsset;
  final DirtLayerConfig dirtConfig;
  final int coinReward;
  final double resistanceFactor;
  final int dirtToughnessLayers;
  final int? timeLimitSeconds;
  final double targetCompletionPercent;

  const GeneratedLevel({
    required this.levelNumber,
    required this.objectId,
    required this.title,
    required this.difficultyLabel,
    required this.difficultyColor,
    required this.cleanAsset,
    required this.dirtConfig,
    required this.coinReward,
    required this.resistanceFactor,
    required this.dirtToughnessLayers,
    this.timeLimitSeconds,
    required this.targetCompletionPercent,
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
        scaffoldBackgroundColor: const Color(0xFF101014),
      ),
      home: const ScraperGameHub(),
    );
  }
}

class ScraperGameHub extends StatefulWidget {
  const ScraperGameHub({super.key});

  @override
  State<ScraperGameHub> createState() => _ScraperGameHubState();
}

class _ScraperGameHubState extends State<ScraperGameHub>
    with TickerProviderStateMixin {
  final MonetizationManager _monetization = MonetizationManager();
  final Random _random = Random();

  // EKRAN DURUMU: true ise Ana Menü (Giriş Ekranı), false ise Kazıma Oyunu gösterilir!
  bool _isInMainMenu = true;

  // SES VE TİTREŞİM AYARLARI
  bool _isSoundEnabled = true;
  bool _isHapticsEnabled = true;

  // MÜZEDE KEŞFEDİLEN NESNELERİN ID LİSTESİ VE KAÇ KEZ TEMİZLENDİĞİ
  Set<String> _discoveredTrophyIds = {};
  Map<String, int> _trophyCleanCounts = {};

  final List<Map<String, dynamic>> _easyObjects = const [
    {
      'id': 'elmas',
      'asset': 'assets/images/elmas.png',
      'title': 'KRALİYET ELMASI',
    },
    {
      'id': 'zumrut',
      'asset': 'assets/images/zumrut.png',
      'title': 'KADİM ZÜMRÜT',
    },
  ];

  final List<Map<String, dynamic>> _mediumObjects = const [
    {
      'id': 'bitcoin',
      'asset': 'assets/images/bitcoin.png',
      'title': 'ALTIN BITCOIN',
    },
    {
      'id': 'elmas',
      'asset': 'assets/images/elmas.png',
      'title': 'KRALİYET ELMASI',
    },
    {
      'id': 'disko_topu',
      'asset': 'assets/images/disko_topu.png',
      'title': 'RETRO DİSKO TOPU',
    },
  ];

  final List<Map<String, dynamic>> _hardObjects = const [
    {
      'id': 'disko_topu',
      'asset': 'assets/images/disko_topu.png',
      'title': 'RETRO DİSKO TOPU',
    },
    {
      'id': 'teker',
      'asset': 'assets/images/teker.png',
      'title': 'YARIŞ JANTI & TEKER',
    },
    {
      'id': 'bitcoin',
      'asset': 'assets/images/bitcoin.png',
      'title': 'ALTIN BITCOIN',
    },
  ];

  final List<ScraperTool> _tools = const [
    ScraperTool(
      id: 'brush',
      shortName: 'Fırça',
      fullName: 'İnce Tel Fırça',
      icon: Icons.brush_rounded,
      baseBrushSize: 32.0,
      scrapePower: 1,
      strokeCap: StrokeCap.round,
      audioAsset: 'audio/scrape_loop.wav',
      vibrationDuration: 14,
      vibrationAmplitude: 80,
      unlockLevel: 1,
    ),
    ScraperTool(
      id: 'sponge',
      shortName: 'Sünger',
      fullName: 'Zımpara Süngeri',
      icon: Icons.cleaning_services_rounded,
      baseBrushSize: 45.0,
      scrapePower: 1,
      strokeCap: StrokeCap.round,
      audioAsset: 'audio/scrape_loop.wav',
      vibrationDuration: 18,
      vibrationAmplitude: 110,
      unlockLevel: 10,
    ),
    ScraperTool(
      id: 'razor',
      shortName: 'Jilet',
      fullName: 'Çelik Jilet Spatula',
      icon: Icons.carpenter_rounded,
      baseBrushSize: 55.0,
      scrapePower: 2,
      strokeCap: StrokeCap.square,
      audioAsset: 'audio/razor_loop.wav',
      vibrationDuration: 12,
      vibrationAmplitude: 160,
      unlockLevel: 20,
    ),
    ScraperTool(
      id: 'grinder',
      shortName: 'Zımpara',
      fullName: 'Dev Sanayi Spatulası',
      icon: Icons.handyman_rounded,
      baseBrushSize: 70.0,
      scrapePower: 3,
      strokeCap: StrokeCap.square,
      audioAsset: 'audio/razor_loop.wav',
      vibrationDuration: 22,
      vibrationAmplitude: 200,
      unlockLevel: 30,
    ),
    ScraperTool(
      id: 'mega',
      shortName: 'Lazer',
      fullName: 'Mega Plazma Lazeri',
      icon: Icons.bolt_rounded,
      baseBrushSize: 90.0,
      scrapePower: 4,
      strokeCap: StrokeCap.round,
      audioAsset: 'audio/laser_loop.wav',
      vibrationDuration: 30,
      vibrationAmplitude: 255,
      unlockLevel: 40,
    ),
  ];

  final List<ToolSkin> _skins = const [
    ToolSkin(
      id: 'skin_default',
      name: 'Usta Kırmızısı',
      description: 'Klasik cilalı ahşap ve çelik kaplama',
      price: 0,
      handleGradient: [Color(0xFFE53935), Color(0xFFB71C1C), Color(0xFF4A0000)],
      trimColor: Color(0xFFBDBDBD),
      customSparkColors: null,
      icon: Icons.brush_rounded,
    ),
    ToolSkin(
      id: 'skin_magma',
      name: 'Magma Ejderi',
      description: 'Kor ateş gövde + Kazırken lav kıvılcımları saçar!',
      price: 300,
      handleGradient: [Color(0xFFFFEA00), Color(0xFFFF6D00), Color(0xFFDD2C00)],
      trimColor: Color(0xFFFFAB00),
      customSparkColors: [
        Color(0xFFFFEA00),
        Color(0xFFFF3D00),
        Color(0xFFFF9100),
      ],
      icon: Icons.local_fire_department_rounded,
    ),
    ToolSkin(
      id: 'skin_cyber',
      name: 'Cyberpunk Neon',
      description: 'Siber Pembe/Mavi + Kazırken neon plazma saçar!',
      price: 600,
      handleGradient: [Color(0xFFFF007F), Color(0xFF7C4DFF), Color(0xFF00E5FF)],
      trimColor: Color(0xFF00E5FF),
      customSparkColors: [
        Color(0xFFFF007F),
        Color(0xFF00E5FF),
        Color(0xFFFFFFFF),
      ],
      icon: Icons.electric_bolt_rounded,
    ),
    ToolSkin(
      id: 'skin_void',
      name: 'Kara Delik (Void)',
      description: 'Kozmik Mor/Altın zırh + Yıldız tozu efekti!',
      price: 1000,
      handleGradient: [Color(0xFF120024), Color(0xFF6A1B9A), Color(0xFFFFD700)],
      trimColor: Color(0xFFFFD700),
      customSparkColors: [
        Color(0xFFE040FB),
        Color(0xFFFFD700),
        Color(0xFFFFFFFF),
      ],
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  List<String> _unlockedSkinIds = ['skin_default'];
  String _currentSkinId = 'skin_default';

  int _currentLevelNumber = 1;
  int _totalCoins = 0;
  int _skipTickets = 0;
  int _brushPowerUpgradeLevel = 0;
  int _selectedToolIndex = 0;

  late GeneratedLevel _currentLevel;
  ScraperTool get _currentTool => _tools[_selectedToolIndex];
  ToolSkin get _currentSkin => _skins.firstWhere(
    (s) => s.id == _currentSkinId,
    orElse: () => _skins.first,
  );

  double get _effectiveBrushSize {
    final double upgradeBonus = 1.0 + (_brushPowerUpgradeLevel * 0.08);
    if (_currentTool.id == 'mega')
      return _currentTool.baseBrushSize * upgradeBonus;
    return (_currentTool.baseBrushSize *
            _currentLevel.resistanceFactor *
            upgradeBonus)
        .clamp(14.0, 120.0);
  }

  double get _effectiveStrokeEraseOpacity {
    final int layers = _currentLevel.dirtToughnessLayers;
    final int power = _currentTool.scrapePower;
    if (power >= layers) return 1.0;
    return (power / layers + 0.12).clamp(0.35, 1.0);
  }

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

  Timer? _levelCountdownTimer;
  int? _remainingSeconds;
  bool _isTimerRunning = false;

  bool _hasVibrator = false;
  DateTime _lastVibrationTime = DateTime.now();

  static const int _gridSize = 100;
  late List<List<bool>> _isTargetCell;
  late List<List<int>> _cellRemainingDirtHealth;
  late List<List<int>> _cellLastHitMs;

  int _totalMaxDirtHealth = 0;
  int _currentRemovedDirtHealth = 0;
  double _cleanPercentage = 0.0;
  bool _isLevelCompleted = false;
  Offset? _lastPanPosition;

  late final ConfettiController _confettiController;
  late final AnimationController _shineController;
  late final AnimationController _pulseController;

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _particleTicker = createTicker(_onTickParticles)..start();
    _initGame();
  }

  Future<void> _initGame() async {
    await _loadSavedProgress();
    await _initAudioAndHaptics();
    _currentLevel = _generateLevel50Progression(_currentLevelNumber);
    await _loadLevelAssets();
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLevelNumber = prefs.getInt('saved_level') ?? 1;
    _totalCoins = prefs.getInt('saved_coins') ?? 0;
    _skipTickets = prefs.getInt('saved_skip_tickets') ?? 0;
    _brushPowerUpgradeLevel = prefs.getInt('saved_power_upgrade') ?? 0;
    _monetization.isProUser = prefs.getBool('saved_is_pro') ?? false;
    _currentSkinId = prefs.getString('saved_skin') ?? 'skin_default';
    _isSoundEnabled = prefs.getBool('saved_sound_on') ?? true;
    _isHapticsEnabled = prefs.getBool('saved_haptics_on') ?? true;

    final List<String>? savedSkins = prefs.getStringList(
      'saved_unlocked_skins',
    );
    if (savedSkins != null) {
      _unlockedSkinIds = savedSkins;
    }

    final List<String>? savedTrophies = prefs.getStringList('saved_trophies');
    if (savedTrophies != null) {
      _discoveredTrophyIds = savedTrophies.toSet();
    }

    for (final t in TrophyItem.allTrophies) {
      _trophyCleanCounts[t.id] = prefs.getInt('trophy_count_${t.id}') ?? 0;
    }

    final String today = _getTodayDateString();
    final String? lastResetDate = prefs.getString('last_reset_date');

    if (lastResetDate != today) {
      _monetization.remainingProSkipsToday =
          MonetizationManager.maxDailyProSkips;
      _monetization.dailyAdUnlockedTools.clear();
      await prefs.setString('last_reset_date', today);
      await prefs.setInt(
        'saved_pro_skips',
        _monetization.remainingProSkipsToday,
      );
      await prefs.setStringList('saved_daily_tools', []);
    } else {
      _monetization.remainingProSkipsToday =
          prefs.getInt('saved_pro_skips') ??
          MonetizationManager.maxDailyProSkips;
      final List<String>? dailyTools = prefs.getStringList('saved_daily_tools');
      if (dailyTools != null) {
        _monetization.dailyAdUnlockedTools = dailyTools.toSet();
      }
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_level', _currentLevelNumber);
    await prefs.setInt('saved_coins', _totalCoins);
    await prefs.setInt('saved_skip_tickets', _skipTickets);
    await prefs.setInt('saved_power_upgrade', _brushPowerUpgradeLevel);
    await prefs.setBool('saved_is_pro', _monetization.isProUser);
    await prefs.setString('saved_skin', _currentSkinId);
    await prefs.setStringList('saved_unlocked_skins', _unlockedSkinIds);
    await prefs.setInt('saved_pro_skips', _monetization.remainingProSkipsToday);
    await prefs.setStringList(
      'saved_daily_tools',
      _monetization.dailyAdUnlockedTools.toList(),
    );
    await prefs.setStringList('saved_trophies', _discoveredTrophyIds.toList());
    await prefs.setBool('saved_sound_on', _isSoundEnabled);
    await prefs.setBool('saved_haptics_on', _isHapticsEnabled);

    for (final entry in _trophyCleanCounts.entries) {
      await prefs.setInt('trophy_count_${entry.key}', entry.value);
    }
  }

  // ============================================================================
  // 🏛️ HAZİNE MÜZESİ (TROPHY ROOM) EKRANI
  // ============================================================================
  void _showTrophyRoomModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14141A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final int discoveredCount = _discoveredTrophyIds.length;
        final int totalCount = TrophyItem.allTrophies.length;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                children: [
                  // Üst Başlık
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.museum_rounded,
                            color: Colors.amber,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HAZİNE MÜZESİ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'Kurtarılan Nadir Yadigarlar Vitrini',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          'KEŞİF: $discoveredCount / $totalCount',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Müze Vitrin Izgarası
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.78,
                          ),
                      itemCount: TrophyItem.allTrophies.length,
                      itemBuilder: (context, index) {
                        final trophy = TrophyItem.allTrophies[index];
                        final bool isDiscovered = _discoveredTrophyIds.contains(
                          trophy.id,
                        );
                        final int cleanCount =
                            _trophyCleanCounts[trophy.id] ?? 0;

                        return GestureDetector(
                          onTap: () {
                            if (isDiscovered) {
                              _showTrophyDetailDialog(trophy, cleanCount);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '🔒 Bu gizemli nesneyi keşfetmek için Seviye ${trophy.requiredLevelToDiscover}\'e ulaş ve temizle!',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isDiscovered
                                    ? [
                                        trophy.rarityColor.withValues(
                                          alpha: 0.18,
                                        ),
                                        const Color(0xFF1E1E26),
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.04),
                                        Colors.black.withValues(alpha: 0.4),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDiscovered
                                    ? trophy.rarityColor.withValues(alpha: 0.65)
                                    : Colors.white12,
                                width: isDiscovered ? 2.0 : 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Nadirlik Rozeti
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDiscovered
                                          ? trophy.rarityColor.withValues(
                                              alpha: 0.2,
                                            )
                                          : Colors.white10,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isDiscovered ? trophy.rarity : 'GİZLİ',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: isDiscovered
                                            ? trophy.rarityColor
                                            : Colors.white38,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),

                                // Nesne Görseli (Keşfedilmediyse Siyah Silüet + Kilit!)
                                SizedBox(
                                  height: 92,
                                  width: 92,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (isDiscovered)
                                        Image.asset(
                                          trophy.assetPath,
                                          fit: BoxFit.contain,
                                        )
                                      else
                                        ColorFiltered(
                                          colorFilter: const ColorFilter.mode(
                                            Colors.black,
                                            BlendMode.srcIn,
                                          ),
                                          child: Opacity(
                                            opacity: 0.65,
                                            child: Image.asset(
                                              trophy.assetPath,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      if (!isDiscovered)
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.7,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.amber.withValues(
                                                alpha: 0.6,
                                              ),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.lock_rounded,
                                            color: Colors.amber,
                                            size: 22,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Spacer(),

                                Text(
                                  isDiscovered
                                      ? trophy.title
                                      : '??? GİZEMLİ NESNE',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: isDiscovered
                                        ? Colors.white
                                        : Colors.white38,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isDiscovered
                                      ? '$cleanCount Kez Parlatıldı ✨'
                                      : 'Seviye ${trophy.requiredLevelToDiscover}\'de Açılır',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDiscovered
                                        ? Colors.amber
                                        : Colors.white24,
                                  ),
                                ),
                              ],
                            ),
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

  /// Müzedeki keşfedilmiş bir nesneye tıklanınca açılan Büyük İnceleme Kartı
  void _showTrophyDetailDialog(TrophyItem trophy, int cleanCount) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: trophy.rarityColor, width: 2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: trophy.rarityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trophy.rarity,
                  style: TextStyle(
                    color: trophy.rarityColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                width: 150,
                child: Image.asset(trophy.assetPath, fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              Text(
                trophy.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                trophy.lore,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Toplam Temizlenme: $cleanCount Kez',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'KAPAT',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // ⚙️ SES VE HAPTIC AYARLARI EKRANI
  // ============================================================================
  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.settings_rounded,
                        color: Colors.amber,
                        size: 26,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'OYUN & ASMR AYARLARI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    activeColor: Colors.amber,
                    secondary: const Icon(
                      Icons.volume_up_rounded,
                      color: Colors.amber,
                    ),
                    title: const Text(
                      'ASMR Kazıma Sesleri',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Fırça, jilet ve lazer ses efektleri'),
                    value: _isSoundEnabled,
                    onChanged: (val) {
                      setState(() => _isSoundEnabled = val);
                      setModalState(() {});
                      if (!val) _stopScrapeFeedback();
                      _saveProgress();
                    },
                  ),
                  SwitchListTile(
                    activeColor: Colors.amber,
                    secondary: const Icon(
                      Icons.vibration_rounded,
                      color: Colors.amber,
                    ),
                    title: const Text(
                      'Haptic Mikro-Titreşim',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Kazırken dokunsal yüzey geri bildirimi',
                    ),
                    value: _isHapticsEnabled,
                    onChanged: (val) {
                      setState(() => _isHapticsEnabled = val);
                      setModalState(() {});
                      _saveProgress();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeveloperDebugModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.bug_report_rounded,
                    color: Colors.greenAccent,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'GELİŞTİRİCİ TEST KONSOLU',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Mevcut: Sv.$_currentLevelNumber | $_totalCoins 🪙 | Kir Katmanı: ${_currentLevel.dirtToughnessLayers}x | PRO: ${_monetization.isProUser ? "AÇIK" : "KAPALI"}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const Divider(color: Colors.white24, height: 24),

              ElevatedButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  setState(() {
                    _currentLevelNumber = 1;
                    _totalCoins = 0;
                    _skipTickets = 0;
                    _brushPowerUpgradeLevel = 0;
                    _monetization.isProUser = false;
                    _monetization.dailyAdUnlockedTools.clear();
                    _monetization.remainingProSkipsToday = 0;
                    _unlockedSkinIds = ['skin_default'];
                    _currentSkinId = 'skin_default';
                    _discoveredTrophyIds.clear();
                    _trophyCleanCounts.clear();
                    _selectedToolIndex = 0;
                    _currentLevel = _generateLevel50Progression(1);
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _loadLevelAssets();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text(
                  'HER ŞEYİ SIFIRLA (SV.1 & MÜZE SIFIRLA)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _monetization.isProUser = !_monetization.isProUser;
                    if (_monetization.isProUser) {
                      _monetization.remainingProSkipsToday =
                          MonetizationManager.maxDailyProSkips;
                    }
                    if (!_isToolUnlocked(_currentTool)) {
                      _selectedToolIndex = 0;
                    }
                  });
                  await _saveProgress();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(
                  _monetization.isProUser
                      ? 'PRO HESABI KAPAT (NORMAL OYUNCU OL)'
                      : 'PRO HESABI AKTİF ET',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        setState(() {
                          _currentLevelNumber += 10;
                          _currentLevel = _generateLevel50Progression(
                            _currentLevelNumber,
                          );
                        });
                        await _saveProgress();
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadLevelAssets();
                      },
                      child: const Text('+10 Seviye Atla'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        setState(() => _totalCoins += 1000);
                        await _saveProgress();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('+1000 🪙 Ekle'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  GeneratedLevel _generateLevel50Progression(int levelNum) {
    final int idx = levelNum - 1;
    final dirtConfig =
        DirtLayerConfig.configs[idx % DirtLayerConfig.configs.length];

    Map<String, dynamic> chosenObj;
    String diffLabel;
    Color diffColor;
    double resistance;
    int toughnessLayers;
    int? timeLimit;
    double targetPercent;

    if (levelNum <= 10) {
      chosenObj = (levelNum % 4 == 0)
          ? _mediumObjects[idx % _mediumObjects.length]
          : _easyObjects[idx % _easyObjects.length];
      diffLabel = 'KOLAY (1 KATMAN)';
      diffColor = Colors.greenAccent;
      resistance = 1.0;
      toughnessLayers = 1;
      timeLimit = null;
      targetPercent = 97.5;
    } else if (levelNum <= 25) {
      chosenObj = _mediumObjects[idx % _mediumObjects.length];
      diffLabel = 'ORTA (2 KAT KİR)';
      diffColor = Colors.amber;
      resistance = 0.65;
      toughnessLayers = 2;
      timeLimit = 35;
      targetPercent = 98.5;
    } else if (levelNum <= 40) {
      chosenObj = _hardObjects[idx % _hardObjects.length];
      diffLabel = 'ZOR (3 KAT ZIRHLI KİR)';
      diffColor = Colors.orangeAccent;
      resistance = 0.48;
      toughnessLayers = 3;
      timeLimit = 28;
      targetPercent = 99.0;
    } else {
      chosenObj = _hardObjects[idx % _hardObjects.length];
      diffLabel = 'KABUS! (4 KAT FOSİL)';
      diffColor = Colors.redAccent;
      resistance = 0.40;
      toughnessLayers = 4;
      timeLimit = 22;
      targetPercent = 99.2;
    }

    if (levelNum % 5 == 0 && levelNum > 5) {
      chosenObj = {
        'id': 'teker',
        'asset': 'assets/images/teker.png',
        'title': 'BOSS: DEV TEKER',
      };
      toughnessLayers = (toughnessLayers + 1).clamp(2, 4);
      diffLabel = 'BOSS ($toughnessLayers KAT KİR!)';
      diffColor = Colors.purpleAccent;
      resistance *= 0.85;
      timeLimit = (timeLimit ?? 35) - 5;
    }

    return GeneratedLevel(
      levelNumber: levelNum,
      objectId: chosenObj['id'] as String,
      title: chosenObj['title'] as String,
      difficultyLabel: '$diffLabel • ${dirtConfig.name}',
      difficultyColor: diffColor,
      cleanAsset: chosenObj['asset'] as String,
      dirtConfig: dirtConfig,
      coinReward: 50 + (levelNum * 8).clamp(0, 200),
      resistanceFactor: resistance,
      dirtToughnessLayers: toughnessLayers,
      timeLimitSeconds: timeLimit,
      targetCompletionPercent: targetPercent,
    );
  }

  void _startCountdownIfNeeded(double canvasSize) {
    if (_isTimerRunning ||
        _currentLevel.timeLimitSeconds == null ||
        _isLevelCompleted ||
        _isZenMode) {
      return;
    }
    _isTimerRunning = true;
    _levelCountdownTimer?.cancel();
    _levelCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isLevelCompleted || _isZenMode || _isInMainMenu) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds != null && _remainingSeconds! > 0) {
          _remainingSeconds = _remainingSeconds! - 1;
          if (_remainingSeconds == 0) {
            timer.cancel();
            _onTimeOut(canvasSize);
          }
        }
      });
    });
  }

  void _onTimeOut(double canvasSize) {
    _stopScrapeFeedback();
    _activeFingerPos = null;
    if (_hasVibrator && _isHapticsEnabled) {
      Vibration.vibrate(duration: 300, amplitude: 255);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          title: const Column(
            children: [
              Icon(Icons.timer_off_rounded, color: Colors.redAccent, size: 52),
              SizedBox(height: 8),
              Text(
                'SÜRE BİTTİ!',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: Text(
            'Bu bölümdeki ${_currentLevel.dirtToughnessLayers} katmanlı inatçı kir çok sert çıktı! İlerlemeni kaybetmeden devam etmek ister misin?',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final watched = await _monetization.showRewardedAd(
                      context,
                      purpose: '+15 Saniye Ek Süre ve Mega Lazer Desteği almak',
                    );
                    if (watched && mounted) {
                      setState(() {
                        _remainingSeconds = 15;
                        _isTimerRunning = false;
                        _monetization.dailyAdUnlockedTools.add('mega');
                        _selectedToolIndex = 4;
                      });
                      _startCountdownIfNeeded(canvasSize);
                    } else {
                      _resetCanvas();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.ondemand_video_rounded),
                  label: const Text(
                    '+15 SN EK SÜRE + LAZER (REKLAM)',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _handleSkipLevel(canvasSize);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.fast_forward_rounded),
                  label: const Text(
                    'BU BÖLÜMÜ TAMAMEN ATLA',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _resetCanvas();
                  },
                  child: const Text(
                    'Sıfırla ve Baştan Dene',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  bool _isToolUnlocked(ScraperTool tool) {
    if (_monetization.isProUser) return true;
    if (_currentLevelNumber >= tool.unlockLevel) return true;
    if (_monetization.dailyAdUnlockedTools.contains(tool.id)) return true;
    return false;
  }

  Future<void> _handleSkipLevel(double canvasSize) async {
    if (_isLevelCompleted) return;
    _stopScrapeFeedback();
    _levelCountdownTimer?.cancel();

    if (_monetization.isProUser && _monetization.remainingProSkipsToday > 0) {
      setState(() => _monetization.remainingProSkipsToday--);
      await _saveProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '👑 PRO Hak Kullanıldı! Bugün kalan: ${_monetization.remainingProSkipsToday}/${MonetizationManager.maxDailyProSkips}',
            ),
            backgroundColor: Colors.amber.shade800,
          ),
        );
      }
      _completeLevelAutomatically(canvasSize);
      return;
    }

    if (_skipTickets > 0) {
      setState(() => _skipTickets--);
      await _saveProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎟️ Atlama Bileti kullanıldı! Kalan biletin: $_skipTickets',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      _completeLevelAutomatically(canvasSize);
      return;
    }

    final bool watched = await _monetization.showRewardedAd(
      context,
      purpose: 'Bu zorlu bölümü anında geçmek',
    );

    if (watched && mounted) {
      _completeLevelAutomatically(canvasSize);
    }
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
    final skin = _currentSkin;
    final int count = tool.id == 'mega' ? 9 : 6;
    final List<Color> dirtPalette = _currentLevel.dirtConfig.flakeColors;

    for (int i = 0; i < count; i++) {
      final double spread = _effectiveBrushSize * 0.45;
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

      Color color;
      if (tool.id == 'mega') {
        const laserColors = [
          Color(0xFF00E5FF),
          Color(0xFF18FFFF),
          Color(0xFFFFFFFF),
          Color(0xFFFFEA00),
        ];
        color = laserColors[_random.nextInt(laserColors.length)];
      } else if (skin.customSparkColors != null &&
          _random.nextDouble() < 0.45) {
        color =
            skin.customSparkColors![_random.nextInt(
              skin.customSparkColors!.length,
            )];
      } else {
        color = dirtPalette[_random.nextInt(dirtPalette.length)];
      }

      final double size =
          3.5 + _random.nextDouble() * (tool.id == 'mega' ? 6.5 : 5.0);

      _particles.add(
        ScrapeParticle(
          position: spawnPos,
          velocity: velocity,
          size: size,
          color: color,
          decay: 0.025 + _random.nextDouble() * 0.025,
          isSquare: tool.strokeCap == StrokeCap.square,
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
    _levelCountdownTimer?.cancel();
    _isTimerRunning = false;

    setState(() {
      _isLoading = true;
      _activeFingerPos = null;
      _isShowingBefore = false;
      _remainingSeconds = _currentLevel.timeLimitSeconds;
    });

    if (!_isToolUnlocked(_currentTool)) {
      _selectedToolIndex = 0;
    }

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
    final int maxLayers = _currentLevel.dirtToughnessLayers;
    _isTargetCell = List.generate(
      _gridSize,
      (_) => List.filled(_gridSize, false),
    );
    _cellRemainingDirtHealth = List.generate(
      _gridSize,
      (_) => List.filled(_gridSize, 0),
    );
    _cellLastHitMs = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));

    _totalMaxDirtHealth = 0;
    _currentRemovedDirtHealth = 0;
    _cleanPercentage = 0.0;
    _isLevelCompleted = false;
    _remainingSeconds = _currentLevel.timeLimitSeconds;
    _isTimerRunning = false;

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
          _cellRemainingDirtHealth[gy][gx] = maxLayers;
          _totalMaxDirtHealth += maxLayers;
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
    if (canvasSize <= 0 || _totalMaxDirtHealth == 0 || _isLevelCompleted)
      return false;

    bool newlyScrapedAny = false;
    final double brushSize = _effectiveBrushSize;
    final double brushRadiusInGrid =
        ((brushSize * 0.5) / canvasSize) * _gridSize;
    final double radiusSq = brushRadiusInGrid * brushRadiusInGrid;

    final double distance = (to - from).distance;
    final int steps = (distance / 4.0).ceil().clamp(1, 30);
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int toolPower = _currentTool.scrapePower;

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
          final int currentHealth = _cellRemainingDirtHealth[gy][gx];
          if (currentHealth > 0 && (nowMs - _cellLastHitMs[gy][gx] > 180)) {
            final double dx = (gx + 0.5) - centerGx;
            final double dy = (gy + 0.5) - centerGy;
            if (dx * dx + dy * dy <= radiusSq) {
              final int damage = min(currentHealth, toolPower);
              _cellRemainingDirtHealth[gy][gx] = currentHealth - damage;
              _cellLastHitMs[gy][gx] = nowMs;
              _currentRemovedDirtHealth += damage;
              newlyScrapedAny = true;
            }
          }
        }
      }
    }

    if (newlyScrapedAny) {
      _cleanPercentage =
          (_currentRemovedDirtHealth / _totalMaxDirtHealth) * 100.0;

      if (_cleanPercentage >= _currentLevel.targetCompletionPercent &&
          !_isLevelCompleted) {
        _completeLevelAutomatically(canvasSize);
      }
    }

    return newlyScrapedAny;
  }

  void _completeLevelAutomatically(double canvasSize) {
    _levelCountdownTimer?.cancel();
    _isTimerRunning = false;
    _isLevelCompleted = true;
    _cleanPercentage = 100.0;
    _activeFingerPos = null;
    _stopScrapeFeedback();
    _particles.clear();

    // Nesneyi Müze Vitrinine (Trophy Room) ekle!
    final String objId = _currentLevel.objectId;
    final bool isFirstDiscovery = !_discoveredTrophyIds.contains(objId);
    _discoveredTrophyIds.add(objId);
    _trophyCleanCounts[objId] = (_trophyCleanCounts[objId] ?? 0) + 1;

    _totalCoins += _currentLevel.coinReward;
    _currentLevelNumber++;
    _saveProgress();

    if (isFirstDiscovery && mounted && !_isZenMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🏛️ YENİ MÜZE KEŞFİ: "${_currentLevel.title}" Hazine Müzesine eklendi!',
          ),
          backgroundColor: Colors.purple.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    final fullClearPath = Path()
      ..addRect(Rect.fromLTWH(-50, -50, canvasSize + 100, canvasSize + 100));
    _strokes.add(
      ScrapeStroke(
        path: fullClearPath,
        brushSize: canvasSize,
        strokeCap: StrokeCap.round,
        eraseOpacity: 1.0,
      ),
    );

    if (_isSoundEnabled) {
      _completePlayer.stop().then((_) {
        _completePlayer.play(AssetSource('audio/level_complete.wav'));
      });
    }

    _confettiController.play();
    _shineController.forward(from: 0.0);

    if (_hasVibrator && _isHapticsEnabled) {
      Vibration.vibrate(
        pattern: [0, 60, 80, 120],
        intensities: [0, 180, 0, 255],
      );
    }
    setState(() {});
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
      _currentLevel = _generateLevel50Progression(_currentLevelNumber);
    });
    _loadLevelAssets();
  }

  Future<void> _onSelectTool(int index) async {
    final tool = _tools[index];

    if (!_isToolUnlocked(tool)) {
      final bool unlocked = await _monetization.showRewardedAd(
        context,
        purpose:
            '${tool.fullName} aracını bugünlük açmak (Normalde Seviye ${tool.unlockLevel}\'de açılır)',
      );
      if (!unlocked || !mounted) return;

      _monetization.dailyAdUnlockedTools.add(tool.id);
      await _saveProgress();
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
                'PRO VIP PAKETİ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '• Tüm Zorunlu Geçiş Reklamlarını Kaldır\n'
                '• 5 Aletin Hepsini Seviye Beklemeden Anında Aç!\n'
                '• Her Gün 5 Adet Ücretsiz "Bölümü Atla" Hakkı!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
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
                      await _onSelectTool(4);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🎉 PRO sürüm aktif! Tüm 5 alet ve günlük 5 Atlama hakkı tanımlandı!',
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
                    'TEK TIKLA PRO OL (₺49.99)',
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

  void _showShopModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final int upgradeCost = 200 + (_brushPowerUpgradeLevel * 150);
            final bool isMaxUpgrade = _brushPowerUpgradeLevel >= 10;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            color: Colors.amber,
                            size: 26,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ATÖLYE & MAĞAZA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.purpleAccent.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: Text(
                              '🎟️ $_skipTickets',
                              style: const TextStyle(
                                color: Colors.purpleAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
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
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final watched = await _monetization.showRewardedAd(
                              context,
                              purpose: '+250 Ücretsiz Altın kazanmak',
                            );
                            if (watched && mounted) {
                              setState(() => _totalCoins += 250);
                              setModalState(() {});
                              await _saveProgress();
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade800,
                                  Colors.green.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.ondemand_video_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'ÜCRETSİZ +250 🪙',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Reklam İzle Kazan',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (_totalCoins >= 300) {
                              setState(() {
                                _totalCoins -= 300;
                                _skipTickets++;
                              });
                              setModalState(() {});
                              _saveProgress();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '⚠️ Bilet için 300 Altın gerekli!',
                                  ),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade800,
                                  Colors.deepPurple.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.fast_forward_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '+1 ATLAMA BİLETİ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Fiyat: 300 🪙',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kalıcı Kazıma Çapı (Lv.$_brushPowerUpgradeLevel/10)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Tüm aletlerin kazıma alanını +%'
                                '${_brushPowerUpgradeLevel * 8} büyütür!',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: isMaxUpgrade
                              ? null
                              : () {
                                  if (_totalCoins >= upgradeCost) {
                                    setState(() {
                                      _totalCoins -= upgradeCost;
                                      _brushPowerUpgradeLevel++;
                                    });
                                    setModalState(() {});
                                    _saveProgress();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '⚠️ Yeterli altının yok!',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isMaxUpgrade ? 'MAKS' : '$upgradeCost 🪙',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'EFSANEVİ EFEKTLİ ALET KOSTÜMLERİ (SKINS)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 195,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _skins.length,
                      itemBuilder: (context, index) {
                        final item = _skins[index];
                        final bool isUnlocked = _unlockedSkinIds.contains(
                          item.id,
                        );
                        final bool isEquipped = _currentSkinId == item.id;

                        return Container(
                          width: 155,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                item.handleGradient.first.withValues(
                                  alpha: 0.25,
                                ),
                                item.handleGradient.last.withValues(
                                  alpha: 0.10,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isEquipped
                                  ? Colors.greenAccent
                                  : item.trimColor.withValues(alpha: 0.6),
                              width: isEquipped ? 2.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: item.handleGradient,
                                  ),
                                  border: Border.all(
                                    color: item.trimColor,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
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
                                            '⚠️ Yeterli altının yok!',
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
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    isEquipped
                                        ? 'SEÇİLİ'
                                        : (isUnlocked
                                              ? 'KUŞAN'
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
    if (_isSoundEnabled && !_isPlayingSound) {
      _isPlayingSound = true;
      _toolPlayers[_currentTool.id]?.resume();
    }

    _movementStopTimer?.cancel();
    _movementStopTimer = Timer(const Duration(milliseconds: 120), () {
      _stopScrapeFeedback();
    });

    if (_isHapticsEnabled) {
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
    _startCountdownIfNeeded(canvasSize);
    _lastPanPosition = details.localPosition;

    setState(() {
      _activeFingerPos = details.localPosition;
      _toolTiltAngle = 0.2;
      _currentPath = Path()
        ..moveTo(details.localPosition.dx, details.localPosition.dy);
      _strokes.add(
        ScrapeStroke(
          path: _currentPath!,
          brushSize: _effectiveBrushSize,
          strokeCap: _currentTool.strokeCap,
          eraseOpacity: _effectiveStrokeEraseOpacity,
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
    _levelCountdownTimer?.cancel();
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
    _levelCountdownTimer?.cancel();
    _particleTicker.dispose();
    _movementStopTimer?.cancel();
    for (final player in _toolPlayers.values) {
      player.dispose();
    }
    _completePlayer.dispose();
    _confettiController.dispose();
    _shineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    // EĞER OYUNCU ANA MENÜDEYSE GİRİŞ EKRANINI GÖSTER!
    if (_isInMainMenu) {
      return _buildMainMenuScreen();
    }

    return _buildGameplayScreen();
  }

  // ============================================================================
  // 🎮 AŞAMA 12: MODERN ANA MENÜ (GİRİŞ EKRANI)
  // ============================================================================
  Widget _buildMainMenuScreen() {
    final int discoveredCount = _discoveredTrophyIds.length;
    final int totalTrophies = TrophyItem.allTrophies.length;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.2),
            radius: 1.1,
            colors: [Color(0xFF231D2E), Color(0xFF101014)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              children: [
                // 1. ÜST BAR: CÜZDAN, AYARLAR VE DEBUG KONSOLU
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _showSettingsModal,
                          icon: const Icon(
                            Icons.settings_rounded,
                            color: Colors.white70,
                          ),
                          tooltip: 'Ayarlar',
                        ),
                        IconButton(
                          onPressed: _showDeveloperDebugModal,
                          icon: const Icon(
                            Icons.bug_report_rounded,
                            color: Colors.greenAccent,
                          ),
                          tooltip: 'Geliştirici Test Konsolu',
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (_monetization.isProUser)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              '👑 PRO',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
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
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$_totalCoins',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // 2. ORTA VİTRİN: PARLAYAN AKTİF NESNE ÖNİZLEMESİ VE OYUN BAŞLIĞI
                ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.04).animate(
                    CurvedAnimation(
                      parent: _pulseController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    width: 170,
                    height: 170,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withValues(alpha: 0.08),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.35),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      _currentLevel.cleanAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'SATISFYING',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    color: Colors.amber,
                  ),
                ),
                const Text(
                  'ASMR RESTORATION STUDIO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.0,
                    color: Colors.white54,
                  ),
                ),

                const SizedBox(height: 24),

                // MEVCUT SEVİYE BİLGİ KARTI
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SIRADAKİ GÖREV: SEVİYE ${_currentLevel.levelNumber} / 50',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _currentLevel.difficultyColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currentLevel.title} (${_currentLevel.dirtConfig.name})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 3. DEV "OYNA / DEVAM ET" BUTONU
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isInMainMenu = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      elevation: 12,
                      shadowColor: Colors.amber.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 34),
                    label: Text(
                      'SEVİYE ${_currentLevel.levelNumber} • BAŞLA',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. ALT 3'LÜ KISAYOL MENÜSÜ (MÜZE, MAĞAZA, VIP)
                Row(
                  children: [
                    // Hazine Müzesi Butonu
                    Expanded(
                      child: InkWell(
                        onTap: _showTrophyRoomModal,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.purpleAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.museum_rounded,
                                color: Colors.purpleAccent,
                                size: 26,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'MÜZE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '$discoveredCount/$totalTrophies Açık',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Atölye & Mağaza Butonu
                    Expanded(
                      child: InkWell(
                        onTap: _showShopModal,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.greenAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.storefront_rounded,
                                color: Colors.greenAccent,
                                size: 26,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'ATÖLYE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Çap Lv.$_brushPowerUpgradeLevel',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // PRO VIP Butonu
                    Expanded(
                      child: InkWell(
                        onTap: _showProPaywall,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.workspace_premium_rounded,
                                color: Colors.amber,
                                size: 26,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'VIP PRO',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _monetization.isProUser ? 'Aktif' : 'Reklamsız',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // KAZIMA OYUN EKRANI
  // ============================================================================
  Widget _buildGameplayScreen() {
    final int displayPercent = _cleanPercentage.floor().clamp(0, 100);

    String skipButtonText = 'ATLA (📺 REKLAM)';
    if (_monetization.isProUser && _monetization.remainingProSkipsToday > 0) {
      skipButtonText = 'ATLA (${_monetization.remainingProSkipsToday}/5 PRO)';
    } else if (_skipTickets > 0) {
      skipButtonText = 'ATLA (🎟️ $_skipTickets BİLET)';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isZenMode)
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  _stopScrapeFeedback();
                  _levelCountdownTimer?.cancel();
                  _isTimerRunning = false;
                  setState(() => _isInMainMenu = true);
                },
                icon: const Icon(
                  Icons.home_rounded,
                  color: Colors.amber,
                  size: 22,
                ),
                tooltip: 'Ana Menüye Dön',
              ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _isZenMode = !_isZenMode),
              icon: Icon(
                _isZenMode
                    ? Icons.visibility_off_rounded
                    : Icons.videocam_rounded,
                color: _isZenMode ? Colors.white24 : Colors.white70,
                size: 20,
              ),
              tooltip: 'TikTok Kayıt Modu',
            ),
          ],
        ),
        title: _isZenMode
            ? null
            : Column(
                children: [
                  Text(
                    'SV.${_currentLevel.levelNumber}/50 • ${_currentLevel.difficultyLabel}',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: _currentLevel.difficultyColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    _currentLevel.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
        centerTitle: true,
        actions: _isZenMode
            ? []
            : [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _showTrophyRoomModal,
                  icon: const Icon(
                    Icons.museum_rounded,
                    color: Colors.purpleAccent,
                    size: 20,
                  ),
                  tooltip: 'Hazine Müzesi',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _showShopModal,
                  icon: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                  tooltip: 'Mağaza',
                ),
                GestureDetector(
                  onTap: _showShopModal,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
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
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$_totalCoins',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _resetCanvas,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white70,
                    size: 19,
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
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_remainingSeconds != null &&
                                  !_isLevelCompleted)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer_rounded,
                                      size: 15,
                                      color: _remainingSeconds! <= 8
                                          ? Colors.redAccent
                                          : Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'KALAN SÜRE: $_remainingSeconds SN',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: _remainingSeconds! <= 8
                                            ? Colors.redAccent
                                            : Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              Text(
                                _isLevelCompleted
                                    ? '+${_currentLevel.coinReward} ALTIN KAZANDIN!'
                                    : (_currentLevel.dirtToughnessLayers > 1
                                          ? '${_currentLevel.dirtToughnessLayers} KATMANLI SERT KİR!'
                                          : 'TEMİZLENİYOR...'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: _isLevelCompleted
                                      ? Colors.amberAccent
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '%$displayPercent',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: _isLevelCompleted
                                  ? Colors.greenAccent
                                  : Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: _cleanPercentage / 100.0,
                          minHeight: 11,
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

              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double canvasSize = constraints.maxWidth;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
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
                                    effectiveBrushSize: _effectiveBrushSize,
                                    toolTiltAngle: _toolTiltAngle,
                                    dirtOpacity: _dirtOpacity,
                                    activeSkin: _currentSkin,
                                  ),
                                );
                              },
                            ),
                          ),

                          if (!_isLevelCompleted && !_isZenMode)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: InkWell(
                                onTap: () => _handleSkipLevel(canvasSize),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.72),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.amber.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.fast_forward_rounded,
                                        size: 15,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        skipButtonText,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              if (!_isZenMode)
                SizedBox(
                  height: 82,
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
                        : _buildFixedFiveToolDock(),
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

  Widget _buildFixedFiveToolDock() {
    return Padding(
      key: const ValueKey('fixed_tool_dock'),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: List.generate(_tools.length, (index) {
          final tool = _tools[index];
          final bool isSelected = _selectedToolIndex == index;
          final bool isUnlocked = _isToolUnlocked(tool);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.5),
              child: InkWell(
                onTap: () => _onSelectTool(index),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.greenAccent.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.greenAccent
                          : (!isUnlocked
                                ? Colors.amber.withValues(alpha: 0.45)
                                : Colors.white12),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                            ),
                            child: Icon(
                              tool.icon,
                              color: isSelected
                                  ? Colors.greenAccent
                                  : (!isUnlocked
                                        ? Colors.white38
                                        : Colors.white70),
                              size: 22,
                            ),
                          ),
                          if (!isUnlocked)
                            const Icon(
                              Icons.lock_rounded,
                              color: Colors.amber,
                              size: 12,
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        tool.shortName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.greenAccent : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        !isUnlocked
                            ? 'SV.${tool.unlockLevel} / 📺'
                            : '${tool.scrapePower}x GÜÇ',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: !isUnlocked ? Colors.amber : Colors.white54,
                        ),
                      ),
                    ],
                  ),
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
  final double eraseOpacity;

  const ScrapeStroke({
    required this.path,
    required this.brushSize,
    required this.strokeCap,
    required this.eraseOpacity,
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
  final double effectiveBrushSize;
  final double toolTiltAngle;
  final double dirtOpacity;
  final ToolSkin activeSkin;

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
    required this.effectiveBrushSize,
    required this.toolTiltAngle,
    required this.dirtOpacity,
    required this.activeSkin,
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
          ..strokeCap = stroke.strokeCap
          ..color = Color.fromRGBO(0, 0, 0, stroke.eraseOpacity);
        canvas.drawPath(stroke.path, erasePaint);
      }
    }

    canvas.restore();

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

    if (activeFingerPos != null && !isLevelCompleted) {
      _drawRealisticTool(canvas, activeFingerPos!);
    }
  }

  void _drawRealisticTool(Canvas canvas, Offset pos) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    final double w = effectiveBrushSize;

    if (activeSkin.customSparkColors != null) {
      canvas.drawCircle(
        const Offset(0, 35),
        w * 0.65,
        Paint()
          ..color = activeSkin.trimColor.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    if (activeTool.id == 'brush' || activeTool.id == 'sponge') {
      canvas.rotate(toolTiltAngle);

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
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: activeTool.id == 'sponge'
                ? [const Color(0xFFFFEE58), const Color(0xFFFBC02D)]
                : [const Color(0xFFFFD54F), const Color(0xFFD87A16)],
          ).createShader(Rect.fromLTWH(-w * 0.5, -16, w, 34)),
      );

      final Rect ferruleRect = Rect.fromLTWH(-w * 0.43, 16, w * 0.86, 18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(ferruleRect, const Radius.circular(3)),
        Paint()
          ..shader = LinearGradient(
            colors: [activeSkin.trimColor, Colors.white, activeSkin.trimColor],
          ).createShader(ferruleRect),
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: activeSkin.handleGradient,
          ).createShader(Rect.fromLTWH(-w * 0.4, 32, w * 0.8, 85)),
      );
    } else if (activeTool.id == 'razor' || activeTool.id == 'grinder') {
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
