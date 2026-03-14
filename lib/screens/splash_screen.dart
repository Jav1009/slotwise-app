// lib/features/auth/screens/splash_screen.dart
//
// WHAT THIS FILE DOES:
//   Branded splash screen shown on every cold start.
//   Runs tryRestoreSession() concurrently with the animation.
//   Waits for BOTH the animation (min 2.2s) AND session check to finish,
//   then navigates to the correct screen — no flicker, no jarring cuts.
//
// ANIMATION SEQUENCE:
//   0.0s  → Logo fades + scales in
//   0.6s  → App name slides up and fades in
//   1.1s  → Tagline fades in
//   1.6s  → Loading indicator fades in
//   2.2s+ → Navigate (only after session check also completes)
//
// NAVIGATION (via AppNav shortcuts — all use pushNamedAndRemoveUntil):
//   authenticated + isAdmin → AdminDashboardScreen  (/admin)
//   authenticated + isStaff → StaffDashboardScreen  (/staff)
//   authenticated           → CustomerShell         (/home)
//   unauthenticated         → LoginScreen           (/login)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slot_wise_booking/providers/auth_provider.dart';
import 'package:slot_wise_booking/routes/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Animation controllers ─────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _taglineCtrl;
  late final AnimationController _loaderCtrl;
  late final AnimationController _pulseCtrl;   // Pulse ring behind logo

  // ── Animations ────────────────────────────────────────────────────
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset>  _textSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _loaderFade;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseFade;

  // Track whether the session check is done
  bool _sessionCheckDone = false;
  // Track whether the minimum animation time has elapsed
  bool _minTimeDone = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // ── Logo: fade + scale in ──────────────────────────────────────
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );

    // ── App name: slide up + fade in ──────────────────────────────
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    // ── Tagline: fade in ──────────────────────────────────────────
    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _taglineFade = CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeIn);

    // ── Loading dots: fade in ─────────────────────────────────────
    _loaderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loaderFade = CurvedAnimation(parent: _loaderCtrl, curve: Curves.easeIn);

    // ── Pulse ring behind logo ─────────────────────────────────────
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseScale = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseFade = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
  }

  Future<void> _startSequence() async {
    // Start session check immediately — runs in parallel with animations
    final authProvider = context.read<AuthProvider>();
    authProvider.tryRestoreSession().then((_) {
      if (mounted) {
        setState(() => _sessionCheckDone = true);
        _maybeNavigate();
      }
    });

    // ── Animation sequence with staggered delays ──────────────────
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    _taglineCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _loaderCtrl.forward();

    // Minimum splash duration — feels intentional, not like a flash
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _minTimeDone = true);
    _maybeNavigate();
  }

  // Navigate only when BOTH the session check AND the minimum animation
  // time have completed — whichever finishes last triggers the route.
  void _maybeNavigate() {
    if (!_sessionCheckDone || !_minTimeDone) return;
    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    if (auth.isLoggedIn) {
      if (auth.isAdmin) {
        context.goAdminDashboard();
      } else if (auth.isStaff) {
        context.goStaffDashboard();
      } else {
        context.goCustomerHome();
      }
    } else {
      context.goLogin();
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _taglineCtrl.dispose();
    _loaderCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B3E), // Brand navy
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            // ── Logo with pulse ring ───────────────────────────────
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulse ring
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Opacity(
                        opacity: _pulseFade.value,
                        child: Transform.scale(
                          scale: _pulseScale.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFF9800),
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Icon container
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A4480), Color(0xFF0D1B3E)],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E56A8).withOpacity(0.5),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const _CalendarIcon(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            // ── App name ───────────────────────────────────────────
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textFade,
                child: const Text(
                  'SlotWise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    height: 1.0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Tagline ────────────────────────────────────────────
            FadeTransition(
              opacity: _taglineFade,
              child: const Text(
                'Book your appointment',
                style: TextStyle(
                  color: Color(0xFFFF9800),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2.5,
                ),
              ),
            ),

            const Spacer(flex: 3),

            // ── Loading indicator ──────────────────────────────────
            FadeTransition(
              opacity: _loaderFade,
              child: const _PulsingDots(),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

// ── Custom calendar icon drawn with widgets ───────────────────────────────────
class _CalendarIcon extends StatelessWidget {
  const _CalendarIcon();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Calendar header bar
          Container(
            height: 9,
            decoration: BoxDecoration(
              color: const Color(0xFF1E56A8),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 6),
          // Slot rows
          _slotRow(const Color(0xFFFF9800), 0.85),
          const SizedBox(height: 4),
          _slotRow(Colors.white.withOpacity(0.35), 0.6),
          const SizedBox(height: 4),
          // Row with checkmark
          Row(
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF9800), width: 1.5),
                ),
                child: const Icon(Icons.check, size: 9, color: Color(0xFFFF9800)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _slotRow(Colors.white.withOpacity(0.2), 0.7),
        ],
      ),
    );
  }

  Widget _slotRow(Color color, double widthFactor) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 7,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

// ── Three pulsing dots loading indicator ─────────────────────────────────────
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations    = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      final anim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
      _controllers.add(ctrl);
      _animations.add(anim);

      // Stagger each dot by 200ms
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: FadeTransition(
            opacity: _animations[i],
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF9800),
              ),
            ),
          ),
        );
      }),
    );
  }
}