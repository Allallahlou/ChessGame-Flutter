import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username != null && mounted) {
      _navigateToHome(username);
    }
  }

  void _navigateToHome(String username) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(username: username),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_usernameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _usernameController.text.trim());

    if (mounted) {
      setState(() => _isLoading = false);
      _navigateToHome(_usernameController.text.trim());
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
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
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  _isLogin ? 'Welcome Back!' : 'Create Account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin 
                    ? 'Sign in to continue your chess journey'
                    : 'Start your chess journey today',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  controller: _usernameController,
                  hint: 'Username',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AppColors.accent.withOpacity(0.5),
                    ),
                    child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isLogin ? 'SIGN IN' : 'SIGN UP',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin 
                      ? "Don't have an account? Sign Up"
                      : "Already have an account? Sign In",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _navigateToHome('Guest'),
                  child: const Text(
                    'Continue as Guest →',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(icon, color: Colors.white60),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
