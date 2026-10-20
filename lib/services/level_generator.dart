import 'package:flutter/material.dart';
import '../models/game_models.dart';

class LevelGenerator {
  static const Map<String, String> _elmasObj = {
    'id': 'elmas',
    'asset': 'assets/images/elmas.png',
    'title': 'KRALİYET ELMASI',
  };
  static const Map<String, String> _zumrutObj = {
    'id': 'zumrut',
    'asset': 'assets/images/zumrut.png',
    'title': 'KADİM ZÜMRÜT',
  };
  static const Map<String, String> _bitcoinObj = {
    'id': 'bitcoin',
    'asset': 'assets/images/bitcoin.png',
    'title': 'ALTIN BITCOIN',
  };
  static const Map<String, String> _diskoObj = {
    'id': 'disko_topu',
    'asset': 'assets/images/disko_topu.png',
    'title': 'RETRO DİSKO TOPU',
  };
  static const Map<String, String> _tekerObj = {
    'id': 'teker',
    'asset': 'assets/images/teker.png',
    'title': 'YARIŞ JANTI & TEKER',
  };

  static GeneratedLevel generateLevel(int levelNum) {
    final int idx = levelNum - 1;
    final bool isBoss = (levelNum % 5 == 0);

    const mud = DirtLayerConfig.mudLayer; // Sv.1 Sünger
    const tar = DirtLayerConfig.tarLayer; // Sv.10 Buhar
    const rust = DirtLayerConfig.rustLayer; // Sv.20 Jilet
    const oxide = DirtLayerConfig.heavyOxideLayer; // Sv.30 Zımpara
    const polish = DirtLayerConfig.polishFoamLayer; // Sv.1 Cila Spreyi (Final)

    Map<String, String> chosenObj;
    String chapterTitle;
    String diffLabel;
    Color diffColor;
    List<DirtLayerConfig> stages;
    double resistance;
    double targetPercent;

    if (levelNum < 10) {
      // BÖLÜM 1 (SV 1-9): ÇIRAK ATÖLYESİ (Sünger + Cila)
      chapterTitle = 'BÖLÜM 1: ÇIRAK ATÖLYESİ';
      final pool = [_elmasObj, _zumrutObj, _elmasObj, _bitcoinObj];
      chosenObj = isBoss ? _tekerObj : pool[idx % pool.length];

      if (levelNum >= 3) {
        stages = [mud, polish];
        diffLabel = isBoss ? '👑 BOSS (ÇAMUR ➔ CİLA)' : 'KOLAY (2 AŞAMA)';
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
      // BÖLÜM 2 (SV 10-19): BUHARLI TEMİZLİK (Sünger + Buhar + Cila)
      chapterTitle = 'BÖLÜM 2: BUHARLI TEMİZLİK';
      final pool = [_bitcoinObj, _zumrutObj, _diskoObj, _elmasObj];
      chosenObj = isBoss ? _tekerObj : pool[idx % pool.length];

      if (isBoss || levelNum >= 13) {
        stages = [mud, tar, polish];
        diffLabel = isBoss ? '👑 BOSS (3 AŞAMA)' : 'ORTA (3 AŞAMA)';
      } else {
        stages = [tar, polish];
        diffLabel = 'ORTA (2 AŞAMA)';
      }
      diffColor = isBoss ? Colors.purpleAccent : Colors.amber;
      // Sv.10'da 0.80 ile başlar, Sv.19'da 0.71'e kadar kademeli daralır
      resistance = 0.80 - ((levelNum - 10) * 0.01);
      targetPercent = 98.2;
    } else if (levelNum < 30) {
      // BÖLÜM 3 (SV 20-29): PASLI KALINTILAR (Jilet Spatula Devrede!)
      chapterTitle = 'BÖLÜM 3: PASLI KALINTILAR';
      final pool = [_diskoObj, _bitcoinObj, _tekerObj, _zumrutObj];
      chosenObj = isBoss ? _tekerObj : pool[idx % pool.length];

      stages = (isBoss || levelNum >= 25)
          ? [mud, tar, rust, polish] // 4 Aşama
          : [tar, rust, polish]; // 3 Aşama
      diffLabel = isBoss
          ? '👑 BOSS (${stages.length} AŞAMA)'
          : 'ZOR (${stages.length} AŞAMA)';
      diffColor = isBoss ? Colors.purpleAccent : Colors.orangeAccent;
      // Sv.20'de 0.68 ile başlar, Sv.29'da 0.59'a kadar daralır
      resistance = 0.68 - ((levelNum - 20) * 0.01);
      targetPercent = 98.6;
    } else {
      // BÖLÜM 4 (SV 30-50+): AĞIR SANAYİ & MAHZEN (Dev Zımpara + 4/5 Aşama!)
      chapterTitle = 'BÖLÜM 4: AĞIR SANAYİ & MAHZEN';
      final pool = [_tekerObj, _diskoObj, _bitcoinObj];
      chosenObj = isBoss ? _diskoObj : pool[idx % pool.length];

      stages = (isBoss || levelNum >= 40)
          ? [mud, tar, rust, oxide, polish] // 5 Aşamalı Tam Restorasyon!
          : [tar, rust, oxide, polish]; // 4 Aşama
      diffLabel = isBoss
          ? '👑 FİNAL BOSS (${stages.length} AŞAMA!)'
          : 'KABUS! (${stages.length} AŞAMA)';
      diffColor = Colors.redAccent;
      // Sv.30'da 0.56 ile başlar, Sv.50'de 0.44'e kadar iner (Atölye upgrade'i veya Lazer/Fever şart olur!)
      resistance = (0.56 - ((levelNum - 30) * 0.006)).clamp(0.44, 0.56);
      targetPercent = 99.0;
    }

    // ========================================================================
    // DİNAMİK VE ADİL SÜRE HESAPLAMA MOTORU
    // ========================================================================
    int? calculatedTimeLimit;
    if (levelNum >= 10 || isBoss) {
      // 1. Seviye ilerledikçe katman başına verilen süreyi daralt (Sv.1: 15sn -> Sv.50: 9.5sn)
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

      // 2. Nesne yüzey alanı düzeltmesi (Teker ve Disko Topu geniş olduğu için +5 sn, Elmas/Zümrüt küçük olduğu için -2 sn)
      final String objId = chosenObj['id']!;
      if (objId == 'teker' || objId == 'disko_topu') {
        totalSec += 5.0;
      } else if (objId == 'elmas' || objId == 'zumrut') {
        totalSec -= 2.0;
      }

      // 3. Boss bölümlerinde ekstra heyecan için süreyi %10 sıkılaştır
      if (isBoss) {
        totalSec *= 0.90;
      }

      calculatedTimeLimit = totalSec.round().clamp(18, 65);
    }

    return GeneratedLevel(
      levelNumber: levelNum,
      objectId: chosenObj['id']!,
      title: chosenObj['title']!,
      chapterTitle: chapterTitle,
      difficultyLabel: diffLabel,
      difficultyColor: diffColor,
      isBossLevel: isBoss,
      cleanAsset: chosenObj['asset']!,
      dirtStages: stages,
      coinReward: (isBoss ? 150 : 60) + (levelNum * 6).clamp(0, 220),
      resistanceFactor: resistance,
      timeLimitSeconds: calculatedTimeLimit,
      targetCompletionPercent: targetPercent,
    );
  }
}
