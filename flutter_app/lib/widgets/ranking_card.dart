import 'package:flutter/material.dart';
import '../models/top_score.dart';

class RankingCard extends StatefulWidget {
  const RankingCard({
    super.key,
    required this.score,
    required this.rank,
    required this.delay,
  });

  final TopScore score;
  final int rank; // 0-indexed
  final Duration delay;

  @override
  State<RankingCard> createState() => _RankingCardState();
}

class _RankingCardState extends State<RankingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slide;

  static const _medals = ['👑', '🥈', '🥉'];
  static const _goldColor = Color(0xFFFFD700);
  static const _silverColor = Color(0xFFBDBDBD);
  static const _bronzeColor = Color(0xFFCD7F32);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _rankColor {
    switch (widget.rank) {
      case 0:
        return _goldColor;
      case 1:
        return _silverColor;
      case 2:
        return _bronzeColor;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.score;
    final rank = widget.rank;
    final isFirst = rank == 0;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slide,
        child: Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isFirst
                ? BorderSide(color: _goldColor.withOpacity(0.6), width: 1.5)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(
                  _medals[rank.clamp(0, 2)],
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.nickName,
                        style: TextStyle(
                          color: _rankColor,
                          fontSize: 16,
                          fontWeight: isFirst
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.kanriDate,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+${s.point.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: _rankColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
