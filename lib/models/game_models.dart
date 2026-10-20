import 'dart:ui';
import 'package:flutter/material.dart';

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
          'Yüzyıllarca madenin derinliklerinde unutulmuş kusursuz kesim elmas.',
    ),
    TrophyItem(
      id: 'zumrut',
      title: 'KADİM ZÜMRÜT',
      assetPath: 'assets/images/zumrut.png',
      rarity: 'NADİR',
      rarityColor: Colors.greenAccent,
      requiredLevelToDiscover: 2,
      lore:
          'Antik tapınak kalıntılarından çıkarılan zümrüt yeşili değerli taş.',
    ),
    TrophyItem(
      id: 'bitcoin',
      title: 'ALTIN BITCOIN',
      assetPath: 'assets/images/bitcoin.png',
      rarity: 'DESTANSI',
      rarityColor: Colors.amber,
      requiredLevelToDiscover: 4,
      lore:
          'Soğuk cüzdan mahzenlerinde çamura bulanmış fiziksel koleksiyon parası.',
    ),
    TrophyItem(
      id: 'disko_topu',
      title: 'RETRO DİSKO TOPU',
      assetPath: 'assets/images/disko_topu.png',
      rarity: 'DESTANSI',
      rarityColor: Colors.purpleAccent,
      requiredLevelToDiscover: 7,
      lore: '80\'lerin efsanevi kulüplerinden kalma ayna parçalı disko küresi.',
    ),
    TrophyItem(
      id: 'teker',
      title: 'YARIŞ JANTI & TEKER',
      assetPath: 'assets/images/teker.png',
      rarity: 'EFSANEVİ (BOSS)',
      rarityColor: Colors.redAccent,
      requiredLevelToDiscover: 5,
      lore:
          'Zorlu ralli etaplarında katran ve çamura gömülmüş özel yarış tekeri.',
    ),
  ];
}

class DirtLayerConfig {
  final String name;
  final String assetPath;
  final String requiredToolId;
  final String requiredToolName;
  final int requiredToolUnlockLevel;
  final List<Color> flakeColors;
  final bool isPolishStage;

  const DirtLayerConfig({
    required this.name,
    required this.assetPath,
    required this.requiredToolId,
    required this.requiredToolName,
    required this.requiredToolUnlockLevel,
    required this.flakeColors,
    this.isPolishStage = false,
  });

  static const DirtLayerConfig mudLayer = DirtLayerConfig(
    name: 'Kaba Çamur',
    assetPath: 'assets/images/kirli_camur.png',
    requiredToolId: 'sponge',
    requiredToolName: 'SÜNGER',
    requiredToolUnlockLevel: 1,
    flakeColors: [
      Color(0xFF4E342E),
      Color(0xFF6D4C41),
      Color(0xFF8D6E63),
      Color(0xFF3E2723),
    ],
  );

  // Buhar kullanılırken beyaz/mavi sıcak su buharı ve çözülen kahve damlacıkları çıkar!
  static const DirtLayerConfig tarLayer = DirtLayerConfig(
    name: 'Kahve & Katran',
    assetPath: 'assets/images/kirli_kahve.png',
    requiredToolId: 'steam',
    requiredToolName: 'BUHAR MAKİNESİ',
    requiredToolUnlockLevel: 10,
    flakeColors: [
      Color(0xFFFFFFFF), // Saf Beyaz Sıcak Buhar
      Color(0xFFE0F7FA), // Açık Buz Mavisi Buhar
      Color(0xFFCFD8DC), // Yoğun Duman Grisi
      Color(0xFF8D6E63), // Çözülen Kahve Buharı
    ],
  );

  static const DirtLayerConfig rustLayer = DirtLayerConfig(
    name: 'Kızıl Pas',
    assetPath: 'assets/images/kirli_pas.png',
    requiredToolId: 'razor',
    requiredToolName: 'JİLET',
    requiredToolUnlockLevel: 20,
    flakeColors: [
      Color(0xFF8B4513),
      Color(0xFFA0522D),
      Color(0xFFD2691E),
      Color(0xFF5C3A21),
    ],
  );

  static const DirtLayerConfig heavyOxideLayer = DirtLayerConfig(
    name: 'Ağır Oksit',
    assetPath: 'assets/images/kirli_pas2.png',
    requiredToolId: 'grinder',
    requiredToolName: 'ZIMPARA',
    requiredToolUnlockLevel: 30,
    flakeColors: [
      Color(0xFFBF360C),
      Color(0xFFD84315),
      Color(0xFF6D4C41),
      Color(0xFFFF7043),
    ],
  );

  static const DirtLayerConfig polishFoamLayer = DirtLayerConfig(
    name: 'Cila Köpüğü',
    assetPath: 'assets/images/kirli_camur.png',
    requiredToolId: 'polish',
    requiredToolName: 'CİLA SPREYİ',
    requiredToolUnlockLevel: 1,
    flakeColors: [
      Color(0xFFFFFFFF),
      Color(0xFF80D8FF),
      Color(0xFFB388FF),
      Color(0xFFFFF59D),
    ],
    isPolishStage: true,
  );
}

class ScrapeParticle {
  Offset position;
  Offset velocity;
  double size;
  double life;
  final double decay;
  final Color color;
  final bool isSquare;
  final bool
  isSteamCloud; // YENİ: Buhar bulutu yerçekimiyle düşmez, yukarı yükselip genişler!

  ScrapeParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    this.life = 1.0,
    this.decay = 0.035,
    this.isSquare = false,
    this.isSteamCloud = false,
  });

  void update() {
    position += velocity;
    if (isSteamCloud) {
      // GERÇEK BUHAR FİZİĞİ: Yukarı doğru süzülür (-0.22 ivme) ve yayıldıkça çapı büyür (1.035x)!
      velocity = Offset(velocity.dx * 0.94, velocity.dy - 0.22);
      size *= 1.032;
      life -= decay * 0.85;
    } else {
      // KATI TOZ/TALAŞ FİZİĞİ: Yerçekimiyle aşağı düşer (+0.38 ivme) ve küçülür
      velocity = Offset(velocity.dx * 0.96, velocity.dy + 0.38);
      size *= 0.98;
      life -= decay;
    }
  }
}

class ScraperTool {
  final String id;
  final String shortName;
  final String fullName;
  final String specialtyLabel;
  final IconData icon;
  final double baseBrushSize;
  final StrokeCap strokeCap;
  final String audioAsset;
  final int vibrationDuration;
  final int vibrationAmplitude;
  final int unlockLevel;
  final bool isVipJoker;

  const ScraperTool({
    required this.id,
    required this.shortName,
    required this.fullName,
    required this.specialtyLabel,
    required this.icon,
    required this.baseBrushSize,
    required this.strokeCap,
    required this.audioAsset,
    required this.vibrationDuration,
    required this.vibrationAmplitude,
    required this.unlockLevel,
    this.isVipJoker = false,
  });

  static const List<ScraperTool> allTools = [
    ScraperTool(
      id: 'sponge',
      shortName: 'Sünger',
      fullName: 'Islak Temizlik Süngeri',
      specialtyLabel: 'ÇAMUR',
      icon: Icons.cleaning_services_rounded,
      baseBrushSize: 44.0,
      strokeCap: StrokeCap.round,
      audioAsset: 'audio/scrape_loop.wav',
      vibrationDuration: 15,
      vibrationAmplitude: 90,
      unlockLevel: 1,
    ),
    ScraperTool(
      id: 'polish',
      shortName: 'Cila',
      fullName: 'Parlatıcı Cila Spreyi',
      specialtyLabel: 'PARLATIR',
      icon: Icons.auto_fix_high_rounded,
      baseBrushSize: 52.0,
      strokeCap: StrokeCap.round,
      audioAsset: 'audio/scrape_loop.wav',
      vibrationDuration: 10,
      vibrationAmplitude: 65,
      unlockLevel: 1,
    ),
    ScraperTool(
      id: 'steam',
      shortName: 'Buhar',
      fullName: 'Basınçlı Buhar Makinesi',
      specialtyLabel: 'KAHVE',
      icon: Icons.cloud_rounded,
      baseBrushSize: 48.0,
      strokeCap: StrokeCap.round,
      audioAsset: 'audio/scrape_loop.wav',
      vibrationDuration: 18,
      vibrationAmplitude: 125,
      unlockLevel: 10,
    ),
    ScraperTool(
      id: 'razor',
      shortName: 'Jilet',
      fullName: 'Çelik Jilet Spatula',
      specialtyLabel: 'PAS',
      icon: Icons.carpenter_rounded,
      baseBrushSize: 54.0,
      strokeCap: StrokeCap.square,
      audioAsset: 'audio/razor_loop.wav',
      vibrationDuration: 12,
      vibrationAmplitude: 165,
      unlockLevel: 20,
    ),
    ScraperTool(
      id: 'grinder',
      shortName: 'Zımpara',
      fullName: 'Ağır Sanayi Zımparası',
      specialtyLabel: 'OKSİT',
      icon: Icons.handyman_rounded,
      baseBrushSize: 60.0,
      strokeCap: StrokeCap.square,
      audioAsset: 'audio/razor_loop.wav',
      vibrationDuration: 22,
      vibrationAmplitude: 210,
      unlockLevel: 30,
    ),
    ScraperTool(
      id: 'mega',
      shortName: 'Lazer',
      fullName: 'Mega Plazma Lazeri (JOKER)',
      specialtyLabel: 'JOKER',
      icon: Icons.bolt_rounded,
      baseBrushSize: 88.0,
      strokeCap: StrokeCap.round,
      audioAsset: 'audio/laser_loop.wav',
      vibrationDuration: 28,
      vibrationAmplitude: 255,
      unlockLevel: 40,
      isVipJoker: true,
    ),
  ];
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

  static const List<ToolSkin> allSkins = [
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
}

class GeneratedLevel {
  final int levelNumber;
  final String objectId;
  final String title;
  final String chapterTitle;
  final String difficultyLabel;
  final Color difficultyColor;
  final bool isBossLevel;
  final String cleanAsset;
  final List<DirtLayerConfig> dirtStages;
  final int coinReward;
  final double resistanceFactor;
  final int? timeLimitSeconds;
  final double targetCompletionPercent;

  const GeneratedLevel({
    required this.levelNumber,
    required this.objectId,
    required this.title,
    required this.chapterTitle,
    required this.difficultyLabel,
    required this.difficultyColor,
    required this.isBossLevel,
    required this.cleanAsset,
    required this.dirtStages,
    required this.coinReward,
    required this.resistanceFactor,
    this.timeLimitSeconds,
    required this.targetCompletionPercent,
  });
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

class LeaderboardEntry {
  final String playerName;
  final String countryFlag;
  final double bestTimeSeconds;
  final int totalLevelsCleared;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.playerName,
    required this.countryFlag,
    required this.bestTimeSeconds,
    required this.totalLevelsCleared,
    this.isCurrentUser = false,
  });
}
