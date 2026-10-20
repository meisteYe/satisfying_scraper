import 'dart:async';
import 'package:flutter/material.dart';

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
