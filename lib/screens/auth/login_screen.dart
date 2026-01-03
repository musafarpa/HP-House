import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';

// Glassmorphism Dark Theme
class _Theme {
  static const Color bg = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color glass = Color(0xFF252525);
  static const Color glassBorder = Color(0xFF3A3A3A);

  static const Color white = Color(0xFFFFFFFF);
  static const Color text = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF888888);

  static const Color accent = Color(0xFF6366F1);  // Indigo
  static const Color accentLight = Color(0xFF818CF8);
  static const Color accentDark = Color(0xFF4F46E5);

  static const Color error = Color(0xFFEF4444);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _usernameFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLogin = true;
  bool _isSubmitting = false;  // Local flag to prevent multiple submissions
  String? _errorMessage;

  late AnimationController _bgController;
  late AnimationController _contentController;
  late AnimationController _shakeController;
  late Animation<double> _headerAnim;
  late Animation<double> _formAnim;
  late Animation<double> _footerAnim;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    _emailFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
    _usernameFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  void _initAnimations() {
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _headerAnim = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );

    _formAnim = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    );

    _footerAnim = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );

    _contentController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _usernameFocus.dispose();
    _bgController.dispose();
    _contentController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _Theme.bg,
        body: Stack(
          children: [
            // Animated Background Orbs
            _AnimatedBackground(controller: _bgController),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 50),
                      _buildHeader(),
                      const SizedBox(height: 50),
                      _buildGlassCard(),
                      const SizedBox(height: 30),
                      _buildFooter(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(_headerAnim),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_Theme.accent, _Theme.accentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _Theme.accent.withAlpha(102),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.home_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 32),

            // Title
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                _isLogin ? 'Welcome\nBack' : 'Join\nHP House',
                key: ValueKey('title_$_isLogin'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: _Theme.white,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isLogin ? 'Sign in to continue to your account' : 'Create an account to get started',
                key: ValueKey('subtitle_$_isLogin'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: _Theme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return FadeTransition(
      opacity: _formAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_formAnim),
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            // Shake animation - oscillates left and right
            final shakeOffset = _shakeAnimation.value * 10 *
                ((_shakeAnimation.value * 10).toInt() % 2 == 0 ? 1 : -1) *
                (1 - _shakeAnimation.value);
            return Transform.translate(
              offset: Offset(shakeOffset, 0),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _Theme.glass.withAlpha(153),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _Theme.glassBorder.withAlpha(128)),
                ),
                child: Column(
                  children: [
                    // Error Message Banner
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _errorMessage != null
                          ? Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: _Theme.error.withAlpha(30),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _Theme.error.withAlpha(100)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _Theme.error.withAlpha(40),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.error_outline_rounded,
                                      color: _Theme.error,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: _Theme.error,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _errorMessage = null),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: _Theme.error,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Tab Switcher
                    _TabSwitcher(
                      isLogin: _isLogin,
                      onChanged: (isLogin) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isLogin = isLogin;
                          _errorMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 28),

                    // Form Fields
                    AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Column(
                      children: [
                        if (!_isLogin) ...[
                          _GlassInput(
                            controller: _usernameController,
                            focusNode: _usernameFocus,
                            hint: 'Username',
                            icon: Icons.alternate_email_rounded,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _emailFocus.requestFocus(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _GlassInput(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          hint: 'Email address',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 16),
                        _GlassInput(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          hint: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleSubmit(),
                          suffix: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                            child: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: _Theme.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Forgot Password
                  if (_isLogin) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pushNamed(context, RouteNames.forgotPassword);
                        },
                        child: Text(
                          'Forgot password?',
                          style: GoogleFonts.plusJakartaSans(
                            color: _Theme.accentLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Submit Button
                  _GradientButton(
                    text: _isLogin ? 'Sign In' : 'Create Account',
                    onTap: _handleSubmit,
                    isSubmitting: _isSubmitting,
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: _Theme.glassBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: GoogleFonts.plusJakartaSans(
                            color: _Theme.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Container(height: 1, color: _Theme.glassBorder)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Social Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _SocialBtn(
                          icon: Icons.g_mobiledata_rounded,
                          label: 'Google',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.read<AuthProvider>().signInWithGoogle();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SocialBtn(
                          icon: Icons.apple_rounded,
                          label: 'Apple',
                          onTap: () => HapticFeedback.lightImpact(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _footerAnim,
      child: Center(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _isLogin = !_isLogin);
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(fontSize: 15),
                children: [
                  TextSpan(
                    text: _isLogin ? "Don't have an account? " : 'Already have an account? ',
                    style: const TextStyle(color: _Theme.textSecondary),
                  ),
                  TextSpan(
                    text: _isLogin ? 'Sign Up' : 'Sign In',
                    style: const TextStyle(
                      color: _Theme.accentLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() async {
    // Prevent multiple clicks - check local flag first (immediate block)
    if (_isSubmitting) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) return;

    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && username.isEmpty)) {
      _showError('Please fill in all fields');
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    // Validate password length
    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    // Block immediately before any async operation
    setState(() => _isSubmitting = true);

    HapticFeedback.mediumImpact();

    try {
      bool success = false;

      if (_isLogin) {
        success = await authProvider.signIn(email: email, password: password);
      } else {
        success = await authProvider.signUp(
          email: email,
          password: password,
          username: username,
        );
      }

      if (!mounted) return;

      if (success) {
        // Navigate on success - don't reset _isSubmitting as we're leaving
        Navigator.pushReplacementNamed(context, RouteNames.home);
      } else {
        // Reset and show error
        setState(() => _isSubmitting = false);
        if (authProvider.error != null) {
          _showError(authProvider.error!);
        } else {
          _showError('Authentication failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        String errorMessage = e.toString();
        // Clean up error message
        if (errorMessage.contains('Invalid login credentials')) {
          errorMessage = 'Invalid email or password';
        } else if (errorMessage.contains('User already registered')) {
          errorMessage = 'An account with this email already exists';
        } else if (errorMessage.contains('Exception:')) {
          errorMessage = errorMessage.replaceAll('Exception:', '').trim();
        }
        _showError(errorMessage);
      }
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    setState(() => _errorMessage = message);

    // Trigger shake animation
    _shakeController.forward(from: 0).then((_) {
      _shakeController.reset();
    });
  }
}

// ==================== WIDGETS ====================

// Animated Background with floating orbs
class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -100 + (50 * (controller.value)),
              right: -80 + (30 * controller.value),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _Theme.accent.withAlpha(77),
                      _Theme.accent.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150 + (60 * (1 - controller.value)),
              left: -100 + (40 * controller.value),
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _Theme.accentDark.withAlpha(64),
                      _Theme.accentDark.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              left: -50 + (25 * controller.value),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _Theme.accentLight.withAlpha(38),
                      _Theme.accentLight.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Tab Switcher
class _TabSwitcher extends StatelessWidget {
  final bool isLogin;
  final Function(bool) onChanged;

  const _TabSwitcher({required this.isLogin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _Theme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabItem(
              text: 'Sign In',
              isActive: isLogin,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _TabItem(
              text: 'Sign Up',
              isActive: !isLogin,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({required this.text, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [_Theme.accent, _Theme.accentDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: isActive ? Colors.white : _Theme.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

// Glass Input
class _GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? suffix;
  final Function(String)? onSubmitted;

  const _GlassInput({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.suffix,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isFocused ? 1 : 0),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            color: _Theme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color.lerp(_Theme.glassBorder, _Theme.accent, value)!,
              width: 1.5,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: _Theme.accent.withAlpha(38),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        onFieldSubmitted: onSubmitted,
        cursorColor: _Theme.accent,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(color: _Theme.textSecondary, fontSize: 15),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, color: focusNode.hasFocus ? _Theme.accent : _Theme.textSecondary, size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 56),
          suffixIcon: suffix != null
              ? Padding(padding: const EdgeInsets.only(right: 16), child: suffix)
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 56),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}

// Gradient Button
class _GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isSubmitting;

  const _GradientButton({
    required this.text,
    required this.onTap,
    this.isSubmitting = false,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isLoading = auth.isLoading || widget.isSubmitting;

        return IgnorePointer(
          ignoring: isLoading,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: AnimatedOpacity(
                opacity: isLoading ? 0.7 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_Theme.accent, _Theme.accentDark],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _Theme.accent.withAlpha(isLoading ? 50 : 102),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isLoading
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.text,
                              key: ValueKey(widget.text),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Social Button
class _SocialBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialBtn({required this.icon, required this.label, required this.onTap});

  @override
  State<_SocialBtn> createState() => _SocialBtnState();
}

class _SocialBtnState extends State<_SocialBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: _Theme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _Theme.glassBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: _Theme.text, size: 24),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  color: _Theme.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
