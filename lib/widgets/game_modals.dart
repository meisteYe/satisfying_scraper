import 'package:flutter/material.dart';
import '../models/game_models.dart';

class GameModals {
  /// 🏆 CANLI OYUNCU SIRALAMASI (OVERFLOW HATASI %100 GİDERİLDİ + KULLANICI ADI DÜZENLEME EKLENDİ)
  static void showLeaderboardModal(
    BuildContext context, {
    required String currentPlayerName,
    required double userBestTimeSeconds,
    required int userHighestLevel,
    required ValueChanged<String> onUpdatePlayerName,
  }) {
    final List<LeaderboardEntry> competitors = [
      const LeaderboardEntry(
        playerName: 'Emir_01',
        countryFlag: '🇹🇷',
        bestTimeSeconds: 3.92,
        totalLevelsCleared: 50,
      ),
      const LeaderboardEntry(
        playerName: 'NeoScraper_JP',
        countryFlag: '🇯🇵',
        bestTimeSeconds: 4.15,
        totalLevelsCleared: 48,
      ),
      const LeaderboardEntry(
        playerName: 'KralRestorator',
        countryFlag: '🇹🇷',
        bestTimeSeconds: 4.65,
        totalLevelsCleared: 45,
      ),
      const LeaderboardEntry(
        playerName: 'BlitzCleaner',
        countryFlag: '🇩🇪',
        bestTimeSeconds: 5.10,
        totalLevelsCleared: 42,
      ),
      const LeaderboardEntry(
        playerName: 'ZenMaster_KR',
        countryFlag: '🇰🇷',
        bestTimeSeconds: 5.88,
        totalLevelsCleared: 39,
      ),
      const LeaderboardEntry(
        playerName: 'RustBuster99',
        countryFlag: '🇬🇧',
        bestTimeSeconds: 6.45,
        totalLevelsCleared: 31,
      ),
      LeaderboardEntry(
        playerName: currentPlayerName,
        countryFlag: '🇹🇷',
        bestTimeSeconds: userBestTimeSeconds <= 0 ? 99.9 : userBestTimeSeconds,
        totalLevelsCleared: userHighestLevel,
        isCurrentUser: true,
      ),
    ];

    competitors.sort((a, b) => a.bestTimeSeconds.compareTo(b.bestTimeSeconds));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14141A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // ÜST BAŞLIK SATIRI: Expanded kullanılarak 17 piksellik taşma %100 engellendi!
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.amber,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DÜNYA HIZ SIRALAMASI',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'En Hızlı Seviye Temizleme Rekorları',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          userBestTimeSeconds <= 0
                              ? 'REKOR YOK'
                              : '${userBestTimeSeconds.toStringAsFixed(2)}s',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // KULLANICI ADI (NICKNAME) DEĞİŞTİRME ŞERİDİ
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          color: Colors.cyanAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Oyuncu Adın: $currentPlayerName',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            final controller = TextEditingController(
                              text: currentPlayerName,
                            );
                            showDialog(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E26),
                                title: const Text(
                                  'Oyuncu Adını Değiştir',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: TextField(
                                  controller: controller,
                                  maxLength: 16,
                                  decoration: const InputDecoration(
                                    hintText: 'Takma adın (Nickname)',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx),
                                    child: const Text('İptal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final newName = controller.text.trim();
                                      if (newName.isNotEmpty) {
                                        onUpdatePlayerName(newName);
                                      }
                                      Navigator.pop(dCtx);
                                      Navigator.pop(ctx);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('Kaydet'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: Colors.amber,
                          ),
                          label: const Text(
                            'Adı Değiştir',
                            style: TextStyle(color: Colors.amber, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: competitors.length,
                      itemBuilder: (context, index) {
                        final entry = competitors[index];
                        final int rank = index + 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: entry.isCurrentUser
                                ? Colors.amber.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: entry.isCurrentUser
                                  ? Colors.amber
                                  : Colors.white12,
                              width: entry.isCurrentUser ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: rank == 1
                                      ? Colors.amber
                                      : (rank == 2
                                            ? Colors.grey.shade400
                                            : (rank == 3
                                                  ? Colors.brown.shade400
                                                  : Colors.white10)),
                                ),
                                child: Text(
                                  '$rank',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: rank <= 3
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                entry.countryFlag,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.playerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: entry.isCurrentUser
                                            ? Colors.amber
                                            : Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Ulaşılan Seviye: ${entry.totalLevelsCleared}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                entry.bestTimeSeconds >= 99.0
                                    ? '--.-- sn'
                                    : '⚡ ${entry.bestTimeSeconds.toStringAsFixed(2)} sn',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: Colors.cyanAccent,
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

  /// 🗺️ 50 SEVİYELİK YOL HARİTASI
  static void showLevelMapModal(
    BuildContext context, {
    required int highestUnlockedLevel,
    required int activePlayingLevelNum,
    required Map<int, int> levelStars,
    required ValueChanged<int> onSelectLevel,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14141A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.80,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            final int totalStars = levelStars.values.fold(0, (a, b) => a + b);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.map_rounded,
                        color: Colors.amber,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '50 SEVİYE YOL HARİTASI',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Her 10 seviyede yeni bir uzman alet açılır!',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
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
                          '⭐ $totalStars / 150',
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
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: 50,
                      itemBuilder: (context, index) {
                        final int lvl = index + 1;
                        final bool isUnlocked = lvl <= highestUnlockedLevel;
                        final bool isCurrent = lvl == activePlayingLevelNum;
                        final bool isBoss = lvl % 5 == 0;
                        final int stars = levelStars[lvl] ?? 0;

                        return GestureDetector(
                          onTap: () {
                            if (isUnlocked) {
                              Navigator.pop(ctx);
                              onSelectLevel(lvl);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '🔒 Seviye $lvl henüz kilitli! Önce Seviye $highestUnlockedLevel\'i tamamla.',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: isCurrent
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFFFB300),
                                        Color(0xFFFF6F00),
                                      ],
                                    )
                                  : (isBoss && isUnlocked
                                        ? LinearGradient(
                                            colors: [
                                              Colors.purple.shade800,
                                              Colors.deepPurple.shade900,
                                            ],
                                          )
                                        : null),
                              color: isUnlocked
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrent
                                    ? Colors.white
                                    : (isBoss
                                          ? Colors.purpleAccent.withValues(
                                              alpha: 0.6,
                                            )
                                          : Colors.white12),
                                width: isCurrent ? 2.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isBoss)
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 13,
                                    color: isCurrent
                                        ? Colors.black
                                        : Colors.purpleAccent,
                                  ),
                                Text(
                                  '$lvl',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: isCurrent
                                        ? Colors.black
                                        : (isUnlocked
                                              ? Colors.white
                                              : Colors.white24),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                if (!isUnlocked)
                                  const Icon(
                                    Icons.lock_rounded,
                                    size: 12,
                                    color: Colors.white24,
                                  )
                                else
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(3, (starIdx) {
                                      return Icon(
                                        Icons.star_rounded,
                                        size: 11,
                                        color: starIdx < stars
                                            ? (isCurrent
                                                  ? Colors.black
                                                  : Colors.amber)
                                            : Colors.white24,
                                      );
                                    }),
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

  /// 🏛️ HAZİNE MÜZESİ
  static void showTrophyRoomModal(
    BuildContext context, {
    required Set<String> discoveredTrophyIds,
    required Map<String, int> trophyCleanCounts,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14141A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final int discoveredCount = discoveredTrophyIds.length;
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
                  Row(
                    children: [
                      const Icon(
                        Icons.museum_rounded,
                        color: Colors.amber,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HAZİNE MÜZESİ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Kurtarılan Nadir Yadigarlar Vitrini',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
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
                        final bool isDiscovered = discoveredTrophyIds.contains(
                          trophy.id,
                        );
                        final int cleanCount =
                            trophyCleanCounts[trophy.id] ?? 0;

                        return Container(
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
}
