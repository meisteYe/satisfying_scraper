import 'package:flutter/material.dart';
import '../models/game_models.dart';

class LevelGenerator {
  static GeneratedLevel generateLevel(int levelNum) {
    final int idx = levelNum - 1;
    final bool isBoss = (levelNum % 5 == 0);

    // TrophyItem listesindeki 20 nesneyi sırasıyla kullanıyoruz!
    const allObjects = TrophyItem.allTrophies;
    final TrophyItem chosenTrophy = allObjects[idx % allObjects.length];

    const mud = DirtLayerConfig.mudLayer; // Sv.1 Sünger
    const tar = DirtLayerConfig.tarLayer; // Sv.10 Buhar
    const rust = DirtLayerConfig.rustLayer; // Sv.20 Jilet
    const oxide = DirtLayerConfig.heavyOxideLayer; // Sv.30 Zımpara
    const polish = DirtLayerConfig.polishFoamLayer; // Sv.1 Cila Spreyi

    String chapterTitle;
    String diffLabel;
    Color diffColor;
    List<DirtLayerConfig> stages;
    double resistance;
    double targetPercent;

    if (levelNum < 10) {
      chapterTitle = 'BÖLÜM 1: ÇIRAK ATÖLYESİ';
      if (levelNum >= 3) {
        stages = [mud, polish];
        diffLabel = isBoss ? '👑 GİZEMLİ BOSS (2 AŞAMA)' : 'KOLAY (2 AŞAMA)';
        diffColor = isBoss ? Colors.purpleAccent : Colors.cyanAccent;
        resistance = isBoss ? 0.85 : 0.94;
      } else {
        stages = [mud];
        diffLabel = 'ISINMA (1 AŞAMA)';
        diffColor = Colors.greenAccent;
        resistance = 1.0;
      }
      targetPercent = 97.5;
    } else if (levelNum < 20) {
      chapterTitle = 'BÖLÜM 2: BUHARLI TEMİZLİK';
      if (isBoss || levelNum >= 13) {
        stages = [mud, tar, polish];
        diffLabel = isBoss ? '👑 GİZEMLİ BOSS (3 AŞAMA)' : 'ORTA (3 AŞAMA)';
      } else {
        stages = [tar, polish];
        diffLabel = 'ORTA (2 AŞAMA)';
      }
      diffColor = isBoss ? Colors.purpleAccent : Colors.amber;
      resistance = 0.80 - ((levelNum - 10) * 0.01);
      targetPercent = 98.2;
    } else if (levelNum < 30) {
      chapterTitle = 'BÖLÜM 3: PASLI KALINTILAR';
      stages = (isBoss || levelNum >= 25)
          ? [mud, tar, rust, polish]
          : [tar, rust, polish];
      diffLabel = isBoss
          ? '👑 GİZEMLİ BOSS (${stages.length} AŞAMA)'
          : 'ZOR (${stages.length} AŞAMA)';
      diffColor = isBoss ? Colors.purpleAccent : Colors.orangeAccent;
      resistance = 0.68 - ((levelNum - 20) * 0.01);
      targetPercent = 98.6;
    } else {
      chapterTitle = 'BÖLÜM 4: AĞIR SANAYİ & MAHZEN';
      stages = (isBoss || levelNum >= 40)
          ? [mud, tar, rust, oxide, polish]
          : [tar, rust, oxide, polish];
      diffLabel = isBoss
          ? '👑 FİNAL BOSS (${stages.length} AŞAMA!)'
          : 'KABUS! (${stages.length} AŞAMA)';
      diffColor = Colors.redAccent;
      resistance = (0.56 - ((levelNum - 30) * 0.006)).clamp(0.44, 0.56);
      targetPercent = 99.0;
    }

    int? calculatedTimeLimit;
    if (levelNum >= 10 || isBoss) {
      final double secondsPerDirtLayer = (15.5 - (levelNum * 0.12)).clamp(
        9.5,
        15.5,
      );
      final double polishLayerSeconds = (9.5 - (levelNum * 0.05)).clamp(
        6.5,
        9.5,
      );

      double totalSec = 0;
      for (final st in stages) {
        totalSec += st.isPolishStage ? polishLayerSeconds : secondsPerDirtLayer;
      }

      if (isBoss) {
        totalSec += 4.0;
      }

      calculatedTimeLimit = totalSec.round().clamp(20, 68);
    }

    return GeneratedLevel(
      levelNumber: levelNum,
      objectId: chosenTrophy.id,
      title: chosenTrophy.title,
      chapterTitle: chapterTitle,
      difficultyLabel: diffLabel,
      difficultyColor: diffColor,
      isBossLevel: isBoss,
      isMysteryBoss: isBoss, // Her Boss bölümü gizemli (Mystery) başlar!
      cleanAsset: chosenTrophy.assetPath,
      dirtStages: stages,
      coinReward: (isBoss ? 180 : 65) + (levelNum * 6).clamp(0, 250),
      resistanceFactor: resistance,
      timeLimitSeconds: calculatedTimeLimit,
      targetCompletionPercent: targetPercent,
    );
  }
}
