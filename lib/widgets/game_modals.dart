import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/leaderboard_service.dart';

class GameModals {
  /// 🎁 GÜNLÜK GİRİŞ ÖDÜLÜ (7 GÜNLÜK SERİ BONUS PENCERESİ)
  static void showDailyLoginRewardDialog(
    BuildContext context, {
    required int streakDay,
    required int rewardCoins,
    required bool givesTicket,
    required VoidCallback onClaim,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181822),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(color: Colors.amber, width: 2),
          ),
          title: const Column(
            children: [
              Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 54),
              SizedBox(height: 8),
              Text(
                'GÜNLÜK ATÖLYE ÖDÜLÜ!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GÜN $streakDay SERİ BONUSU',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '+$rewardCoins 🪙 ALTIN',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber,
                      ),
                    ),
                    if (givesTicket) ...[
                      const SizedBox(height: 6),
                      const Text(
                        '+1 🎟️ ÜCRETSİZ ATLAMA BİLETİ!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Her gün oyuna girerek ödülünü katla!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onClaim();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'ÖDÜLÜ TOPLA!',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 🏆 2 SEKMELİ CANLI DÜNYA SIRALAMASI (1: KAMPANYA LİDERLERİ | 2: BU SEVİYENİN EN HIZLILARI)
  static void showLeaderboardModal(
    BuildContext context, {
    required String currentPlayerId,
    required String currentPlayerName,
    required int currentLevelNumber,
    required String currentLevelTitle,
    required int userHighestLevel,
    required ValueChanged<String> onUpdatePlayerName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14141A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DefaultTabController(
          length: 2,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.82,
            minChildSize: 0.5,
            maxChildSize: 0.94,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
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
                                'CANLI DÜNYA SIRALAMASI',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Gerçek Oyuncular • Firebase Canlı Veritabanı',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ],
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
                                      if (newName.isNotEmpty)
                                        onUpdatePlayerName(newName);
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
                          label: Text(
                            currentPlayerName,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 2 SEKME SEÇİCİ: GENEL SEVİYE LİDERLERİ vs BU SEVİYENİN HIZ REKORU!
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.white70,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                        tabs: [
                          const Tab(text: '👑 KAMPANYA LİDERLERİ'),
                          Tab(text: '⚡ SEVİYE $currentLevelNumber HIZ REKORU'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: TabBarView(
                        children: [
                          // SEKME 1: GENEL KAMPANYA LİDERLERİ (Ulaşılan Seviye & Yıldız)
                          StreamBuilder<List<LeaderboardEntry>>(
                            stream: LeaderboardService.streamCampaignLeaders(
                              currentPlayerId,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.amber,
                                  ),
                                );
                              }
                              final players = snapshot.data ?? [];
                              if (players.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'Henüz sıralama kaydı yok.\nBir seviye tamamlayarak liderliği ele geçir!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                );
                              }
                              return ListView.builder(
                                controller: scrollController,
                                itemCount: players.length,
                                itemBuilder: (context, index) {
                                  final entry = players[index];
                                  final int rank = index + 1;
                                  return _buildLeaderboardRow(
                                    rank: rank,
                                    entry: entry,
                                    rightBadgeText:
                                        'SV.${entry.totalLevelsCleared} • ⭐${entry.totalStars}',
                                  );
                                },
                              );
                            },
                          ),

                          // SEKME 2: SADECE BU SEVİYENİN (SV.X) SPEEDRUN HIZ REKORLARI!
                          Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Sadece Seviye $currentLevelNumber ($currentLevelTitle) bölümünü "Atla" kullanmadan en hızlı bitirenler!',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: StreamBuilder<List<LeaderboardEntry>>(
                                  stream:
                                      LeaderboardService.streamLevelSpeedruns(
                                        currentLevelNumber,
                                        currentPlayerId,
                                      ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.amber,
                                        ),
                                      );
                                    }
                                    final players = snapshot.data ?? [];
                                    if (players.isEmpty) {
                                      return Center(
                                        child: Text(
                                          'Seviye $currentLevelNumber için henüz hız rekoru kırılmadı!\nBu seviyeyi tamamla ve ilk rekoru sen koy! ⚡',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      );
                                    }
                                    return ListView.builder(
                                      itemCount: players.length,
                                      itemBuilder: (context, index) {
                                        final entry = players[index];
                                        final int rank = index + 1;
                                        return _buildLeaderboardRow(
                                          rank: rank,
                                          entry: entry,
                                          rightBadgeText:
                                              '⚡ ${entry.bestTimeSeconds.toStringAsFixed(2)} sn',
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static Widget _buildLeaderboardRow({
    required int rank,
    required LeaderboardEntry entry,
    required String rightBadgeText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? Colors.amber.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.isCurrentUser ? Colors.amber : Colors.white12,
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
                        : (rank == 3 ? Colors.brown.shade400 : Colors.white10)),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: rank <= 3 ? Colors.black : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(entry.countryFlag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.isCurrentUser
                  ? '${entry.playerName} (SEN)'
                  : entry.playerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: entry.isCurrentUser ? Colors.amber : Colors.white,
              ),
            ),
          ),
          Text(
            rightBadgeText,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: Colors.cyanAccent,
            ),
          ),
        ],
      ),
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
                              '20 Eşsiz Nesne • Her 5 Seviyede Gizemli Boss!',
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
                                    Icons.help_outline_rounded,
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

  /// 🏛️ 20 NESNELİ HAZİNE MÜZESİ
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
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.94,
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
                              'HAZİNE MÜZESİ (20 ESER)',
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
                            childAspectRatio: 0.80,
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
                                height: 88,
                                width: 88,
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
                                    : '??? GİZEMLİ ESER',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.5,
                                  color: isDiscovered
                                      ? Colors.white
                                      : Colors.white38,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isDiscovered
                                    ? '$cleanCount Kez Parlatıldı ✨'
                                    : 'Seviye ${trophy.requiredLevelToDiscover}\'de Keşfedilir',
                                style: TextStyle(
                                  fontSize: 9.5,
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
