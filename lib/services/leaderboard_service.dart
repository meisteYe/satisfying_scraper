import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/game_models.dart';

class LeaderboardService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _playersCollection = 'leaderboard';

  /// 1. Oyuncunun genel Kampanya ilerlemesini (En Yüksek Seviye ve Toplam Yıldız) kaydeder
  static Future<void> submitCampaignProgress({
    required String playerId,
    required String playerName,
    required int highestLevel,
    required int totalStars,
    String countryFlag = '🇹🇷',
  }) async {
    try {
      await _db.collection(_playersCollection).doc(playerId).set({
        'playerName': playerName,
        'countryFlag': countryFlag,
        'totalLevelsCleared': highestLevel,
        'totalStars': totalStars,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Kampanya skoru yazma hatası: $e');
    }
  }

  /// 2. SADECE belirli bir seviyenin (Örn: Seviye 12) bilek hakkıyla kırılan hız rekorunu kaydeder!
  /// (Atla butonu kullanılan bölümler buraya gönderilmez!)
  static Future<void> submitLevelSpeedrun({
    required int levelNumber,
    required String playerId,
    required String playerName,
    required double clearTimeSeconds,
    required int highestLevel,
    String countryFlag = '🇹🇷',
  }) async {
    // 2.0 saniyeden kısa imkansız/hatalı süreleri kaydetme
    if (clearTimeSeconds < 2.0 || clearTimeSeconds >= 99.0) return;

    final docRef = _db
        .collection('level_speedruns')
        .doc('level_$levelNumber')
        .collection('scores')
        .doc(playerId);

    try {
      final existing = await docRef.get();
      if (existing.exists) {
        final prevBest = ((existing.data()?['bestTimeSeconds'] as num?) ?? 99.9)
            .toDouble();
        // Eğer oyuncunun bu seviyedeki eski rekoru daha iyiyse üzerine yazma!
        if (clearTimeSeconds >= prevBest) return;
      }

      await docRef.set({
        'playerName': playerName,
        'countryFlag': countryFlag,
        'bestTimeSeconds': double.parse(clearTimeSeconds.toStringAsFixed(2)),
        'totalLevelsCleared': highestLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Seviye speedrun yazma hatası: $e');
    }
  }

  /// SEKME 1: Genel Kampanya Liderlerini (En yüksek seviyeye ulaşanları) getirir
  static Stream<List<LeaderboardEntry>> streamCampaignLeaders(
    String currentPlayerId,
  ) {
    return _db
        .collection(_playersCollection)
        .orderBy('totalLevelsCleared', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return LeaderboardEntry(
              playerName: (data['playerName'] as String?) ?? 'Usta_Oyuncu',
              countryFlag: (data['countryFlag'] as String?) ?? '🇹🇷',
              bestTimeSeconds: ((data['bestTimeSeconds'] as num?) ?? 0.0)
                  .toDouble(),
              totalLevelsCleared: ((data['totalLevelsCleared'] as num?) ?? 1)
                  .toInt(),
              totalStars: ((data['totalStars'] as num?) ?? 0).toInt(),
              isCurrentUser: doc.id == currentPlayerId,
            );
          }).toList();
        });
  }

  /// SEKME 2: Sadece seçili olan seviyenin (Örn: Seviye 5) en hızlı oyuncularını getirir!
  static Stream<List<LeaderboardEntry>> streamLevelSpeedruns(
    int levelNumber,
    String currentPlayerId,
  ) {
    return _db
        .collection('level_speedruns')
        .doc('level_$levelNumber')
        .collection('scores')
        .orderBy('bestTimeSeconds', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return LeaderboardEntry(
              playerName: (data['playerName'] as String?) ?? 'Usta_Oyuncu',
              countryFlag: (data['countryFlag'] as String?) ?? '🇹🇷',
              bestTimeSeconds: ((data['bestTimeSeconds'] as num?) ?? 99.9)
                  .toDouble(),
              totalLevelsCleared: ((data['totalLevelsCleared'] as num?) ?? 1)
                  .toInt(),
              isCurrentUser: doc.id == currentPlayerId,
            );
          }).toList();
        });
  }
}
