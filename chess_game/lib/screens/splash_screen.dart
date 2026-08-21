import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'login_screen.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);

    _controller.forward().then((_) {
      _fadeController.forward();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotateAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '♚',
                          style: TextStyle(fontSize: 70, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Column(
                children: [
                  Text(
                    'CHESS MASTER',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Strategy. Skill. Victory.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white60,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accent.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
