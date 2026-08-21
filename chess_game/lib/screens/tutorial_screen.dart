import 'package:flutter/material.dart';
import '../utils/constants.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  final List<Map<String, dynamic>> _sections = const [
    {
      'title': 'How to Play',
      'content': 'Chess is played on an 8x8 board between two players: White and Black.\n\nWhite always moves first. Players alternate turns, moving one piece at a time.\n\nThe goal is to checkmate the opponent\'s king - put it in a position where it cannot escape capture.',
      'icon': Icons.sports_esports,
    },
    {
      'title': 'The Pieces',
      'content': 'Pawn - Moves forward 1 square (2 from starting position). Captures diagonally.\nKnight - Moves in an L shape. Can jump over pieces.\nBishop - Moves diagonally any distance.\nRook - Moves horizontally/vertically any distance.\nQueen - Combines Bishop and Rook movements.\nKing - Moves 1 square in any direction. The most important piece!',
      'icon': Icons.emoji_events,
    },
    {
      'title': 'Special Moves',
      'content': 'CASTLING: Move king 2 squares toward a rook, then place rook on the other side. Conditions: neither moved, path clear, king not in check.\n\nEN PASSANT: If a pawn moves 2 squares and lands beside an enemy pawn, that pawn can capture it as if it moved 1 square. Only on the next move!\n\nPROMOTION: When a pawn reaches the other end, it becomes a Queen (or other piece).',
      'icon': Icons.bolt,
    },
    {
      'title': 'Game Modes',
      'content': 'PLAYER vs PLAYER: Play against a friend on the same device.\n\nPLAYER vs AI: Challenge the computer! Choose difficulty: Easy, Medium, or Hard.\n\nTimer: Each player has 10 minutes. Run out of time = you lose!',
      'icon': Icons.videogame_asset,
    },
    {
      'title': 'Winning',
      'content': 'CHECK: Your king is under attack. You MUST respond!\n\nCHECKMATE: Your king is in check and cannot escape. Game over!\n\nSTALEMATE: No legal moves but king not in check. Draw!\n\nUse the UNDO button if you make a mistake.',
      'icon': Icons.military_tech,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.darkBackground,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'How to Play',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.accent.withOpacity(0.3),
                      AppColors.darkBackground,
                    ],
                  ),
                ),
                child: const Center(
                  child: Text(
                    '♛',
                    style: TextStyle(fontSize: 80, color: Colors.white24),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final section = _sections[index];
                  return _buildSection(
                    title: section['title']!,
                    content: section['content']!,
                    icon: section['icon']!,
                    index: index,
                  );
                },
                childCount: _sections.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: ExpansionTile(
          iconColor: AppColors.accent,
          collapsedIconColor: Colors.white60,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accentLight],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                content,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
