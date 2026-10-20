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

import '../models/game_models.dart';
import '../services/level_generator.dart';
import '../services/monetization_manager.dart';
import '../widgets/game_modals.dart';
import '../widgets/scrape_painter.dart';

class ScraperGameHub extends StatefulWidget {
  const ScraperGameHub({super.key});

  @override
  State<ScraperGameHub> createState() => _ScraperGameHubState();
}

class _ScraperGameHubState extends State<ScraperGameHub>
    with TickerProviderStateMixin {
  final MonetizationManager _monetization = MonetizationManager();
  final Random _random = Random();

  bool _isInMainMenu = true;
  bool _isSoundEnabled = true;
  bool _isHapticsEnabled = true;

  String _playerName = 'Usta_Oyuncu';
  Set<String> _discoveredTrophyIds = {};
  Map<String, int> _trophyCleanCounts = {};
  Map<int, int> _levelStars = {};

  final List<ScraperTool> _tools = ScraperTool.allTools;
  final List<ToolSkin> _skins = ToolSkin.allSkins;

  List<String> _unlockedSkinIds = ['skin_default'];
  String _currentSkinId = 'skin_default';

  int _highestUnlockedLevel = 1;
  int _activePlayingLevelNum = 1;
  int _totalCoins = 0;
  int _skipTickets = 0;
  int _brushPowerUpgradeLevel = 0;
  int _selectedToolIndex = 0;

  double _bestSpeedrunSeconds = 0.0;
  DateTime? _levelStartTimestamp;
  double _lastClearedTimeSeconds = 0.0;

  double _feverCharge = 0.0;
  bool _isFeverActive = false;

  // KRİTİK KORUMA: Bir katman bittiğinde oyuncu parmağını ekrandan çekip
  // yeni katmanın aletini seçmeden kazımaya devam etmesini %100 engeller!
  bool _waitingForFingerLift = false;

  late GeneratedLevel _currentLevel;
  ScraperTool get _currentTool => _tools[_selectedToolIndex];
  ToolSkin get _currentSkin => _skins.firstWhere(
    (s) => s.id == _currentSkinId,
    orElse: () => _skins.first,
  );

  List<ui.Image> _stageDirtyImages = [];
  int _currentStageIndex = 0;
  int get _totalStages => _currentLevel.dirtStages.length;
  DirtLayerConfig get _activeStageDirtConfig =>
      _currentLevel.dirtStages[_currentStageIndex];

  /// Seçili olan alet şu anki katmanı temizleyebilir mi?
  /// (Artık Cila aşaması da zorunlu olarak 'polish' aletini veya Joker Lazer'i ister!)
  bool get _isCorrectToolSelectedForCurrentStage {
    if (_currentTool.isVipJoker) return true;
    return _currentTool.id == _activeStageDirtConfig.requiredToolId;
  }

  String? _wrongToolWarningMessage;
  Timer? _warningClearTimer;

  double get _effectiveBrushSize {
    final double upgradeBonus = 1.0 + (_brushPowerUpgradeLevel * 0.08);
    final double feverMultiplier = _isFeverActive ? 1.35 : 1.0;
    if (_currentTool.isVipJoker) {
      return _currentTool.baseBrushSize * upgradeBonus * feverMultiplier;
    }
    return (_currentTool.baseBrushSize *
            _currentLevel.resistanceFactor *
            upgradeBonus *
            feverMultiplier)
        .clamp(16.0, 140.0);
  }

  bool _isZenMode = false;
  Offset? _activeFingerPos;
  double _toolTiltAngle = 0.25;
  bool _isShowingBefore = false;

  final double _dirtOpacity = 0.75;

  ui.Image? _cleanImage;
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
  int _lastEarnedStars = 3;

  bool _hasVibrator = false;
  DateTime _lastVibrationTime = DateTime.now();

  static const int _gridSize = 100;
  late List<List<bool>> _isTargetCell;
  late List<List<bool>> _isCleanedInCurrentStage;

  int _totalTargetCells = 0;
  int _cleanedCellsInStage = 0;
  double _stageCleanPercentage = 0.0;
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
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _particleTicker = createTicker(_onTickFrame)..start();
    _initGame();
  }

  Future<void> _initGame() async {
    await _loadSavedProgress();
    await _initAudioAndHaptics();
    _currentLevel = LevelGenerator.generateLevel(_activePlayingLevelNum);
    await _loadLevelAssets();
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _playerName = prefs.getString('saved_player_name') ?? 'Usta_Oyuncu';
    _highestUnlockedLevel = prefs.getInt('saved_level') ?? 1;
    _activePlayingLevelNum = _highestUnlockedLevel;
    _totalCoins = prefs.getInt('saved_coins') ?? 0;
    _skipTickets = prefs.getInt('saved_skip_tickets') ?? 0;
    _brushPowerUpgradeLevel = prefs.getInt('saved_power_upgrade') ?? 0;
    _monetization.isProUser = prefs.getBool('saved_is_pro') ?? false;
    _currentSkinId = prefs.getString('saved_skin') ?? 'skin_default';
    _isSoundEnabled = prefs.getBool('saved_sound_on') ?? true;
    _isHapticsEnabled = prefs.getBool('saved_haptics_on') ?? true;
    _bestSpeedrunSeconds = prefs.getDouble('saved_best_speedrun') ?? 0.0;

    final List<String>? savedSkins = prefs.getStringList(
      'saved_unlocked_skins',
    );
    if (savedSkins != null) _unlockedSkinIds = savedSkins;

    final List<String>? savedTrophies = prefs.getStringList('saved_trophies');
    if (savedTrophies != null) _discoveredTrophyIds = savedTrophies.toSet();

    for (final t in TrophyItem.allTrophies) {
      _trophyCleanCounts[t.id] = prefs.getInt('trophy_count_${t.id}') ?? 0;
    }

    for (int i = 1; i <= 50; i++) {
      final int? s = prefs.getInt('level_stars_$i');
      if (s != null) _levelStars[i] = s;
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
    await prefs.setString('saved_player_name', _playerName);
    await prefs.setInt('saved_level', _highestUnlockedLevel);
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
    await prefs.setDouble('saved_best_speedrun', _bestSpeedrunSeconds);

    for (final entry in _trophyCleanCounts.entries) {
      await prefs.setInt('trophy_count_${entry.key}', entry.value);
    }
    for (final entry in _levelStars.entries) {
      await prefs.setInt('level_stars_${entry.key}', entry.value);
    }
  }

  bool _isToolUnlocked(ScraperTool tool) {
    if (_monetization.isProUser) return true;
    if (_highestUnlockedLevel >= tool.unlockLevel) return true;
    if (_monetization.dailyAdUnlockedTools.contains(tool.id)) return true;
    return false;
  }

  void _onTickFrame(Duration elapsed) {
    bool needsRepaint = false;

    if (_particles.isNotEmpty) {
      needsRepaint = true;
      for (int i = _particles.length - 1; i >= 0; i--) {
        _particles[i].update();
        if (_particles[i].life <= 0.02 || _particles[i].size <= 0.5) {
          _particles.removeAt(i);
        }
      }
    }

    if (_feverCharge > 0.0 && !_isLevelCompleted) {
      needsRepaint = true;
      _feverCharge = (_feverCharge - (_isFeverActive ? 0.0045 : 0.003)).clamp(
        0.0,
        1.0,
      );
      if (_feverCharge <= 0.05 && _isFeverActive) {
        _isFeverActive = false;
      }
    }

    if (needsRepaint && mounted) {
      setState(() {});
    }
  }

  void _spawnParticles(Offset position, Offset dragDelta) {
    if (_particles.length > 160) return;

    final tool = _currentTool;
    final skin = _currentSkin;
    final bool isUsingSteam = tool.id == 'steam';
    final int count = (tool.isVipJoker || _isFeverActive)
        ? 9
        : (isUsingSteam ? 7 : 6);
    final List<Color> dirtPalette = _activeStageDirtConfig.flakeColors;

    for (int i = 0; i < count; i++) {
      final double spread = _effectiveBrushSize * 0.45;
      final Offset spawnPos =
          position +
          Offset(
            (_random.nextDouble() - 0.5) * spread,
            (_random.nextDouble() - 0.5) * spread,
          );

      final double angle = _random.nextDouble() * 2 * pi;
      final double speed = isUsingSteam
          ? (0.6 + _random.nextDouble() * 2.0) // Buhar daha yumuşak dağılır
          : (1.2 + _random.nextDouble() * 4.2);

      final Offset velocity = isUsingSteam
          ? Offset(
              cos(angle) * speed + (dragDelta.dx * 0.1),
              -1.2 -
                  _random.nextDouble() *
                      2.2, // Buhar bulutu doğrudan YUKARI yükselir!
            )
          : Offset(
              cos(angle) * speed + (dragDelta.dx * 0.15),
              sin(angle) * speed - 1.5,
            );

      Color color;
      if (isUsingSteam) {
        color = dirtPalette[_random.nextInt(dirtPalette.length)];
      } else if (_isFeverActive && _random.nextDouble() < 0.5) {
        color = Colors.amberAccent;
      } else if (tool.isVipJoker) {
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

      final double size = isUsingSteam
          ? (7.0 +
                _random.nextDouble() *
                    8.0) // Buhar bulutları daha dolgun başlar
          : (3.5 + _random.nextDouble() * (tool.isVipJoker ? 6.5 : 5.0));

      _particles.add(
        ScrapeParticle(
          position: spawnPos,
          velocity: velocity,
          size: size,
          color: color,
          decay: 0.025 + _random.nextDouble() * 0.025,
          isSquare: tool.strokeCap == StrokeCap.square,
          isSteamCloud: isUsingSteam, // Buhar fiziğini aktif et!
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
    _levelStartTimestamp = null;

    setState(() {
      _isLoading = true;
      _activeFingerPos = null;
      _isShowingBefore = false;
      _currentStageIndex = 0;
      _waitingForFingerLift = false;
      _feverCharge = 0.0;
      _isFeverActive = false;
      _wrongToolWarningMessage = null;
      _remainingSeconds = _currentLevel.timeLimitSeconds;
    });

    if (!_isToolUnlocked(_currentTool)) {
      _selectedToolIndex = 0;
    }

    final cleanImg = await _loadUiImage(_currentLevel.cleanAsset);
    final List<ui.Image> loadedStageImages = [];
    for (final stageConfig in _currentLevel.dirtStages) {
      loadedStageImages.add(await _loadUiImage(stageConfig.assetPath));
    }

    final ByteData? pixelData = await cleanImg.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    if (mounted) {
      _cleanImage = cleanImg;
      _stageDirtyImages = loadedStageImages;
      _cleanPixelData = pixelData;
      _strokes.clear();
      _particles.clear();
      _buildTargetGridForNewLevel();

      setState(() => _isLoading = false);
    }
  }

  void _buildTargetGridForNewLevel() {
    _isTargetCell = List.generate(
      _gridSize,
      (_) => List.filled(_gridSize, false),
    );
    _isCleanedInCurrentStage = List.generate(
      _gridSize,
      (_) => List.filled(_gridSize, false),
    );

    _totalTargetCells = 0;
    _cleanedCellsInStage = 0;
    _stageCleanPercentage = 0.0;
    _isLevelCompleted = false;
    _currentStageIndex = 0;
    _waitingForFingerLift = false;
    _feverCharge = 0.0;
    _isFeverActive = false;
    _remainingSeconds = _currentLevel.timeLimitSeconds;
    _isTimerRunning = false;
    _levelStartTimestamp = null;

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

  /// Katman bittiğinde dokunuşu kilitler (`_waitingForFingerLift = true`)!
  /// Böylece oyuncu elini çekip yeni aleti seçmeden bir sonraki katmanı yanlışlıkla silemez!
  void _advanceToNextDirtStage() {
    _stopScrapeFeedback();
    _waitingForFingerLift = true; // ELİNİ ÇEKMEDEN DEVAM ETMESİNİ KİLİTLE!
    _activeFingerPos = null;
    _currentPath = null;
    _lastPanPosition = null;

    _currentStageIndex++;
    _strokes.clear();
    _cleanedCellsInStage = 0;
    _stageCleanPercentage = 0.0;
    _wrongToolWarningMessage = null;
    _isCleanedInCurrentStage = List.generate(
      _gridSize,
      (_) => List.filled(_gridSize, false),
    );

    if (_hasVibrator && _isHapticsEnabled) {
      Vibration.vibrate(duration: 85, amplitude: 230);
    }

    if (mounted && !_isZenMode) {
      final nextConfig = _activeStageDirtConfig;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✨ Katman tamamlandı! Şimdi ${nextConfig.name} için alt bardan "${nextConfig.requiredToolName}" aracını seç!',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          backgroundColor: nextConfig.isPolishStage
              ? Colors.cyan.shade800
              : Colors.deepOrange.shade800,
          duration: const Duration(milliseconds: 2400),
        ),
      );
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
    if (canvasSize <= 0 ||
        _totalTargetCells == 0 ||
        _isLevelCompleted ||
        _waitingForFingerLift) {
      return false;
    }

    bool newlyScrapedAny = false;
    int newlyScrapedCount = 0;
    final double brushSize = _effectiveBrushSize;
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
          if (_isTargetCell[gy][gx] && !_isCleanedInCurrentStage[gy][gx]) {
            final double dx = (gx + 0.5) - centerGx;
            final double dy = (gy + 0.5) - centerGy;
            if (dx * dx + dy * dy <= radiusSq) {
              _isCleanedInCurrentStage[gy][gx] = true;
              _cleanedCellsInStage++;
              newlyScrapedCount++;
              newlyScrapedAny = true;
            }
          }
        }
      }
    }

    if (newlyScrapedAny) {
      _feverCharge = (_feverCharge + (newlyScrapedCount * 0.0035)).clamp(
        0.0,
        1.0,
      );
      if (_feverCharge >= 0.95 && !_isFeverActive) {
        _isFeverActive = true;
      }

      _stageCleanPercentage =
          (_cleanedCellsInStage / _totalTargetCells) * 100.0;

      if (_stageCleanPercentage >= _currentLevel.targetCompletionPercent &&
          !_isLevelCompleted) {
        if (_currentStageIndex + 1 < _totalStages) {
          _advanceToNextDirtStage();
        } else {
          _completeEntireLevel(canvasSize);
        }
      }
    }

    return newlyScrapedAny;
  }

  void _completeEntireLevel(double canvasSize) {
    _levelCountdownTimer?.cancel();
    _isTimerRunning = false;
    _isLevelCompleted = true;
    _waitingForFingerLift = false;
    _stageCleanPercentage = 100.0;
    _activeFingerPos = null;
    _isFeverActive = false;
    _wrongToolWarningMessage = null;
    _stopScrapeFeedback();
    _particles.clear();

    if (_levelStartTimestamp != null) {
      final int elapsedMs = DateTime.now()
          .difference(_levelStartTimestamp!)
          .inMilliseconds;
      _lastClearedTimeSeconds = (elapsedMs / 1000.0).clamp(1.2, 99.0);
      if (_bestSpeedrunSeconds <= 0.0 ||
          _lastClearedTimeSeconds < _bestSpeedrunSeconds) {
        _bestSpeedrunSeconds = _lastClearedTimeSeconds;
      }
    } else {
      _lastClearedTimeSeconds = 5.0;
    }

    if (_currentLevel.timeLimitSeconds == null || _remainingSeconds == null) {
      _lastEarnedStars = 3;
    } else {
      final double ratio = _remainingSeconds! / _currentLevel.timeLimitSeconds!;
      _lastEarnedStars = ratio >= 0.35 ? 3 : (ratio >= 0.15 ? 2 : 1);
    }

    final int prevStars = _levelStars[_currentLevel.levelNumber] ?? 0;
    if (_lastEarnedStars > prevStars) {
      _levelStars[_currentLevel.levelNumber] = _lastEarnedStars;
    }

    final String objId = _currentLevel.objectId;
    final bool isFirstDiscovery = !_discoveredTrophyIds.contains(objId);
    _discoveredTrophyIds.add(objId);
    _trophyCleanCounts[objId] = (_trophyCleanCounts[objId] ?? 0) + 1;

    final int bonusAppliedReward = _lastEarnedStars == 3
        ? (_currentLevel.coinReward * 1.25).round()
        : _currentLevel.coinReward;

    _totalCoins += bonusAppliedReward;
    if (_activePlayingLevelNum >= _highestUnlockedLevel) {
      _highestUnlockedLevel++;
    }
    _activePlayingLevelNum++;
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

  void _startCountdownIfNeeded(double canvasSize) {
    _levelStartTimestamp ??= DateTime.now();
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
            'Aşama ${_currentStageIndex + 1}/$_totalStages (${_activeStageDirtConfig.name}) çok inatçı çıktı! Devam etmek ister misin?',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final watched = await _monetization.showRewardedAd(
                      context,
                      purpose:
                          '+18 Saniye Ek Süre ve JOKER Lazer Desteği almak',
                    );
                    if (watched && mounted) {
                      setState(() {
                        _remainingSeconds = 18;
                        _isTimerRunning = false;
                        _monetization.dailyAdUnlockedTools.add('mega');
                        _selectedToolIndex = 5; // 6. alet Lazer!
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
                    '+18 SN EK SÜRE + JOKER LAZER (REKLAM)',
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
              '👑 PRO Hak Kullanıldı! Kalan: ${_monetization.remainingProSkipsToday}/${MonetizationManager.maxDailyProSkips}',
            ),
            backgroundColor: Colors.amber.shade800,
          ),
        );
      }
      _completeEntireLevel(canvasSize);
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
      _completeEntireLevel(canvasSize);
      return;
    }

    final bool watched = await _monetization.showRewardedAd(
      context,
      purpose: 'Bu bölümü anında geçmek',
    );

    if (watched && mounted) {
      _completeEntireLevel(canvasSize);
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
      _currentLevel = LevelGenerator.generateLevel(_activePlayingLevelNum);
    });
    _loadLevelAssets();
  }

  Future<void> _onSelectTool(int index) async {
    final tool = _tools[index];

    if (!_isToolUnlocked(tool)) {
      final bool unlocked = await _monetization.showRewardedAd(
        context,
        purpose:
            '${tool.fullName} aracını bugünlük erkenden açmak (Normalde Sv.${tool.unlockLevel}\'de açılır)',
      );
      if (!unlocked || !mounted) return;

      _monetization.dailyAdUnlockedTools.add(tool.id);
      await _saveProgress();
    }

    _stopScrapeFeedback();

    setState(() {
      _selectedToolIndex = index;
      _waitingForFingerLift = false; // Yeni alet seçildiğinde kilidi aç!
      _wrongToolWarningMessage = null;
    });
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
                'Seviye: $_activePlayingLevelNum (Açık: $_highestUnlockedLevel) | Katman: ${_currentStageIndex + 1}/$_totalStages | PRO: ${_monetization.isProUser ? "AÇIK" : "KAPALI"}',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
              const Divider(color: Colors.white24, height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  setState(() {
                    _highestUnlockedLevel = 1;
                    _activePlayingLevelNum = 1;
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
                    _levelStars.clear();
                    _selectedToolIndex = 0;
                    _currentLevel = LevelGenerator.generateLevel(1);
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
                  'HER ŞEYİ SIFIRLA (SV.1 & KİLİTLERİ AKTİF ET)',
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
                          _highestUnlockedLevel = (_highestUnlockedLevel + 10)
                              .clamp(1, 50);
                          _activePlayingLevelNum = _highestUnlockedLevel;
                          _currentLevel = LevelGenerator.generateLevel(
                            _activePlayingLevelNum,
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
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                '• Tüm Zorunlu Geçiş Reklamlarını Kaldır\n'
                '• 6 Aletin Hepsini (JOKER Lazer Dahil) Sv.1\'den İtibaren Aç!\n'
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
                      await _onSelectTool(5); // Lazer
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
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '🎟️ $_skipTickets  |  🪙 $_totalCoins',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final watched = await _monetization.showRewardedAd(
                              context,
                              purpose: '+250 Altın kazanmak',
                            );
                            if (watched && mounted) {
                              setState(() => _totalCoins += 250);
                              setModalState(() {});
                              await _saveProgress();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(
                            Icons.ondemand_video_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            '+250 🪙 (REKLAM)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_totalCoins >= 300) {
                              setState(() {
                                _totalCoins -= 300;
                                _skipTickets++;
                              });
                              setModalState(() {});
                              _saveProgress();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(
                            Icons.fast_forward_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            '+1 BİLET (300 🪙)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    tileColor: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.amber,
                      size: 30,
                    ),
                    title: Text(
                      'Kalıcı Çap Büyütme (Lv.$_brushPowerUpgradeLevel/10)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      'Tüm aletleri +%'
                      '${_brushPowerUpgradeLevel * 8} büyütür',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: ElevatedButton(
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
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(
                        isMaxUpgrade ? 'MAKS' : '$upgradeCost 🪙',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 170,
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
                          width: 145,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isEquipped
                                  ? Colors.greenAccent
                                  : item.trimColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: item.handleGradient.first,
                                child: Icon(item.icon, color: Colors.white),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isEquipped
                                        ? Colors.greenAccent
                                        : Colors.amber,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: Text(
                                    isEquipped
                                        ? 'SEÇİLİ'
                                        : (isUnlocked
                                              ? 'KUŞAN'
                                              : '${item.price} 🪙'),
                                    style: const TextStyle(
                                      fontSize: 10,
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

  void _triggerWrongToolWarning() {
    _stopScrapeFeedback();
    if (_wrongToolWarningMessage == null) {
      if (_isHapticsEnabled) HapticFeedback.heavyImpact();
      setState(() {
        _wrongToolWarningMessage =
            '⚠️ ${_activeStageDirtConfig.name} için alt bardan "${_activeStageDirtConfig.requiredToolName}" seçmelisin!';
      });
    }
    _warningClearTimer?.cancel();
    _warningClearTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _wrongToolWarningMessage = null);
      }
    });
  }

  void _onPanStart(DragStartDetails details, double canvasSize) {
    if (_isLevelCompleted) return;
    // Yeni bir dokunuş başladığında parmak kaldırma kilidini aç
    _waitingForFingerLift = false;
    _startCountdownIfNeeded(canvasSize);
    _lastPanPosition = details.localPosition;

    setState(() {
      _activeFingerPos = details.localPosition;
      _toolTiltAngle = 0.2;
    });

    if (!_isCorrectToolSelectedForCurrentStage) {
      _triggerWrongToolWarning();
      return;
    }

    setState(() {
      _wrongToolWarningMessage = null;
      _currentPath = Path()
        ..moveTo(details.localPosition.dx, details.localPosition.dy);
      _strokes.add(
        ScrapeStroke(
          path: _currentPath!,
          brushSize: _effectiveBrushSize,
          strokeCap: _currentTool.strokeCap,
        ),
      );
      final bool didScrape = _markCellsAlongLine(
        details.localPosition,
        details.localPosition,
        canvasSize,
      );
      if (didScrape && !_waitingForFingerLift) {
        _spawnParticles(details.localPosition, Offset.zero);
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details, double canvasSize) {
    // EĞER AZ ÖNCE BİR KATMAN BİTTİYSE VE KULLANICI ELİNİ ÇEKMEDEN KAYDIRMAYA DEVAM EDİYORSA:
    // Yeni katmanı (Cila vb.) kazımasını %100 ENGELLE!
    if (_isLevelCompleted || _waitingForFingerLift) return;

    final Offset currentPos = details.localPosition;
    final Offset fromPos = _lastPanPosition ?? currentPos;
    _lastPanPosition = currentPos;

    final double targetTilt = (0.2 + (details.delta.dx * 0.025)).clamp(
      -0.45,
      0.55,
    );

    if (!_isCorrectToolSelectedForCurrentStage) {
      if (details.delta.distance > 1.5) {
        _triggerWrongToolWarning();
      }
      setState(() {
        _activeFingerPos = currentPos;
        _toolTiltAngle = _toolTiltAngle * 0.75 + targetTilt * 0.25;
      });
      return;
    }

    final bool didScrapeNewDirt = _markCellsAlongLine(
      fromPos,
      currentPos,
      canvasSize,
    );

    // Eğer _markCellsAlongLine sırasında katman bittiyse (_waitingForFingerLift == true olduysa) hemen çık!
    if (_waitingForFingerLift) return;

    if (details.delta.distance > 0.5) {
      if (didScrapeNewDirt) {
        _triggerScrapeFeedback();
        _spawnParticles(currentPos, details.delta);
      } else {
        _stopScrapeFeedback();
      }
    }

    setState(() {
      _activeFingerPos = currentPos;
      _toolTiltAngle = _toolTiltAngle * 0.75 + targetTilt * 0.25;
      _currentPath?.lineTo(currentPos.dx, currentPos.dy);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _waitingForFingerLift = false;
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
      _wrongToolWarningMessage = null;
      _strokes.clear();
      _particles.clear();
      _buildTargetGridForNewLevel();
    });
  }

  @override
  void dispose() {
    _warningClearTimer?.cancel();
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

    return _isInMainMenu ? _buildMainMenuScreen() : _buildGameplayScreen();
  }

  Widget _buildMainMenuScreen() {
    final int discoveredCount = _discoveredTrophyIds.length;
    final int totalTrophies = TrophyItem.allTrophies.length;
    final int totalStars = _levelStars.values.fold(0, (a, b) => a + b);

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
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _showDeveloperDebugModal,
                          icon: const Icon(
                            Icons.bug_report_rounded,
                            color: Colors.greenAccent,
                          ),
                          tooltip: 'Test Konsolu',
                        ),
                        IconButton(
                          onPressed: () => GameModals.showLeaderboardModal(
                            context,
                            currentPlayerName: _playerName,
                            userBestTimeSeconds: _bestSpeedrunSeconds,
                            userHighestLevel: _highestUnlockedLevel,
                            onUpdatePlayerName: (newName) {
                              setState(() => _playerName = newName);
                              _saveProgress();
                            },
                          ),
                          icon: const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.amber,
                          ),
                          tooltip: 'Dünya Hız Sıralaması',
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
                        '🪙 $_totalCoins',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1.03).animate(
                    CurvedAnimation(
                      parent: _pulseController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    width: 150,
                    height: 150,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withValues(alpha: 0.08),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: Image.asset(
                      _currentLevel.cleanAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'SATISFYING',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    color: Colors.amber,
                  ),
                ),
                Text(
                  _currentLevel.chapterTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'GÖREV: SEVİYE ${_currentLevel.levelNumber}/50 • ${_currentLevel.difficultyLabel}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: _currentLevel.difficultyColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentLevel.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _isInMainMenu = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 30),
                    label: Text(
                      'SEVİYE ${_currentLevel.levelNumber} • BAŞLA',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMenuCardButton(
                        icon: Icons.map_rounded,
                        color: Colors.cyanAccent,
                        title: 'HARİTA',
                        subtitle: '⭐ $totalStars/150',
                        onTap: () => GameModals.showLevelMapModal(
                          context,
                          highestUnlockedLevel: _highestUnlockedLevel,
                          activePlayingLevelNum: _activePlayingLevelNum,
                          levelStars: _levelStars,
                          onSelectLevel: (lvl) {
                            setState(() {
                              _activePlayingLevelNum = lvl;
                              _isInMainMenu = false;
                              _currentLevel = LevelGenerator.generateLevel(lvl);
                            });
                            _loadLevelAssets();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildMenuCardButton(
                        icon: Icons.emoji_events_rounded,
                        color: Colors.orangeAccent,
                        title: 'SIRALAMA',
                        subtitle: _bestSpeedrunSeconds <= 0
                            ? 'Rekor Yok'
                            : '${_bestSpeedrunSeconds.toStringAsFixed(1)}s',
                        onTap: () => GameModals.showLeaderboardModal(
                          context,
                          currentPlayerName: _playerName,
                          userBestTimeSeconds: _bestSpeedrunSeconds,
                          userHighestLevel: _highestUnlockedLevel,
                          onUpdatePlayerName: (newName) {
                            setState(() => _playerName = newName);
                            _saveProgress();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildMenuCardButton(
                        icon: Icons.museum_rounded,
                        color: Colors.purpleAccent,
                        title: 'MÜZE',
                        subtitle: '$discoveredCount/$totalTrophies',
                        onTap: () => GameModals.showTrophyRoomModal(
                          context,
                          discoveredTrophyIds: _discoveredTrophyIds,
                          trophyCleanCounts: _trophyCleanCounts,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildMenuCardButton(
                        icon: Icons.storefront_rounded,
                        color: Colors.greenAccent,
                        title: 'ATÖLYE',
                        subtitle: 'Lv.$_brushPowerUpgradeLevel',
                        onTap: _showShopModal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCardButton({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
            ),
            Text(
              subtitle,
              maxLines: 1,
              style: const TextStyle(fontSize: 9, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameplayScreen() {
    final int displayPercent = _stageCleanPercentage.floor().clamp(0, 100);
    final double screenCanvasEstimate = MediaQuery.of(context).size.width - 48;

    String skipButtonText = 'ATLA (📺)';
    if (_monetization.isProUser && _monetization.remainingProSkipsToday > 0) {
      skipButtonText = 'ATLA (${_monetization.remainingProSkipsToday}/5)';
    } else if (_skipTickets > 0) {
      skipButtonText = 'ATLA (🎟️$_skipTickets)';
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Column(
              children: [
                // 1. ÖZEL ESNEK ÜST BAR
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  child: Row(
                    children: [
                      if (!_isZenMode)
                        _buildSmallTopIconButton(
                          icon: Icons.home_rounded,
                          color: Colors.amber,
                          onTap: () {
                            _stopScrapeFeedback();
                            _levelCountdownTimer?.cancel();
                            _isTimerRunning = false;
                            setState(() => _isInMainMenu = true);
                          },
                        ),
                      _buildSmallTopIconButton(
                        icon: _isZenMode
                            ? Icons.visibility_off_rounded
                            : Icons.videocam_rounded,
                        color: _isZenMode ? Colors.white24 : Colors.white70,
                        onTap: () => setState(() => _isZenMode = !_isZenMode),
                      ),
                      if (!_isZenMode)
                        _buildSmallTopIconButton(
                          icon: Icons.bug_report_rounded,
                          color: Colors.greenAccent,
                          onTap: _showDeveloperDebugModal,
                        ),

                      Expanded(
                        child: _isZenMode
                            ? const SizedBox.shrink()
                            : GestureDetector(
                                onTap: () => GameModals.showLevelMapModal(
                                  context,
                                  highestUnlockedLevel: _highestUnlockedLevel,
                                  activePlayingLevelNum: _activePlayingLevelNum,
                                  levelStars: _levelStars,
                                  onSelectLevel: (lvl) {
                                    setState(() {
                                      _activePlayingLevelNum = lvl;
                                      _currentLevel =
                                          LevelGenerator.generateLevel(lvl);
                                    });
                                    _loadLevelAssets();
                                  },
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'SV.${_currentLevel.levelNumber}/50 • ${_currentLevel.difficultyLabel}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                _currentLevel.difficultyColor,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        Text(
                                          _currentLevel.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),

                      if (!_isZenMode) ...[
                        _buildSmallTopIconButton(
                          icon: Icons.emoji_events_rounded,
                          color: Colors.orangeAccent,
                          onTap: () => GameModals.showLeaderboardModal(
                            context,
                            currentPlayerName: _playerName,
                            userBestTimeSeconds: _bestSpeedrunSeconds,
                            userHighestLevel: _highestUnlockedLevel,
                            onUpdatePlayerName: (newName) {
                              setState(() => _playerName = newName);
                              _saveProgress();
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: _showShopModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              '🪙 $_totalCoins',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        _buildSmallTopIconButton(
                          icon: Icons.refresh_rounded,
                          color: Colors.white70,
                          onTap: _resetCanvas,
                        ),
                      ],
                    ],
                  ),
                ),

                const Spacer(),

                // 2. KONTROL ŞERİDİ
                if (!_isZenMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _wrongToolWarningMessage != null
                                      ? Colors.redAccent.withValues(alpha: 0.25)
                                      : Colors.white.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _wrongToolWarningMessage != null
                                        ? Colors.redAccent
                                        : Colors.cyanAccent.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                                ),
                                child: Text(
                                  _isLevelCompleted
                                      ? '✨ SÜRE: ${_lastClearedTimeSeconds.toStringAsFixed(2)} SN (REKOR: ${_bestSpeedrunSeconds.toStringAsFixed(2)}s)'
                                      : (_wrongToolWarningMessage ??
                                            'AŞAMA ${_currentStageIndex + 1}/$_totalStages: ${_activeStageDirtConfig.name.toUpperCase()} ➔ "${_activeStageDirtConfig.requiredToolName}" SEÇ'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: _wrongToolWarningMessage != null
                                        ? Colors.amberAccent
                                        : Colors.cyanAccent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!_isLevelCompleted)
                              InkWell(
                                onTap: () =>
                                    _handleSkipLevel(screenCanvasEstimate),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.amber),
                                  ),
                                  child: Text(
                                    skipButtonText,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              )
                            else
                              GestureDetector(
                                onTapDown: (_) =>
                                    setState(() => _isShowingBefore = true),
                                onTapUp: (_) =>
                                    setState(() => _isShowingBefore = false),
                                onTapCancel: () =>
                                    setState(() => _isShowingBefore = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isShowingBefore
                                        ? Colors.amber
                                        : Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.amber),
                                  ),
                                  child: Text(
                                    _isShowingBefore
                                        ? 'İLK HALİ'
                                        : 'ÖNCESİ (TUT)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: _isShowingBefore
                                          ? Colors.black
                                          : Colors.amber,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_remainingSeconds != null &&
                                      !_isLevelCompleted)
                                    Text(
                                      '⏱️ KALAN SÜRE: $_remainingSeconds SN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: _remainingSeconds! <= 8
                                            ? Colors.redAccent
                                            : Colors.amber,
                                      ),
                                    ),
                                  Text(
                                    _isFeverActive
                                        ? '🔥 FEVER 2X KOMBO AKTİF! (+%35 DEV ÇAP)'
                                        : (_isCorrectToolSelectedForCurrentStage
                                              ? '✅ DOĞRU ALET SEÇİLİ (${_currentTool.shortName.toUpperCase()})'
                                              : '❌ ALT BARDAN "${_activeStageDirtConfig.requiredToolName}" SEÇ!'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: _isFeverActive
                                          ? Colors.deepOrangeAccent
                                          : (_isCorrectToolSelectedForCurrentStage
                                                ? Colors.greenAccent
                                                : Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '%$displayPercent',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: _isLevelCompleted
                                    ? Colors.greenAccent
                                    : Colors.amber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _stageCleanPercentage / 100.0,
                            minHeight: 9,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isLevelCompleted
                                  ? Colors.greenAccent
                                  : Colors.amber,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _feverCharge,
                            minHeight: 4,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isFeverActive
                                  ? Colors.deepOrangeAccent
                                  : Colors.cyanAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                // 3. KAZIMA TUVALİ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: LayoutBuilder(
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
                                  stageDirtyImages: _stageDirtyImages,
                                  dirtStages: _currentLevel.dirtStages,
                                  currentStageIndex: _currentStageIndex,
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
                                  isFeverActive: _isFeverActive,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const Spacer(),

                // 4. ALT 6'LI SABİT DOCK BAR
                if (!_isZenMode)
                  SizedBox(
                    height: 80,
                    child: _isLevelCompleted
                        ? Center(
                            child: ElevatedButton.icon(
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
                                'SEVİYE $_activePlayingLevelNum • DEVAM ET',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          )
                        : _buildFixedSixToolDock(),
                  ),
                const SizedBox(height: 8),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallTopIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  /// SABİT 6'LI ALET DOCK ÇUBUĞU (Sünger, Cila, Buhar, Jilet, Zımpara, Lazer)
  Widget _buildFixedSixToolDock() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: List.generate(_tools.length, (index) {
          final tool = _tools[index];
          final bool isSelected = _selectedToolIndex == index;
          final bool isUnlocked = _isToolUnlocked(tool);
          final bool isRequiredForCurrentDirt =
              tool.id == _activeStageDirtConfig.requiredToolId;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: InkWell(
                onTap: () => _onSelectTool(index),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final bool shouldHighlight =
                        isRequiredForCurrentDirt && !isSelected;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isRequiredForCurrentDirt || tool.isVipJoker
                                  ? Colors.greenAccent.withValues(alpha: 0.18)
                                  : Colors.redAccent.withValues(alpha: 0.18))
                            : (shouldHighlight
                                  ? Colors.amber.withValues(
                                      alpha:
                                          0.12 +
                                          (_pulseController.value * 0.18),
                                    )
                                  : Colors.white.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? (isRequiredForCurrentDirt || tool.isVipJoker
                                    ? Colors.greenAccent
                                    : Colors.redAccent)
                              : (shouldHighlight
                                    ? Colors.amber
                                    : (!isUnlocked
                                          ? Colors.white24
                                          : Colors.white12)),
                          width: (isSelected || shouldHighlight) ? 2.0 : 1.0,
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
                                  horizontal: 3.0,
                                ),
                                child: Icon(
                                  tool.icon,
                                  color: isSelected
                                      ? (isRequiredForCurrentDirt ||
                                                tool.isVipJoker
                                            ? Colors.greenAccent
                                            : Colors.redAccent)
                                      : (shouldHighlight
                                            ? Colors.amber
                                            : (!isUnlocked
                                                  ? Colors.white38
                                                  : Colors.white)),
                                  size: 19,
                                ),
                              ),
                              if (!isUnlocked)
                                const Icon(
                                  Icons.lock_rounded,
                                  color: Colors.amber,
                                  size: 11,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              tool.shortName,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: shouldHighlight
                                    ? Colors.amber
                                    : Colors.white,
                              ),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              !isUnlocked
                                  ? 'SV.${tool.unlockLevel}/📺'
                                  : (shouldHighlight
                                        ? '★ SEÇ'
                                        : tool.specialtyLabel),
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                color: shouldHighlight
                                    ? Colors.amberAccent
                                    : (!isUnlocked
                                          ? Colors.amber
                                          : Colors.cyanAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
