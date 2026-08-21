import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_screen.dart';
import 'tutorial_screen.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  int _gamesPlayed = 0;
  int _gamesWon = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gamesPlayed = prefs.getInt('games_played') ?? 0;
      _gamesWon = prefs.getInt('games_won') ?? 0;
    });
  }

  void _startGame(PlayerColor color, int difficulty, bool vsComputer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          playerColor: color,
          difficulty: difficulty,
          vsComputer: vsComputer,
          username: widget.username,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome,',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          widget.username,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      color: AppColors.darkerBackground,
                      onSelected: (value) {
                        if (value == 'logout') _logout();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.white70, size: 20),
                              SizedBox(width: 12),
                              Text('Logout', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentLight],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Games', _gamesPlayed.toString(), Icons.games),
                      Container(width: 1, height: 40, color: Colors.white30),
                      _buildStat('Wins', _gamesWon.toString(), Icons.emoji_events),
                      Container(width: 1, height: 40, color: Colors.white30),
                      _buildStat(
                        'Win Rate',
                        _gamesPlayed > 0
                          ? '${((_gamesWon / _gamesPlayed) * 100).toStringAsFixed(0)}%'
                          : '0%',
                        Icons.trending_up,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'GAME MODES',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white38,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 16),
                _buildGameModeCard(
                  title: 'Play vs Computer',
                  subtitle: 'Challenge the AI',
                  icon: '🤖',
                  color: const Color(0xFF6c5ce7),
                  onTap: () => _showDifficultyDialog(),
                ),
                const SizedBox(height: 12),
                _buildGameModeCard(
                  title: 'Two Players',
                  subtitle: 'Play with a friend',
                  icon: '👥',
                  color: const Color(0xFF00b894),
                  onTap: () => _showColorDialog(vsComputer: false),
                ),
                const SizedBox(height: 12),
                _buildGameModeCard(
                  title: 'How to Play',
                  subtitle: 'Learn chess rules',
                  icon: '📖',
                  color: const Color(0xFF0984e3),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TutorialScreen()),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildGameModeCard({
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkerBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Select Difficulty',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyButton('Easy', 'Beginner friendly', 1, Colors.green),
            const SizedBox(height: 8),
            _buildDifficultyButton('Medium', 'Balanced challenge', 2, Colors.orange),
            const SizedBox(height: 8),
            _buildDifficultyButton('Hard', 'For experts', 3, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String title, String subtitle, int difficulty, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _showColorDialog(vsComputer: true, difficulty: difficulty);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorDialog({required bool vsComputer, int difficulty = 1}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkerBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Choose Your Side',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Row(
          children: [
            Expanded(
              child: _buildColorButton('White', 'White', '♔', Colors.white,
                PlayerColor.white, vsComputer, difficulty),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildColorButton('Black', 'Black', '♚', Colors.black,
                PlayerColor.black, vsComputer, difficulty),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(String label, String label2, String symbol, Color color,
      PlayerColor playerColor, bool vsComputer, int difficulty) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _startGame(playerColor, difficulty, vsComputer);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color == Colors.white
            ? Colors.white.withOpacity(0.15)
            : Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color == Colors.white
              ? Colors.white.withOpacity(0.3)
              : Colors.grey.withOpacity(0.5),
          ),
        ),
        child: Column(
          children: [
            Text(symbol, style: TextStyle(fontSize: 48, color: color == Colors.white ? Colors.white : Colors.white70)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color == Colors.white ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
